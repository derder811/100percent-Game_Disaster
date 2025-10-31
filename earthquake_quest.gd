extends Node

var tables_required: int = 3
var tables_hidden: Dictionary = {}
var exit_reached: bool = false

@onready var quest_box: Control
@onready var checkbox1: CheckBox
@onready var label1: Label
@onready var checkbox2: CheckBox
@onready var label2: Label
var original_position: Vector2
var is_quest_box_visible := false
# Add earthquake timer and shake configuration
var quake_total_duration_sec: float = 60.0
var quake_shake_interval_sec: float = 5.0
var _shake_timer: Timer
var _quake_timer: Timer
var _quest_active: bool = true
# New: quest fail timer and collapse state
var quest_time_limit_sec: float = 60.0
var _quest_timer: Timer
var _collapse_started: bool = false
var game_over_scene_path: String = "res://game_over.tscn"
var _continuous_shake_running: bool = false
var _camera_original_offset: Vector2 = Vector2.ZERO

# Safe await helper to avoid get_tree() being null
func _await_seconds(sec: float) -> void:
	if not is_inside_tree():
		return
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = sec
	add_child(t)
	t.start()
	await t.timeout
	if is_instance_valid(t):
		t.queue_free()

func is_active() -> bool:
	return _quest_active
func _ready():
	quest_box = get_node_or_null("Quest UI/Earthquake Quest Box")
	checkbox1 = get_node_or_null("Quest UI/Earthquake Quest Box/QuestContainer/Objectives/Objective1/CheckBox1")
	label1 = get_node_or_null("Quest UI/Earthquake Quest Box/QuestContainer/Objectives/Objective1/Label1")
	checkbox2 = get_node_or_null("Quest UI/Earthquake Quest Box/QuestContainer/Objectives/Objective2/CheckBox2")
	label2 = get_node_or_null("Quest UI/Earthquake Quest Box/QuestContainer/Objectives/Objective2/Label2")
	
	if quest_box:
		# Hide initially; reposition after layout so size is correct on mobile
		quest_box.visible = false
		call_deferred("_reposition_quest_box")
		call_deferred("show_quest_box_with_animation")
	
	# Hide first quake visuals if present while quest is ongoing
	_hide_first_quake_if_present()
	# Hide StoreQuest UI while EarthquakeQuest is active
	_set_store_quest_hidden(true)
	
	# Connect to all tables
	var tables = get_tree().get_nodes_in_group("table_hide")
	for t in tables:
		if t and t.has_signal("player_hidden"):
			t.connect("player_hidden", Callable(self, "_on_table_hidden"))
			# Track initial state per table
			tables_hidden[t.name] = false
	
	# Connect to exit area
	var exit_area = get_tree().current_scene.find_child("Store Exit", true, false)
	if exit_area and exit_area is Area2D:
		exit_area.body_entered.connect(_on_exit_entered)
	
	update_quest_ui()
	
	# Start earthquake timers: total duration and periodic shaking
	_start_quake_timers()
	# Begin continuous camera shake for the duration of the quest
	call_deferred("_start_continuous_camera_shake", 10.0)
	# Start earthquake ambience
	if AudioManager:
		AudioManager.stop_ambient()
		AudioManager.play_ambient("res://PLayer insteraction Talking and pick up talking/Music/Earthquak.mp3", true)
	# Trigger Player3 safety self-talk sequence right after quake begins
	call_deferred("_trigger_player3_safety_self_talk")
	# Start 1-minute quest timer for fail-state
	if _quest_timer == null:
		_quest_timer = Timer.new()
		_quest_timer.wait_time = quest_time_limit_sec
		_quest_timer.timeout.connect(_on_quest_time_limit_reached)
		add_child(_quest_timer)
		_quest_timer.start()

func _on_table_hidden(table_name: String):
	if not tables_hidden.has(table_name) or tables_hidden[table_name]:
		return
	# Mark this table as hidden at least once
	tables_hidden[table_name] = true
	update_quest_ui()
	# If achieved required count, complete objective 1
	if _hidden_count() >= tables_required:
		_complete_objective(1)
		# Prompt player for next step
		_show_hint_dialog("Good! Now go to the exit.")

func _hidden_count() -> int:
	var count := 0
	for k in tables_hidden.keys():
		if tables_hidden[k]:
			count += 1
	return count

func _on_exit_entered(body):
	if exit_reached:
		return
	if body and body.is_in_group("Player2"):
		exit_reached = true
		_complete_objective(2)
		_show_hint_dialog("I made it to the exit! Quest complete.")

# Public: allow interaction-area to complete via exit
func complete_via_exit_interaction():
	if exit_reached:
		return
	exit_reached = true
	_complete_objective(2)
	_show_hint_dialog("I made it to the exit! Quest complete.")

