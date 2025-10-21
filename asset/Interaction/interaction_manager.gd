extends Node2D

# Get player from group "Player"
@onready var player = get_tree().get_first_node_in_group("Player2")

# Store label reference
@onready var label = $Label

# Constants
const BASE_TEXT = "Press (E) to  "

# Variables
var active_areas: Array = []
var can_interact = true

func _ready():
	print("=== InteractionManager _ready() ===")
	print("InteractionManager ready. Player found: ", player != null)
	if player and is_instance_valid(player):
		print("Player position: ", player.global_position)
		print("Player groups: ", player.get_groups())
		
		# Safe collision_layer access
		if player.has_method("get") and "collision_layer" in player:
			print("Player collision_layer: ", player.collision_layer)
			print("Player collision_mask: ", player.collision_mask)
		else:
			print("Player collision_layer: Not available (not a physics body)")
	else:
		print("ERROR: Player not found in Player2 group!")
	print("Label reference: ", label != null)
	if label and is_instance_valid(label):
		print("Label initial position: ", label.global_position)
		print("Label initial visibility: ", label.visible)
	print("=== End InteractionManager _ready() ===")

# Functions
func register_area(area: InteractionArea):
	print("DEBUG: InteractionManager registering area: ", area.action_name)
	if area not in active_areas:
		active_areas.append(area)
		print("DEBUG: Area registered successfully. Total areas: ", active_areas.size())
	else:
		print("DEBUG: Area already registered")

func unregister_area(area: InteractionArea):
	print("DEBUG: InteractionManager unregistering area: ", area.action_name)
	if area in active_areas:
		active_areas.erase(area)
		print("DEBUG: Area unregistered successfully. Total areas: ", active_areas.size())
	else:
		print("DEBUG: Area was not in active_areas list")

func sort_by_distance_to_player(a, b):
	if not player or not is_instance_valid(player) or not a or not is_instance_valid(a) or not b or not is_instance_valid(b):
		return false
	var distance_a = player.global_position.distance_to(a.global_position)
	var distance_b = player.global_position.distance_to(b.global_position)
	return distance_a < distance_b

func _process(delta):
	if not player:
		# Late-bind the player if group assignment happens after our _ready
		player = get_tree().get_first_node_in_group("Player2")
		if not player:
			return
		else:
			print("InteractionManager: late-bound Player2 found: ", player.name)
	
	# Prune invalid or freed areas to avoid accessing invalid nodes
	for i in range(active_areas.size() - 1, -1, -1):
		var area = active_areas[i]
		if area == null or not is_instance_valid(area):
			active_areas.remove_at(i)
	
	if active_areas.size() > 0:
		# Sort areas by distance to player
		active_areas.sort_custom(sort_by_distance_to_player)
		var closest_area = active_areas[0]
		if closest_area == null or not is_instance_valid(closest_area):
			if label:
				label.visible = false
			return
		
		# Show interaction prompt for closest area
		if label:
			label.text = "Press (E) to " + closest_area.action_name
			label.visible = true
			
			# Position label near the interactable object
			var target_position = closest_area.global_position
			# Offset the label to appear below and slightly to the right of the object
			label.global_position = target_position + Vector2(20, 60)
		
		# Handle interaction input
		if Input.is_action_just_pressed("interact"):
			print("DEBUG: E key pressed! Calling interact on: ", closest_area.action_name)
			if closest_area.interact:
				closest_area.interact.call()
	else:
		# Hide interaction prompt when no areas are active
		if label:
			label.visible = false

func _input(event):
	# Check if E key is pressed
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		# Prune invalid entries before use
		for i in range(active_areas.size() - 1, -1, -1):
			var area = active_areas[i]
			if area == null or not is_instance_valid(area):
				active_areas.remove_at(i)
		
		if active_areas.size() > 0:
			var area = active_areas[0]
			if area != null and is_instance_valid(area):
				print("InteractionManager: E key pressed, calling interact on: ", area.action_name)
				can_interact = false
				if label:
					label.visible = false
				await area.interact.call()
				can_interact = true

# Function to show fallback self-talk when system is not found
func _show_fallback_self_talk():
	print("Self-talk system not found, showing fallback message")
	# Could implement a simple fallback dialog here if needed
