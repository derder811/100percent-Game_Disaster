extends Node

# Quest objectives tracking - Sequential progression
var objectives = {
	"check_television": false,
	"interact_fuse_box": false,
	"collect_emergency_items": false
}

# Current active objective index (0-based)
var current_objective_index = 0

# Track emergency items collected
var emergency_items_collected = 0
var total_emergency_items = 9  # powerbank, phone, documents, first aid (medkit), battery, flashlight, canned food, water bottle, medicine 3

# Timer variables for third quest
var quest_timer: Timer
var timer_duration = 90.0  # 1 minute 30 seconds
var time_remaining = 90.0
var is_timer_active = false
var timer_label: Label

# Reference to the bag inventory
var bag_inventory = null

# References to UI elements
@onready var objective_checkboxes = []
@onready var objective_labels = []
@onready var quest_box: Control
var original_position: Vector2
var is_quest_box_visible: bool = false

func _ready():
	print("Quest: _ready() called - initializing quest system")
	
	# Register as global singleton first
	if not Engine.has_singleton("QuestManager"):
		Engine.register_singleton("QuestManager", self)
		print("Quest: Registered as QuestManager singleton")
	
	# Initialize timer for third quest
	setup_quest_timer()
	
	# Find the bag inventory in the scene
	find_bag_inventory()
	
	# Get references to the objective checkboxes and labels in the quest UI
	var objectives_container = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/Objectives")
	quest_box = get_node_or_null("Quest UI/Quest Text Box")
	
	print("Quest: objectives_container found: ", objectives_container != null)
	print("Quest: quest_box found: ", quest_box != null)
	
	# Store original position and hide quest box initially
	if quest_box:
		original_position = quest_box.position
		hide_quest_box()
		print("Quest: Quest box hidden initially at position: ", original_position)
		
		# Setup timer label
		setup_timer_label()
	else:
		print("Quest: ERROR - Quest box not found!")
	
	if objectives_container:
		print("Quest: Found objectives container with ", objectives_container.get_child_count(), " children")
		for child in objectives_container.get_children():
			if child is HBoxContainer:
				print("Quest: Processing HBoxContainer with ", child.get_child_count(), " children")
				# Find checkbox and label in each HBoxContainer
				for subchild in child.get_children():
					if subchild is CheckBox:
						objective_checkboxes.append(subchild)
						print("Quest: Found checkbox: ", subchild.name)
					elif subchild is Label:
						objective_labels.append(subchild)
						print("Quest: Found label: ", subchild.name)
	
	print("Quest: Total checkboxes found: ", objective_checkboxes.size())
	print("Quest: Total labels found: ", objective_labels.size())
	
	# Set initial objective text
	update_quest_ui()
	
	# Connect to global signals for interactions
	# We'll use a custom signal system for quest completion
	if not has_signal("objective_completed"):
		add_user_signal("objective_completed", [{"name": "objective_name", "type": TYPE_STRING}])

func update_quest_ui():
	# Update the quest UI to show only the current active objective
	var objective_texts = [
		"Go downstairs and check the television",
		"Find and interact with the fuse box", 
		"Collect all pickable emergency items"
	]
	
	print("Quest: Updating UI for objective index: ", current_objective_index)
	print("Quest: objective_checkboxes size: ", objective_checkboxes.size())
	print("Quest: objective_labels size: ", objective_labels.size())
	
	# Safety check - ensure arrays are not empty
	if objective_checkboxes.size() == 0 or objective_labels.size() == 0:
		print("Quest: WARNING - UI arrays not initialized yet, skipping update")
		return
	
	# Hide all checkboxes and labels first
	for i in range(objective_checkboxes.size()):
		if i < objective_checkboxes.size() and objective_checkboxes[i]:
			objective_checkboxes[i].visible = false
		if i < objective_labels.size() and objective_labels[i]:
			objective_labels[i].visible = false
	
	# Show only the current active objective
	if current_objective_index < objective_texts.size() and current_objective_index < objective_labels.size() and current_objective_index < objective_checkboxes.size():
		var current_label = objective_labels[current_objective_index]
		var current_checkbox = objective_checkboxes[current_objective_index]
		
		if current_label:
			current_label.visible = true
			var current_text = objective_texts[current_objective_index]
			
			# Add progress for emergency items collection
			if current_objective_index == 2:  # Emergency items objective
				current_text += " (" + str(emergency_items_collected) + "/" + str(total_emergency_items) + ")"
			
			# Check if objective is completed
			var objective_keys = ["check_television", "interact_fuse_box", "collect_emergency_items"]
			if current_objective_index < objective_keys.size():
				var is_completed = objectives[objective_keys[current_objective_index]]
				
				if is_completed:
					current_label.modulate = Color.GREEN
					current_label.text = "✓ " + current_text
				else:
					current_label.modulate = Color.WHITE
					current_label.text = current_text
			
			print("Quest: Set current objective text: ", current_label.text)
		
		if current_checkbox:
			current_checkbox.visible = true
			var objective_keys = ["check_television", "interact_fuse_box", "collect_emergency_items"]
			if current_objective_index < objective_keys.size():
				current_checkbox.button_pressed = objectives[objective_keys[current_objective_index]]
	
	# Update progress label to show overall progress
	var progress_label = get_node_or_null("Quest UI/Quest Text Box/QuestContainer/ProgressLabel")
	if progress_label:
		var completed_count = 0
		for objective in objectives.values():
			if objective:
				completed_count += 1
		
		progress_label.visible = true
		progress_label.text = "Quest Progress: " + str(completed_count) + "/3"
		print("Quest: Set progress text: ", progress_label.text)

