extends CharacterBody2D

# Movement Configuration
@export var max_speed: float = 180.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

# Interaction Configuration
@export var interaction_radius: float = 60.0
var nearby_interactables: Array[Node] = []
var closest_interactable: Node = null

# Input Actions - Player 1 WASD movement
const MOVE_LEFT = "move_left"       # A key
const MOVE_RIGHT = "move_right"     # D key
const MOVE_UP = "move_up"           # W key
const MOVE_DOWN = "move_down"       # S key
const INTERACT = "interact"         # E key

# UI Elements
var interaction_ui_container: Control
var interaction_label: Label
var interaction_ui: Node  # Reference to enhanced UI system

# Animation
@onready var animation_tree: AnimationTree = $AnimationTree

# Bag/Inventory reference
@onready var bag: Control

# DialogBox scene reference
var _dialog_box_scene: PackedScene = preload("res://Scenes/dialog_box.tscn")


func _ready():
	# Add player to the Player1 group for interaction system
	add_to_group("Player1")
	setup_interaction_ui()
	ensure_mobile_overlay()
	setup_enhanced_ui()
	setup_bag_reference()
	# Connect to physics process for smooth movement
	set_physics_process(true)
	# Show welcome dialog centered on screen after scene loads
	call_deferred("_show_earthquake_welcome")

func ensure_mobile_overlay():
	var scene = get_tree().current_scene
	var root = get_tree().root
	print("Earthquake: ensure_mobile_overlay on scene:", scene)
	if root:
		if not root.get_node_or_null("InteractionUI"):
			print("Earthquake: Adding InteractionUI overlay to root")
			var ui_scene: PackedScene = load("res://InteractionUI.tscn")
			if ui_scene:
				var ui_instance = ui_scene.instantiate()
				ui_instance.name = "InteractionUI"
				root.add_child(ui_instance)
		if not root.get_node_or_null("MobileControls"):
			print("Earthquake: Adding MobileControls overlay to root")
			var mc_scene: PackedScene = load("res://MobileControls.tscn")
			if mc_scene:
				var mc_instance = mc_scene.instantiate()
				mc_instance.name = "MobileControls"
				root.add_child(mc_instance)
	# Update reference for enhanced UI
	interaction_ui = root.get_node_or_null("InteractionUI")
	print("Earthquake: InteractionUI present on root:", interaction_ui != null)

func setup_enhanced_ui():
	# Get reference to the scene-level InteractionUI node
	var scene = get_tree().current_scene
	if scene:
		interaction_ui = scene.get_node_or_null("InteractionUI")
	
	if not interaction_ui:
		print("Warning: InteractionUI node not found in scene")
	else:
		print("InteractionUI found and connected successfully")

func setup_bag_reference():
	# Find the bag as a child of the player
	bag = get_node_or_null("Bag")
	if not bag:
		print("✗ WARNING: Bag node not found as child of player 1")
		print("Available child nodes:")
		for child in get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	else:
		print("✓ Player 1 Bag found and connected successfully")
		print("Bag type: ", bag.get_class())
		print("Bag has get_items method: ", bag.has_method("get_items"))

func setup_interaction_ui():
	# The interaction UI is now handled by the scene-level InteractionUI node
	# This function is kept for compatibility but doesn't create duplicate UI
	pass
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
		animation_tree.set("parameters/Walk/blend_position", input_vector)
	
	# Apply movement with smooth acceleration/deceleration
	if input_vector != Vector2.ZERO:
		# Accelerate towards target velocity
		velocity = velocity.move_toward(input_vector * max_speed, acceleration * delta)
	else:
		# Apply friction when not moving
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func update_nearby_interactables():
	# Find all interactable objects in the scene
	var interactables = get_tree().get_nodes_in_group("interactable")
	nearby_interactables.clear()
	closest_interactable = null
	
	var closest_distance = interaction_radius
	
	print("Player 1: Checking for interactables within radius ", interaction_radius)
	
	# Check each interactable object
	for interactable in interactables:
		print("Player 1: Found ", interactables.size(), " interactable objects in scene")
		
		if not interactable or not is_instance_valid(interactable):
			continue
			
		# Calculate distance to interactable
		var distance = global_position.distance_to(interactable.global_position)
		
		# Check if within interaction radius
		if distance <= interaction_radius:
			print("Player 1: Distance to ", interactable.name, " is ", distance)
			nearby_interactables.append(interactable)
			
			# Update closest interactable
			if distance < closest_distance:
				print("Player 1: ", interactable.name, " is within interaction range!")
				closest_distance = distance
				closest_interactable = interactable
				print("Player 1: ", interactable.name, " is now the closest interactable")
	
	# Update UI based on closest interactable
	update_interaction_ui()

