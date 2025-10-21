extends Node2D
class_name Player3SelfTalkSystem

# Self-talk messages for Player 3 in the store
var self_talk_messages = {
	"store_entry": [
		"Alright, I'm in the store now. Let me look around and see what I can find.",

	] as Array[String],
	"after_item_interact": {
		"snacks": "Ooh, snacks! Always hard to choose... do I go salty or sweet?",
		"fridge": "Hmm... beverages.",
		"slurpee": "DROP COVER AND HOLD",
		"ice_cream_fridge": "Ice cream won't last long without power, but maybe there are other frozen goods.",
		"meat_fridge": "Frozen meat could be useful if I can cook it before the power goes out completely.",
		"hotdog_siopao": "Hotdog or siopao? Man, tough choice. Maybe HotPao?.",
		"food_section": "Let's see what they've got here... canned stuff, quick bites. Pretty standard."
	},
	"movement_comments": [
		"Let me check over here...",
		"What's in this section?",
		"I should look around more carefully.",
		"Maybe there's something useful here.",
		"I need to cover all areas of the store."
	] as Array[String],
	"go_to_exit": [
		"I should head to the exit now.",
		"Time to get out—make for the exit!",
		"The exit's my best bet. Let's move."
	] as Array[String],
	"building_collapse": [
		"The building is collapsing! Get to the exit!"
	] as Array[String]
}

# Cooldown tracking to prevent spam across all self-talk types
var last_self_talk_ms: int = 0
var movement_comment_cooldown_ms: int = 10000  # 10 seconds
var movement_min_velocity: float = 10.0         # Require player to be moving
# Global cooldown applied to ALL self-talk types (movement, interaction, custom)
var global_self_talk_cooldown_ms: int = 10000   # 10 seconds
# Interaction queue and dedupe to serialize messages triggered by item interactions
var interaction_queue: Array[String] = []
var interaction_processing: bool = false
var _last_item_type: String = ""
var _last_item_type_time_ms: int = 0
var interaction_dedupe_window_ms: int = 1500

var has_shown_entry_message = false
var is_currently_interacting = false
var pending_interaction_self_talk = ""
var interaction_self_talk_timer: Timer

@onready var player = get_parent()

# Unified check to prevent any overlapping dialogs (DialogManager or SimpleDialogManager)
func _is_any_dialog_active() -> bool:
	# Use autoload nodes via /root to avoid null globals
	var dm = get_node_or_null("/root/DialogManager")
	if dm != null:
		var is_active := bool(dm.get("is_dialog_active"))
		if is_active:
			return true
		var cur = dm.get("current_dialog")
		if cur != null and is_instance_valid(cur):
			# Only treat as active when visible or actively showing
			if bool(cur.get("visible")):
				return true
			if bool(cur.get("is_showing")):
				return true
	# Check SimpleDialogManager similarly
	var sdm = get_node_or_null("/root/SimpleDialogManager")
	if sdm != null:
		var cur2 = sdm.get("current_dialog")
		if cur2 != null and is_instance_valid(cur2):
			if bool(cur2.get("visible")):
				return true
			if bool(cur2.get("is_showing")):
				return true
	# Consider internal bubble active
	if _bubble_active and _bubble_panel != null and _bubble_panel.visible:
		return true
	# Consider bottom textbox active
	if _textbox_active and _textbox_panel != null and _textbox_panel.visible:
		return true
	return false

func _ready():
	# Add this node to a group so it can be found
	add_to_group("player3_self_talk_system")
	
	# Create timer for delayed interaction self-talk
	interaction_self_talk_timer = Timer.new()
	interaction_self_talk_timer.one_shot = true
	interaction_self_talk_timer.timeout.connect(_show_pending_interaction_self_talk)
	add_child(interaction_self_talk_timer)
	
	# Listen for new nodes so we can restyle newly spawned dialog bubbles
	var tree := get_tree()
	if tree != null and _force_restyle_manager_dialogs:
		tree.node_added.connect(_on_node_added)
	
	# Wait a moment for the scene to fully load, then show entry message
	await get_tree().create_timer(2.0).timeout
	show_store_entry_message()

