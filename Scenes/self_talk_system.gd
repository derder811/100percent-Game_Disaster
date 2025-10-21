extends Node2D
class_name SelfTalkSystem

# Self-talk messages for different scenarios
var self_talk_messages = {
	"game_start": [
		"It's early in the morning. Heavy rain pours outside as strong winds shake the trees. A typhoon is approaching, and you're the only one left at home. Your goal is to stay safe and prepare for the storm by gathering important items and taking the right precautions. Learn what to do before and during a typhoon through each interaction inside the house."
 
	] as Array[String],
	"timer_based": [
		"It's raining hard... gonna check the window.",
		"It's really pouring out there... I hope the roof holds up.",
		"I know I kept some supplies somewhere...",
		"Feels a bit eerie being alone during a storm like this.",
		"I can hear the rain hitting the walls... I need to stay focused and finished preparing."
	] as Array[String],
	"item_pickup": {
		"flashlight": "Good thing the flashlight still works. This will help if the power's out for long.",
		"battery": "Extra batteries—perfect. I'll save these for the flashlight.",
		"documents": "These documents are important... Gonna keep them on my bag",
		"canned_food": "Good thing there are still some canned foods left.",
		"water_bottle": "I'll keep these bottled waters ready... the tap might get contaminated later.",
		"medkit": "Good.. Everything's here — bandages, alcohol, medicine.",
		"medicine_2": "Good thing I still have some antibiotics left... just in case anyone gets an infection after the storm.",
		"medicine_3": "Painkillers and cold meds, these might come in handy if anyone feels sick.",
		"mobile_phone": "Signal's weak... I'll keep my phone on me, just in case of any emergency or updates.",
		"powerbank": "This power bank will be useful to keep my phone charged during emergencies.",
		"go_bag": "Gonna find some food, water, and medicine… anything essential before things get worse.",
		"candle": "I'll use this if the power goes out... but maybe a flashlight is safer. I don't want to cause a fire."
	}
}

# Store-style after-interact messages (for scenes where items are browsed)
var after_item_interact_msgs := {
	"snacks": "Ooh, snacks! Always hard to choose... do I go salty or sweet?",
	"fridge": "Hmm... beverages.",
	"slurpee": "DROP COVER AND HOLD",
	"ice_cream_fridge": "Ice cream won't last long without power, but maybe there are other frozen goods.",
	"meat_fridge": "Frozen meat could be useful if I can cook it before the power goes out completely.",
	"hotdog_siopao": "Hotdog or siopao? Man, tough choice. Maybe HotPao?.",
	"food_section": "Let's see what they've got here... canned stuff, quick bites. Pretty standard."
}

var has_shown_startup_message = false
var timer_self_talk_active = false
@onready var player = get_parent()

# Bottom textbox UI (matches Player 3 style)
var _textbox_layer: CanvasLayer = null
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_active: bool = false
var _textbox_ttl_timer: Timer = null

func _ready():
	# Add this node to a group so it can be found by the interaction manager
	add_to_group("self_talk_system")
	
	# Wait a moment for the scene to fully load, then show startup message
	await get_tree().create_timer(1.0).timeout
	show_startup_message()
	
	# Start the timer-based self talk after startup
	await get_tree().create_timer(2.0).timeout
	start_timer_self_talk()

func start_timer_self_talk():
	timer_self_talk_active = true
	_timer_self_talk_loop()

func stop_timer_self_talk():
	timer_self_talk_active = false

func _timer_self_talk_loop():
	while timer_self_talk_active:
		await get_tree().create_timer(30.0).timeout  # Wait 30 seconds
		# Avoid overlapping with other dialogs if a manager is active
		if timer_self_talk_active and player and is_instance_valid(player):
			if not DialogManager.is_dialog_active:
				show_timer_self_talk()

func show_timer_self_talk():
	# Get a random timer-based self-talk message
	var messages = self_talk_messages["timer_based"]
	var random_message = messages[randi() % messages.size()]
	_show_textbox(random_message)

func show_startup_message():
	if has_shown_startup_message:
		return
	
	has_shown_startup_message = true
	
	# Find the DialogBox in the scene
	var dialog_box = get_tree().get_first_node_in_group("dialog_system")
	if dialog_box and dialog_box.has_method("show_dialog"):
		dialog_box.show_dialog("WELCOME", self_talk_messages["game_start"])
		# Connect to the dialog finished signal to show follow-up self-talk
		if not dialog_box.dialog_finished.is_connected(_on_startup_dialog_finished):
			dialog_box.dialog_finished.connect(_on_startup_dialog_finished)
	else:
		print("DialogBox not found for startup message")

func _on_startup_dialog_finished():
	# Show a brief self-talk message after the startup dialog
	await get_tree().create_timer(2.0).timeout
	show_self_talk_message()

func show_self_talk_message():
	# Always show the first message "It's raining hard... gonna check the window." as the first automatic talk
	var first_message = "It's raining hard... gonna check the window."
	_show_textbox(first_message)

# Function to trigger custom self-talk with a specific message
func trigger_custom_self_talk(custom_message: String):
	_show_textbox(custom_message)

# Function to trigger self-talk from external sources
func trigger_self_talk(message_type: String = "timer_based"):
	if message_type in self_talk_messages:
		var messages = self_talk_messages[message_type]
		var random_message = messages[randi() % messages.size()]
		_show_textbox(random_message)

# Function to trigger item pickup self-talk
func trigger_item_pickup_self_talk(item_name: String):
	if "item_pickup" in self_talk_messages and item_name in self_talk_messages["item_pickup"]:
		var message = self_talk_messages["item_pickup"][item_name]
		_show_textbox(message)

# NEW: Function to trigger self-talk right after interacting with store items
func trigger_after_item_interact_talk(item_type: String):
	if after_item_interact_msgs.has(item_type):
		_show_textbox(after_item_interact_msgs[item_type])

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
