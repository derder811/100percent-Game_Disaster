extends Control

@onready var game_over_sprite = $Sprite2D
@onready var menu_button = $TextureButton

# Animation variables
var is_animating = false
var button_idle_tween: Tween
var button_hover_tween: Tween
var _final_title_scale: Vector2 = Vector2.ONE

func _viewport_size() -> Vector2:
	return Vector2(get_viewport().get_visible_rect().size)

func _center_and_scale_title():
	# Make the title large and fully visible, centered in screen
	if game_over_sprite == null or game_over_sprite.texture == null:
		return
	var vp: Vector2 = _viewport_size()
	var tex_size: Vector2 = game_over_sprite.texture.get_size()
	if tex_size == Vector2.ZERO:
		tex_size = Vector2(1, 1)
	# Fit inside width and a reasonable height portion to avoid clipping
	var max_width: float = vp.x * 0.92
	var max_height: float = vp.y * 0.55
	var scale_x: float = max_width / tex_size.x
	var scale_y: float = max_height / tex_size.y
	var uniform_scale: float = min(scale_x, scale_y)
	_final_title_scale = Vector2(uniform_scale, uniform_scale)
	game_over_sprite.centered = true
	game_over_sprite.scale = _final_title_scale
	# Center a bit above middle to leave room for the button
	game_over_sprite.position = Vector2(vp.x * 0.5, vp.y * 0.35)

func _center_menu_button():
	# Ensure the Menu button appears centered below the title
	if menu_button == null:
		return
	var vp: Vector2 = _viewport_size()
	# Fix anchors to top-left so position uses top-left origin
	menu_button.anchor_left = 0.0
	menu_button.anchor_top = 0.0
	menu_button.anchor_right = 0.0
	menu_button.anchor_bottom = 0.0
	# Compute scaled button size
	var btn_size: Vector2 = menu_button.size * menu_button.scale
	# Default target below center; override using title if available
	var target_y: float = vp.y * 0.5
	if game_over_sprite and game_over_sprite.texture:
		var tex_size: Vector2 = game_over_sprite.texture.get_size()
		if tex_size == Vector2.ZERO:
			tex_size = Vector2(1, 1)
		var title_height: float = tex_size.y * game_over_sprite.scale.y
		var title_bottom_y: float = game_over_sprite.position.y + (title_height * 0.5)
		var spacing: float = max(24.0, vp.y * 0.03)
		target_y = title_bottom_y + spacing
	# Center horizontally and place just under the title
	var x: float = (vp.x - btn_size.x) * 0.5
	menu_button.position = Vector2(x, target_y)

func _ready():
	print("Game Over: _ready() called")
	# Clean up any global overlays that may sit above this screen
	_cleanup_global_overlays()
	# Fill the entire viewport area
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = _viewport_size()
	# Release any potentially stuck inputs from mobile controls
	for act in ["move_left", "move_right", "move_up", "move_down", "ui_left", "ui_right", "ui_up", "ui_down", "interact", "advance_dialog", "ui_accept"]:
		if InputMap.has_action(act):
			Input.action_release(act)
	# Stop any ongoing ambience and play Game Over SFX
	AudioManager.stop_ambient()
	AudioManager.play_sfx("res://Music/Game Over.mp3")
	# Connect the menu button
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
		menu_button.mouse_entered.connect(_on_menu_button_hover)
		menu_button.mouse_exited.connect(_on_menu_button_unhover)
		print("Game Over: Menu button connected")
	# Compute layout for large centered title and button
	_center_and_scale_title()
	_center_menu_button()
	# Start with everything invisible for animation
	modulate.a = 0.0
	if game_over_sprite:
		game_over_sprite.scale = Vector2(0.1, 0.1)
	# Start the entrance animation
	show_game_over_animation()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		# Re-center and rescale when the window size changes
		_center_and_scale_title()
		_center_menu_button()

func _cleanup_global_overlays():
	var root = get_tree().root
	if root == null:
		return
	# Overlays added at runtime from gameplay scenes
	var overlay_names: Array[String] = ["MobileControls", "InteractionUI"]
	for name in overlay_names:
		var node = root.get_node_or_null(name)
		if node != null and is_instance_valid(node):
			node.queue_free()

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
		var overshoot: Vector2 = _final_title_scale * 1.08
		tween.tween_property(game_over_sprite, "scale", overshoot, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(game_over_sprite, "scale", _final_title_scale, 0.3).set_delay(0.8)
	# Animate the menu button with enhanced entrance
	if menu_button:
		menu_button.modulate.a = 0.0
		menu_button.scale = Vector2(0.3, 0.3)
		menu_button.rotation = -0.5  # Start rotated
		# Fade in and scale up with bounce
		tween.tween_property(menu_button, "modulate:a", 1.0, 0.6).set_delay(1.5)
		tween.tween_property(menu_button, "scale", Vector2(0.26, 0.26), 0.4).set_delay(1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(menu_button, "scale", Vector2(0.24, 0.24), 0.2).set_delay(1.9)
		# Rotate to normal position
		tween.tween_property(menu_button, "rotation", 0.0, 0.5).set_delay(1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	# Mark animation as complete and start idle animations
	tween.tween_callback(func(): 
		is_animating = false
		# Re-center the button after animations finalize scales
		_center_menu_button()
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
	# Add subtle scale pulsing (larger button)
	var scale_tween = create_tween()
	scale_tween.set_loops()
	scale_tween.tween_property(menu_button, "scale", Vector2(0.245, 0.245), 1.5).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(menu_button, "scale", Vector2(0.24, 0.24), 1.5).set_ease(Tween.EASE_IN_OUT)

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
	button_hover_tween.tween_property(menu_button, "scale", Vector2(0.26, 0.26), 0.2).set_ease(Tween.EASE_OUT)
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
	unhover_tween.tween_property(menu_button, "scale", Vector2(0.24, 0.24), 0.2).set_ease(Tween.EASE_OUT)
	unhover_tween.tween_property(menu_button, "modulate", Color.WHITE, 0.2)
	unhover_tween.tween_property(menu_button, "rotation", 0.0, 0.2)
	# Restart idle animation after unhover
	unhover_tween.tween_callback(start_button_idle_animation).set_delay(0.2)

func animate_label_pulse():
	"""Label node not present; keep stub for compatibility"""
	pass

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
	# Enhanced press animation - scale down and bounce back larger
	button_tween.tween_property(menu_button, "scale", Vector2(0.22, 0.22), 0.1).set_ease(Tween.EASE_OUT)
	button_tween.tween_property(menu_button, "scale", Vector2(0.28, 0.28), 0.15).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	button_tween.tween_property(menu_button, "scale", Vector2(0.24, 0.24), 0.1).set_delay(0.25)
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
			# Stop SFX and ambience before switching scenes
			AudioManager.stop_all()
			get_tree().change_scene_to_file(scene_path)
			return
	# If no main menu found, restart current scene
	print("Game Over: No main menu found, restarting current scene")
	AudioManager.stop_all()
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
	# Show the game over screen
	show_game_over_animation()
