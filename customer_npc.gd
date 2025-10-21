extends CharacterBody2D

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var player2: CharacterBody2D = null
var _player_was_moving: bool = false
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

func _process(delta):
	# Resolve player ref if not yet cached
	if player2 == null:
		player2 = get_tree().get_first_node_in_group("Player2") as CharacterBody2D
	# When player starts moving, face the exit once
	if player2 != null:
		var moving := player2.velocity.length() > 0.1
		if moving and not _player_was_moving:
			face_exit()
		_player_was_moving = moving

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
	print("Customer NPC: player interacted")
	var lines: Array[String] = [
		"Okay, this section's stacked.",
		"What am I even in the mood for?"
	]
	# Prefer bottom DialogBox UI for conversation
	var box = _get_dialog_box()
	if box != null and box.has_method("show_dialog"):
		box.show_dialog("CUSTOMER", lines)
	else:
		# Fallback: use bubble dialog above customer
		var pos = global_position + Vector2(0, -120)
		DialogManager.start_dialog(pos, lines)

func face_towards(dir: Vector2, moving: bool = false) -> void:
	if anim_player == null:
		return
	var anim_name := ""
	if abs(dir.x) > abs(dir.y):
		if dir.x >= 0:
			if moving:
				anim_name = "walk_right"
			else:
				anim_name = "idle_right"
		else:
			if moving:
				anim_name = "walk_left"
			else:
				anim_name = "idle_left"
	else:
		if dir.y >= 0:
			if moving:
				anim_name = "walk_down"
			else:
				anim_name = "idle_down"
		else:
			if moving:
				anim_name = "walk_up"
			else:
				anim_name = "idle"
	anim_player.play(anim_name)
	# Ensure AnimationTree does not override AnimationPlayer during cutscenes
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
