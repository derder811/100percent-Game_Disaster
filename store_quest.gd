extends Node

# Store quest: sequential interactions in order
# 1) Ice Cream Fridge
# 2) Meat Fridge
# 3) Hotdog & Siopao Fridge
# 4) Slurpee Machine (last)

var objectives = {
	"interact_ice_cream_fridge": false,
	"interact_meat_fridge": false,
	"interact_hotdog_siopao": false,
	"interact_slurpee": false,
}

var current_objective_index := 0

@onready var objective_checkboxes: Array = []
@onready var objective_labels: Array = []
@onready var quest_box: Control
var original_position: Vector2
var is_quest_box_visible := false
var quest_started := false

func _ready():
	# Cache UI nodes
	var objectives_container = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/Objectives")
	quest_box = get_node_or_null("Quest UI/Quest Text Box")
	
	if quest_box:
		# Hide initially; reposition after layout so size is correct on mobile
		quest_box.visible = false
		call_deferred("_reposition_quest_box")
	else:
		print("StoreQuest: WARNING - Quest box not found")
	
	if objectives_container:
		for child in objectives_container.get_children():
			if child is HBoxContainer:
				for subchild in child.get_children():
					if subchild is CheckBox:
						objective_checkboxes.append(subchild)
					elif subchild is Label:
						objective_labels.append(subchild)
	else:
		print("StoreQuest: WARNING - Objectives container not found")
	
	update_quest_ui()
	# Do not auto-start on mobile; quest should start via cashier interaction

func update_quest_ui():
	var objective_texts = [
		"Interact with the Ice Cream Fridge",
		"Interact with the Meat Fridge",
		"Interact with the Hotdog & Siopao Fridge",
		"Interact with the Slurpee Machine",
	]
	
	# Hide all
	for i in range(objective_checkboxes.size()):
		if i < objective_checkboxes.size() and objective_checkboxes[i]:
			objective_checkboxes[i].visible = false
		if i < objective_labels.size() and objective_labels[i]:
			objective_labels[i].visible = false
	
	# Show current
	if current_objective_index < objective_texts.size() and current_objective_index < objective_labels.size() and current_objective_index < objective_checkboxes.size():
		var current_label: Label = objective_labels[current_objective_index]
		var current_checkbox: CheckBox = objective_checkboxes[current_objective_index]
		if current_label:
			current_label.visible = true
			var keys = ["interact_ice_cream_fridge", "interact_meat_fridge", "interact_hotdog_siopao", "interact_slurpee"]
			var text = objective_texts[current_objective_index]
			var completed = objectives[keys[current_objective_index]]
			if completed:
				current_label.modulate = Color.GREEN
				current_label.text = "✓ " + text
			else:
				current_label.modulate = Color.WHITE
				current_label.text = text
		if current_checkbox:
			current_checkbox.visible = true
			var keys2 = ["interact_ice_cream_fridge", "interact_meat_fridge", "interact_hotdog_siopao", "interact_slurpee"]
			current_checkbox.button_pressed = objectives[keys2[current_objective_index]]
	
	# Progress label
	var progress_label: Label = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/ProgressLabel")
	if progress_label:
		var done := 0
		for v in objectives.values():
			if v: done += 1
		progress_label.text = "Quest Progress: %d/4" % done

func complete_objective(objective_name: String):
	# Ignore interactions until cashier explicitly starts the quest
	if not quest_started:
		print("StoreQuest: ignoring interaction before quest start: ", objective_name)
		return
	var idx := _objective_index(objective_name)
	if idx == -1:
		print("StoreQuest: Unknown objective", objective_name)
		return
	# Enforce sequence strictly
	if idx != current_objective_index:
		print("StoreQuest: Not the current objective yet (", objective_name, ")")
		return
	if objectives[objective_name]:
		print("StoreQuest: Objective already completed", objective_name)
		return
	
	objectives[objective_name] = true
	update_quest_ui()
	animate_objective_completion(idx)
	
	await get_tree().create_timer(0.8).timeout
	if current_objective_index < 3:
		current_objective_index += 1
		update_quest_ui()
	else:
		animate_quest_completion()