func update_quest_ui():
	if label1:
		label1.text = "Hide under 3 tables (%d/%d)" % [_hidden_count(), tables_required]
	if checkbox1:
		checkbox1.button_pressed = _hidden_count() >= tables_required
	if checkbox2:
		checkbox2.button_pressed = exit_reached

func _complete_objective(index: int):
	# Bounce and highlight the quest box when an objective completes
	if quest_box:
		var tween = create_tween()
		quest_box.modulate = Color(1, 1, 1, 1)
		quest_box.scale = Vector2(1, 1)
		tween.tween_property(quest_box, "scale", Vector2(1.05, 1.05), 0.15)
		tween.tween_property(quest_box, "modulate", Color(1, 0.95, 0.8), 0.1)
		tween.tween_property(quest_box, "modulate", Color(1, 1, 1), 0.4)
		await tween.finished
	# Update corresponding checkbox after animation
	if index == 1:
		if checkbox1:
			checkbox1.button_pressed = true
	elif index == 2:
		if checkbox2:
			checkbox2.button_pressed = true
	# If all objectives completed, stop quake shakes
	_maybe_end_quake()

func show_quest_box_with_animation():
	if is_quest_box_visible:
		return
	if not quest_box:
		return
	quest_box.visible = true
	# Slide-in from the right with a subtle bounce using offset properties
	var tween = create_tween()
	var margin := 24.0
	var top_offset := 80.0
	
	# Start position (off-screen to the right)
	quest_box.offset_left = 40.0  # Start 40px to the right
	quest_box.offset_right = quest_box.offset_left + quest_box.size.x
	quest_box.offset_top = top_offset
	
	# Target position (anchored to right edge)
	var target_left = -(quest_box.size.x + margin)
	var target_right = -margin
	
	tween.tween_property(quest_box, "offset_left", target_left, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quest_box, "offset_right", target_right, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(quest_box, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.1)
	await tween.finished
	is_quest_box_visible = true

func _show_hint_dialog(text: String):
	# Prefer bottom textbox via Player3SelfTalkSystem when available
	var sys = get_tree().get_first_node_in_group("player3_self_talk_system")
	if sys != null:
		# If message asks to go to exit, use dedicated bottom hint
		if "exit" in text.to_lower() and sys.has_method("trigger_go_to_exit_hint"):
			sys.trigger_go_to_exit_hint()
			return
		# Otherwise use generic self-talk bottom textbox
		if sys.has_method("trigger_custom_self_talk"):
			sys.trigger_custom_self_talk(text)
			return
	# Fallback to top DialogBox
	var dialog_box = get_tree().root.get_node_or_null("DialogBox")
	if dialog_box and dialog_box.has_method("show_dialog"):
		dialog_box.show_dialog("INFO", [text])

func _start_quake_timers():
	if _shake_timer == null:
		_shake_timer = Timer.new()
		_shake_timer.wait_time = quake_shake_interval_sec
		_shake_timer.timeout.connect(_do_periodic_shake)
		add_child(_shake_timer)
		_shake_timer.start()
	if _quake_timer == null:
		_quake_timer = Timer.new()
		_quake_timer.wait_time = quake_total_duration_sec
		_quake_timer.timeout.connect(_on_quake_duration_done)
		add_child(_quake_timer)
		_quake_timer.start()

func _trigger_player3_safety_self_talk():
	var sts_nodes = get_tree().get_nodes_in_group("player3_self_talk_system")
	if sts_nodes and sts_nodes.size() > 0:
		var sys = sts_nodes[0]
		if sys and sys.has_method("trigger_earthquake_safety_sequence"):
			sys.trigger_earthquake_safety_sequence()

# Hide any pre-existing earthquake visuals while the quest is active
func _hide_first_quake_if_present():
	var eq_node = get_tree().current_scene.find_child("Earthquake", true, false)
	if eq_node and eq_node is Node2D:
		eq_node.visible = false

# New: hide or show StoreQuest UI while quake is active
func _set_store_quest_hidden(hidden: bool):
	var store_quest = get_tree().current_scene.find_child("StoreQuest", true, false)
	if store_quest:
		if hidden:
			if store_quest.has_method("hide_quest_ui"):
				store_quest.hide_quest_ui()
			else:
				var box = store_quest.get_node_or_null("Quest UI/Quest Text Box")
				if box and box is Control:
					box.visible = false
		else:
			if store_quest.has_method("show_quest_ui"):
				store_quest.show_quest_ui()
			else:
				var box2 = store_quest.get_node_or_null("Quest UI/Quest Text Box")
				if box2 and box2 is Control:
					box2.visible = true

# Shake the camera every interval to sustain game flow
func _do_periodic_shake():
	if not _quest_active:
		return
	_camera_shake(0.6, 10.0)

# When the 50s quake duration ends, stop periodic shakes
func _on_quake_duration_done():
	if _collapse_started:
		return
	_quest_active = false
	if _shake_timer:
		_shake_timer.stop()
	# Restore StoreQuest UI after quake ends
	_set_store_quest_hidden(false)
	# Stop ambient earthquake sound
	AudioManager.stop_ambient()
	_show_hint_dialog("The shaking subsides. Stay cautious and proceed carefully.")

# Helper to stop shakes when all objectives are done
func _maybe_end_quake():
	if checkbox1 and checkbox1.button_pressed and checkbox2 and checkbox2.button_pressed:
		_quest_active = false
		if _shake_timer:
			_shake_timer.stop()
		# Stop quest fail timer to avoid unintended game over
		if _quest_timer:
			_quest_timer.stop()
		# Stop continuous camera shake when quest completes
		_stop_continuous_camera_shake()
		# Restore StoreQuest if objectives finished early
		_set_store_quest_hidden(false)
		# Stop ambient earthquake sound
		AudioManager.stop_ambient()
		# Transition to Survive scene when quest completes
		if get_tree():
			get_tree().change_scene_to_file("res://Survive.tscn")

# Camera shake coroutine
func _camera_shake(duration_sec: float, magnitude: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	var original_offset: Vector2 = camera.offset
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var elapsed := 0.0
	while elapsed < duration_sec:
		camera.offset = Vector2(rng.randf_range(-magnitude, magnitude), rng.randf_range(-magnitude, magnitude))
		await _await_seconds(0.02)
		elapsed += 0.02
	camera.offset = original_offset

# New: quest time limit reached -> collapse then game over
func _on_quest_time_limit_reached():
	if _collapse_started:
		return
	# If objectives are already done, ignore
	var done := (checkbox1 and checkbox1.button_pressed) and (checkbox2 and checkbox2.button_pressed)
	if done:
		return
	_collapse_and_game_over()

# New: collapse animation then load Game Over scene
func _collapse_and_game_over():
	_collapse_started = true
	_quest_active = false
	# Stop continuous camera shake during collapse
	_stop_continuous_camera_shake()
	if _shake_timer:
		_shake_timer.stop()
	if _quake_timer:
		_quake_timer.stop()
	# Stop ambient earthquake sound
	AudioManager.stop_ambient()
	# Hide StoreQuest UI during collapse
	_set_store_quest_hidden(true)
	# Create and fade-in a black overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(overlay)
	# Fade to dark while shaking
	var fade_tween = create_tween()
	fade_tween.tween_property(overlay, "color", Color(0, 0, 0, 0.7), 1.0)
	await _camera_shake(1.5, 28.0)
	# Try to tilt and drop the building/root for collapse effect
	if scene_root and scene_root is Node2D:
		var collapse_tween = create_tween()
		collapse_tween.tween_property(scene_root, "rotation", deg_to_rad(10), 0.8)
		collapse_tween.tween_property(scene_root, "position:y", scene_root.position.y + 80, 0.8)
		await collapse_tween.finished
	# Finish fade to black
	var fade_to_black = create_tween()
	fade_to_black.tween_property(overlay, "color", Color(0, 0, 0, 1.0), 0.6)
	await fade_to_black.finished
	# Change to Game Over scene (adjust path if different)
	if game_over_scene_path != "" and get_tree():
		get_tree().change_scene_to_file(game_over_scene_path)

# Continuous camera shake controls
func _start_continuous_camera_shake(magnitude: float = 10.0):
	if _continuous_shake_running:
		return
	_continuous_shake_running = true
	var camera = get_viewport().get_camera_2d()
	if camera:
		_camera_original_offset = camera.offset
	call_deferred("_run_continuous_camera_shake", magnitude)

func _run_continuous_camera_shake(magnitude: float):
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		_continuous_shake_running = false
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	while _continuous_shake_running:
		# stop when objectives complete or collapse begins
		var done := (checkbox1 and checkbox1.button_pressed) and (checkbox2 and checkbox2.button_pressed)
		if done or _collapse_started:
			break
		camera.offset = Vector2(rng.randf_range(-magnitude, magnitude), rng.randf_range(-magnitude, magnitude))
		await _await_seconds(0.02)
	_stop_continuous_camera_shake()

func _stop_continuous_camera_shake():
	if not _continuous_shake_running:
		return
	_continuous_shake_running = false
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.offset = _camera_original_offset

func _reposition_quest_box():
	if quest_box:
		# With anchoring to top-right, we only need to adjust the offset
		# The quest box is now anchored to the right edge, so it will automatically
		# position correctly regardless of screen size
		var margin := 24.0
		var top_offset := 80.0
		
		# Set the offset from the right edge (negative because it's anchored right)
		quest_box.offset_left = -(quest_box.size.x + margin)
		quest_box.offset_right = -margin
		quest_box.offset_top = top_offset
		
		# Store original position for animations
		original_position = quest_box.position
	else:
		print("EarthquakeQuest: WARNING - Quest box not found during reposition")