func show_store_entry_message():
	if has_shown_entry_message:
		return
	
	has_shown_entry_message = true
	
	# Show a random entry message
	var messages = self_talk_messages["store_entry"]
	var random_message = messages[randi() % messages.size()]
	
	# Avoid overlapping or spamming; respect global cooldown
	if not _can_show_now():
		# Queue entry message when blocked
		interaction_queue.push_back(random_message)
		is_currently_interacting = true
		_ensure_interaction_processing()
	else:
		_show_dialog_above_player(random_message)

func trigger_after_item_interact_talk(item_type: String):
	# Ensure message only enqueues if player is truly interacting with the asset
	if not _is_interacting_with_item(item_type):
		print("DEBUG: Skipping after_interact talk; not actively interacting with ", item_type)
		return
	
	# Check if we have the after_item_interact category
	if not self_talk_messages.has("after_item_interact"):
		return
	var after_item_interact = self_talk_messages["after_item_interact"]
	if not after_item_interact.has(item_type):
		return
	
	# Dedupe rapid repeated triggers for same item type
	var now_ms: int = Time.get_ticks_msec()
	if item_type == _last_item_type and (now_ms - _last_item_type_time_ms) < interaction_dedupe_window_ms:
		return
	_last_item_type = item_type
	_last_item_type_time_ms = now_ms
	
	var message: String = after_item_interact[item_type]
	interaction_queue.push_back(message)
	is_currently_interacting = true
	_ensure_interaction_processing()

func _wait_for_dialog_and_show_self_talk():
	# Wait until no active dialog AND global cooldown is ready
	while _is_any_dialog_active() or not _cooldown_ready():
		await get_tree().create_timer(0.25).timeout
	
	# Add a small delay to prevent overlap
	await get_tree().create_timer(0.75).timeout
	
	# Show the self-talk if we still have a pending message
	if pending_interaction_self_talk != "":
		_show_dialog_above_player(pending_interaction_self_talk)
		pending_interaction_self_talk = ""
	
	# Reset interaction state after a delay
	await get_tree().create_timer(3.0).timeout
	is_currently_interacting = false

func _cooldown_ready() -> bool:
	return Time.get_ticks_msec() - last_self_talk_ms >= global_self_talk_cooldown_ms

func _can_show_now() -> bool:
	return (not _is_any_dialog_active()) and _cooldown_ready()

# Interactions should bypass the global cooldown and only block on active dialogs
func _can_show_interaction_now() -> bool:
	return not _is_any_dialog_active()

func _show_pending_interaction_self_talk():
	if pending_interaction_self_talk != "" and not _is_any_dialog_active():
		# Bail out if player became invalid (scene change)
		if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
			pending_interaction_self_talk = ""
			is_currently_interacting = false
			return
		_show_dialog_above_player(pending_interaction_self_talk)
		pending_interaction_self_talk = ""
		
		# Reset interaction state after showing the message
		await get_tree().create_timer(3.0).timeout
		is_currently_interacting = false

func trigger_movement_comment():
	# Don't show movement comments during interactions
	if is_currently_interacting:
		return
	
	# Only show if no dialog of any kind is active
	if _is_any_dialog_active():
		return
	
	# Ensure player reference is valid and inside tree
	if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
		return
	
	# Global cooldown: only allow movement comment if 10s has passed since any self-talk
	var now: int = Time.get_ticks_msec()
	if now - last_self_talk_ms < movement_comment_cooldown_ms:
		return
	
	# Require player to be moving to avoid idle spam
	if player is CharacterBody2D:
		if player.velocity.length() < movement_min_velocity:
			return
	
	var messages = self_talk_messages["movement_comments"]
	var random_message = messages[randi() % messages.size()]
	_show_dialog_above_player(random_message)