func animate_objective_completion(objective_index: int):
	"""Animate the completion of an objective with smooth transitions"""
	if objective_index >= 0 and objective_index < objective_checkboxes.size() and objective_index < objective_labels.size():
		var checkbox = objective_checkboxes[objective_index]
		var label = objective_labels[objective_index]
		
		if checkbox and label:
			# Create a tween for smooth animations
			var tween = create_tween()
			tween.set_parallel(true)  # Allow multiple animations to run simultaneously
			
			# 1. Checkbox scaling animation
			checkbox.scale = Vector2(0.8, 0.8)
			tween.tween_property(checkbox, "scale", Vector2(1.2, 1.2), 0.2)
			tween.tween_property(checkbox, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2)
			
			# 2. Label color transition animation
			label.modulate = Color.WHITE
			tween.tween_property(label, "modulate", Color.GREEN, 0.4)
			
			# 3. Quest box highlight animation
			if quest_box:
				var original_modulate = quest_box.modulate
				tween.tween_property(quest_box, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.3)
				tween.tween_property(quest_box, "modulate", original_modulate, 0.3).set_delay(0.3)
			
			# 4. Add a subtle shake effect to the quest box
			animate_quest_box_shake()

func animate_quest_box_shake():
	"""Add a subtle shake animation to the quest box when objective is completed"""
	if quest_box:
		var original_position = quest_box.position
		var tween = create_tween()
		
		# Small shake animation
		tween.tween_property(quest_box, "position", original_position + Vector2(3, 0), 0.05)
		tween.tween_property(quest_box, "position", original_position + Vector2(-3, 0), 0.05)
		tween.tween_property(quest_box, "position", original_position + Vector2(2, 0), 0.05)
		tween.tween_property(quest_box, "position", original_position + Vector2(-2, 0), 0.05)
		tween.tween_property(quest_box, "position", original_position, 0.05)

func complete_objective(objective_name: String):
	print("=== COMPLETE OBJECTIVE DEBUG ===")
	print("Attempting to complete objective: ", objective_name)
	print("Current objectives status: ", objectives)
	print("Current objective index: ", current_objective_index)
	
	if objectives.has(objective_name) and not objectives[objective_name]:
		objectives[objective_name] = true
		print("Quest: Objective completed - ", objective_name)
		
		# Find the index of the completed objective for animation
		var objective_index = -1
		match objective_name:
			"check_television":
				objective_index = 0
			"interact_fuse_box":
				objective_index = 1
			"collect_emergency_items":
				objective_index = 2
		
		print("Objective index: ", objective_index)
		
		# Update UI first
		update_quest_ui()
		
		# Then animate the completion
		if objective_index >= 0:
			animate_objective_completion(objective_index)
		
		# For emergency items, we should complete it regardless of current_objective_index
		if objective_name == "collect_emergency_items":
			print("Emergency items objective completed!")
			# Stop the timer when emergency items quest is completed
			stop_quest_timer()
			# Set current objective to this one if it's not already
			if current_objective_index < 2:
				current_objective_index = 2
				print("Advanced current_objective_index to 2 for emergency items")
		
		# Advance to next objective if not at the end
		if objective_index == current_objective_index and current_objective_index < 2:
			# Wait for animation to complete before advancing
			await get_tree().create_timer(1.0).timeout
			current_objective_index += 1
			print("Quest: Advanced to objective index ", current_objective_index)
			
			# Start timer when advancing to the third quest (emergency items collection)
			if current_objective_index == 2:
				print("Quest: Starting timer for emergency items collection")
				start_quest_timer()
			
			# Update UI to show the new objective
			update_quest_ui()
		elif current_objective_index >= 2:
			# All objectives completed
			print("Quest: All objectives completed!")
			await get_tree().create_timer(1.0).timeout
			animate_quest_completion()
		
		# Check if all objectives are complete
		if all_objectives_complete():
			print("Quest: All objectives completed!")
			animate_quest_completion()
	else:
		print("Objective not completed because:")
		if not objectives.has(objective_name):
			print("  - Objective name not found in objectives dict")
		elif objectives[objective_name]:
			print("  - Objective already completed")
	print("===============================")

