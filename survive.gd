extends Control

@onready var sprite: Sprite2D = $Sprite2D
@onready var menu_button: Button = $Sprite2D/Button
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready():
	# Confirm music is playing
	if audio_player:
		print("Survive: Playing survive.mp3 music")
	
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
		# Subtle hover animation
		menu_button.mouse_entered.connect(func():
			var t = create_tween()
			t.tween_property(menu_button, "scale", Vector2(0.75, 0.60), 0.15)
		)
		menu_button.mouse_exited.connect(func():
			var t = create_tween()
			t.tween_property(menu_button, "scale", Vector2(0.697569, 0.558686), 0.15)
		)
	# Run a celebratory intro animation
	_animate_intro()

func _animate_intro():
	if sprite:
		var original_scale := sprite.scale
		sprite.modulate.a = 0.0
		sprite.scale = original_scale * 0.8
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "scale", original_scale * 1.05, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "scale", original_scale, 0.25).set_delay(0.35)

func _on_menu_button_pressed():
	print("Survive: Menu button pressed - going to main menu")
	var menu_scene_path := "res://asset/button/Menu/main_menu.tscn"
	if ResourceLoader.exists(menu_scene_path):
		print("Survive: Loading main menu scene")
		get_tree().change_scene_to_file(menu_scene_path)
	else:
		print("ERROR: Menu scene not found at ", menu_scene_path)
		# Fallback to game selection if main menu not found
		var fallback_path := "res://GAME SELECTION.tscn"
		if ResourceLoader.exists(fallback_path):
			print("Survive: Using fallback - loading game selection scene")
			get_tree().change_scene_to_file(fallback_path)
		else:
			print("ERROR: No menu scenes found!")
