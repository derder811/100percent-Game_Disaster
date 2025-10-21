extends Area2D

func _tween_to(node: Object, prop: String, target, dur: float) -> void:
	var t = create_tween()
	t.tween_property(node, prop, target, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

func _ready():
	# Configure the existing InteractionArea child
	var interaction_area = $InteractionArea
	if interaction_area:
		interaction_area.action_name = "examine slurpee"
		interaction_area.interact = Callable(self, "_on_interact")
		print("Slurpee interaction area configured")
	else:
		print("ERROR: InteractionArea not found in slurpee")

func _on_interact():
	print("DEBUG: _on_interact called in slurpee.gd")
	print("Slurpee machine interacted with!")
	# Earthquake sequence: shake camera, self-talk, then trigger new quest
	_trigger_camera_shake(1.5, 12.0)
	
	# Trigger self-talk for earthquake safety guidance
	var player = get_tree().get_first_node_in_group("Player2")
	print("DEBUG: Found player: ", player != null)
	if player and player.has_method("trigger_item_self_talk"):
		player.trigger_item_self_talk("slurpee")
	else:
		print("DEBUG: Player not found or missing trigger_item_self_talk")
	
	# Trigger the EarthquakeQuest UI and logic (after pre-quest cutscene)
	_trigger_earthquake_quest()
	
	# Update StoreQuest objective (still complete the store quest step)
	var store_quest = get_tree().current_scene.find_child("StoreQuest", true, false)
	if store_quest and store_quest.has_method("on_slurpee_interaction"):
		store_quest.on_slurpee_interaction()

# Simple camera shake using Camera2D offset jitter
func _trigger_camera_shake(duration_sec := 1.5, magnitude := 10.0) -> void:
	# Defer to avoid blocking the interaction flow
	call_deferred("_do_camera_shake", duration_sec, magnitude)

func _do_camera_shake(duration_sec: float, magnitude: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		print("Camera2D not found; skipping shake")
		return
	var original_offset: Vector2 = camera.offset
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var elapsed := 0.0
	while elapsed < duration_sec:
		camera.offset = Vector2(rng.randf_range(-magnitude, magnitude), rng.randf_range(-magnitude, magnitude))
		await get_tree().create_timer(0.02).timeout
		elapsed += 0.02
	camera.offset = original_offset

# Helper: visual position that clamps extreme child offsets; defaults to root
func _get_npc_visual_position(npc: Node) -> Vector2:
	if npc == null:
		return Vector2.ZERO
	var anchor_local := _get_npc_anchor_local(npc)
	if npc is Node2D:
		return (npc as Node2D).to_global(anchor_local)
	return Vector2.ZERO

# Helper: local anchor offset (prefer Sprite2D; else CollisionShape2D; else ZERO)
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

# New: helper to focus camera with optional zoom (using global_position for accuracy)
func _focus_camera(cam: Camera2D, target_pos: Vector2, zoom: Vector2, dur: float) -> void:
	var t = create_tween()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_parallel(true)
	t.tween_property(cam, "global_position", target_pos, dur)
	t.tween_property(cam, "zoom", zoom, dur)
	await t.finished

# Ensure a dedicated cutscene camera that we fully control
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

# Path helpers: move a node along a Path2D's curve
func _update_node_along_path(progress: float, node: Node2D, path: Path2D) -> void:
	var curve := path.curve
	if curve == null:
		return
	var len := curve.get_baked_length()
	var local := curve.sample_baked(progress * len)
	var global := (path as Node2D).to_global(local)
	node.global_position = global

func _tween_along_path(node: Node2D, path: Path2D, duration: float) -> void:
	var callable := Callable(self, "_update_node_along_path").bind(node, path)
	var t := create_tween()
	t.tween_method(callable, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

# Curve helpers: move a node along a dynamically built Curve2D
func _update_node_along_curve(progress: float, node: Node2D, curve: Curve2D) -> void:
	var len := curve.get_baked_length()
	var pos := curve.sample_baked(progress * len)
	node.global_position = pos

func _tween_along_curve(node: Node2D, curve: Curve2D, duration: float) -> void:
	var callable := Callable(self, "_update_node_along_curve").bind(node, curve)
	var t := create_tween()
	t.tween_method(callable, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

func _build_evacuation_curve(start: Vector2, exit_pos: Vector2, out_pos: Vector2) -> Curve2D:
	var c := Curve2D.new()
	# Gentle arc: start -> mid (near exit, slightly up) -> out
	c.add_point(start)
	var mid := start.lerp(exit_pos, 0.6) + Vector2(0, -30)
	c.add_point(mid)
	c.add_point(out_pos)
	return c

# Camera-follow helpers (use global_position for the camera)
func _update_node_and_cam_along_path(progress: float, node: Node2D, path: Path2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2) -> void:
	var curve := path.curve
	if curve == null:
		return
	var len := curve.get_baked_length()
	var local := curve.sample_baked(progress * len)
	var target_sprite_global := (path as Node2D).to_global(local)
	# Move root so that the anchored child (sprite) sits exactly on the curve
	node.global_position = target_sprite_global - anchor_local
	# Center camera on the sprite position with optional framing offset
	cam.global_position = target_sprite_global + extra_offset

func _tween_node_and_cam_along_path(node: Node2D, path: Path2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2, duration: float) -> void:
	var callable := Callable(self, "_update_node_and_cam_along_path").bind(node, path, cam, anchor_local, extra_offset)
	var t := create_tween()
	t.tween_method(callable, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

func _update_node_and_cam_along_curve(progress: float, node: Node2D, curve: Curve2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2) -> void:
	var len := curve.get_baked_length()
	var target_sprite_global := curve.sample_baked(progress * len)
	# Move root to place the anchored child (sprite) on the target curve point
	node.global_position = target_sprite_global - anchor_local
	# Center camera on the sprite position
	cam.global_position = target_sprite_global + extra_offset
	# NEW: keep NPC facing exit while moving along the curve
	if node and node.has_method("face_exit_walk"):
		node.face_exit_walk()

func _tween_node_and_cam_along_curve(node: Node2D, curve: Curve2D, cam: Camera2D, anchor_local: Vector2, extra_offset: Vector2, duration: float) -> void:
	var callable := Callable(self, "_update_node_and_cam_along_curve").bind(node, curve, cam, anchor_local, extra_offset)
	var t := create_tween()
	t.tween_method(callable, 0.0, 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

# NEW: Play pre-earthquake cutscene (cashier + customer evacuate, camera focuses)
func _play_pre_earthquake_evacuation_cutscene() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
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
		if cashier is CanvasItem:
			(cashier as CanvasItem).visible = false
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
		if customer is CanvasItem:
			(customer as CanvasItem).visible = false
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

func _trigger_earthquake_quest():
	# Avoid duplicating the quest if already present
	var existing = get_tree().current_scene.find_child("EarthquakeQuest", true, false)
	if existing:
		print("EarthquakeQuest already active")
		return
	# Play the pre-quest evacuation cutscene first
	await _play_pre_earthquake_evacuation_cutscene()
	var quest_res: PackedScene = load("res://earthquake_quest.tscn")
	if quest_res:
		var quest_instance = quest_res.instantiate()
		get_tree().current_scene.add_child(quest_instance)
		print("EarthquakeQuest instantiated")
	else:
		print("ERROR: earthquake_quest.tscn not found")