func animate_quest_completion():
	"""Special animation when all objectives are completed"""
	if quest_box:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Pulse animation for the entire quest box
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.3)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.3)
		
		# Golden glow effect
		tween.tween_property(quest_box, "modulate", Color(1.5, 1.3, 0.8, 1.0), 0.5)
		tween.tween_property(quest_box, "modulate", Color.WHITE, 0.5).set_delay(0.5)

func all_objectives_complete() -> bool:
	for objective in objectives.values():
		if not objective:
			return false
	return true

# Function to be called when player interacts with window
func on_window_interaction():
	print("Quest: on_window_interaction() called!")
	# Show the quest box when window is interacted with
	show_quest_box_with_animation()
	print("Quest system activated by window interaction!")

# Function to be called when player interacts with TV
func on_tv_interaction():
	complete_objective("check_television")

# Function to be called when player interacts with fuse box
func on_fusebox_interaction():
	complete_objective("interact_fuse_box")

# Function to be called when player collects an emergency item
func on_emergency_item_collected():
	emergency_items_collected += 1
	print("Emergency item collected! Progress: ", emergency_items_collected, "/", total_emergency_items)
	
	# Update the UI to show progress
	update_emergency_items_ui()
	
	# Complete the objective if all items are collected
	if emergency_items_collected >= total_emergency_items:
		complete_objective("collect_emergency_items")

func find_bag_inventory():
	"""Find the bag inventory in the scene tree"""
	print("=== QUEST BAG DISCOVERY DEBUG ===")
	var scene = get_tree().current_scene
	if scene:
		print("Current scene: ", scene.name)
		
		# First try to find the player
		var player = scene.find_child("Player", true, false)
		if not player:
			# Try alternative player names
			player = scene.find_child("CharacterBody2D", true, false)
		
		if player:
			print("Found player: ", player.name)
			print("Player children:")
			for child in player.get_children():
				print("  - ", child.name, " (", child.get_class(), ")")
			
			# Look for bag as child of player
			bag_inventory = player.find_child("Bag", true, false)
			if bag_inventory:
				print("✓ Found bag inventory as child of player: ", bag_inventory.name)
				print("Bag has get_emergency_items_count method: ", bag_inventory.has_method("get_emergency_items_count"))
				print("Bag has items property: ", "items" in bag_inventory)
			else:
				print("✗ Bag not found as child of player")
		else:
			print("✗ Player not found in scene")
			# Fallback: Look for bag directly in scene
			bag_inventory = scene.find_child("Bag", true, false)
			if bag_inventory:
				print("✓ Found bag inventory in scene: ", bag_inventory.name)
			else:
				print("✗ Bag inventory not found anywhere in scene")
	else:
		print("✗ No current scene found")
	
	print("Final bag_inventory: ", bag_inventory)
	print("===============================")

func get_emergency_items_count():
	"""Get the count of emergency items from the bag inventory"""
	if bag_inventory and bag_inventory.has_method("get_emergency_items_count"):
		return bag_inventory.get_emergency_items_count()
	elif bag_inventory and "items" in bag_inventory:
		# Count emergency items in the bag - exact names from scripts (case-insensitive)
		var emergency_item_names = [
			"powerbank",
			"phone",
			"documents",
			"first aid kit",
			"battery",
			"flashlight",
			"canned food",
			"water bottle",
			"medicine 3"
		]
		var count = 0
		for item in bag_inventory.items:
			if "name" in item:
				var item_name = item["name"].to_lower()
				# Check if the item name matches any emergency item (case-insensitive)
				var is_emergency = false
				for emergency_name in emergency_item_names:
					if item_name == emergency_name:
						is_emergency = true
						break
				
				if is_emergency:
					count += 1
		return count
	else:
		# Fallback to manual tracking
		return emergency_items_collected

