extends CharacterBody2D

# Movement Configuration
@export var max_speed: float = 180.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Interaction Configuration
@export var interaction_radius: float = 60.0
var nearby_interactables: Array[Node] = []
var closest_interactable: Node = null

# UI Elements
var interaction_ui_container: Control
var interaction_label: Label
var interaction_ui: Node  # Reference to enhanced UI system

# Animation
@onready var animation_tree: AnimationTree = $AnimationTree

# Bag/Inventory reference
@onready var bag: Control

# Input Actions - Player 2 WASD movement
const MOVE_LEFT = "move_left"       # A key
const MOVE_RIGHT = "move_right"     # D key
const MOVE_UP = "move_up"           # W key
const MOVE_DOWN = "move_down"       # S key
const INTERACT = "interact"         # E key

func _ready():
	# Add player to the Player2 group for interaction system
	add_to_group("Player2")
	setup_interaction_ui()
	setup_enhanced_ui()
	setup_bag_reference()
	# Connect to physics process for smooth movement
	set_physics_process(true)

func setup_bag_reference():
	# Find the bag as a child of the player
	bag = get_node_or_null("Bag")
	
	if not bag:
		print("✗ WARNING: Bag node not found as child of player")
		print("Available child nodes:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("✓ Bag found and connected successfully")
		print("Bag type: ", bag.get_class())
		print("Bag has get_items method: ", bag.has_method("get_items"))

func setup_interaction_ui():
	# The interaction UI is now handled by the scene-level InteractionUI node
	# This function is kept for compatibility but doesn't create duplicate UI
	pass

func setup_enhanced_ui():
	# Get reference to the scene-level InteractionUI node
	var scene = get_tree().current_scene
	if scene:
		interaction_ui = scene.get_node_or_null("InteractionUI")
	
	if not interaction_ui:
		print("Warning: InteractionUI node not found in scene")
	else:
		print("InteractionUI found and connected successfully")

func _physics_process(delta):
	handle_movement(delta)
	update_nearby_interactables()
	handle_interactions()
	move_and_slide()

func handle_movement(delta):
	# Get input vector
	var input_vector = Vector2.ZERO
	
	# Check for movement input
	if Input.is_action_pressed(MOVE_LEFT):
		input_vector.x -= 1
	if Input.is_action_pressed(MOVE_RIGHT):
		input_vector.x += 1
	if Input.is_action_pressed(MOVE_UP):
		input_vector.y -= 1
	if Input.is_action_pressed(MOVE_DOWN):
		input_vector.y += 1
	
	# Normalize for consistent diagonal movement
	input_vector = input_vector.normalized()
	
	# Update animation direction based on movement
	if input_vector != Vector2.ZERO:
		animation_tree.set("parameters/walk/blend_position", input_vector)
	
	# Apply movement with smooth acceleration/deceleration
	if input_vector != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func handle_interactions():
	# Update nearby interactables
	update_nearby_interactables()
	
	# Handle interaction input
	if Input.is_action_just_pressed(INTERACT) and closest_interactable:
		print("Player: SPACE key pressed! Interacting with ", closest_interactable.name)
		perform_interaction(closest_interactable)
	elif Input.is_action_just_pressed(INTERACT):
		print("Player: SPACE key pressed but no closest interactable found!")

func update_nearby_interactables():
	# Safety check: ensure node is ready and in scene tree
	if not is_inside_tree():
		return
		
	# Clear previous list
	nearby_interactables.clear()
	var previous_closest = closest_interactable
	closest_interactable = null
	var closest_distance = interaction_radius
	
	print("Player: Checking for interactables within radius ", interaction_radius)
	
	# Find all interactable objects in the scene
	var interactables = get_tree().get_nodes_in_group("interactable")
	print("Player: Found ", interactables.size(), " interactable objects in scene")
	
	for interactable in interactables:
		if not interactable or not is_instance_valid(interactable):
			continue
		
		# Skip CanvasLayer nodes (like DialogSystem) as they don't have global_position
		if interactable is CanvasLayer:
			continue
			
		# Safety check to ensure global_position is accessible
		if not interactable.has_method("get_global_position"):
			continue
		var distance = global_position.distance_to(interactable.global_position)
		print("Player: Distance to ", interactable.name, " is ", distance)
		
		if distance <= interaction_radius:
			nearby_interactables.append(interactable)
			print("Player: ", interactable.name, " is within interaction range!")
			
			if distance < closest_distance:
				closest_distance = distance
				closest_interactable = interactable
				print("Player: ", interactable.name, " is now the closest interactable")
	
	# Update UI if closest interactable changed
	if closest_interactable != previous_closest:
		update_interaction_ui()

func update_interaction_ui():
	print("Player: update_interaction_ui called, closest_interactable: ", closest_interactable.name if closest_interactable and is_instance_valid(closest_interactable) else "null")
	
	if closest_interactable and is_instance_valid(closest_interactable):
		print("Player: Found interactable object: ", closest_interactable.name)
		
		# Use enhanced UI system
		if interaction_ui and interaction_ui.has_method("show_interaction_prompt"):
			print("Player: Calling show_interaction_prompt on InteractionUI")
			interaction_ui.show_interaction_prompt(closest_interactable)
		else:
			print("Player: ERROR - interaction_ui is null or doesn't have show_interaction_prompt method")
			print("Player: interaction_ui exists: ", interaction_ui != null)
			if interaction_ui:
				print("Player: interaction_ui methods: ", interaction_ui.get_method_list())
		
		# Fallback to basic UI
		interaction_label.visible = true
		
		# Update text based on object
		if closest_interactable.has_method("get_interaction_prompt"):
			interaction_label.text = closest_interactable.get_interaction_prompt()
		else:
			interaction_label.text = "Press SPACE to interact"
			
		print("Player: Basic interaction label text set to: ", interaction_label.text)
	else:
		print("Player: No interactable object found, hiding UI")
		
		# Use enhanced UI system
		if interaction_ui and interaction_ui.has_method("hide_interaction_prompt"):
			interaction_ui.hide_interaction_prompt()
		
		# Hide basic interaction prompt
		interaction_label.visible = false

func perform_interaction(target):
	if not target:
		print("Player: perform_interaction called with null target")
		return
	
	print("Player: Interacting with: ", target.name)
	
	# Call object's interaction method if it exists
	if target.has_method("on_interact"):
		print("Player: Calling on_interact method on ", target.name)
		target.on_interact(self)
	else:
		print("Player: ERROR - ", target.name, " does not have on_interact method!")
	
	# Handle different types of objects
	match target.get_groups():
		var groups when "furniture" in groups:
			interact_with_furniture(target)
		var groups when "items" in groups:
			interact_with_item(target)
		var groups when "doors" in groups:
			interact_with_door(target)
		var groups when "containers" in groups:
			interact_with_container(target)

func interact_with_furniture(furniture):
	print("Using furniture: ", furniture.name)
	# Example: sitting on chair, opening drawer, etc.
	if furniture.has_method("use"):
		furniture.use()

func interact_with_item(item):
	print("Picking up item: ", item.name)
	# Example: add to inventory, remove from scene
	if item.has_method("pickup"):
		item.pickup()
	else:
		# Default pickup behavior
		get_items(item)
		item.queue_free()

# Function to add items to bag inventory
func get_items(itemData):
	print("=== GET_ITEMS CALLED ===")
	print("Player received item data: ", itemData)
	print("Bag reference exists: ", bag != null)
	
	if bag and bag.has_method("get_items"):
		print("✓ Calling bag.get_items with data: ", itemData)
		bag.get_items(itemData)
		print("✓ Item successfully added to bag")
	else:
		print("✗ ERROR: Bag not found or doesn't have get_items method")
		if not bag:
			print("  - Bag is null")
		else:
			print("  - Bag exists but missing get_items method")

# Function to add items to inventory (alias for get_items for compatibility)
func add_item_to_inventory(itemData):
	print("=== ADD_ITEM_TO_INVENTORY CALLED ===")
	get_items(itemData)

func interact_with_door(door):
	print("Opening/closing door: ", door.name)
	# Example: toggle door state
	if door.has_method("toggle"):
		door.toggle()

func interact_with_container(container):
	print("Opening container: ", container.name)
	# Example: show inventory, loot window
	if container.has_method("open"):
		container.open()

# Helper function to get interaction UI for other scripts
func get_interaction_ui():
	return interaction_ui

# Helper function to make any object interactable
func make_interactable(object: Node, prompt: String = "Press SPACE to interact"):
	if not object.is_in_group("interactable"):
		object.add_to_group("interactable")
	
	# Add interaction prompt method if it doesn't exist
	if not object.has_method("get_interaction_prompt"):
		var script_text = """
extends Node

var interaction_prompt = "%s"

func get_interaction_prompt():
	return interaction_prompt

func on_interact(player):
	print("Default interaction with ", name)
""" % prompt
		
		var new_script = GDScript.new()
		new_script.source_code = script_text
		object.set_script(new_script)

# Debug function to visualize interaction radius
func _draw():
	if Engine.is_editor_hint():
		return
	
	# Safety check: ensure node is ready and in scene tree
	if not is_inside_tree():
		return
	
	# Draw interaction radius in debug mode
	if OS.is_debug_build():
		draw_circle(Vector2.ZERO, interaction_radius, Color.CYAN, false, 2.0)
		
		# Draw line to closest interactable
		if closest_interactable and is_instance_valid(closest_interactable):
			var direction = (closest_interactable.global_position - global_position)
			draw_line(Vector2.ZERO, direction, Color.GREEN, 2.0)

# Forward item self-talk to SelfTalkSystem for consistent bottom textbox UI
func trigger_item_self_talk(item_type: String):
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("trigger_after_item_interact_talk"):
		sys.trigger_after_item_interact_talk(item_type)

# Forward custom self-talk to SelfTalkSystem
func trigger_custom_self_talk(message: String):
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("trigger_custom_self_talk"):
		sys.trigger_custom_self_talk(message)