func update_interaction_ui():
	print("Player 1: update_interaction_ui called, closest_interactable: ", closest_interactable.name if closest_interactable and is_instance_valid(closest_interactable) else "null")
	
	if closest_interactable and is_instance_valid(closest_interactable):
		print("Player 1: Found interactable object: ", closest_interactable.name)
		
		# Try to use the enhanced UI system first
		if interaction_ui and interaction_ui.has_method("show_interaction_prompt"):
			print("Player 1: Calling show_interaction_prompt on InteractionUI")
			interaction_ui.show_interaction_prompt(closest_interactable)
		else:
			print("Player 1: ERROR - interaction_ui is null or doesn't have show_interaction_prompt method")
			print("Player 1: interaction_ui exists: ", interaction_ui != null)
			if interaction_ui:
				print("Player 1: interaction_ui methods: ", interaction_ui.get_method_list())
			
			# Fallback to basic label system
			if interaction_label:
				interaction_label.text = "Press E to interact with " + closest_interactable.name
				interaction_label.visible = true
				interaction_label.global_position = closest_interactable.global_position + Vector2(0, -50)
				print("Player 1: Basic interaction label text set to: ", interaction_label.text)
	else:
		print("Player 1: No interactable object found, hiding UI")
		
		# Hide enhanced UI
		if interaction_ui and interaction_ui.has_method("hide_interaction_prompt"):
			interaction_ui.hide_interaction_prompt()
		
		# Hide basic UI
		if interaction_label:
			interaction_label.visible = false

func handle_interactions():
	if Input.is_action_just_pressed(INTERACT):
		perform_interaction(closest_interactable)

func perform_interaction(target):
	if not target or not is_instance_valid(target):
		print("Player 1: perform_interaction called with null target")
		return
	
	print("Player 1: Interacting with: ", target.name)
	
	# Try to call the interaction method on the target
	if target.has_method("on_interact"):
		print("Player 1: Calling on_interact method on ", target.name)
		target.on_interact(self)
	else:
		print("Player 1: ERROR - ", target.name, " does not have on_interact method!")

# Inventory system methods
func get_items(itemData):
	if bag and bag.has_method("get_items"):
		print("Player 1: Passing item to bag inventory system")
		bag.get_items(itemData)
	else:
		print("Player 1: No bag inventory system found, storing item data directly")
		# Fallback: store item data in a simple array or dictionary
		if not has_meta("inventory"):
			set_meta("inventory", [])
		
		var inventory = get_meta("inventory")
		inventory.append(itemData)
		set_meta("inventory", inventory)
		
		print("Player 1 received item data: ", itemData)
		print("Player 1 current inventory: ", inventory)

func has_item(item_name: String) -> bool:
	if bag and bag.has_method("has_item"):
		return bag.has_item(item_name)
	else:
		# Fallback: check meta inventory
		if has_meta("inventory"):
			var inventory = get_meta("inventory")
			for item in inventory:
				if item.has("name") and item.name == item_name:
					return true
		return false

func remove_item(item_name: String) -> bool:
	if bag and bag.has_method("remove_item"):
		return bag.remove_item(item_name)
	else:
		# Fallback: remove from meta inventory
		if has_meta("inventory"):
			var inventory = get_meta("inventory")
			for i in range(inventory.size()):
				if inventory[i].has("name") and inventory[i].name == item_name:
					inventory.remove_at(i)
					set_meta("inventory", inventory)
					return true
		return false

func get_inventory():
	if bag and bag.has_method("get_inventory"):
		return bag.get_inventory()
	else:
		# Fallback: return meta inventory
		if has_meta("inventory"):
			return get_meta("inventory")
		return []

# Method for other objects to interact with this player
func on_interact(player):
	print("Player 1: Someone is trying to interact with me!")
	# Add any specific behavior when other objects interact with this player

# Internal: ensure a DialogBox exists and return it
func _ensure_dialog_box_present() -> Node:
	var dialog_box = get_tree().get_first_node_in_group("dialog_system")
	if dialog_box and is_instance_valid(dialog_box):
		return dialog_box
	# Not present: instance and add to current scene
	if _dialog_box_scene:
		var instance = _dialog_box_scene.instantiate()
		var scene = get_tree().current_scene
		if scene:
			scene.add_child(instance)
			print("DialogBox instantiated and added to scene")
			return instance
	print("Failed to instantiate DialogBox scene")
	return null

# Show earthquake welcome dialog centered on screen
func _show_earthquake_welcome() -> void:
	if Engine.is_editor_hint():
		return
	# Ensure DialogBox exists and show centered welcome
	var dialog_box = _ensure_dialog_box_present()
	if dialog_box and dialog_box.has_method("show_dialog"):
		var welcome_text := "It’s a calm afternoon. The sun is high, and the street feels peaceful as people go about their day. You stop in front of a small grocery store, thinking of picking up a few items before heading home."
		var lines: Array[String] = [welcome_text] as Array[String]
		dialog_box.show_dialog("WELCOME", lines)
	else:
		print("DialogBox not found; cannot show earthquake welcome")
