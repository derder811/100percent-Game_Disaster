extends Area2D

@export var itemName: String = "Go Bag"
@export var itemIcon: Texture2D

var itemData: Dictionary
var player_nearby: Node = null
var pickup_prompt: Label = null

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D

const lines: Array[String] = [
	"Good, my emergency bag's here. I'll start packing the essentials in case we need to leave later.",
	"Prepare a Go Bag with water, food, medicine, flashlight, batteries, and important documents for quick evacuation."
]

func _ready():
	# Use the texture from the Sprite2D if itemIcon is not set
	if itemIcon:
		$Sprite2D.texture = itemIcon
	else:
		itemIcon = $Sprite2D.texture
	
	itemData = {
		"name": itemName,
		"icon": itemIcon
	}
	
	# Create pickup prompt label
	create_pickup_prompt()
	
	# Connect body signals for pickup functionality
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("✓ body_entered signal connected for ", itemName)
	
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		print("✓ body_exited signal connected for ", itemName)
	
	# Interaction functionality removed - only pickup is available
	# interaction_area.interact = Callable(self, "_on_interact")
	# interaction_area.action_name = "examine go bag"
	
	print("Item '", itemName, "' initialized at position: ", global_position)

func create_pickup_prompt():
	pickup_prompt = Label.new()
	pickup_prompt.text = "Pick up this item"
	pickup_prompt.add_theme_font_size_override("font_size", 12)
	pickup_prompt.add_theme_color_override("font_color", Color.WHITE)
	pickup_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	pickup_prompt.add_theme_constant_override("shadow_offset_x", 1)
	pickup_prompt.add_theme_constant_override("shadow_offset_y", 1)
	pickup_prompt.position = Vector2(-40, -30)  # Position above the item
	pickup_prompt.visible = false
	add_child(pickup_prompt)

func _physics_process(_delta):
	# Check for E key press when player is nearby
	if player_nearby and Input.is_action_just_pressed("interact"):
		pickup_item()

func _on_body_entered(body):
	print("=== GO BAG COLLISION DETECTED ===")
	print("Item '", itemName, "' detected collision with: ", body.name)
	print("Body type: ", body.get_class())
	print("Body groups: ", body.get_groups())
	print("Checking if 'Player' in body.name: ", "Player" in body.name)
	print("Checking if body is in group 'Player2': ", body.is_in_group("Player2"))
	
	# Check if it's the player by looking for the Player2 group or Player in name
	if body.is_in_group("Player2") or "Player" in body.name:
		print("✓ Player detected! Showing pickup prompt...")
		player_nearby = body
		if pickup_prompt:
			pickup_prompt.visible = true
	else:
		print("✗ Not a player, ignoring collision")

func _on_body_exited(body):
	if body == player_nearby:
		player_nearby = null
		if pickup_prompt:
			pickup_prompt.visible = false

func pickup_item():
	if player_nearby:
		# Don't add to inventory - just pickup the item
		print("✓ Go Bag picked up (not added to inventory)!")
		
		# Set the global flag that the go bag has been picked up
		GameState.set_go_bag_picked_up()
		
		# Show self-talk about the go bag first
		show_item_self_talk()
		
		# Hide the pickup prompt after interaction
		if pickup_prompt:
			pickup_prompt.visible = false

func show_item_self_talk():
	# Trigger self-talk first using the self-talk system
	var self_talk_nodes = get_tree().get_nodes_in_group("self_talk_system")
	if self_talk_nodes.size() > 0:
		var self_talk_system = self_talk_nodes[0]
		if self_talk_system.has_method("trigger_item_pickup_self_talk"):
			self_talk_system.trigger_item_pickup_self_talk("go_bag")
	
	# Show SimpleDialogManager safety tips after 3 seconds
	await get_tree().create_timer(3.0).timeout
	SimpleDialogManager.show_item_dialog("go_bag", global_position)
	
	# Wait for dialog to complete before destroying the item
	await get_tree().create_timer(4.0).timeout
	queue_free()

# Examine functionality removed - _on_interact method no longer used
# func _on_interact():
# 	# Safety check for overlapping bodies
# 	var overlapping_bodies = interaction_area.get_overlapping_bodies()
# 	if overlapping_bodies.size() > 0:
# 		sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
# 		# Use the new DialogManager autoload with asset type for safety tips
# 		var dialog_position = global_position + Vector2(0, -50)  # Position dialog above go bag
# 		DialogManager.start_dialog(dialog_position, lines, "go_bag")		
# 		# Complete the quest objective for go bag interaction
# 		var quest_node = get_node("../Quest")
# 		if quest_node and quest_node.has_method("on_go_bag_interaction"):
# 			quest_node.on_go_bag_interaction()
# 			print("Go Bag: Quest objective completed!")