func _objective_index(name: String) -> int:
	match name:
		"interact_ice_cream_fridge":
			return 0
		"interact_meat_fridge":
			return 1
		"interact_hotdog_siopao":
			return 2
		"interact_slurpee":
			return 3
		_:
			return -1

func animate_objective_completion(objective_index: int):
	if objective_index >= 0 and objective_index < objective_checkboxes.size() and objective_index < objective_labels.size():
		var checkbox: CheckBox = objective_checkboxes[objective_index]
		var label: Label = objective_labels[objective_index]
		if checkbox and label:
			var tween = create_tween()
			tween.set_parallel(true)
			checkbox.scale = Vector2(0.85, 0.85)
			tween.tween_property(checkbox, "scale", Vector2(1.15, 1.15), 0.2)
			tween.tween_property(checkbox, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
			label.modulate = Color.WHITE
			tween.tween_property(label, "modulate", Color.GREEN, 0.35)
			# Extra quest box bounce + highlight
			if quest_box:
				var q_tween = create_tween()
				q_tween.set_parallel(true)
				q_tween.tween_property(quest_box, "scale", Vector2(1.06, 1.06), 0.15)
				q_tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.15).set_delay(0.15)
				var original_modulate: Color = quest_box.modulate
				q_tween.tween_property(quest_box, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.15)
				q_tween.tween_property(quest_box, "modulate", original_modulate, 0.15).set_delay(0.15)
			animate_quest_box_shake()

func animate_quest_box_shake():
	if quest_box:
		var orig = quest_box.position
		var tween = create_tween()
		tween.tween_property(quest_box, "position", orig + Vector2(3, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(-3, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(2, 0), 0.05)
		tween.tween_property(quest_box, "position", orig + Vector2(-2, 0), 0.05)
		tween.tween_property(quest_box, "position", orig, 0.05)

func animate_quest_completion():
	if quest_box:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.25)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.25).set_delay(0.25)
		tween.tween_property(quest_box, "modulate", Color(1.5, 1.3, 0.8, 1.0), 0.5)
		tween.tween_property(quest_box, "modulate", Color.WHITE, 0.5).set_delay(0.5)
		# Trigger earthquake quest after the animation instead of going to survive scene
		call_deferred("_trigger_earthquake_quest")

func _trigger_earthquake_quest():
	# Hide the store quest UI since earthquake quest will take over
	hide_quest_ui()
	
	# Wait a moment for the animation to complete
	await get_tree().create_timer(0.8).timeout
	
	# Check if earthquake quest is already active to avoid duplicates
	var existing = get_tree().current_scene.find_child("EarthquakeQuest", true, false)
	if existing:
		print("StoreQuest: EarthquakeQuest already active")
		return
	
	# Play the pre-quest evacuation cutscene first
	await _play_pre_earthquake_evacuation_cutscene()
	
	# Load and instantiate the earthquake quest
	var quest_res: PackedScene = load("res://earthquake_quest.tscn")
	if quest_res:
		var quest_instance = quest_res.instantiate()
		get_tree().current_scene.add_child(quest_instance)
		print("StoreQuest: EarthquakeQuest instantiated after store quest completion")
	else:
		print("StoreQuest: ERROR - earthquake_quest.tscn not found")

