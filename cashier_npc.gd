extends CharacterBody2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
var dialog_box_scene: PackedScene = preload("res://Scenes/dialog_box.tscn")
var store_quest_activated: bool = false

func _ready():
	if interaction_area != null:
		interaction_area.action_name = "talk to cashier"
		interaction_area.interact = Callable(self, "_on_interact")
		print("Cashier NPC interaction configured")
	else:
		print("ERROR: InteractionArea not found on Cashier NPC")

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
	var lines: Array[String] = [
		"Hello... Welcome to the store.",
		"Yes we accept Gcash payment"
	]
	# Prefer bottom DialogBox UI for conversation
	var box = _get_dialog_box()
	if box != null and box.has_method("show_dialog"):
		# Connect both finished and closed to show StoreQuest UI
		if box.has_signal("dialog_finished"):
			box.dialog_finished.connect(_on_cashier_dialog_finished)
		if box.has_signal("dialog_closed"):
			box.dialog_closed.connect(_on_cashier_dialog_finished)
		box.show_dialog("CASHIER", lines)
		# Safety fallback: ensure StoreQuest shows even if signals don’t fire
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

func _on_cashier_dialog_finished() -> void:
	if store_quest_activated:
		return
	store_quest_activated = true
	print("Cashier NPC: conversation finished, showing StoreQuest UI")
	_show_store_quest_ui()

func _show_store_quest_ui() -> void:
	var store_quest = get_tree().current_scene.find_child("StoreQuest", true, false)
	if store_quest:
		if store_quest.has_method("start_quest"):
			store_quest.start_quest()
			print("Cashier NPC: StoreQuest started")
		elif store_quest.has_method("show_quest_ui"):
			store_quest.show_quest_ui()
			print("Cashier NPC: StoreQuest UI shown (fallback)")
		else:
			print("Cashier NPC: StoreQuest found but no start_quest/show_quest_ui methods")
	else:
		print("Cashier NPC: StoreQuest node not found in current scene")

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
		# Idle when not following a path
		velocity = Vector2.ZERO