func trigger_custom_self_talk(custom_message: String):
	# Don't show custom self-talk during interactions unless it's from the debug system
	if is_currently_interacting and not "debug system" in custom_message:
		return
	# Prevent overlap with any active dialog and apply global cooldown
	if not _can_show_now():
		return
	# Ensure player is valid before showing
	if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
		return
		
	_show_dialog_above_player(custom_message)

# NEW: Prompt player to go to the exit (priority, bypass cooldown)
func trigger_go_to_exit_hint():
	var messages = self_talk_messages.get("go_to_exit", [])
	var msg: String = "Head to the exit."
	if messages.size() > 0:
		msg = messages[randi() % messages.size()]
	if not _can_show_interaction_now():
		interaction_queue.push_back(msg)
		_ensure_interaction_processing()
		return
	last_self_talk_ms = Time.get_ticks_msec()
	# Use bottom textbox style; persist until cleared
	_show_textbox(msg, 0.0, false)

# NEW: Urgent alert when the building is collapsing (priority, bypass cooldown)
func trigger_building_collapse_alert():
	var messages = self_talk_messages.get("building_collapse", [])
	var msg: String = "The building is collapsing! Get to the exit!"
	if messages.size() > 0:
		msg = messages[0]
	if not _can_show_interaction_now():
		interaction_queue.push_back(msg)
		_ensure_interaction_processing()
		return
	last_self_talk_ms = Time.get_ticks_msec()
	# Urgent bottom textbox style (red background)
	_show_textbox(msg, 6.0, true)

# Follow UI state
var _follow_dialog: Node = null
var _follow_active: bool = false
var _follow_offset: Vector2 = Vector2(0, -120)
var _follow_random_x: float = 0.0
# Internal bubble UI fallback
var _use_manager_for_self_talk: bool = false
var _bubble_layer: CanvasLayer = null
var _bubble_panel: Panel = null
var _bubble_label: Label = null
var _bubble_active: bool = false
var _bubble_ttl_timer: Timer = null
# Bottom textbox UI
var _use_textbox_for_self_talk: bool = true
var _textbox_layer: CanvasLayer = null
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_active: bool = false
var _textbox_ttl_timer: Timer = null
# Force restyle of manager dialogs into bottom textbox
var _force_restyle_manager_dialogs: bool = false
var _last_restyle_text: String = ""

func _show_dialog_above_player(message: String):
	"""Show dialog above the player"""
	print("DEBUG: _show_dialog_above_player called with message: ", message)
	var p = player
	if p == null or not is_instance_valid(p) or p.is_queued_for_deletion() or not p.is_inside_tree():
		print("DEBUG: Player invalid or freed; aborting self-talk display")
		return
	
	var dialog_position: Vector2
	var sprite = p.get_node_or_null("Sprite2D")
	# Validate sprite before using it; freed objects can still be non-null
	if sprite != null and is_instance_valid(sprite) and not sprite.is_queued_for_deletion() and sprite.is_inside_tree():
		# Use sprite's global_position directly
		var sprite_global_pos = sprite.global_position
		var texture_height = 0
		if sprite.texture:
			texture_height = sprite.texture.get_height() * sprite.scale.y
		dialog_position = Vector2(sprite_global_pos.x, sprite_global_pos.y - texture_height/2 - 80)
	else:
		# Fallback: position above player center with spacing
		dialog_position = p.global_position + Vector2(0, -120)
	
	# Add some randomization to prevent exact overlap
	var random_shift := randf_range(-20, 20)
	dialog_position.x += random_shift
	_follow_random_x = random_shift
	# Use internal UI when not using manager
	if not _use_manager_for_self_talk:
		last_self_talk_ms = Time.get_ticks_msec()
		if _use_textbox_for_self_talk:
			_show_textbox(message)
		else:
			_show_follow_bubble(message)
		return
	
	# Safely call the available manager to start the dialog
	var created_dialog: Node = null
	# Ensure we pass a typed Array[String] to start_dialog
	var lines: Array[String] = []
	lines.append(message)
	var dm = get_node_or_null("/root/DialogManager")
	if dm != null and is_instance_valid(dm) and dm.has_method("start_dialog"):
		created_dialog = dm.start_dialog(dialog_position, lines)
	else:
		var sdm = get_node_or_null("/root/SimpleDialogManager")
		if sdm != null and is_instance_valid(sdm) and sdm.has_method("start_dialog"):
			created_dialog = sdm.start_dialog(dialog_position, lines)
		else:
			# As a last resort, try setting current_dialog directly if present (manager may auto-create)
			created_dialog = null
	
	# Track last self-talk time (for cooldown)
	last_self_talk_ms = Time.get_ticks_msec()
	# Begin following the current dialog with the same horizontal shift
	_follow_random_x = random_shift
	if created_dialog != null and is_instance_valid(created_dialog):
		_follow_dialog = created_dialog
	# Always begin follow so we can reacquire even if current node not yet available
	_follow_active = true
	set_process(true)
	# Try immediate acquisition via manager APIs
	_start_following_current_dialog()