func update_emergency_items_ui():
	print("=== QUEST UI UPDATE DEBUG ===")
	# Get the actual count from the bag inventory
	var actual_count = get_emergency_items_count()
	print("Actual count from bag: ", actual_count)
	print("Total emergency items needed: ", total_emergency_items)
	print("Current objective index: ", current_objective_index)
	print("Objectives status: ", objectives)
	
	# Update the third objective label to show progress
	if objective_labels.size() > 2:
		var progress_text = "Collect all pickable emergency items (" + str(actual_count) + "/" + str(total_emergency_items) + ")"
		objective_labels[2].text = progress_text
		print("Updated objective label: ", progress_text)
	else:
		print("ERROR: Not enough objective labels (", objective_labels.size(), ")")
	
	# Check if quest should be completed based on actual inventory count
	if actual_count >= total_emergency_items:
		print("QUEST COMPLETION TRIGGERED! Calling complete_objective")
		complete_objective("collect_emergency_items")
	else:
		print("Quest not complete yet. Need ", total_emergency_items - actual_count, " more items")
	print("============================")

func toggle_quest_box_visibility():
	"""Toggle quest box visibility - show if hidden, hide if shown"""
	if is_quest_box_visible:
		hide_quest_box()
	else:
		show_quest_box_with_animation()

func hide_quest_box():
	"""Hide the quest box completely"""
	if quest_box:
		quest_box.visible = false
		quest_box.modulate.a = 0.0
		quest_box.scale = Vector2(0.8, 0.8)
		is_quest_box_visible = false

