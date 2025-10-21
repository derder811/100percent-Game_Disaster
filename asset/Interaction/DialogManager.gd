extends Node

@onready var text_box_scene = preload("res://asset/Text Box/text_box.tscn")

var dialog_lines: Array[String] = []
var current_line_index = 0

var text_box
var text_box_position: Vector2
var current_asset_type = ""

var is_dialog_active = false
var can_advance_line = false
var active_text_boxes: Array[Node] = []  # Track all active text boxes

func start_dialog(position: Vector2, lines: Array[String], asset_type: String = ""):
	print("DialogManager.start_dialog called with position: ", position, " lines: ", lines, " asset_type: ", asset_type)
	
	# Prevent overlap with safety/item dialogs managed by SimpleDialogManager
	if SimpleDialogManager and SimpleDialogManager.current_dialog and is_instance_valid(SimpleDialogManager.current_dialog):
		if SimpleDialogManager.current_dialog.visible or SimpleDialogManager.current_dialog.is_showing:
			print("DialogManager: SimpleDialog active; skipping text box to avoid overlap")
			return
	
	if is_dialog_active:
		print("Dialog request ignored - dialog already active")
		return
	
	# Clean up any lingering text boxes
	_cleanup_old_text_boxes()
	
	print("Starting new dialog...")
	dialog_lines = lines
	text_box_position = position
	current_asset_type = asset_type
	current_line_index = 0
	_show_text_box()
	
	is_dialog_active = true
	print("Dialog started successfully")

func _cleanup_old_text_boxes():
	# Remove any invalid or orphaned text boxes
	for i in range(active_text_boxes.size() - 1, -1, -1):
		var box = active_text_boxes[i]
		if not is_instance_valid(box) or box.is_queued_for_deletion():
			active_text_boxes.remove_at(i)
		else:
			# Force close any remaining text boxes
			box.queue_free()
			active_text_boxes.remove_at(i)
	
	# Also check for any text boxes in the scene tree that might have been missed
	var all_text_boxes = get_tree().get_nodes_in_group("text_box")
	for box in all_text_boxes:
		if is_instance_valid(box) and not box.is_queued_for_deletion():
			box.queue_free()

func _show_text_box():
	print("_show_text_box called - creating text box instance")
	text_box = text_box_scene.instantiate()
	print("Text box instantiated: ", text_box)
	
	# Add to group for tracking
	text_box.add_to_group("text_box")
	active_text_boxes.append(text_box)
	
	text_box.finished_displaying.connect(_on_text_box_finished_displaying)
	print("Signal connected")
	
	# Set the asset type for safety tips
	if current_asset_type != "":
		text_box.current_asset_type = current_asset_type
		print("Setting asset type to text box: ", current_asset_type)  # Debug print
	
	print("Adding text box to scene tree")
	get_tree().root.add_child(text_box)
	print("Text box added to scene")
	
	# Set initial position based on desired location
	print("Setting initial position to: ", text_box_position)
	text_box.global_position = text_box_position
	
	# Display text to finalize size before overlap adjustment
	print("Calling display_text with: ", dialog_lines[current_line_index])
	text_box.display_text(dialog_lines[current_line_index])
	await get_tree().process_frame
	
	# Adjust position to prevent overlap using actual size and final position
	var adjusted_position = _get_non_overlapping_position(text_box.global_position)
	print("Adjusted position to: ", adjusted_position)
	text_box.global_position = adjusted_position
	
	can_advance_line = false
	print("_show_text_box completed")
	
	# Auto-close single-line dialogs after a brief delay to prevent blocking
	if dialog_lines.size() == 1:
		var t := Timer.new()
		t.one_shot = true
		t.wait_time = 2.5
		t.timeout.connect(func():
			if is_dialog_active and text_box and is_instance_valid(text_box):
				# Remove from tracking before freeing
				var index = active_text_boxes.find(text_box)
				if index != -1:
					active_text_boxes.remove_at(index)
				text_box.queue_free()
				is_dialog_active = false
				current_line_index = 0
		)
		get_tree().root.add_child(t)
		t.start()

func _get_non_overlapping_position(desired_position: Vector2) -> Vector2:
	var adjusted_position = desired_position
	var offset_increment := 16  # Fine-grained vertical spacing
	var max_iterations := 32    # Safety cap to prevent infinite loops
	
	# Use actual text box size after display_text for accurate collision checks
	var new_rect := Rect2(adjusted_position, text_box.size)
	var iterations := 0
	
	while iterations < max_iterations:
		var overlaps := false
		for box in active_text_boxes:
			if is_instance_valid(box) and box != text_box:
				var box_rect := Rect2(box.global_position, box.size)
				if box_rect.intersects(new_rect):
					overlaps = true
					break
		if not overlaps:
			break
		adjusted_position.y += offset_increment
		new_rect.position = adjusted_position
		iterations += 1
	
	return adjusted_position

func _on_text_box_finished_displaying():
	can_advance_line = true

func _unhandled_input(event):
	if (
		event.is_action_pressed("advance_dialog") &&
		is_dialog_active &&
		can_advance_line
	):
		if text_box and is_instance_valid(text_box):
			# Remove from tracking before freeing
			var index = active_text_boxes.find(text_box)
			if index != -1:
				active_text_boxes.remove_at(index)
			text_box.queue_free()
		
		current_line_index += 1
		if current_line_index >= dialog_lines.size():
			is_dialog_active = false
			current_line_index = 0
		else:
			_show_text_box()