func _ensure_interaction_processing():
	if interaction_processing:
		return
	interaction_processing = true
	call_deferred("_process_interaction_queue")

func _process_interaction_queue():
	while interaction_queue.size() > 0:
		# Abort if player becomes invalid (e.g., scene change)
		if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
			interaction_queue.clear()
			interaction_processing = false
			is_currently_interacting = false
			return
		# Wait until no active dialog; interactions bypass global cooldown
		while not _can_show_interaction_now():
			await get_tree().create_timer(0.25).timeout
		
		var msg: String = interaction_queue.pop_front()
		_show_dialog_above_player(msg)
		# Wait a bit for auto-close and avoid immediate stacking
		await get_tree().create_timer(2.5).timeout
	
	# Clear interaction state when queue drains
	interaction_processing = false
	await get_tree().create_timer(0.5).timeout
	is_currently_interacting = false

# Add mapping to ensure after_interact messages only show when interacting with the asset
var action_name_by_item_type: Dictionary = {
	"snacks": "examine snacks",
	"fridge": "examine fridge",
	"slurpee": "examine slurpee",
	"ice_cream_fridge": "examine ice cream fridge",
	"meat_fridge": "examine meat fridge",
	"hotdog_siopao": "examine hotdog and siopao",
	"food_section": "examine snacks"
}

func _is_interacting_with_item(item_type: String) -> bool:
	# Validate that the current active InteractionArea corresponds to the item_type
	if typeof(InteractionManager) == TYPE_NIL:
		print("DEBUG: InteractionManager not available; gating failed for ", item_type)
		return false
	var expected: String = action_name_by_item_type.get(item_type, "")
	if expected == "":
		# If we don't have a mapping, allow by default (legacy assets may not set an action name)
		return true
	# InteractionManager.active_areas is sorted by closest; index 0 is the area that was interacted
	if not InteractionManager.active_areas or InteractionManager.active_areas.size() == 0:
		return false
	var closest_area = InteractionManager.active_areas[0]
	if not closest_area:
		return false
	# Safely read action_name; returns null if missing, then cast to String
	var current_action: String = str(closest_area.get("action_name"))
	return current_action == expected

# removed duplicate trigger_after_item_interact_talk; consolidated above with active-area gating

# Earthquake safety self-talk sequence messages for Player 3
var earthquake_safety_messages: Array[String] = [
	"Drop, cover, and hold…",
	"Okay, stay calm… just stay under the table.",
	"Please let this stop soon..."
]

var eq_sequence_running: bool = false

