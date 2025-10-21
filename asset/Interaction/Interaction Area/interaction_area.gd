class_name InteractionArea
extends Area2D

@export var action_name: String = "interact"

var interact: Callable = func():
	pass

func _ready():
	print("InteractionArea ready: ", action_name)
	print("Collision layer: ", collision_layer)
	print("Collision mask: ", collision_mask)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	print("Signals connected for InteractionArea: ", action_name)

func _on_body_entered(body):
	print("DEBUG: Body entered InteractionArea: ", body.name, " Groups: ", body.get_groups())
	
	# Check if body has collision_layer property (CharacterBody2D, RigidBody2D, etc.)
	var collision_info = "No collision_layer"
	if body.has_method("get") and "collision_layer" in body:
		collision_info = str(body.collision_layer)
	elif body is CharacterBody2D or body is RigidBody2D or body is StaticBody2D:
		collision_info = str(body.collision_layer)
	
	print("InteractionArea: Body collision_layer: ", collision_info)
	print("InteractionArea: My collision_mask: ", collision_mask)
	print("InteractionArea: Checking if body is in Player2 group: ", body.is_in_group("Player2"))
	
	if body.is_in_group("Player2"):
		print("DEBUG: Player2 detected! Registering area with action: ", action_name)
		InteractionManager.register_area(self)
	else:
		print("DEBUG: Body is not in Player2 group")

func _on_body_exited(body):
	print("DEBUG: Body exited InteractionArea: ", body.name)
	if body.is_in_group("Player2"):
		print("DEBUG: Player2 exited! Unregistering area")
		InteractionManager.unregister_area(self)
	else:
		print("DEBUG: Non-Player2 body exited")

func _exit_tree():
	print("InteractionArea: exiting tree, unregistering if needed")
	InteractionManager.unregister_area(self)
