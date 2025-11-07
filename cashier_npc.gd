extends CharacterBody2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var cashier_audio_player: AudioStreamPlayer = $CashierAudioPlayer
var dialog_box_scene: PackedScene = preload("res://Scenes/dialog_box.tscn")
var store_quest_activated: bool = false
var current_dialog_box: Node = null

func _ready():
	if interaction_area != null:
		interaction_area.action_name = "talk to cashier"
		interaction_area.interact = Callable(self, "_on_interact")
		print("Cashier NPC interaction configured")
	else:
		print("ERROR: InteractionArea not found on Cashier NPC")

	# Ensure cashier audio uses ReEarthquake WAV
	if cashier_audio_player != null:
		var wav_path := "res://retyphoon (2)/ReEarthquake/Yes we accept Gcash payment.wav"
		var stream: AudioStream = load(wav_path)
		if stream != null:
			cashier_audio_player.stream = stream
			print("Cashier NPC: Loaded cashier audio stream:", wav_path)

	# Ensure idle animation when gameplay starts (no cutscene)
	if anim_player != null:
		anim_player.play("idle")
	if anim_tree != null:
		anim_tree.active = false

func _get_dialog_box() -> Node:
	# Try to find an existing DialogSystem
	var existing = get_tree().get_first_node_in_group("dialog_system")
	if existing != null and is_instance_valid(existing):
		return existing
	# Otherwise instantiate one
	var inst = dialog_box_scene.instantiate()
	get_tree().root.add_child(inst)
	return inst


func _on_interact() -> void:
	# Trigger Player3 self-talk for cashier interaction first
	var p3_self_talk = get_tree().get_first_node_in_group("player3_self_talk_system")
	if p3_self_talk and p3_self_talk.has_method("trigger_after_item_interact_talk"):
		p3_self_talk.trigger_after_item_interact_talk("cashier")

	# Wait for Player3 self-talk to fully finish (text and audio)
	if p3_self_talk and p3_self_talk.has_method("await_self_talk_finished"):
		await p3_self_talk.await_self_talk_finished()
	else:
		# Fallback: wait for SFX, then poll until no dialog is active or timeout
		if typeof(AudioManager) != TYPE_NIL and AudioManager and AudioManager.has_method("wait_sfx_finished"):
			await AudioManager.wait_sfx_finished()
		var max_wait := 4.0
		var elapsed := 0.0
		while p3_self_talk and p3_self_talk.has_method("_is_any_dialog_active") and p3_self_talk._is_any_dialog_active() and elapsed < max_wait:
			await get_tree().create_timer(0.1).timeout
			elapsed += 0.1

	# Optionally hide Player3 textbox before NPC speaks
	if p3_self_talk and p3_self_talk.has_method("_hide_textbox"):
		p3_self_talk._hide_textbox()

	# Now play cashier NPC response audio
	if cashier_audio_player != null:
		cashier_audio_player.play()
		print("Cashier NPC: Playing cashier response audio")
	
	# Hide any existing quest UI during dialogue to prevent overlap
	_hide_existing_quest_ui()
	
	# Merge lines into a single message to avoid Next
	var merged_text: String = "Hello... Welcome to the store.\nYes we accept Gcash payment"
	var lines: Array[String] = [merged_text]
	# Prefer bottom DialogBox UI for conversation
	var box = _get_dialog_box()
	if box != null and box.has_method("show_dialog"):
		current_dialog_box = box
		# Connect both finished and closed to show StoreQuest UI
		# Make sure we only connect once to avoid duplicate connections
		if box.has_signal("dialog_finished") and not box.dialog_finished.is_connected(_on_cashier_dialog_finished):
			box.dialog_finished.connect(_on_cashier_dialog_finished)
		if box.has_signal("dialog_closed") and not box.dialog_closed.is_connected(_on_cashier_dialog_finished):
			box.dialog_closed.connect(_on_cashier_dialog_finished)
		box.show_dialog("CASHIER", lines)

		# Schedule auto-close: 2 seconds after cashier audio finishes
		call_deferred("_schedule_auto_close_after_audio")
		
		# Safety timer as fallback in case signals don't work
		var safety_timer := Timer.new()
		safety_timer.one_shot = true
		safety_timer.wait_time = 8.0
		safety_timer.timeout.connect(func():
			if not store_quest_activated:
				print("Cashier NPC: safety timer; showing StoreQuest UI")
				_on_cashier_dialog_finished()
		)
		add_child(safety_timer)
		safety_timer.start()
	else:
		# Fallback: use bubble dialog above cashier, then show StoreQuest UI after a short delay
		var pos = global_position + Vector2(0, -120)
		DialogManager.start_dialog(pos, lines)
		var t := Timer.new()
		t.one_shot = true
		t.wait_time = 4.0
		t.timeout.connect(_on_cashier_dialog_finished)
		add_child(t)
		t.start()

		# Also schedule auto-close after audio for bubble dialog
		call_deferred("_schedule_auto_close_after_audio")

func _schedule_auto_close_after_audio() -> void:
	if cashier_audio_player == null:
		return
	# Wait until cashier audio finishes
	await cashier_audio_player.finished
	# Then wait 2 seconds before closing the dialog textbox
	await get_tree().create_timer(2.0).timeout
	# If using DialogSystem, close it to vanish the textbox
	if current_dialog_box != null and current_dialog_box.has_method("close_dialog"):
		current_dialog_box.close_dialog()
	else:
		# Fallback: trigger quest finish which hides bubble flows
		_on_cashier_dialog_finished()

func _hide_existing_quest_ui() -> void:
	# Hide any existing quest UI to prevent overlap with dialogue
	var store_quest = _find_store_quest()
	if store_quest != null and store_quest.has_method("hide_quest_ui"):
		store_quest.hide_quest_ui()
		print("Cashier NPC: Hidden existing quest UI during dialogue")

