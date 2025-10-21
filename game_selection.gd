extends Node2D

# Animation variables
var original_scales = {}
var is_transitioning = false

# Button references
@onready var typhoon_button = $typoon
@onready var earthquake_button = $earthquake

# Called when the node enters the scene tree for the first time.
func _ready():
	# Wait for the scene to be fully loaded
	await get_tree().process_frame
	
	# Store original button scales
	if typhoon_button:
		original_scales["typhoon"] = typhoon_button.scale
		print("Typhoon button found, scale: ", typhoon_button.scale)
	else:
		print("Typhoon button not found!")
		
	if earthquake_button:
		original_scales["earthquake"] = earthquake_button.scale
		print("Earthquake button found, scale: ", earthquake_button.scale)
	else:
		print("Earthquake button not found!")
	
	# Connect button signals to their respective functions
	if typhoon_button:
		typhoon_button.pressed.connect(_on_typhoon_button_pressed)
		typhoon_button.mouse_entered.connect(_on_button_hover.bind("typhoon"))
		typhoon_button.mouse_exited.connect(_on_button_unhover.bind("typhoon"))
		print("Typhoon button signals connected")
	
	if earthquake_button:
		earthquake_button.pressed.connect(_on_earthquake_button_pressed)
		earthquake_button.mouse_entered.connect(_on_button_hover.bind("earthquake"))
		earthquake_button.mouse_exited.connect(_on_button_unhover.bind("earthquake"))
		print("Earthquake button signals connected")
	
	# Fade in animation for the menu
	_fade_in_menu()

# Fade in animation when menu appears
func _fade_in_menu():
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.8)

# Button hover animation - simplified and more reliable
func _on_button_hover(button_name: String):
	if is_transitioning:
		return
	
	var button = get_button_by_name(button_name)
	if button and original_scales.has(button_name):
		print("Hovering over: ", button_name)
		var hover_tween = create_tween()
		hover_tween.tween_property(button, "scale", original_scales[button_name] * 1.1, 0.2)

# Button unhover animation - simplified and more reliable
func _on_button_unhover(button_name: String):
	if is_transitioning:
		return
	
	var button = get_button_by_name(button_name)
	if button and original_scales.has(button_name):
		print("Unhovering from: ", button_name)
		var unhover_tween = create_tween()
		unhover_tween.tween_property(button, "scale", original_scales[button_name], 0.2)

# Button click animation - simplified for better reliability
func _animate_button_click(button_name: String, callback: Callable):
	if is_transitioning:
		return
	
	is_transitioning = true
	var button = get_button_by_name(button_name)
	
	if button and original_scales.has(button_name):
		print("Animating button click: ", button_name)
		# Simplified click animation
		var click_tween = create_tween()
		click_tween.tween_property(button, "scale", original_scales[button_name] * 0.9, 0.1)
		click_tween.tween_property(button, "scale", original_scales[button_name] * 1.1, 0.1)
		click_tween.tween_property(button, "scale", original_scales[button_name], 0.1)
		
		# Wait for animation to complete then execute callback
		await click_tween.finished
		callback.call()
	else:
		print("Button not found or no scale stored for: ", button_name)
		callback.call()

# Helper function to get button by name
func get_button_by_name(button_name: String) -> TextureButton:
	match button_name:
		"typhoon":
			return typhoon_button
		"earthquake":
			return earthquake_button
		_:
			print("Unknown button name: ", button_name)
			return null

# Scene transition animation - simplified
func _transition_to_scene(scene_path: String, disaster_type: String):
	print("Selected disaster type: ", disaster_type)
	print("Transitioning to scene: ", scene_path)
	
	# Simple fade out transition
	var transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await transition_tween.finished
	
	# Change scene to the main game
	get_tree().change_scene_to_file(scene_path)

# Function called when Typhoon button is pressed
func _on_typhoon_button_pressed():
	print("Typhoon button pressed - Loading typhoon scenario")
	_animate_button_click("typhoon", func(): _transition_to_scene("res://GAME_SCENE/first_scenario.tscn", "Typhoon"))

# Function called when Earthquake button is pressed
func _on_earthquake_button_pressed():
	print("Earthquake button pressed - Loading earthquake scenario")
	_animate_button_click("earthquake", func(): _transition_to_scene("res://earthquake.tscn", "Earthquake"))

# Optional: Add keyboard support for accessibility
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_on_typhoon_button_pressed()
			KEY_2:
				_on_earthquake_button_pressed()
			KEY_ESCAPE:
				_go_back_to_main_menu()

# Function to go back to main menu (can be called by ESC key)
func _go_back_to_main_menu():
	if is_transitioning:
		return
	
	print("Going back to main menu")
	var transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await transition_tween.finished
	
	# Change scene back to main menu
	get_tree().change_scene_to_file("res://asset/button/Menu/main_menu.tscn")
