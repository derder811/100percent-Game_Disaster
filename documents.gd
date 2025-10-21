extends Area2D

@export var itemName: String = "Documents"
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
	
	# Connect body signals - ensure they're not already connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
		print("✓ body_entered signal connected for ", itemName)
	
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
		print("✓ body_exited signal connected for ", itemName)
	
	print("Item '", itemName, "' initialized at position: ", global_position)
	print("Collision mask: ", collision_mask)
	print("Collision layer: ", collision_layer)

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
		print("✓ E key pressed for Documents! Attempting pickup...")
		pickup_item()
	elif player_nearby:
		# Debug: Show that player is nearby but E key not pressed
		if Input.is_action_pressed("interact"):
			print("E key is being held down for Documents...")
		# Check if interact action exists
		if not InputMap.has_action("interact"):
			print("✗ ERROR: 'interact' action not found in InputMap!")
		else:
			print("✓ 'interact' action exists in InputMap")

func _on_body_entered(body):
	print("=== DOCUMENTS COLLISION DETECTED ===")
	print("Item '", itemName, "' detected collision with: ", body.name)
	print("Body type: ", body.get_class())
	print("Body groups: ", body.get_groups())
	print("Body position: ", body.global_position)
	print("Item position: ", global_position)
	print("Body parent: ", body.get_parent().name if body.get_parent() else "No parent")
	print("Checking if 'Player' in body.name: ", "Player" in body.name)
	print("Checking if body is in group 'Player2': ", body.is_in_group("Player2"))
	
	# Check for both direct player detection and nested player structure
	var is_player = false
	if "Player" in body.name or body.is_in_group("Player2"):
		is_player = true
	elif body.get_class() == "CharacterBody2D" and body.has_method("get") and "collision_layer" in body and body.collision_layer == 2:
		is_player = true
		print("✓ Detected player by collision layer 2")
	
	if is_player:
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
		
		# Show self-talk about the documents' purpose
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
		self_talk_system.trigger_item_pickup_self_talk("documents")
	
	# Show SimpleDialogManager safety tips after 3 seconds
	await get_tree().create_timer(3.0).timeout
	SimpleDialogManager.show_item_dialog("documents", global_position)