func trigger_earthquake_safety_sequence():
	# Only run once per earthquake
	if eq_sequence_running:
		return
	# Ensure player is valid
	if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
		return
	eq_sequence_running = true
	call_deferred("_run_earthquake_safety_sequence")

func _run_earthquake_safety_sequence():
	for msg in earthquake_safety_messages:
		# bail if player invalid mid-sequence
		if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
			eq_sequence_running = false
			return
		# wait until no other dialog and global cooldown is ready
		while _is_any_dialog_active() or not _cooldown_ready():
			await get_tree().create_timer(0.25).timeout
			if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
				eq_sequence_running = false
				return
		_show_dialog_above_player(msg)
		# brief pause between safety lines
		await get_tree().create_timer(3.0).timeout
	eq_sequence_running = false

func _get_current_dialog_node() -> Node:
	var dlg: Node = null
	var dm = get_node_or_null("/root/DialogManager")
	if dm != null and is_instance_valid(dm):
		if dm.has_method("get_current_dialog"):
			dlg = dm.get_current_dialog()
		else:
			dlg = dm.get("current_dialog")
	if dlg == null:
		var sdm = get_node_or_null("/root/SimpleDialogManager")
		if sdm != null and is_instance_valid(sdm):
			dlg = sdm.get("current_dialog")
	# Fallback: scan scene tree for any visible dialog/bubble if managers not found
	if dlg == null:
		dlg = _scan_for_visible_dialog_node()
	return dlg

func _start_following_current_dialog():
	var dlg = _get_current_dialog_node()
	if dlg != null and is_instance_valid(dlg):
		_follow_dialog = dlg
	# Always mark follow active to allow reacquisition on next frames
	_follow_active = true
	set_process(true)

func _stop_following_dialog():
	_follow_active = false
	_follow_dialog = null
	set_process(false)

func _ensure_bubble_nodes():
	if _bubble_layer == null:
		_bubble_layer = CanvasLayer.new()
		_bubble_layer.layer = 100
		add_child(_bubble_layer)
	if _bubble_panel == null:
		_bubble_panel = Panel.new()
		_bubble_panel.size = Vector2(240, 60)
		_bubble_panel.visible = false
		_bubble_layer.add_child(_bubble_panel)
	if _bubble_label == null:
		_bubble_label = Label.new()
		_bubble_label.position = Vector2(8, 8)
		_bubble_label.size = _bubble_panel.size - Vector2(16, 16)
		_bubble_panel.add_child(_bubble_label)
	if _bubble_ttl_timer == null:
		_bubble_ttl_timer = Timer.new()
		_bubble_ttl_timer.one_shot = true
		_bubble_ttl_timer.timeout.connect(_hide_bubble)
		add_child(_bubble_ttl_timer)

func _show_follow_bubble(message: String):
	_ensure_bubble_nodes()
	_bubble_label.text = message
	_bubble_panel.visible = true
	_bubble_active = true
	_follow_active = true
	set_process(true)
	# Auto-hide after a short delay
	if _bubble_ttl_timer != null:
		_bubble_ttl_timer.start(3.0)

func _hide_bubble():
	_bubble_active = false
	if _bubble_panel != null:
		_bubble_panel.visible = false

