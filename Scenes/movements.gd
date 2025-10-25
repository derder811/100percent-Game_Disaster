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
	# Try to find Bag as a direct child first
	bag = get_node_or_null("Bag")
	
	# If not found, try to locate Bag anywhere in the current scene
	if not bag:
		var scene = get_tree().current_scene
		if scene:
			bag = scene.find_child("Bag", true, false)
			if bag:
				print("✓ Bag found in scene and connected successfully: ", bag.name)
			else:
				print("✗ WARNING: Bag node not found in player or scene. Will instance one.")
		else:
			print("✗ WARNING: No current scene while searching for Bag")
	
	# If still not found, instance Bag.tscn and place it on a top CanvasLayer
	if not bag:
		var bag_scene: PackedScene = load("res://Bag.tscn")
		if bag_scene:
			bag = bag_scene.instantiate()
			var scene2 = get_tree().current_scene
			if scene2:
				var bag_layer: CanvasLayer = scene2.get_node_or_null("UILayer_Bag")
				if not bag_layer:
					bag_layer = CanvasLayer.new()
					bag_layer.name = "UILayer_Bag"
					bag_layer.layer = 200
					scene2.add_child(bag_layer)
				bag_layer.add_child(bag)
				print("✓ Instanced Bag.tscn under UILayer_Bag for UI on top")
			else:
				print("✗ ERROR: Failed to get current scene for bag instancing")
		else:
			print("✗ ERROR: Failed to load Bag.tscn")
	
	if bag:
		# Ensure bag is under our top UI layer and captures clicks
		var scene3 = get_tree().current_scene
		if scene3:
			var bag_layer2: CanvasLayer = scene3.get_node_or_null("UILayer_Bag")
			if not bag_layer2:
				bag_layer2 = CanvasLayer.new()
				bag_layer2.name = "UILayer_Bag"
				bag_layer2.layer = 200
				scene3.add_child(bag_layer2)
			if bag.get_parent() != bag_layer2:
				bag_layer2.add_child(bag)
		bag.mouse_filter = Control.MOUSE_FILTER_STOP
		if bag.has_node("TextureButton"):
			var btn: TextureButton = bag.get_node("TextureButton")
			btn.disabled = false
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
		print("✓ Bag connected. Type: ", bag.get_class())
		print("Bag has get_items method: ", bag.has_method("get_items"))
		# If a Bag UI exists, mark the go bag as available so items can be picked up
		if Engine.has_singleton("GameState"):
			GameState.set_go_bag_picked_up()
		else:
			# Direct access if autoload is used
			if typeof(GameState) != TYPE_NIL and GameState.has_method("set_go_bag_picked_up"):
				GameState.set_go_bag_picked_up()
			else:
				print("✗ WARNING: GameState singleton not available to mark go bag picked up")
	else:
		print("✗ Bag setup failed — inventory will not function")

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
	
	# Apply movement with smooth acceleration/deceleration
	if input_vector != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Apply friction when no input
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Update animation based on actual movement (velocity), not just input
	update_animation(input_vector)

func update_animation(input_vector: Vector2):
	# Check if character is actually moving (velocity threshold to avoid micro-movements)
	var is_moving = velocity.length() > 10.0  # Minimum speed threshold
	
	if is_moving and input_vector != Vector2.ZERO:
		# Character is moving - play walking animation
		if animation_tree:
			animation_tree.active = true
			# Use input direction for animation direction (for responsive feel)
			animation_tree.set("parameters/walk/blend_position", input_vector)
			print("Playing walk animation with direction: ", input_vector)
	else:
		# Character is not moving - play idle animation
		if animation_tree:
			animation_tree.active = false
			# Use AnimationPlayer directly for idle
			var anim_player = get_node_or_null("AnimationPlayer")
			if anim_player:
				anim_player.play("idle")
				print("Playing idle animation")

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
			# E.g., prompt like "Press E to inspect TV"
			var prompt_text = closest_interactable.get_interaction_prompt()
			print("Player: interaction prompt text: ", prompt_text)
		else:
			print("Player: interactable has no get_interaction_prompt method")
	else:
		# Hide UI when there's no interactable nearby
		interaction_label.visible = false

func perform_interaction(target):
	print("Player: perform_interaction called on: ", target.name)
	
	# Generic interaction handling
	if target.has_method("interact"):
		print("Player: target has interact method, calling it")
		target.interact()
		return
	
	# Specific interactions
	if target.name.contains("Door"):
		interact_with_door(target)
	elif target.name.contains("Cabinet"):
		interact_with_container(target)
	elif target.is_in_group("item"):
		pickup_item(target)
	else:
		print("Player: No specific interaction handler for: ", target.name)

func pickup_item(item):
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
# Simply add the node to the "interactable" group and implement get_interaction_prompt()
# func make_interactable(node: Node, prompt: String):
# 	if node:
# 		node.add_to_group("interactable")
# 		if not node.has_method("get_interaction_prompt"):
# 			node.get_interaction_prompt = func():
# 				return prompt
