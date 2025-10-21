extends Control

# Settings variables
var master_volume: float = 100.0
var sfx_volume: float = 100.0
var is_fullscreen: bool = false
var is_vsync_enabled: bool = true

@onready var back_button: TextureButton = get_node_or_null("SettingsPanel#VBoxContainer/SettingsPanel_VBoxContainer#ButtonContainer/SettingsPanel_VBoxContainer_ButtonContainer#BackButton")
@onready var resume_button: TextureButton = get_node_or_null("SettingsPanel#VBoxContainer/SettingsPanel_VBoxContainer#ButtonContainer/SettingsPanel_VBoxContainer_ButtonContainer#ResumeButton")

# Animation variables
var original_scales = {}
var is_transitioning = false

func _ready():
	# Store original button scales with null checks
	if back_button:
		original_scales["BackButton"] = back_button.scale
	if resume_button:
		original_scales["ResumeButton"] = resume_button.scale
	
	# Connect button signals with null checks
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
		back_button.mouse_entered.connect(_on_button_hover.bind("BackButton"))
		back_button.mouse_exited.connect(_on_button_unhover.bind("BackButton"))
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_button_pressed)
		resume_button.mouse_entered.connect(_on_button_hover.bind("ResumeButton"))
		resume_button.mouse_exited.connect(_on_button_unhover.bind("ResumeButton"))
	
	# Load saved settings
	_load_settings()
	
	# Initially hide the settings menu
	visible = false

func _input(event):
	# Allow direct access to settings with Tab key during gameplay
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.keycode == KEY_TAB):
		if not visible:
			show_settings()
		else:
			hide_settings()

func _load_settings():
	# Load settings from file or use defaults
	master_volume = 100.0
	sfx_volume = 100.0
	is_fullscreen = false
	is_vsync_enabled = true

func _save_settings():
	# Here you can implement saving to a config file
	# For now, we'll just apply the settings
	_apply_settings()

func _apply_settings():
	# Apply audio settings
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume / 100.0))
	# Check if SFX bus exists, if not create or use Master
	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index == -1:
		sfx_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume / 100.0))
	
	# Apply graphics settings
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if is_vsync_enabled else DisplayServer.VSYNC_DISABLED)

func show_settings():
	visible = true
	get_tree().paused = true  # Pause the game when showing settings
	# Ensure this panel doesn't block children and sits above base canvas
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_index = 1000
	# Temporarily disable other overlays that may block clicks
	_get_mobile_controls_blocking(true)
	_get_interaction_ui_blocking(true)
	_get_dialog_box_blocking(true)
	# Center the UI on the current camera/viewport
	_center_ui_on_camera()
	_fade_in_menu()

func _center_ui_on_camera():
	# Normalize scale to avoid tiny UI from scene defaults
	scale = Vector2.ONE
	# Get the current camera or use viewport center
	var camera = get_viewport().get_camera_2d()
	if camera and is_instance_valid(camera):
		# Position the UI at the camera's center
		# Set the UI size first
		custom_minimum_size = Vector2(300, 150)
		size = custom_minimum_size
		
		# Get viewport size and camera zoom for proper centering
		var viewport_size_v2: Vector2 = Vector2(get_viewport().get_visible_rect().size)
		var camera_zoom = camera.zoom if camera.zoom != Vector2.ZERO else Vector2.ONE
		
		# Center on viewport considering camera zoom
		var screen_center_v2: Vector2 = viewport_size_v2 / 2.0
		position = screen_center_v2 - (size / 2.0)
		
		print("GameSettings: Centering UI on viewport center with camera zoom: ", camera_zoom)
		print("GameSettings: UI positioned at: ", position, " with size: ", size)
	else:
		# Fallback: try to find player and center on player position
		var player = get_tree().get_first_node_in_group("Player2")
		if player and is_instance_valid(player):
			custom_minimum_size = Vector2(300, 150)
			size = custom_minimum_size
			position = player.global_position - (size / 2.0)
			print("GameSettings: No camera found, centering on player at: ", player.global_position)
		else:
			# Final fallback to viewport center
			var viewport_size_v2: Vector2 = Vector2(get_viewport().get_visible_rect().size)
			custom_minimum_size = Vector2(300, 150)
			size = custom_minimum_size
			position = (viewport_size_v2 / 2.0) - (size / 2.0)
			print("GameSettings: No camera or player found, using viewport center")