func _ensure_textbox_nodes():
	if _textbox_layer == null:
		_textbox_layer = CanvasLayer.new()
		_textbox_layer.layer = 150
		add_child(_textbox_layer)
	if _textbox_panel == null:
		_textbox_panel = Panel.new()
		# Anchor to bottom, full width with margins
		_textbox_panel.anchor_left = 0.0
		_textbox_panel.anchor_right = 1.0
		_textbox_panel.anchor_top = 1.0
		_textbox_panel.anchor_bottom = 1.0
		_textbox_panel.offset_left = 24
		_textbox_panel.offset_right = -24
		_textbox_panel.offset_top = -140
		_textbox_panel.offset_bottom = -24
		_textbox_panel.custom_minimum_size = Vector2(0, 110)
		# Style: dark rounded background
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.75)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		_textbox_panel.add_theme_stylebox_override("panel", sb)
		_textbox_panel.visible = false
		_textbox_layer.add_child(_textbox_panel)
	if _textbox_label == null:
		_textbox_label = Label.new()
		_textbox_label.anchor_left = 0.0
		_textbox_label.anchor_right = 1.0
		_textbox_label.anchor_top = 0.0
		_textbox_label.anchor_bottom = 1.0
		_textbox_label.offset_left = 16
		_textbox_label.offset_right = -16
		_textbox_label.offset_top = 10
		_textbox_label.offset_bottom = -10
		_textbox_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_textbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_textbox_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))
		_textbox_panel.add_child(_textbox_label)
	if _textbox_ttl_timer == null:
		_textbox_ttl_timer = Timer.new()
		_textbox_ttl_timer.one_shot = true
		_textbox_ttl_timer.timeout.connect(_hide_textbox)
		add_child(_textbox_ttl_timer)

# NEW: Allow urgent style for collapse alerts
func _update_textbox_style(is_urgent: bool):
	if _textbox_panel == null:
		return
	var sb := StyleBoxFlat.new()
	if is_urgent:
		sb.bg_color = Color(0.10, 0.00, 0.00, 0.85)
	else:
		sb.bg_color = Color(0, 0, 0, 0.75)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	_textbox_panel.add_theme_stylebox_override("panel", sb)
	if _textbox_label != null:
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))

func _show_textbox(message: String, seconds: float = 4.0, urgent: bool = false):
	_ensure_textbox_nodes()
	_update_textbox_style(urgent)
	_textbox_label.text = message
	_textbox_panel.visible = true
	_textbox_active = true
	# Textbox is screen-anchored; disable follow so it won't move bubble
	_follow_active = false
	set_process(true)
	if _textbox_ttl_timer != null:
		if seconds > 0.0:
			_textbox_ttl_timer.start(seconds)
		else:
			_textbox_ttl_timer.stop()

func _hide_textbox():
	_textbox_active = false
	if _textbox_panel != null:
		_textbox_panel.visible = false

# Restyle active manager dialogs to match bottom textbox UI
func _extract_dialog_text(node: Node) -> String:
	if node == null or not is_instance_valid(node):
		return ""
	if node is Label:
		return (node as Label).text
	if node is RichTextLabel:
		return (node as RichTextLabel).text
	# Try common properties
	for k in ["text", "message", "content"]:
		var v = node.get(k)
		if typeof(v) == TYPE_STRING and v != null:
			return v
	# Search children recursively
	for c in node.get_children():
		var t = _extract_dialog_text(c)
		if t != "":
			return t
	return ""

