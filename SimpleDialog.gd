extends Control

@onready var background = $Background
@onready var content_label = $Background/Border/InnerBackground/VBoxContainer/ContentContainer/ContentLabel
@onready var header_label = $Background/Border/InnerBackground/VBoxContainer/Header
@onready var footer_label = $Background/Border/InnerBackground/VBoxContainer/Footer/FooterLabel

var current_text = ""
var is_showing = false
var tween: Tween

func _ready():
	visible = false
	set_process_input(true)
	# Start with scale 0 for pop animation
	scale = Vector2.ZERO

func show_dialog(text: String, position: Vector2 = Vector2.ZERO, header: String = "TIPS", footer_hint: String = "Close(Space)"):
	print("SimpleDialog.show_dialog called with: ", text)
	current_text = text
	content_label.text = text
	# Update header and footer labels
	if header_label:
		header_label.text = header
	if footer_label:
		footer_label.text = footer_hint
	
	# Position the dialog
	if position != Vector2.ZERO:
		global_position = position - Vector2(size.x / 2, size.y + 50)
	else:
		# Center on screen
		var viewport_size = get_viewport().get_visible_rect().size
		global_position = Vector2(viewport_size.x / 2 - size.x / 2, viewport_size.y / 2 - size.y / 2)
	
	visible = true
	is_showing = true
	
	# Pop animation
	scale = Vector2.ZERO
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	print("Dialog shown at position: ", global_position)

func hide_dialog():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func(): 
		visible = false
		is_showing = false
		print("Dialog hidden")
	)

func _input(event):
	if is_showing and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			hide_dialog()