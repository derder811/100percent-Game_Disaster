extends Control

# Sound settings
var sound_enabled = true
var original_scales = {}

# UI References
@onready var sound_button = $"Toggle Sounds"
@onready var back_button = $"Back Button"

func _ready():
	# Load sound settings from saved data
	_load_sound_settings()
	
	# Store original button scales for animations
	original_scales["Toggle Sounds"] = sound_button.scale
	original_scales["Back Button"] = back_button.scale
	
	# Connect button signals
	sound_button.pressed.connect(_on_sound_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect hover animations
	sound_button.mouse_entered.connect(_on_button_hover.bind("Toggle Sounds"))
	sound_button.mouse_exited.connect(_on_button_unhover.bind("Toggle Sounds"))
	back_button.mouse_entered.connect(_on_button_hover.bind("Back Button"))
	back_button.mouse_exited.connect(_on_button_unhover.bind("Back Button"))
	
	# Update sound button appearance based on current state
	_update_sound_button_appearance()

# Load sound settings from file or use default
func _load_sound_settings():
	if FileAccess.file_exists("user://sound_settings.save"):
		var file = FileAccess.open("user://sound_settings.save", FileAccess.READ)
		if file:
			sound_enabled = file.get_var()
			file.close()
	else:
		sound_enabled = true  # Default to enabled

# Save sound settings to file
func _save_sound_settings():
	var file = FileAccess.open("user://sound_settings.save", FileAccess.WRITE)
	if file:
		file.store_var(sound_enabled)
		file.close()

# Update the sound button appearance based on current state
func _update_sound_button_appearance():
	# You can modify the button's modulate color to show on/off state
	if sound_enabled:
		sound_button.modulate = Color.WHITE  # Normal color when sound is on
	else:
		sound_button.modulate = Color.GRAY   # Grayed out when sound is off

# Apply sound settings to the game
func _apply_sound_settings():
	if sound_enabled:
		# Enable all audio
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
	else:
		# Mute all audio
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)

# Button hover animation
func _on_button_hover(button_name: String):
	var button = get_node(button_name)
	if button and original_scales.has(button_name):
		var hover_tween = create_tween()
		hover_tween.tween_property(button, "scale", original_scales[button_name] * 1.1, 0.2)

# Button unhover animation
func _on_button_unhover(button_name: String):
	var button = get_node(button_name)
	if button and original_scales.has(button_name):
		var unhover_tween = create_tween()
		unhover_tween.tween_property(button, "scale", original_scales[button_name], 0.2)

# Button click animation
func _animate_button_click(button_name: String, callback: Callable):
	var button = get_node(button_name)
	if button and original_scales.has(button_name):
		# Click animation: scale down then up
		var click_tween = create_tween()
		click_tween.tween_property(button, "scale", original_scales[button_name] * 0.9, 0.1)
		click_tween.tween_property(button, "scale", original_scales[button_name] * 1.05, 0.1)
		click_tween.tween_property(button, "scale", original_scales[button_name], 0.1)
		
		# Wait for animation to complete then execute callback
		await click_tween.finished
		callback.call()
	else:
		callback.call()

# Sound button pressed
func _on_sound_button_pressed():
	print("Sound button pressed")
	_animate_button_click("Toggle Sounds", func(): _toggle_sound())

# Toggle sound on/off
func _toggle_sound():
	sound_enabled = !sound_enabled
	print("Sound toggled: ", "ON" if sound_enabled else "OFF")
	
	# Update button appearance
	_update_sound_button_appearance()
	
	# Apply sound settings
	_apply_sound_settings()
	
	# Save settings
	_save_sound_settings()

# Back button pressed
func _on_back_button_pressed():
	print("Back button pressed")
	_animate_button_click("Back Button", func(): _go_back_to_main_menu())

# Go back to main menu
func _go_back_to_main_menu():
	# Fade out animation
	var transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await transition_tween.finished
	
	# Change scene back to main menu
	get_tree().change_scene_to_file("res://asset/button/Menu/main_menu.tscn")
