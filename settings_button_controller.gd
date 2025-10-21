extends CanvasLayer

# Reference to the settings button
@onready var settings_button = $"Settings Button"

func _ready():
	# Connect the settings button to trigger the pause menu
	settings_button.pressed.connect(_on_settings_button_pressed)

func _on_settings_button_pressed():
	print("Settings button pressed - Opening pause menu")
	
	# Get the PauseMenu node from the main scene
	var pause_menu = get_node("../PauseMenu")
	if pause_menu:
		# Trigger the pause menu
		pause_menu.pause_game()
	else:
		print("Error: Could not find PauseMenu node")