func _find_store_quest() -> Node:
	# Helper method to find the StoreQuest node
	var store_quest = get_tree().current_scene.find_child("StoreQuest", true, false)
	if store_quest == null:
		store_quest = get_tree().root.find_child("StoreQuest", true, false)
	if store_quest == null:
		# Search all top-levels for a child named StoreQuest
		for c in get_tree().root.get_children():
			var f = c.find_child("StoreQuest", true, false)
			if f != null:
				store_quest = f
				break
	return store_quest

func _on_cashier_dialog_finished() -> void:
	if store_quest_activated:
		return
	store_quest_activated = true
	print("Cashier NPC: conversation finished, showing StoreQuest UI")
	_show_store_quest_ui()

func _show_store_quest_ui() -> void:
	var store_quest = _find_store_quest()
	if store_quest == null:
		# Last resort: instantiate StoreQuest and attach to current scene
		var store_quest_scene: PackedScene = load("res://store_quest.tscn")
		if store_quest_scene != null:
			store_quest = store_quest_scene.instantiate()
			var parent := get_tree().current_scene if get_tree().current_scene != null else get_tree().root
			parent.add_child(store_quest)
			print("Cashier NPC: StoreQuest instantiated as fallback")
	if store_quest != null:
		if store_quest.has_method("start_quest"):
			store_quest.start_quest()
			print("Cashier NPC: StoreQuest started")
			# Ensure quest UI is re-shown after we hid it for dialogue
			if store_quest.has_method("show_quest_ui"):
				store_quest.show_quest_ui()
				print("Cashier NPC: StoreQuest UI re-shown after dialogue")
			# Complete the cashier objective upon finishing dialog
			if store_quest.has_method("on_cashier_interaction"):
				store_quest.on_cashier_interaction()
				print("Cashier NPC: Cashier objective completed")
		elif store_quest.has_method("show_quest_ui"):
			store_quest.show_quest_ui()
			print("Cashier NPC: StoreQuest UI shown (fallback)")
			if store_quest.has_method("on_cashier_interaction"):
				store_quest.on_cashier_interaction()
				print("Cashier NPC: Cashier objective completed (UI-only fallback)")
		else:
			print("Cashier NPC: StoreQuest found but no start_quest/show_quest_ui methods")
	else:
		print("Cashier NPC: StoreQuest not found or failed to instantiate")

func face_towards(dir: Vector2, moving: bool = false) -> void:
	if anim_player == null:
		return
	var anim_name := "idle"
	if moving:
		if abs(dir.x) > abs(dir.y):
			anim_name = "walk_right" if dir.x >= 0 else "walk_left"
		else:
			anim_name = "walk_down" if dir.y >= 0 else "walk_up"
	anim_player.play(anim_name)
	if anim_tree != null:
		var n := dir.normalized()
		if moving:
			# Drive AnimationTree Walk state during movement
			anim_tree.active = true
			var playback = anim_tree.get("parameters/playback")
			if playback != null:
				playback.travel("Walk")
			anim_tree.set("parameters/Walk/blend_position", Vector2(n.x, n.y))
		else:
			# Disable AnimationTree to avoid overriding AnimationPlayer when idle
			anim_tree.active = false

func face_exit_walk() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var exit_node: Node2D = scene.find_child("Store Exit", true, false) as Node2D
	if exit_node == null:
		exit_node = scene.get_node_or_null("Staff Only Door") as Node2D
	var ref_pos: Vector2 = global_position
	var spr := get_node_or_null("Sprite2D") as Node2D
	if spr != null:
		ref_pos = spr.global_position
	var exit_pos: Vector2 = Vector2.ZERO
	if exit_node != null:
		var exit_shape := exit_node.get_node_or_null("CollisionShape2D") as Node2D
		if exit_shape != null:
			exit_pos = exit_shape.global_position
		else:
			exit_pos = exit_node.global_position
	var dir := exit_pos - ref_pos
	face_towards(dir, true)

# --- New: Follow Path2D to exit ---
var follow_exit_path: bool = false
var exit_path_points: Array[Vector2] = []
var exit_path_index: int = 0
var exit_path_speed: float = 120.0

func start_exit_via_path():
	# Use the Path2D defined under the cashier scene to walk to exit
	var path := get_node_or_null("Sprite2D/Path2D") as Path2D
	if path == null or path.curve == null:
		print("Cashier NPC: Path2D not found or curve missing")
		return
	# Bake the curve to a list of global points so it doesn't move with the NPC
	exit_path_points.clear()
	for p in path.curve.get_baked_points():
		# Convert local path point to world-space
		exit_path_points.append(path.to_global(p))
	if exit_path_points.size() == 0:
		print("Cashier NPC: Path2D has no baked points")
		return
	exit_path_index = 0
	follow_exit_path = true
	print("Cashier NPC: starting exit walk via Path2D (", exit_path_points.size(), " points)")

func _physics_process(delta):
	if follow_exit_path:
		if exit_path_index >= exit_path_points.size():
			follow_exit_path = false
			velocity = Vector2.ZERO
			face_towards(Vector2.ZERO, false)
			return
		var target: Vector2 = exit_path_points[exit_path_index]
		var to_target: Vector2 = target - global_position
		if to_target.length() < 5.0:
			exit_path_index += 1
			return
		var dir: Vector2 = to_target.normalized()
		velocity = dir * exit_path_speed
		face_towards(dir, true)
		move_and_slide()
	else:
		# Not following a path; keep velocity zero but don't override animation.
		# Cutscene tweens will drive face_exit_walk() updates.
		velocity = Vector2.ZERO
