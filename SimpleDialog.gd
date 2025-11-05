extends Control

@onready var background = $Background
@onready var content_label = $Background/Border/InnerBackground/VBoxContainer/ContentContainer/ContentLabel
@onready var header_label = $Background/Border/InnerBackground/VBoxContainer/Header
@onready var footer_label = $Background/Border/InnerBackground/VBoxContainer/Footer/FooterLabel

var current_text = ""
var is_showing = false
var tween: Tween
var auto_hide_timer: Timer

func _ready():
	visible = false
	set_process_input(true)
	# Start with scale 0 for pop animation
	scale = Vector2.ZERO
	
	# Allow this node to process input even when the game is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Create auto-hide timer
	auto_hide_timer = Timer.new()
	auto_hide_timer.wait_time = 2.0
	auto_hide_timer.one_shot = true
	auto_hide_timer.timeout.connect(func(): 
		print("Auto-hide timer expired - closing simple dialog")
		if is_showing:
			hide_dialog()
	)
	add_child(auto_hide_timer)

func show_dialog(text: String, position: Vector2 = Vector2.ZERO, header: String = "TIPS", footer_hint: String = ""):
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
		global_position = position - Vector2(size.x / 2, size.y - 5)
	else:
		# Center on screen
		var viewport_size = get_viewport().get_visible_rect().size
		global_position = Vector2(viewport_size.x / 2 - size.x / 2, viewport_size.y / 2 - size.y / 2 + 35)
	
	visible = true
	is_showing = true
	
	# Pause the game when showing the dialog
	get_tree().paused = true
	print("Game paused - SimpleDialog showing")
	
	# Pop animation
	scale = Vector2.ZERO
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)
	
	# Start auto-hide timer
	if auto_hide_timer:
		auto_hide_timer.start()
		print("Started 2-second auto-hide timer for simple dialog")


func hide_dialog():
	# Stop auto-hide timer if it's running
	if auto_hide_timer and not auto_hide_timer.is_stopped():
		auto_hide_timer.stop()
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func(): 
		visible = false
		is_showing = false
		# Resume the game when hiding the dialog
		get_tree().paused = false
		print("Game resumed - SimpleDialog hidden")
	)

func _input(event):
	if not is_showing:
		return
	# Accept space/enter/escape keys
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			hide_dialog()
			return
	# Accept action presses from mobile controls
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("advance_dialog"):
		hide_dialog()
