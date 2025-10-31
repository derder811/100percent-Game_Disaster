extends Node

# Singleton to manage all interactions and button visibility
signal interaction_changed(object_type: ObjectType)
signal interaction_cleared()

enum ObjectType {
	NONE,
	PICKUPABLE,
	INTERACTABLE
}

var current_object: Node = null
var current_object_type: ObjectType = ObjectType.NONE
var player: Node = null

# References to UI elements
var mobile_controls: Node = null
var interaction_ui: Node = null

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("Player2")
	if not player:
		# Try to find player later
		call_deferred("_find_player")
	
	# Connect to scene changes to re-find UI elements
	get_tree().node_added.connect(_on_node_added)

func _find_player():
	player = get_tree().get_first_node_in_group("Player2")
	if not player:
		# Try again in a bit
		await get_tree().create_timer(0.1).timeout
		_find_player()

func _on_node_added(node: Node):
	# Check if this is a UI element we need
	if node.name == "MobileControls":
		mobile_controls = node
	elif node.name == "InteractionUI":
		interaction_ui = node

func register_object(object: Node, object_type: ObjectType):
	"""Register an object as the current interactable/pickupable"""
	if current_object != object:
		current_object = object
		current_object_type = object_type
		
		var type_string = ""
		match object_type:
			ObjectType.PICKUPABLE:
				type_string = "pickup"
			ObjectType.INTERACTABLE:
				type_string = "interact"
		
		if object_type != ObjectType.NONE:
			interaction_changed.emit(object_type)
			_update_ui_visibility(type_string)

func unregister_object(object: Node):
	"""Unregister an object if it's the current one"""
	if current_object == object:
		current_object = null
		current_object_type = ObjectType.NONE
		interaction_cleared.emit()
		_update_ui_visibility("")

func _update_ui_visibility(object_type: String):
	"""Update the visibility of interaction and pickup buttons"""
	# Find mobile controls if not already found
	if not mobile_controls:
		mobile_controls = get_tree().root.get_node_or_null("MobileControls")
	
	if mobile_controls:
		var interact_button = mobile_controls.get_node_or_null("UIRoot/InteractButton")
		var pickup_button = mobile_controls.get_node_or_null("UIRoot/PickupButton")
		
		if interact_button and pickup_button:
			match object_type:
				"pickup":
					interact_button.visible = false
					pickup_button.visible = true
					pickup_button.text = "Pick Up"
				"interact":
					interact_button.visible = true
					pickup_button.visible = false
					interact_button.text = "Interact"
				_:
					interact_button.visible = false
					pickup_button.visible = false

func get_current_object() -> Node:
	return current_object

func get_current_object_type() -> ObjectType:
	return current_object_type

func is_object_pickupable(object: Node) -> bool:
	"""Check if an object is pickupable based on its script or properties"""
	if not object:
		return false
	
	# Check if it extends Area2D and has pickup-related methods
	if object is Area2D:
		return object.has_method("pickup_item") or object.has_method("get_items")
	
	return false

func is_object_interactable(object: Node) -> bool:
	"""Check if an object is interactable based on its script or properties"""
	if not object:
		return false
	
	# Check if it has interaction methods or is registered with interaction manager
	return object.has_method("interact") or object.has_method("get_interaction_prompt")

func determine_object_type(object: Node) -> ObjectType:
	"""Determine what type of object this is"""
	if is_object_pickupable(object):
		return ObjectType.PICKUPABLE
	elif is_object_interactable(object):
		return ObjectType.INTERACTABLE
	else:
		return ObjectType.NONE

func are_mobile_controls_active() -> bool:
	"""Check if mobile controls are currently active and visible"""
	if not mobile_controls:
		mobile_controls = get_tree().root.get_node_or_null("MobileControls")
	
	if mobile_controls:
		# Check if mobile controls are visible and have any buttons showing
		var interact_button = mobile_controls.get_node_or_null("UIRoot/InteractButton")
		var pickup_button = mobile_controls.get_node_or_null("UIRoot/PickupButton")
		
		if interact_button and pickup_button:
			return interact_button.visible or pickup_button.visible
	
	return false