extends Control

@onready var game_over_sprite = $Sprite2D
@onready var game_over_label = $Sprite2D/Label
@onready var menu_button = $TextureButton

# Animation variables
var is_animating = false
var button_idle_tween: Tween
var button_hover_tween: Tween

func _ready():
	print("Game Over: _ready() called")
	
	# Connect the menu button
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
		menu_button.mouse_entered.connect(_on_menu_button_hover)
		menu_button.mouse_exited.connect(_on_menu_button_unhover)
		print("Game Over: Menu button connected")
	
	# Start with everything invisible for animation
	modulate.a = 0.0
	if game_over_sprite:
		game_over_sprite.scale = Vector2(0.1, 0.1)
	
	# Start the entrance animation
	show_game_over_animation()

func show_game_over_animation():
	"""Animate the game over screen entrance"""
	if is_animating:
		return
	
	is_animating = true
	print("Game Over: Starting entrance animation")
	
	# Make sure everything is visible
	visible = true
	
	# Create entrance animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in the entire screen
	tween.tween_property(self, "modulate:a", 1.0, 1.0).set_ease(Tween.EASE_OUT)
	
	# Scale up the game over sprite with bounce effect
	if game_over_sprite:
		tween.tween_property(game_over_sprite, "scale", Vector2(1.2, 1.2), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(game_over_sprite, "scale", Vector2(0.462, 0.432667), 0.3).set_delay(0.8)
	
	# Animate the label text with typewriter effect
	if game_over_label:
		game_over_label.modulate.a = 0.0
		tween.tween_property(game_over_label, "modulate:a", 1.0, 0.5).set_delay(1.0)
		
		# Add pulsing effect to the label
		animate_label_pulse()
	
	# Animate the menu button with enhanced entrance
	if menu_button:
		menu_button.modulate.a = 0.0
		menu_button.scale = Vector2(0.3, 0.3)
		menu_button.rotation = -0.5  # Start rotated
		
		# Fade in and scale up with bounce
		tween.tween_property(menu_button, "modulate:a", 1.0, 0.6).set_delay(1.5)
		tween.tween_property(menu_button, "scale", Vector2(0.17, 0.17), 0.4).set_delay(1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(menu_button, "scale", Vector2(0.15, 0.15), 0.2).set_delay(1.9)
		
		# Rotate to normal position
		tween.tween_property(menu_button, "rotation", 0.0, 0.5).set_delay(1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Mark animation as complete and start idle animations
	tween.tween_callback(func(): 
		is_animating = false
		start_button_idle_animation()
	).set_delay(2.2)

func start_button_idle_animation():
	"""Start the idle floating animation for the button"""
	if not menu_button:
		return
	
	button_idle_tween = create_tween()
	button_idle_tween.set_loops()  # Infinite loop
	
	# Gentle floating motion
	button_idle_tween.tween_property(menu_button, "position:y", menu_button.position.y - 5, 2.0).set_ease(Tween.EASE_IN_OUT)
	button_idle_tween.tween_property(menu_button, "position:y", menu_button.position.y + 5, 2.0).set_ease(Tween.EASE_IN_OUT)
	
	# Add subtle scale pulsing
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(menu_button, "scale", Vector2(0.153, 0.153), 1.5).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(menu_button, "scale", Vector2(0.15, 0.15), 1.5).set_ease(Tween.EASE_IN_OUT)

func _on_menu_button_hover():
	"""Handle mouse hover over button"""
	if is_animating or not menu_button:
		return
	
	# Stop idle animation
	if button_idle_tween:
		button_idle_tween.kill()
	
	# Create hover animation
	button_hover_tween = create_tween()
	button_hover_tween.set_parallel(true)
	
	# Scale up and brighten
	button_hover_tween.tween_property(menu_button, "scale", Vector2(0.165, 0.165), 0.2).set_ease(Tween.EASE_OUT)
	button_hover_tween.tween_property(menu_button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.2)
	
	# Add subtle rotation wiggle
	button_hover_tween.tween_property(menu_button, "rotation", 0.05, 0.1)
	button_hover_tween.tween_property(menu_button, "rotation", -0.05, 0.1).set_delay(0.1)
	button_hover_tween.tween_property(menu_button, "rotation", 0.0, 0.1).set_delay(0.2)

func _on_menu_button_unhover():
	"""Handle mouse exit from button"""
	if is_animating or not menu_button:
		return
	
	# Stop hover animation
	if button_hover_tween:
		button_hover_tween.kill()
	
	# Return to normal state
	var unhover_tween = create_tween()
	
	unhover_tween.tween_property(menu_button, "scale", Vector2(0.15, 0.15), 0.2).set_ease(Tween.EASE_OUT)
	unhover_tween.tween_property(menu_button, "modulate", Color.WHITE, 0.2)
	unhover_tween.tween_property(menu_button, "rotation", 0.0, 0.2)
	
	# Restart idle animation after unhover
	unhover_tween.tween_callback(start_button_idle_animation).set_delay(0.2)

func animate_label_pulse():
	"""Add a pulsing animation to the game over label"""
	if not game_over_label:
		return
	
	var pulse_tween = create_tween()
	pulse_tween.set_loops()  # Infinite loop
	
	# Pulse between normal and slightly larger scale
	pulse_tween.tween_property(game_over_label, "scale", Vector2(1.1, 1.1), 1.0).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(game_over_label, "scale", Vector2(1.0, 1.0), 1.0).set_ease(Tween.EASE_IN_OUT)

func _on_menu_button_pressed():
	"""Handle menu button press with animation"""
	print("Game Over: Menu button pressed")
	
	if is_animating:
		return
	
	# Stop all button animations
	if button_idle_tween:
		button_idle_tween.kill()
	if button_hover_tween:
		button_hover_tween.kill()
	
	# Animate button press
	animate_button_press()
	
	# Wait for animation then go to main menu
	await get_tree().create_timer(0.6).timeout
	go_to_main_menu()

func animate_button_press():
	"""Animate the button press effect with enhanced feedback"""
	if not menu_button:
		return
	
	var button_tween = create_tween()
	button_tween.set_parallel(true)
	
	# Enhanced press animation - scale down more dramatically
	button_tween.tween_property(menu_button, "scale", Vector2(0.128, 0.128), 0.1).set_ease(Tween.EASE_OUT)
	button_tween.tween_property(menu_button, "scale", Vector2(0.173, 0.173), 0.15).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	button_tween.tween_property(menu_button, "scale", Vector2(0.15, 0.15), 0.1).set_delay(0.25)
	
	# Enhanced flash effect with color cycling
	button_tween.tween_property(menu_button, "modulate", Color(2.0, 1.5, 0.5, 1.0), 0.1)  # Golden flash
	button_tween.tween_property(menu_button, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.1).set_delay(0.1)  # Blue flash
	button_tween.tween_property(menu_button, "modulate", Color.WHITE, 0.2).set_delay(0.2)
	
	# Add rotation for more dynamic feel
	button_tween.tween_property(menu_button, "rotation", 0.1, 0.1)
	button_tween.tween_property(menu_button, "rotation", -0.1, 0.1).set_delay(0.1)
	button_tween.tween_property(menu_button, "rotation", 0.0, 0.2).set_delay(0.2)
	
	# Add position shake for impact
	var original_pos = menu_button.position
	button_tween.tween_property(menu_button, "position", original_pos + Vector2(2, -2), 0.05)
	button_tween.tween_property(menu_button, "position", original_pos + Vector2(-2, 2), 0.05).set_delay(0.05)
	button_tween.tween_property(menu_button, "position", original_pos, 0.1).set_delay(0.1)

func go_to_main_menu():
	"""Navigate to the main menu scene"""
	print("Game Over: Going to main menu")
	
	# Try to find the main menu scene (prioritize actual main menu over game selection)
	var main_menu_scenes = [
		"res://asset/button/Menu/main_menu.tscn",
		"res://main_menu.tscn",
		"res://MainMenu.tscn",
		"res://GAME SELECTION.tscn",
		"res://game_selection.tscn"
	]
	
	for scene_path in main_menu_scenes:
		if ResourceLoader.exists(scene_path):
			print("Game Over: Loading scene: ", scene_path)
			get_tree().change_scene_to_file(scene_path)
			return
	
	# If no main menu found, restart current scene
	print("Game Over: No main menu found, restarting current scene")
	get_tree().reload_current_scene()

func restart_game():
	"""Restart the current game scene"""
	print("Game Over: Restarting game")
	
	# Add exit animation before restarting
	var exit_tween = create_tween()
	exit_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await exit_tween.finished
	get_tree().reload_current_scene()

# Function to be called from quest system when timer expires
func trigger_game_over_from_timer():
	"""Called when the quest timer expires"""
	print("Game Over: Triggered from timer expiration")
	
	# Update the label text for timer expiration
	if game_over_label:
		game_over_label.text = "TIME'S UP! THE FLOOD HAS ENTERED THE HOUSE."
	
	# Show the game over screen
	show_game_over_animation()
