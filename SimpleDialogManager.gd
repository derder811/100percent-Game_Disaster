extends Node

@onready var dialog_scene = preload("res://SimpleDialog.tscn")
var current_dialog: Node

# Helper: wait until any relevant audio (SFX or self-talk voice) finishes
func _wait_any_audio_finished() -> void:
	# Wait for global SFX via AudioManager
	if typeof(AudioManager) != TYPE_NIL and AudioManager.has_method("wait_sfx_finished"):
		await AudioManager.wait_sfx_finished()
	# Also wait for self-talk voice playback, if present
	var self_talk := get_tree().get_first_node_in_group("self_talk_system")
	if self_talk:
		var voice := self_talk.get_node_or_null("SelfTalkVoicePlayer")
		if voice and voice.has_method("is_playing"):
			if voice.is_playing():
				await voice.finished
		elif voice and voice.has_method("play"):
			# AudioStreamPlayer API: use .playing property when available
			if voice.playing:
				await voice.finished

var safety_tips = {
	# Interactive assets (Scenario 1)
	"window": "Close windows securely to prevent water and wind damage.",
	"tv": "Monitor reliable news sources for weather advisories and evacuation.",
	"fuse_box": "Cut power if flooding risk rises to avoid electrocution.",
	"candle": "Avoid candles during storms; use flashlights to prevent fires.",
	"bucket": "Use buckets to manage leaks and keep floors dry.",
	"e_fan": "Unplug electric fans if water is present to avoid shocks.",
	"frying_pan": "Turn off heat and secure cookware to prevent accidents.",

	# Pickable / inventory items (keys used across scripts)
	"go_bag": "Prepare a go bag with essentials: water, food, meds, documents.",
	"mobile_phone": "Keep your phone charged to receive emergency alerts.",
	"phone": "Keep your phone charged to receive emergency alerts.",
	"powerbank": "Charge a power bank to keep devices powered during outages.",
	"power_bank": "Charge a power bank to keep devices powered during outages.",
	"battery": "Stock spare batteries for flashlights and radios.",
	"flashlight": "Use a flashlight instead of candles to avoid fire hazards.",
	"documents": "Store IDs and important papers in waterproof containers.",
	"canned_food": "Choose non-perishable food; check expirations and avoid damaged cans.",
	"water_bottle": "Store bottled water; aim for at least 3 liters per person per day.",
	"bottled_water": "Store bottled water; aim for at least 3 liters per person per day.",
	"first_aid_kit": "Keep a first-aid kit accessible for minor injuries.",
	"medkit": "Keep a first-aid kit accessible for minor injuries.",
	"medicine_3": "Pack prescription meds and dosage instructions.",
}

func show_safety_tips(asset_type: String, position: Vector2, header: String = "TIPS", footer_hint: String = "Close (Space / Interact)"):
	print("SimpleDialogManager.show_safety_tips called for: ", asset_type)
	
	# Close existing dialog if any
	if current_dialog:
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null
	
	# Get safety tip for this asset
	var tip = safety_tips.get(asset_type, "No safety information available for this item.")
	
	# Ensure audio is quiet before showing dialog
	await _wait_any_audio_finished()
	# Prefer unified self-talk textbox style for tips (Scenario 1)
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("show_tips_textbox"):
		# Show as top-center textbox; ignore position for consistency
		sys.show_tips_textbox(tip)
		print("Safety tips shown via self_talk_system textbox")
		return
	# Fallback to legacy SimpleDialog if self-talk system not available
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(tip, position, header, footer_hint)
	print("Safety tips dialog created and shown (fallback)")

# Show item-specific tip dialog near given position
func show_item_dialog(item_name: String, position: Vector2):
	# Get safety tip for this item
	var tip = safety_tips.get(item_name, "No safety information available for this item.")
	
	# Wait for any ongoing audio (pickup SFX or self-talk voice) to finish
	await _wait_any_audio_finished()
	# Prefer unified self-talk textbox style for item tips
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("show_tips_textbox"):
		sys.show_tips_textbox(tip)
		print("Item tip shown via self_talk_system textbox")
		return
	# Fallback to legacy SimpleDialog
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(tip, position)
	print("Dialog created and shown (fallback)")

func hide_current_dialog():
	if current_dialog:
		current_dialog.hide_dialog()
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null

# Optional: expose a start_dialog API for systems expecting DialogManager-like interface
func start_dialog(position: Vector2, lines: Array[String], header: String = "TIPS", footer_hint: String = "Close (Space / Interact)") -> Node:
	# Close existing dialog if any
	if current_dialog:
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null
	# Combine lines into text
	var text := "".join(lines)
	if text == "":
		text = ""
	
	# Wait for any ongoing audio (pickup SFX or self-talk voice) to finish
	await _wait_any_audio_finished()
	# Prefer unified self-talk textbox style
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("show_tips_textbox"):
		sys.show_tips_textbox(text)
		return null
	# Fallback to legacy SimpleDialog
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(text, position, header, footer_hint)
	return current_dialog

# Helpers to reposition current dialog when following player
func set_current_dialog_position(pos: Vector2):
	if current_dialog and is_instance_valid(current_dialog):
		current_dialog.global_position = pos

func move_dialog_to(pos: Vector2):
	set_current_dialog_position(pos)