func show_quest_box_with_animation():
	"""Show quest box with pop animation"""
	print("Quest: show_quest_box_with_animation() called")
	print("Quest: quest_box exists: ", quest_box != null)
	print("Quest: is_quest_box_visible: ", is_quest_box_visible)
	
	if quest_box and not is_quest_box_visible:
		print("Quest: Starting quest box animation")
		is_quest_box_visible = true
		quest_box.visible = true
		
		# Start with small scale and transparent
		quest_box.scale = Vector2(0.3, 0.3)
		quest_box.modulate.a = 0.0
		
		print("Quest: Quest box made visible, starting tween animation")
		
		# Create pop animation
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Scale animation with bounce effect
		tween.tween_property(quest_box, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(quest_box, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.3)
		
		# Fade in animation
		tween.tween_property(quest_box, "modulate:a", 1.0, 0.4)
		
		# Position animation (slide in from side)
		var start_position = original_position + Vector2(-100, 0)
		quest_box.position = start_position
		tween.tween_property(quest_box, "position", original_position, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		print("Quest: Animation started successfully")
	else:
		if not quest_box:
			print("Quest: ERROR - Cannot show quest box, quest_box is null!")
		elif is_quest_box_visible:
			print("Quest: Quest box is already visible")

# Global function that can be called from anywhere
func _notification(what):
	if what == NOTIFICATION_READY:
		# Make this quest system globally accessible
		if not Engine.has_singleton("QuestManager"):
			Engine.register_singleton("QuestManager", self)

func setup_quest_timer():
	"""Initialize the timer for the third quest"""
	quest_timer = Timer.new()
	quest_timer.wait_time = 1.0  # Update every second
	quest_timer.timeout.connect(_on_timer_timeout)
	add_child(quest_timer)
	print("Quest: Timer setup complete")

func setup_timer_label():
	"""Setup the timer label in the UI"""
	if quest_box:
		# Try to find existing timer label or create one
		timer_label = quest_box.find_child("TimerLabel", true, false)
		if not timer_label:
			# Create timer label if it doesn't exist
			timer_label = Label.new()
			timer_label.name = "TimerLabel"
			timer_label.text = ""
			timer_label.add_theme_color_override("font_color", Color.RED)
			timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# Add to quest box
			var quest_container = quest_box.find_child("QuestContainer", true, false)
			if quest_container:
				quest_container.add_child(timer_label)
				# Move timer label to top
				quest_container.move_child(timer_label, 0)
			else:
				quest_box.add_child(timer_label)
			
			print("Quest: Created timer label")
		else:
			print("Quest: Found existing timer label")
		
		timer_label.visible = false  # Hidden initially

func start_quest_timer():
	"""Start the timer for the third quest"""
	if quest_timer and not is_timer_active:
		time_remaining = timer_duration
		is_timer_active = true
		quest_timer.start()
		
		# Show timer label
		if timer_label:
			timer_label.visible = true
			update_timer_display()
		
		print("Quest: Timer started for emergency items collection (90 seconds)")

func stop_quest_timer():
	"""Stop the quest timer"""
	if quest_timer and is_timer_active:
		quest_timer.stop()
		is_timer_active = false
		
		# Hide timer label
		if timer_label:
			timer_label.visible = false
		
		print("Quest: Timer stopped")

func _on_timer_timeout():
	"""Called every second when timer is active"""
	if is_timer_active:
		time_remaining -= 1.0
		update_timer_display()
		
		if time_remaining <= 0:
			# Timer expired - trigger game over
			timer_expired()

func update_timer_display():
	"""Update the timer display in the UI"""
	if timer_label and is_timer_active:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		timer_label.text = "Time Remaining: %02d:%02d" % [minutes, seconds]
		
		# Change color based on remaining time
		if time_remaining <= 30:
			timer_label.add_theme_color_override("font_color", Color.RED)
		elif time_remaining <= 60:
			timer_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)

func timer_expired():
	"""Handle timer expiration - trigger flood animation then game over"""
	print("Quest: Timer expired! Triggering flood animation before game over!")
	stop_quest_timer()
	
	# Trigger flood animation first
	trigger_flood_animation()
	
	# Show game over message
	show_game_over_message()
	
	# Wait longer to allow flood animation to play
	await get_tree().create_timer(5.0).timeout
	trigger_game_over()

func show_game_over_message():
	"""Show a game over message to the player"""
	if timer_label:
		timer_label.text = "TIME'S UP! GAME OVER!"
		timer_label.add_theme_color_override("font_color", Color.RED)
		
		# Animate the game over message
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(timer_label, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_property(timer_label, "modulate", Color(1, 0, 0, 1), 0.5)

func trigger_game_over():
	"""Trigger the actual game over - show game over screen"""
	print("Quest: Triggering game over screen")
	
	# Load and show the game over scene
	var game_over_scene_path = "res://game_over.tscn"
	
	if ResourceLoader.exists(game_over_scene_path):
		print("Quest: Loading game over scene: ", game_over_scene_path)
		get_tree().change_scene_to_file(game_over_scene_path)
	else:
		# Fallback - try alternative paths
		var alternative_paths = [
			"res://GAME OVER.tscn",
			"res://GameOver.tscn"
		]
		
		var scene_loaded = false
		for path in alternative_paths:
			if ResourceLoader.exists(path):
				print("Quest: Loading alternative game over scene: ", path)
				get_tree().change_scene_to_file(path)
				scene_loaded = true
				break
		
		if not scene_loaded:
			print("Quest: No game over scene found, restarting current scene")
			get_tree().reload_current_scene()

# Flood system integration
var flood_system = null

func connect_flood_system(flood_node):
	"""Connect the flood system to this quest manager"""
	flood_system = flood_node
	print("Quest: Flood system connected: ", flood_node.name if flood_node else "null")

func trigger_flood_animation():
	"""Trigger the flood animation"""
	print("Quest: Attempting to trigger flood animation")
	
	if flood_system and flood_system.has_method("on_quest_timer_expired"):
		print("Quest: Calling flood system timer expired method")
		flood_system.on_quest_timer_expired()
	else:
		# Try to find flood system in scene if not connected
		var scene = get_tree().current_scene
		if scene:
			var flood_node = scene.find_child("FLOOD", true, false)
			if not flood_node:
				flood_node = scene.find_child("Flood", true, false)
			
			if flood_node and flood_node.has_method("on_quest_timer_expired"):
				print("Quest: Found flood node in scene, triggering animation")
				flood_node.on_quest_timer_expired()
				flood_system = flood_node  # Cache for future use
			else:
				print("Quest: WARNING - Could not find or trigger flood system")
		else:
			print("Quest: ERROR - No current scene found")

func is_timer_expired() -> bool:
	"""Check if the quest timer has expired"""
	return is_timer_active and time_remaining <= 0