# Pre-earthquake evacuation cutscene (moved from slurpee.gd)
func _play_pre_earthquake_evacuation_cutscene() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	# Play earthquake audio for cutscene (ambient loop), stop store ambience
	if AudioManager:
		AudioManager.stop_ambient()
		AudioManager.play_ambient("res://PLayer insteraction Talking and pick up talking/Music/Earthquak.mp3", true)
	# Get player and temporarily disable RemoteTransform controlling the camera
	var player = get_tree().get_first_node_in_group("Player2")
	if player == null:
		player = scene.find_child("PLAYER 3", true, false)
	print("Cutscene: player found via group or fallback:", player != null)
	var remote_rt: RemoteTransform2D = null
	var old_remote_path: NodePath = NodePath("")
	if player:
		remote_rt = player.get_node_or_null("RemoteTransform2D")
	if remote_rt == null:
		remote_rt = scene.find_child("RemoteTransform2D", true, false)
	if remote_rt and remote_rt is RemoteTransform2D:
		old_remote_path = (remote_rt as RemoteTransform2D).remote_path
		print("Cutscene: detaching RemoteTransform, old path:", old_remote_path)
		(remote_rt as RemoteTransform2D).remote_path = NodePath("")
	var cashier = scene.find_child("Cashier (NPC)", true, false)
	var customer = scene.find_child("Customer (NPC)", true, false)
	var exit_area = scene.find_child("Store Exit", true, false)
	# Ensure walking animations face exit at the start
	if cashier and cashier.has_method("face_exit_walk"):
		cashier.face_exit_walk()
	if customer and customer.has_method("face_exit_walk"):
		customer.face_exit_walk()
	# Keep a reference to the gameplay camera to restore later
	var player_cam: Camera2D = scene.get_node_or_null("Camera2D")
	# Create/activate cutscene camera we fully control
	var cam := _ensure_cutscene_camera(scene)
	print("Cutscene: nodes found — cashier:", cashier != null, " customer:", customer != null, " cam:", cam != null)
	# Determine exit target position
	var exit_pos: Vector2 = Vector2.ZERO
	if exit_area:
		var exit_shape = exit_area.get_node_or_null("CollisionShape2D")
		if exit_shape:
			exit_pos = (exit_shape as Node2D).global_position
		else:
			exit_pos = (exit_area as Node2D).global_position
	else:
		exit_pos = Vector2(get_viewport().size.x * 0.5, get_viewport().size.y * 0.9)
	var exit_out_pos: Vector2 = exit_pos + Vector2(0, 160)
	# Focus camera on cashier using visual anchor (Sprite2D preferred)
	if cashier and cam:
		var cashier_pos := _get_npc_visual_position(cashier)
		print("Cutscene: focusing camera on cashier at:", cashier_pos)
		await _focus_camera(cam, cashier_pos, Vector2(1.0, 1.0), 1.0)
		await get_tree().create_timer(0.1).timeout
	if cashier:
		var cashier_anchor_local := _get_npc_anchor_local(cashier)
		# Reinforce walking facing before moving
		if cashier.has_method("face_exit_walk"):
			cashier.face_exit_walk()
		# Build a curve for the visible sprite position directly to the exit
		var cashier_start := _get_npc_visual_position(cashier)
		var cashier_curve := _build_evacuation_curve(cashier_start, exit_pos + Vector2(0, -60), exit_out_pos)
		await _tween_node_and_cam_along_curve(cashier as Node2D, cashier_curve, cam, cashier_anchor_local, Vector2(0, -24), 3.0)
		await get_tree().create_timer(0.25).timeout
		_disable_npc(cashier)
	# Focus camera on customer using visual anchor
	if customer and cam:
		var customer_pos := _get_npc_visual_position(customer)
		print("Cutscene: focusing camera on customer at:", customer_pos)
		await _focus_camera(cam, customer_pos, Vector2(1.0, 1.0), 1.0)
		await get_tree().create_timer(0.1).timeout
	if customer:
		var customer_anchor_local := _get_npc_anchor_local(customer)
		# Ensure facing exit before moving (walk)
		if customer.has_method("face_exit_walk"):
			customer.face_exit_walk()
		# Build a curve for the visible sprite position directly to the exit
		var customer_start := _get_npc_visual_position(customer)
		var customer_curve := _build_evacuation_curve(customer_start, exit_pos + Vector2(0, -60), exit_out_pos)
		await _tween_node_and_cam_along_curve(customer as Node2D, customer_curve, cam, customer_anchor_local, Vector2(0, -24), 3.0)
		await get_tree().create_timer(0.25).timeout
		_disable_npc(customer)
	# Focus briefly on the exit (zoom back to normal)
	if cam:
		await _focus_camera(cam, exit_pos, Vector2(1.0, 1.0), 0.9)
	# Return camera to player, then hand control back to gameplay camera
	if player and cam:
		await _focus_camera(cam, (player as Node2D).global_position, Vector2(1.0, 1.0), 0.8)
	# Re-enable player follow and actively switch to the camera the RemoteTransform targets
	var restored_cam: Camera2D = player_cam
	if remote_rt and remote_rt is RemoteTransform2D:
		print("Cutscene: restoring RemoteTransform to:", old_remote_path)
		(remote_rt as RemoteTransform2D).remote_path = old_remote_path
		(remote_rt as RemoteTransform2D).update_position = true
		(remote_rt as RemoteTransform2D).update_rotation = false
		(remote_rt as RemoteTransform2D).update_scale = false
		var target = (remote_rt as Node).get_node_or_null(old_remote_path)
		if target and target is Camera2D:
			restored_cam = target as Camera2D
			# Snap gameplay camera to player immediately and make it current
			if player and player is Node2D:
				(restored_cam as Camera2D).global_position = (player as Node2D).global_position
			(restored_cam as Camera2D).make_current()
		else:
			# Fallback: reattach to default store camera path and make it current
			var default_path := NodePath("../../Camera2D")
			(remote_rt as RemoteTransform2D).remote_path = default_path
			var fb_target = (remote_rt as Node).get_node_or_null(default_path)
			if fb_target and fb_target is Camera2D:
				restored_cam = fb_target as Camera2D
				if player and player is Node2D:
					(restored_cam as Camera2D).global_position = (player as Node2D).global_position
				(restored_cam as Camera2D).make_current()
			elif player_cam:
				player_cam.make_current()
	# Force current after one frame to ensure viewport uses restored camera
	await get_tree().process_frame
	var viewport_cam := get_viewport().get_camera_2d()
	if restored_cam and viewport_cam != restored_cam:
		(restored_cam as Camera2D).make_current()
	# Clean up cutscene cam and ensure restored camera is current
	_cleanup_cutscene_camera(scene, cam, restored_cam)
	# Stop earthquake ambience and restore store ambience
	if AudioManager:
		AudioManager.stop_ambient()
		AudioManager.play_ambient("res://Music/INSIDE_THE_STORE_AUDIO.mp3", true)

