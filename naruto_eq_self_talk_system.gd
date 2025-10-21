extends Node2D
class_name NarutoEQSelfTalkSystem

# Self-talk messages for Naruto EQ player
var self_talk_messages = {
	"convenience_store": [
		"Oh hey, a convenience store. Might as well take a look.",
		"Could use a quick break… maybe grab a drink or something."
	] as Array[String],
	"timer_based": [
		"Oh hey, a convenience store. Might as well take a look.",
		"Could use a quick break… maybe grab a drink or something."
	] as Array[String]
}

var has_shown_startup_message = false
var timer_self_talk_active = false
var current_message_index = 0
@onready var player = get_parent()
# Bottom textbox UI (match screenshot)
var _textbox_layer: CanvasLayer = null
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_active: bool = false
var _textbox_ttl_timer: Timer = null

func _ready():
	print("NarutoEQSelfTalkSystem: _ready() called")
	# Get reference to the player (parent node)
	player = get_parent()
	print("NarutoEQSelfTalkSystem: Player reference set to: ", player)
	
	# Check if DialogManager is available
	if DialogManager:
		print("NarutoEQSelfTalkSystem: DialogManager found successfully")
	else:
		print("NarutoEQSelfTalkSystem: ERROR - DialogManager not found!")
	
	# Show first message after 5 seconds
	await get_tree().create_timer(5.0).timeout
	print("NarutoEQSelfTalkSystem: Showing first message...")
	show_specific_message(0)  # Show first message
	
	# Show second message after 10 more seconds
	await get_tree().create_timer(10.0).timeout
	print("NarutoEQSelfTalkSystem: Showing second message...")
	show_specific_message(1)  # Show second message
	
	# Start regular timer-based self talk after that
	await get_tree().create_timer(2.0).timeout
	print("NarutoEQSelfTalkSystem: Starting timer self talk")
	start_timer_self_talk()

func start_timer_self_talk():
	print("NarutoEQSelfTalkSystem: start_timer_self_talk() called")
	timer_self_talk_active = true
	_timer_self_talk_loop()

func stop_timer_self_talk():
	print("NarutoEQSelfTalkSystem: stop_timer_self_talk() called")
	timer_self_talk_active = false

func _timer_self_talk_loop():
	print("NarutoEQSelfTalkSystem: _timer_self_talk_loop() started")
	while timer_self_talk_active:
		await get_tree().create_timer(10.0).timeout  # Reduced to 10 seconds for testing
		print("NarutoEQSelfTalkSystem: Timer expired, checking conditions...")
		
		if timer_self_talk_active and player and is_instance_valid(player):
			print("NarutoEQSelfTalkSystem: Player valid, checking DialogManager...")
			# Check if there's no active dialog before showing timer-based self talk
			if DialogManager and not DialogManager.is_dialog_active:
				print("NarutoEQSelfTalkSystem: Showing timer self talk")
				show_timer_self_talk()
			else:
				print("NarutoEQSelfTalkSystem: DialogManager busy or not available")

# Function to show a specific message by index
func show_specific_message(message_index: int):
	print("NarutoEQSelfTalkSystem: show_specific_message() called with index: ", message_index)
	
	if not player or not is_instance_valid(player):
		print("NarutoEQSelfTalkSystem: ERROR - Player not found or invalid")
		return
	
	var messages = self_talk_messages["timer_based"]
	if message_index >= messages.size():
		print("NarutoEQSelfTalkSystem: ERROR - Message index out of bounds")
		return
	
	var message = messages[message_index]
	print("NarutoEQSelfTalkSystem: Selected message: ", message)
	
	if player and is_instance_valid(player):
		print("NarutoEQSelfTalkSystem: Player found, calculating position...")
		# Get the player's sprite for accurate text positioning
		var sprite = player.get_node_or_null("Sprite2D")
		var dialog_position = player.global_position
		
		if sprite:
			print("NarutoEQSelfTalkSystem: Sprite found, calculating position above sprite")
			# Calculate the top of the sprite by using the sprite's global position
			# and accounting for its texture height
			var sprite_global_pos = player.to_global(sprite.position)
			var texture_height = 0
			if sprite.texture:
				texture_height = sprite.texture.get_height() * sprite.scale.y
			
			# Position text above the sprite's top edge
			dialog_position = Vector2(sprite_global_pos.x, sprite_global_pos.y - texture_height/2 - 50)
		else:
			print("NarutoEQSelfTalkSystem: No sprite found, using fallback position")
			# Fallback: position above player center
			dialog_position = player.global_position + Vector2(0, -100)
		
		print("NarutoEQSelfTalkSystem: Final dialog position: ", dialog_position)
		# Mirror to bottom textbox UI
		_show_textbox(message)

func show_timer_self_talk():
	print("NarutoEQSelfTalkSystem: show_timer_self_talk() called")
	# Get a random timer-based self-talk message
	var messages = self_talk_messages["timer_based"]
	var random_message = messages[randi() % messages.size()]
	print("NarutoEQSelfTalkSystem: Selected message: ", random_message)
	
	if player and is_instance_valid(player):
		print("NarutoEQSelfTalkSystem: Player found, calculating position...")
		# Get the player's sprite for accurate text positioning
		var sprite = player.get_node_or_null("Sprite2D")
		var dialog_position = player.global_position
		
		if sprite:
			print("NarutoEQSelfTalkSystem: Sprite found, calculating position above sprite")
			# Calculate the top of the sprite by using the sprite's global position
			# and accounting for its texture height
			var sprite_global_pos = player.to_global(sprite.position)
			var texture_height = 0
			if sprite.texture:
				texture_height = sprite.texture.get_height() * sprite.scale.y
			
			# Position text above the sprite's top edge
			dialog_position = Vector2(sprite_global_pos.x, sprite_global_pos.y - texture_height/2 - 50)
		else:
			print("NarutoEQSelfTalkSystem: No sprite found, using fallback position")
			# Fallback: position above player center
			dialog_position = player.global_position + Vector2(0, -100)
		
		print("NarutoEQSelfTalkSystem: Final dialog position: ", dialog_position)
		# Mirror to bottom textbox UI
		_show_textbox(random_message)