func hide_settings():
	print("GameSettings: Hiding settings menu")
	_fade_out_menu()
	# Resume the game directly when hiding settings
	get_tree().paused = false
	# Restore overlays
	_get_mobile_controls_blocking(false)
	_get_interaction_ui_blocking(false)
	_get_dialog_box_blocking(false)

func _fade_in_menu():
	var fade_tween = create_tween()
	modulate.a = 0.0
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _fade_out_menu():
	print("GameSettings: Starting fade out animation")
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(func(): 
		visible = false
		print("GameSettings: UI hidden")
	)

func _on_back_button_pressed():
	_animate_button_click("BackButton", func(): go_to_main_menu())

func _on_resume_button_pressed():
	_animate_button_click("ResumeButton", func(): resume_game())

func resume_game():
	print("Resume button pressed - hiding UI and unpausing game")
	# Immediately hide the UI
	visible = false
	# Unpause the game
	get_tree().paused = false
	# Restore overlays
	_get_mobile_controls_blocking(false)
	_get_interaction_ui_blocking(false)
	_get_dialog_box_blocking(false)
	print("Game resumed successfully")

func go_to_main_menu():
	print("GameSettings: Going to main menu")
	# Unpause the game first
	get_tree().paused = false
	
	# Change to main menu scene
	if ResourceLoader.exists("res://asset/button/Menu/main_menu.tscn"):
		print("GameSettings: Loading main menu scene")
		get_tree().change_scene_to_file("res://asset/button/Menu/main_menu.tscn")
	else:
		print("GameSettings: Main menu scene not found, hiding settings instead")
		hide_settings()

func _on_button_hover(button_name: String):
	if is_transitioning:
		return
	
	var button = get_node_or_null("SettingsPanel#VBoxContainer/SettingsPanel_VBoxContainer#ButtonContainer/SettingsPanel_VBoxContainer_ButtonContainer#" + button_name)
	if button and button_name in original_scales:
		var hover_tween = create_tween()
		hover_tween.tween_property(button, "scale", original_scales[button_name] * 1.1, 0.2)

func _on_button_unhover(button_name: String):
	if is_transitioning:
		return
	
	var button = get_node_or_null("SettingsPanel#VBoxContainer/SettingsPanel_VBoxContainer#ButtonContainer/SettingsPanel_VBoxContainer_ButtonContainer#" + button_name)
	if button and button_name in original_scales:
		var unhover_tween = create_tween()
		unhover_tween.tween_property(button, "scale", original_scales[button_name], 0.2)

func _animate_button_click(button_name: String, callback: Callable):
	if is_transitioning:
		return
	
	var button = get_node_or_null("SettingsPanel#VBoxContainer/SettingsPanel_VBoxContainer#ButtonContainer/SettingsPanel_VBoxContainer_ButtonContainer#" + button_name)
	if not button or button_name not in original_scales:
		# If button not found, just execute callback
		callback.call()
		return
	
	is_transitioning = true
	
	var click_tween = create_tween()
	click_tween.tween_property(button, "scale", original_scales[button_name] * 0.9, 0.1)
	click_tween.tween_property(button, "scale", original_scales[button_name] * 1.05, 0.1)
	click_tween.tween_property(button, "scale", original_scales[button_name], 0.1)
	
	# Wait for animation to complete then execute callback
	await click_tween.finished
	is_transitioning = false
	callback.call()

# --- Overlay management (match PauseMenu behavior) -------------------------
func _get_mobile_controls() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("MobileControls")

func _get_interaction_ui() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("InteractionUI")

func _get_dialog_box() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("DialogBox")

func _get_mobile_controls_blocking(block: bool) -> void:
	var mc := _get_mobile_controls()
	if mc:
		var ui_root := mc.get_node_or_null("UIRoot")
		if ui_root:
			ui_root.visible = not block
			ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			var interact := ui_root.get_node_or_null("InteractButton")
			if interact:
				interact.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			var joystick := ui_root.get_node_or_null("Joystick")
			if joystick:
				for c in [joystick, joystick.get_node_or_null("Base"), joystick.get_node_or_null("Knob")]:
					if c:
						c.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP

func _get_interaction_ui_blocking(block: bool) -> void:
	var iu := _get_interaction_ui()
	if iu:
		var ui_root := iu.get_node_or_null("UIRoot")
		if ui_root:
			ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			ui_root.visible = not block

func _get_dialog_box_blocking(block: bool) -> void:
	var db := _get_dialog_box()
	if db:
		var dlg := db.get_node_or_null("DialogControl")
		if dlg:
			dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			dlg.visible = not block
