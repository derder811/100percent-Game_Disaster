extends Control

# Sound settings
var sound_enabled = true
var original_scales = {}

# UI References
@onready var sound_off_button = $"Toggle Sounds"      # Sound OFF button
@onready var sound_on_button = $"Toggle Sounds2"     # Sound ON button  
@onready var back_button = $"Back Button"
@onready var menu_audio_player = $"MenuAudioPlayer"   # Background menu music

func _ready():
	# Load sound settings from saved data
	_load_sound_settings()
	
	# Store original button scales for animations
	original_scales["Toggle Sounds"] = sound_off_button.scale
	original_scales["Toggle Sounds2"] = sound_on_button.scale
	original_scales["Back Button"] = back_button.scale
	
	# Connect button signals for both sound buttons
	sound_off_button.pressed.connect(_on_sound_button_pressed)
	sound_on_button.pressed.connect(_on_sound_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect hover animations for both sound buttons
	sound_off_button.mouse_entered.connect(_on_button_hover.bind("Toggle Sounds"))
	sound_off_button.mouse_exited.connect(_on_button_unhover.bind("Toggle Sounds"))
	sound_on_button.mouse_entered.connect(_on_button_hover.bind("Toggle Sounds2"))
	sound_on_button.mouse_exited.connect(_on_button_unhover.bind("Toggle Sounds2"))
	back_button.mouse_entered.connect(_on_button_hover.bind("Back Button"))
	back_button.mouse_exited.connect(_on_button_unhover.bind("Back Button"))
	
	# Update sound button appearance based on current state
	_update_sound_button_appearance()
	
	# Apply initial sound settings
	_apply_sound_settings()
	
	# Start playing menu background music
	_start_menu_bgm()

# Load sound settings from file or use default
func _load_sound_settings():
	if FileAccess.file_exists("user://sound_settings.save"):
		var file = FileAccess.open("user://sound_settings.save", FileAccess.READ)
		if file:
			sound_enabled = file.get_var()
			file.close()
	else:
		sound_enabled = true  # Default to enabled

# Start playing menu background music
func _start_menu_bgm():
	print("_start_menu_bgm called, sound_enabled: ", sound_enabled)
	if menu_audio_player:
		print("MenuAudioPlayer found")
		var bgm_stream = load("res://PLayer insteraction Talking and pick up talking/Music/Menu BGM.mp3")
		if bgm_stream:
			print("BGM stream loaded successfully")
			menu_audio_player.stream = bgm_stream
			menu_audio_player.volume_db = -10.0  # Slightly quieter background music
			# Always try to play - _apply_sound_settings will handle muting if needed
			menu_audio_player.play()
			print("Menu BGM stream set and play() called")
		else:
			print("Failed to load Menu BGM")
	else:
		print("MenuAudioPlayer not found")

# Save sound settings to file
func _save_sound_settings():
	var file = FileAccess.open("user://sound_settings.save", FileAccess.WRITE)
	if file:
		file.store_var(sound_enabled)
		file.close()

# Update the sound button appearance based on current state
func _update_sound_button_appearance():
	# Show the appropriate button based on sound state
	if sound_enabled:
		sound_on_button.visible = true    # Show ON button when sound is enabled
		sound_off_button.visible = false  # Hide OFF button
	else:
		sound_on_button.visible = false   # Hide ON button when sound is disabled
		sound_off_button.visible = true   # Show OFF button

# Apply sound settings to the game
func _apply_sound_settings():
	if sound_enabled:
		# Enable all audio by setting Master bus to normal volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), 0.0)
		print("Audio enabled - all sounds ON")
		# Resume menu BGM if it was paused
		if menu_audio_player and not menu_audio_player.playing:
			menu_audio_player.play()
	else:
		# Mute all audio by setting Master bus to very low volume
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80.0)
		print("Audio disabled - all sounds OFF")
		# Stop menu BGM
		if menu_audio_player and menu_audio_player.playing:
			menu_audio_player.stop()
		# Also stop any currently playing audio through AudioManager
		if AudioManager:
			AudioManager.stop_all()

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

# Sound button pressed (handles both ON and OFF buttons)
func _on_sound_button_pressed():
	print("Sound button pressed")
	# Determine which button to animate based on current state
	var button_name = "Toggle Sounds" if not sound_enabled else "Toggle Sounds2"
	_animate_button_click(button_name, func(): _toggle_sound())

# Toggle sound on/off
func _toggle_sound():
	# Play button sound effect before toggling (if sound is currently enabled)
	if sound_enabled and AudioManager:
		AudioManager.play_sfx("res://PLayer insteraction Talking and pick up talking/Music/Tapping the Button.mp3")
	
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