# Function to trigger custom self-talk with a specific message
func trigger_custom_self_talk(custom_message: String):
	if player and is_instance_valid(player):
		# Get the player's sprite for accurate text positioning
		var sprite = player.get_node_or_null("Sprite2D")
		var dialog_position = player.global_position
		
		if sprite:
			# Calculate the top of the sprite by using the sprite's global position
			# and accounting for its texture height
			var sprite_global_pos = player.to_global(sprite.position)
			var texture_height = 0
			if sprite.texture:
				texture_height = sprite.texture.get_height() * sprite.scale.y
			
			# Position text above the sprite's top edge
			dialog_position = Vector2(sprite_global_pos.x, sprite_global_pos.y - texture_height/2 - 50)
		else:
			# Fallback: position above player center
			dialog_position = player.global_position + Vector2(0, -100)
		
		_show_textbox(custom_message)

# Function to trigger convenience store self-talk
func trigger_convenience_store_self_talk():
	var messages = self_talk_messages["convenience_store"]
	var random_message = messages[randi() % messages.size()]
	trigger_custom_self_talk(random_message)

# Function to trigger self-talk from external sources
func trigger_self_talk(message_type: String = "timer_based"):
	if message_type in self_talk_messages:
		var messages = self_talk_messages[message_type]
		var random_message = messages[randi() % messages.size()]
		
		if player and is_instance_valid(player):
			# Get the player's sprite for accurate text positioning
			var sprite = player.get_node_or_null("Sprite2D")
			var dialog_position = player.global_position
			
			if sprite:
				# Calculate the top of the sprite by using the sprite's global position
				# and accounting for its texture height
				var sprite_global_pos = player.to_global(sprite.position)
				var texture_height = 0
				if sprite.texture:
					texture_height = sprite.texture.get_height() * sprite.scale.y
				
				# Position text above the sprite's top edge
				dialog_position = Vector2(sprite_global_pos.x, sprite_global_pos.y - texture_height/2 - 50)
			else:
				# Fallback: position above player center
				dialog_position = player.global_position + Vector2(0, -100)
			
			_show_textbox(random_message)

# -----------------------------
# Bottom textbox implementation
# -----------------------------
func _ensure_textbox_nodes():
	if _textbox_layer == null:
		_textbox_layer = CanvasLayer.new()
		_textbox_layer.layer = 150
		add_child(_textbox_layer)
	if _textbox_panel == null:
		_textbox_panel = Panel.new()
		# Anchor to bottom, full width with margins
		_textbox_panel.anchor_left = 0.0
		_textbox_panel.anchor_right = 1.0
		_textbox_panel.anchor_top = 1.0
		_textbox_panel.anchor_bottom = 1.0
		_textbox_panel.offset_left = 24
		_textbox_panel.offset_right = -24
		_textbox_panel.offset_top = -140
		_textbox_panel.offset_bottom = -24
		_textbox_panel.custom_minimum_size = Vector2(0, 110)
		# Style: dark rounded background
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.75)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		_textbox_panel.add_theme_stylebox_override("panel", sb)
		_textbox_panel.visible = false
		_textbox_layer.add_child(_textbox_panel)
	if _textbox_label == null:
		_textbox_label = Label.new()
		_textbox_label.anchor_left = 0.0
		_textbox_label.anchor_right = 1.0
		_textbox_label.anchor_top = 0.0
		_textbox_label.anchor_bottom = 1.0
		_textbox_label.offset_left = 16
		_textbox_label.offset_right = -16
		_textbox_label.offset_top = 10
		_textbox_label.offset_bottom = -10
		_textbox_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_textbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_textbox_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))
		_textbox_panel.add_child(_textbox_label)
	if _textbox_ttl_timer == null:
		_textbox_ttl_timer = Timer.new()
		_textbox_ttl_timer.one_shot = true
		_textbox_ttl_timer.timeout.connect(_hide_textbox)
		add_child(_textbox_ttl_timer)

func _update_textbox_style(is_urgent: bool):
	if _textbox_panel == null:
		return
	var sb := StyleBoxFlat.new()
	if is_urgent:
		sb.bg_color = Color(0.10, 0.00, 0.00, 0.85)
	else:
		sb.bg_color = Color(0, 0, 0, 0.75)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	_textbox_panel.add_theme_stylebox_override("panel", sb)
	if _textbox_label != null:
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))

func _show_textbox(message: String, seconds: float = 4.0, urgent: bool = false):
	_ensure_textbox_nodes()
	_update_textbox_style(urgent)
	_textbox_label.text = message
	_textbox_panel.visible = true
	_textbox_active = true
	if _textbox_ttl_timer != null:
		if seconds > 0.0:
			_textbox_ttl_timer.start(seconds)
		else:
			_textbox_ttl_timer.stop()

func _hide_textbox():
	_textbox_active = false
	if _textbox_panel != null:
		_textbox_panel.visible = false