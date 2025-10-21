extends Area2D

@export var itemName: String = "Flashlight"
@export var itemIcon: Texture2D

var itemData: Dictionary
var player_nearby: Node = null
var pickup_prompt: Label = null

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
	
	# Connect body exit signal
	body_exited.connect(_on_body_exited)
	
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
	print("=== COLLISION DETECTED ===")
	print("Item '", itemName, "' detected collision with: ", body.name)
	print("Body type: ", body.get_class())
	print("Body groups: ", body.get_groups())
	print("Checking if 'Player' in body.name: ", "Player" in body.name)
	print("Checking if body is in group 'Player2': ", body.is_in_group("Player2"))
	
	if "Player" in body.name or body.is_in_group("Player2"):
		print("✓ Player detected! Showing pickup prompt...")
		player_nearby = body
		show_pickup_prompt()
	else:
		print("✗ Not a player, ignoring collision")

func _on_body_exited(body):
	if body == player_nearby:
		print("Player left item area, hiding prompt")
		player_nearby = null
		hide_pickup_prompt()

func show_pickup_prompt():
	if pickup_prompt:
		pickup_prompt.visible = true

func hide_pickup_prompt():
	if pickup_prompt:
		pickup_prompt.visible = false

func pickup_item():
	# Check if go bag has been picked up first
	if not GameState.is_go_bag_available():
		# Show message that bag is required
		SimpleDialogManager.show_item_dialog("Get the bag first to pick it up or open the inventory.", global_position)
		return
	
	if player_nearby and player_nearby.has_method("get_items"):
		print("✓ Item '", itemName, "' picked up successfully!")
		player_nearby.get_items(itemData)
		
		# Show self-talk about the flashlight's purpose
		show_item_self_talk()
		
		# Wait for self-talk to complete before destroying the item
		await get_tree().create_timer(4.0).timeout
		queue_free()
	else:
		print("✗ ERROR: Player doesn't have get_items method!")

func show_item_self_talk():
	# Trigger self-talk first using the self-talk system
	var self_talk_system = get_tree().get_first_node_in_group("self_talk_system")
	if self_talk_system and self_talk_system.has_method("trigger_item_pickup_self_talk"):
		self_talk_system.trigger_item_pickup_self_talk("flashlight")
	
	# Show SimpleDialogManager safety tips after 3 seconds
	await get_tree().create_timer(3.0).timeout
	SimpleDialogManager.show_item_dialog("flashlight", global_position)
