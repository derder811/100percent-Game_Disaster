extends Control

# Animation variables
var original_scales = {}
var is_transitioning = false

# Title animation variables
@onready var title_label = $Label
var title_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	# Store original button scales
	original_scales["Play Button"] = $"Play Button".scale
	original_scales["Options Button"] = $"Options Button".scale
	original_scales["Exit Button"] = $"Exit Button".scale
	
	# Connect button signals to their respective functions
	$"Play Button".pressed.connect(_on_play_button_pressed)
	$"Options Button".pressed.connect(_on_options_button_pressed)
	$"Exit Button".pressed.connect(_on_exit_button_pressed)
	
	# Connect hover signals for animations
	$"Play Button".mouse_entered.connect(_on_button_hover.bind("Play Button"))
	$"Play Button".mouse_exited.connect(_on_button_unhover.bind("Play Button"))
	$"Options Button".mouse_entered.connect(_on_button_hover.bind("Options Button"))
	$"Options Button".mouse_exited.connect(_on_button_unhover.bind("Options Button"))
	$"Exit Button".mouse_entered.connect(_on_button_hover.bind("Exit Button"))
	$"Exit Button".mouse_exited.connect(_on_button_unhover.bind("Exit Button"))
	
	# Fade in animation for the menu
	_fade_in_menu()
	
	# Start title animations
	_start_title_animations()

# Fade in animation when menu appears
func _fade_in_menu():
	modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.8)

# Title animations
func _start_title_animations():
	if not title_label:
		return
	
	# Initial fade in for title with delay using timer
	title_label.modulate.a = 0.0
	
	# Wait for the delay, then start the fade in
	await get_tree().create_timer(0.3).timeout
	
	var title_fade_tween = create_tween()
	title_fade_tween.tween_property(title_label, "modulate:a", 1.0, 1.2)
	
	# Wait for fade in to complete, then start floating animation
	await title_fade_tween.finished
	_start_title_floating_animation()

func _start_title_floating_animation():
	if not title_label:
		return
	
	# Create a subtle floating animation
	title_tween = create_tween()
	title_tween.set_loops()  # Infinite loop
	title_tween.set_parallel(true)
	
	# Floating up and down motion
	var original_y = title_label.position.y
	title_tween.tween_method(_update_title_float, 0.0, 1.0, 3.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# Subtle scale pulsing
	title_tween.tween_method(_update_title_pulse, 0.0, 1.0, 4.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _update_title_float(progress: float):
	if title_label:
		var float_offset = sin(progress * PI * 2) * 8.0  # 8 pixels up and down
		title_label.position.y = 50.0 + float_offset

func _update_title_pulse(progress: float):
	if title_label:
		var pulse_scale = 1.0 + sin(progress * PI * 2) * 0.02  # Subtle 2% scale change
		title_label.scale = Vector2(pulse_scale, pulse_scale)

# Button hover animation
func _on_button_hover(button_name: String):
	if is_transitioning:
		return
	var button = get_node(button_name)
	var hover_tween = create_tween()
	hover_tween.tween_property(button, "scale", original_scales[button_name] * 1.1, 0.2)

# Button unhover animation
func _on_button_unhover(button_name: String):
	if is_transitioning:
		return
	var button = get_node(button_name)
	var unhover_tween = create_tween()
	unhover_tween.tween_property(button, "scale", original_scales[button_name], 0.2)

# Button click animation
func _animate_button_click(button_name: String, callback: Callable):
	if is_transitioning:
		return
	is_transitioning = true
	var button = get_node(button_name)
	
	# Click animation: scale down then up
	var click_tween = create_tween()
	click_tween.tween_property(button, "scale", original_scales[button_name] * 0.9, 0.1)
	click_tween.tween_property(button, "scale", original_scales[button_name] * 1.05, 0.1)
	click_tween.tween_property(button, "scale", original_scales[button_name], 0.1)
	
	# Wait for animation to complete then execute callback
	await click_tween.finished
	callback.call()

# Scene transition animation
func _transition_to_scene(scene_path: String):
	# Fade out animation
	var transition_tween = create_tween()
	transition_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await transition_tween.finished
	
	# Change scene
	get_tree().change_scene_to_file(scene_path)

# Function called when Play button is pressed
func _on_play_button_pressed():
	print("Play button pressed - Loading game selection scene")
	_animate_button_click("Play Button", func(): _transition_to_scene("res://GAME SELECTION.tscn"))

# Function called when Options button is pressed
func _on_options_button_pressed():
	print("Options button pressed")
	_animate_button_click("Options Button", func(): _transition_to_scene("res://option.tscn"))

# Function called when Exit button is pressed
func _on_exit_button_pressed():
	print("Exit button pressed - Quitting game")
	_animate_button_click("Exit Button", func(): get_tree().quit())