# Utility: Recursively hide visuals of a CanvasItem tree
func _hide_canvas_visuals(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is CanvasItem:
		var ci := node as CanvasItem
		ci.modulate.a = 0.0
	for c in node.get_children():
		_hide_canvas_visuals(c)

# Fallback: scan scene tree for any visible dialog/bubble-like node
func _scan_for_visible_dialog_node() -> Node:
	var root := get_tree().get_root()
	return _scan_for_visible_dialog_node_rec(root)

func _scan_for_visible_dialog_node_rec(n: Node) -> Node:
	if n == null or not is_instance_valid(n):
		return null
	var name_l := String(n.name).to_lower()
	var looks_like := ("dialog" in name_l) or ("bubble" in name_l) or ("speech" in name_l)
	var is_vis := true
	if n is CanvasItem:
		var ci := n as CanvasItem
		is_vis = ci.visible and ci.modulate.a > 0.0
	if looks_like and is_vis:
		var t := _extract_dialog_text(n)
		if t != "":
			return n
	for c in n.get_children():
		var found := _scan_for_visible_dialog_node_rec(c)
		if found != null:
			return found
	return null

func _restyle_manager_active_dialog():
	if not _force_restyle_manager_dialogs:
		return
	var dlg: Node = _get_current_dialog_node()
	if dlg == null or not is_instance_valid(dlg):
		# Manager dialog ended; if we showed textbox from manager, hide it now
		if _last_restyle_text != "" and _textbox_active:
			_hide_textbox()
		_last_restyle_text = ""
		return
	var is_vis := true
	if dlg is CanvasItem:
		var ci := dlg as CanvasItem
		is_vis = ci.visible and ci.modulate.a > 0.0
	if not is_vis:
		# Manager dialog not visible; hide the textbox if it was from manager
		if _last_restyle_text != "" and _textbox_active:
			_hide_textbox()
		_last_restyle_text = ""
		return
	var msg := _extract_dialog_text(dlg)
	if msg == "":
		return
	# Show only when new or textbox inactive to avoid re-triggering every frame
	if msg != _last_restyle_text or not _textbox_active:
		# Keep textbox visible while manager is active; disable TTL by passing 0
		_show_textbox(msg, 0.0, false)
		_last_restyle_text = msg
	# Hide bubble visuals (Control or Node2D) but keep input logic active
	_hide_canvas_visuals(dlg)
	# Also try hiding parent container if it looks like a bubble/dialog
	var parent := dlg.get_parent()
	if parent != null and is_instance_valid(parent):
		var p_name := String(parent.name).to_lower()
		if ("dialog" in p_name) or ("bubble" in p_name) or ("speech" in p_name):
			_hide_canvas_visuals(parent)
	return

func _process(delta):
	# Restyle manager dialogs into bottom textbox when enabled
	if _force_restyle_manager_dialogs:
		_restyle_manager_active_dialog()
	if not _follow_active:
		return
	# Stop only when player is invalid or dialog disappears; don’t rely solely on manager flags
	if player == null or not is_instance_valid(player) or player.is_queued_for_deletion() or not player.is_inside_tree():
		_stop_following_dialog()
		return
	# Try to reacquire if dialog node freed or replaced; if none and no manager reports active, stop
	if _follow_dialog == null or not is_instance_valid(_follow_dialog):
		var reacquired = _get_current_dialog_node()
		if reacquired != null and is_instance_valid(reacquired):
			_follow_dialog = reacquired
		elif not _is_any_dialog_active():
			_stop_following_dialog()
			return
	# If after reacquire we still don't have a valid dialog, skip this frame
	if _follow_dialog == null or not is_instance_valid(_follow_dialog):
		# Still update internal bubble if active
		var world_pos_missing: Vector2 = (player as Node2D).global_position + _follow_offset
		var vp_missing := get_viewport()
		var canvas_xform_missing: Transform2D = vp_missing.get_canvas_transform()
		if _bubble_active and _bubble_panel != null and _bubble_panel.visible:
			var screen_pos_b_missing: Vector2 = canvas_xform_missing * world_pos_missing
			screen_pos_b_missing.x += _follow_random_x
			var bubble_size_missing: Vector2 = _bubble_panel.size
			var bubble_pos_missing: Vector2 = screen_pos_b_missing - Vector2(bubble_size_missing.x * 0.5, bubble_size_missing.y + 10)
			_bubble_panel.position = bubble_pos_missing
		return
	# If Control dialog becomes hidden, stop following
	if _follow_dialog is Control and not (_follow_dialog as Control).get("visible"):
		_stop_following_dialog()
		return
	# Compute world and screen positions from player
	var world_pos: Vector2 = (player as Node2D).global_position + _follow_offset
	var vp := get_viewport()
	var canvas_xform: Transform2D = vp.get_canvas_transform()
	var screen_pos: Vector2 = canvas_xform * world_pos
	screen_pos.x += _follow_random_x
	# Move dialog depending on node type
	if _follow_dialog is Node2D:
		var nd := _follow_dialog as Node2D
		nd.global_position = world_pos + Vector2(_follow_random_x, 0)
	elif _follow_dialog is Control:
		var ci := _follow_dialog as Control
		# Convert to this control's local canvas coordinates for accurate placement
		var control_canvas: Transform2D = ci.get_canvas_transform()
		var local_pos: Vector2 = control_canvas.affine_inverse() * (canvas_xform * world_pos)
		ci.position = local_pos
	elif _follow_dialog != null and is_instance_valid(_follow_dialog) and _follow_dialog.has_method("set_position"):
		_follow_dialog.set_position(screen_pos)
	# Also push position into dialog managers to avoid them overwriting it
	var manager_pos: Vector2 = world_pos + Vector2(_follow_random_x, 0)
	var dm2 = get_node_or_null("/root/DialogManager")
	if dm2 != null and is_instance_valid(dm2):
		if dm2.has_method("set_dialog_position"):
			dm2.set_dialog_position(manager_pos)
		elif dm2.has_method("set_current_dialog_position"):
			dm2.set_current_dialog_position(manager_pos)
		elif dm2.has_method("move_dialog_to"):
			dm2.move_dialog_to(manager_pos)
		else:
			dm2.set("dialog_position", manager_pos)
	var sdm2 = get_node_or_null("/root/SimpleDialogManager")
	if sdm2 != null and is_instance_valid(sdm2):
		if sdm2.has_method("set_dialog_position"):
			sdm2.set_dialog_position(manager_pos)
		elif sdm2.has_method("set_current_dialog_position"):
			sdm2.set_current_dialog_position(manager_pos)
		elif sdm2.has_method("move_dialog_to"):
			sdm2.move_dialog_to(manager_pos)
		else:
			sdm2.set("dialog_position", manager_pos)
	# Update internal bubble position if active
	if _bubble_active and _bubble_panel != null and is_instance_valid(_bubble_panel):
		var screen_pos_b: Vector2 = canvas_xform * world_pos
		screen_pos_b.x += _follow_random_x
		var bubble_size: Vector2 = _bubble_panel.size
		var bubble_pos: Vector2 = screen_pos_b - Vector2(bubble_size.x * 0.5, bubble_size.y + 10)
		_bubble_panel.position = bubble_pos

# Node-added hook to catch newly spawned dialog/bubble nodes immediately
func _on_node_added(node: Node) -> void:
	if node == null:
		return
	# Defer to allow the node to finish setup (text assignment, children)
	call_deferred("_handle_node_added_deferred", node)

func _handle_node_added_deferred(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	_maybe_restyle_new_node(node)

func _maybe_restyle_new_node(node: Node) -> void:
	# Only consider CanvasItem-derived nodes and typical dialog/bubble naming
	var name_l := String(node.name).to_lower()
	var looks_like := ("dialog" in name_l) or ("bubble" in name_l) or ("speech" in name_l) or ("balloon" in name_l) or ("tutorial" in name_l)
	if not looks_like:
		# If not matched by name, check if it contains a label with text
		var text := _extract_dialog_text(node)
		if text == "":
			return
			# Still restyle if it has dialog text
		looks_like = true
	if node is CanvasItem:
		var ci := node as CanvasItem
		if not ci.visible:
			return
		# Mirror text to bottom textbox and hide visuals
		var msg := _extract_dialog_text(node)
		if msg == "":
			return
		_show_textbox(msg, 0.0, false)
		_last_restyle_text = msg
		_hide_canvas_visuals(node)
		# Hide parent container if it also looks like a bubble
		var parent := node.get_parent()
		if parent != null and is_instance_valid(parent):
			var p_name := String(parent.name).to_lower()
			if ("dialog" in p_name) or ("bubble" in p_name) or ("speech" in p_name) or ("balloon" in p_name) or ("tutorial" in p_name):
				_hide_canvas_visuals(parent)
	return