# Helper functions for the cutscene (moved from slurpee.gd)
func _get_npc_visual_position(npc: Node) -> Vector2:
	if npc == null:
		return Vector2.ZERO
	var anchor_local := _get_npc_anchor_local(npc)
	if npc is Node2D:
		return (npc as Node2D).to_global(anchor_local)
	return Vector2.ZERO

func _get_npc_anchor_local(npc: Node) -> Vector2:
	if npc == null:
		return Vector2.ZERO
	var spr := npc.get_node_or_null("Sprite2D")
	if spr and spr is Node2D:
		return (spr as Node2D).position
	var coll := npc.get_node_or_null("CollisionShape2D")
	if coll and coll is Node2D:
		return (coll as Node2D).position
	return Vector2.ZERO

func _focus_camera(cam: Camera2D, target_pos: Vector2, zoom: Vector2, dur: float) -> void:
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	t.tween_property(cam, "global_position", target_pos, dur)
	t.tween_property(cam, "zoom", zoom, dur)
	await t.finished

func _ensure_cutscene_camera(scene: Node) -> Camera2D:
	var existing := scene.get_node_or_null("CutsceneCamera")
	if existing and existing is Camera2D:
		(existing as Camera2D).make_current()
		return existing as Camera2D
	var cam := Camera2D.new()
	cam.name = "CutsceneCamera"
	cam.position_smoothing_enabled = false
	cam.ignore_rotation = true
	cam.zoom = Vector2(1.0, 1.0)
	scene.add_child(cam)
	cam.make_current()
	return cam

func _cleanup_cutscene_camera(scene: Node, cut_cam: Camera2D, player_cam: Camera2D) -> void:
	if player_cam:
		player_cam.make_current()
	if cut_cam and cut_cam.is_inside_tree():
		cut_cam.queue_free()

