extends Node

# Game initialization script that handles startup messages and automatic self-talk

var has_shown_startup_message = false

# Self-talk messages for different scenarios
var self_talk_messages = {
	"game_start": [
		"Alright, I'm ready to learn about disaster preparedness!",
		"Let me explore this house and see what safety measures I can find.",
		"I should check different rooms and interact with objects to learn more."
	] as Array[String],
	"after_interact": [
		"Im late i need to click my bed",
		"Good to know! This could be really useful in an emergency.",
		"I'm learning so much about disaster preparedness.",
		"These safety measures could save lives in a real disaster.",
		"I should share this knowledge with my family and friends."
	] as Array[String]
}

func _ready():
	# Add this node to a group so it can be found by the interaction manager
	add_to_group("game_initializer")
	
	# Wait a moment for the scene to fully load, then show startup message
	await get_tree().create_timer(1.0).timeout
	show_startup_message()

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
	# Get a random self-talk message
	var messages = self_talk_messages["game_start"]
	var random_message = messages[randi() % messages.size()]
	
	# Prefer the unified SelfTalkSystem bottom textbox instead of bubble
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	if sys and sys.has_method("trigger_custom_self_talk"):
		sys.trigger_custom_self_talk(random_message)
		return
	
	# Fallback: if the self talk system isn't present, continue with bubble
	var player = get_tree().get_first_node_in_group("Player2")
	if player:
		var sprite = player.get_node("Sprite2D")
		var sprite_position = player.global_position
		if sprite:
			sprite_position = player.global_position + sprite.position
		var dialog_position = sprite_position + Vector2(0, -80)
		DialogManager.start_dialog(dialog_position, [random_message])

# Function to connect to interaction events
func setup_interaction_callbacks():
	# This will be called to set up callbacks for object interactions
	var interaction_manager = get_node("/root/InteractionManager")
	if interaction_manager:
		# We'll modify the interaction system to call our self-talk function
		pass
