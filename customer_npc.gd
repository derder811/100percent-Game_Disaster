extends CharacterBody2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var customer_audio_player: AudioStreamPlayer2D = $CustomerAudioPlayer
@onready var player2: CharacterBody2D = null
var _player_was_moving: bool = false
var _current_anim: String = ""

var dialog_box_scene: PackedScene = preload("res://Scenes/dialog_box.tscn")

func _ready():
	if interaction_area != null:
		interaction_area.action_name = "talk to customer"
		interaction_area.interact = Callable(self, "_on_interact")
		print("Customer NPC interaction configured")
	else:
		print("ERROR: InteractionArea not found on Customer NPC")
	# Cache Player 3 reference via Player2 group
	player2 = get_tree().get_first_node_in_group("Player2") as CharacterBody2D
	# Ensure up-facing idle (static) when gameplay starts and no cutscene
	if anim_player != null:
		anim_player.speed_scale = 0.0
		anim_player.play("walk_up")
		_current_anim = "walk_up"
	if anim_tree != null:
		anim_tree.active = false

	# Configure customer voice audio stream
	if customer_audio_player != null:
		# Prefer project-relative path for portability
		var stream: AudioStream = load("res://asset/button/CUSTOMER.mp3")
		if stream != null:
			customer_audio_player.stream = stream
			customer_audio_player.bus = "SFX"
			print("Customer NPC: Loaded voice stream res://asset/button/CUSTOMER.mp3")
		else:
			# Fallback: try absolute path provided by user (Windows)
			var abs_path := "c:/Users/xande/Music/Disaster_2.0-main/asset/button/CUSTOMER.mp3"
			var abs_stream: AudioStream = load(abs_path)
			if abs_stream != null:
				customer_audio_player.stream = abs_stream
				customer_audio_player.bus = "SFX"
				print("Customer NPC: Loaded voice stream via absolute path:", abs_path)
			else:
				push_warning("Customer NPC: Could not load CUSTOMER.mp3 from either res:// or absolute path")

func _process(delta):
	# Remain idle when cutscene is not active; no auto-facing/moving
	if player2 == null:
		player2 = get_tree().get_first_node_in_group("Player2") as CharacterBody2D

func _get_dialog_box() -> Node:
	var existing = get_tree().get_first_node_in_group("dialog_system")
	if existing != null and is_instance_valid(existing):
		return existing
	var inst = dialog_box_scene.instantiate()
	get_tree().root.add_child(inst)
	return inst

func _on_interact() -> void:
	# Play customer voice line when interacting
	if customer_audio_player != null and customer_audio_player.stream != null:
		customer_audio_player.play()
		print("Customer NPC: Playing voice line")

	# Merge lines into a single message to avoid Next progression
	var merged_text: String = "Do you think they have my favorite snacks here?"
	var lines: Array[String] = [merged_text]

	# Hide StoreQuest UI during interaction to prevent overlap
	_hide_existing_quest_ui()
	# Prefer bottom DialogBox UI for conversation
	var box = _get_dialog_box()
	if box != null and box.has_method("show_dialog"):
		# Connect dialog finish/close to restore StoreQuest UI (avoid duplicate connections)
		if box.has_signal("dialog_finished") and not box.dialog_finished.is_connected(_on_customer_dialog_finished):
			box.dialog_finished.connect(_on_customer_dialog_finished)
		if box.has_signal("dialog_closed") and not box.dialog_closed.is_connected(_on_customer_dialog_finished):
			box.dialog_closed.connect(_on_customer_dialog_finished)
		box.show_dialog("CUSTOMER", lines)
	else:
		# Fallback bubble dialog near the customer
		var pos = global_position + Vector2(0, -100)
		DialogManager.start_dialog(pos, lines)
		# As fallback, restore StoreQuest after a short delay
		var t := Timer.new()
		t.one_shot = true
		t.wait_time = 4.0
		t.timeout.connect(_on_customer_dialog_finished)
		add_child(t)
		t.start()

func _on_customer_dialog_finished() -> void:
	# Show StoreQuest UI again after customer interaction ends
	var store_quest = _find_store_quest()
	if store_quest != null and store_quest.has_method("show_quest_ui"):
		store_quest.show_quest_ui()

func _hide_existing_quest_ui() -> void:
	# Hide any existing quest UI to prevent overlap with dialogue
	var store_quest = _find_store_quest()
	if store_quest != null and store_quest.has_method("hide_quest_ui"):
		store_quest.hide_quest_ui()

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

func face_towards(dir: Vector2, moving: bool = false) -> void:
	if anim_player == null:
		return
	var anim_name := "walk_up"
	if moving:
		if abs(dir.x) > abs(dir.y):
			anim_name = "walk_right" if dir.x >= 0 else "walk_left"
		else:
			anim_name = "walk_down" if dir.y >= 0 else "walk_up"
	# Avoid restarting the same animation every frame to keep it continuous
	if _current_anim != anim_name:
		anim_player.play(anim_name)
		_current_anim = anim_name
	# Freeze on first frame when idle; run normally when moving
	var target_speed := 1.0 if moving else 0.0
	if anim_player.speed_scale != target_speed:
		anim_player.speed_scale = target_speed
	# Ensure AnimationTree does not override AnimationPlayer during cutscenes or idle
	if anim_tree != null:
		anim_tree.active = false
		# Guarded: only set blend if path exists
		var path := "parameters/BlendSpace2D/blend_position"
		var existing = anim_tree.get(path)
		if existing != null:
			var n := dir.normalized()
			anim_tree.set(path, Vector2(n.x, n.y))

func face_exit() -> void:
	if anim_player == null:
		return
	var scene := get_tree().current_scene
	var exit_node: Node2D = null
	if scene != null:
		# Prefer the Store Exit if present; fallback to Staff Only Door
		exit_node = scene.find_child("Store Exit", true, false) as Node2D
		if exit_node == null:
			exit_node = scene.get_node_or_null("Staff Only Door") as Node2D
	# Compute direction using the visible sprite's global position and actual exit child shape
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
	var dir := Vector2.RIGHT
	if exit_node != null:
		dir = exit_pos - ref_pos
	face_towards(dir, false)

func face_exit_walk() -> void:
	var scene := get_tree().current_scene
	var exit_node: Node2D = null
	if scene != null:
		exit_node = scene.find_child("Store Exit", true, false) as Node2D
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
	var dir := Vector2.RIGHT
	if exit_node != null:
		dir = exit_pos - ref_pos
	face_towards(dir, true)