func _disable_npc(npc: Node) -> void:
	if npc == null:
		return
	if npc is CanvasItem:
		(npc as CanvasItem).visible = false
	npc.set_process(false)
	npc.set_physics_process(false)
	var ia = npc.get_node_or_null("InteractionArea")
	if ia and ia is Area2D:
		(ia as Area2D).monitoring = false
		(ia as Area2D).set_deferred("monitorable", false)
	var coll = npc.get_node_or_null("CollisionShape2D")
	if coll and coll is CollisionShape2D:
		(coll as CollisionShape2D).disabled = true
	if npc is PhysicsBody2D:
		var body := npc as PhysicsBody2D
		body.collision_layer = 0
		body.collision_mask = 0

func _build_evacuation_curve(start: Vector2, exit_pos: Vector2, out_pos: Vector2) -> Curve2D:
	var c := Curve2D.new()
	c.add_point(start)
	var mid := start.lerp(exit_pos, 0.6) + Vector2(0, -30)
	c.add_point(mid)
	c.add_point(out_pos)
	return c

func _update_node_and_cam_along_curve(progress: float, node: Node2D, curve: Curve2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2) -> void:
	var len := curve.get_baked_length()
	var target_sprite_global := curve.sample_baked(progress * len)
	node.global_position = target_sprite_global - anchor_local
	cam.global_position = target_sprite_global + extra_offset
	if node and node.has_method("face_exit_walk"):
		node.face_exit_walk()

func _tween_node_and_cam_along_curve(node: Node2D, curve: Curve2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2, duration: float) -> void:
	var callable := Callable(self, "_update_node_and_cam_along_curve").bind(node, curve, cam, anchor_local, extra_offset)
	var t := create_tween()
	t.tween_method(callable, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

func show_quest_box_with_animation():
	if quest_box and not is_quest_box_visible:
		is_quest_box_visible = true
		quest_box.visible = true
		quest_box.scale = Vector2(0.3, 0.3)
		quest_box.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
		tween.tween_property(quest_box, "modulate:a", 1.0, 0.4)
		# Use offset_left for anchor-based positioning animation
		var start_offset = original_position.x + 120
		quest_box.offset_left = start_offset
		quest_box.offset_right = start_offset + 420.0  # box_width
		tween.tween_property(quest_box, "offset_left", original_position.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(quest_box, "offset_right", original_position.x + 420.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	elif not quest_box:
		print("StoreQuest: ERROR - quest_box is null")

# Entry points called by item scripts
func on_ice_cream_fridge_interaction():
	complete_objective("interact_ice_cream_fridge")

func on_meat_fridge_interaction():
	complete_objective("interact_meat_fridge")

func on_hotdog_siopao_interaction():
	complete_objective("interact_hotdog_siopao")

func on_slurpee_interaction():
	complete_objective("interact_slurpee")

# New: allow external systems to hide/show the StoreQuest UI
func hide_quest_ui():
	is_quest_box_visible = false
	if quest_box:
		quest_box.visible = false

func show_quest_ui():
	if quest_box:
		quest_box.visible = true
	# Re-run the slide-in animation if it was hidden
	show_quest_box_with_animation()

func _reposition_quest_box():
	if quest_box:
		# Use anchor-based positioning instead of absolute positioning
		# This ensures proper positioning in both windowed and fullscreen modes
		quest_box.anchors_preset = Control.PRESET_TOP_LEFT
		quest_box.anchor_left = 0.0
		quest_box.anchor_right = 0.0
		quest_box.anchor_top = 0.0
		quest_box.anchor_bottom = 0.0
		
		# Set offsets for proper positioning (left-side anchoring)
		var margin := 24.0
		var top_offset := 80.0
		var box_width := 420.0  # Fixed width based on scene file
		var box_height := 200.0  # Fixed height based on scene file
		
		quest_box.offset_left = margin
		quest_box.offset_right = margin + box_width
		quest_box.offset_top = top_offset
		quest_box.offset_bottom = top_offset + box_height
		
		# Store the anchor-based position for animations
		original_position = Vector2(quest_box.offset_left, quest_box.offset_top)
	else:
		print("StoreQuest: WARNING - Quest box not found during reposition")

# New: explicit start, only called by cashier interaction
func start_quest():
	if quest_started:
		return
	quest_started = true
	print("StoreQuest: started by cashier interaction")
	update_quest_ui()
	show_quest_ui()
