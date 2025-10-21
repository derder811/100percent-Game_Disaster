class_name DialogSystem
extends CanvasLayer

signal dialog_closed
signal dialog_finished

# Node references
@onready var dialog_control: Control = $DialogControl
@onready var title_label: Label = $DialogControl/VBoxContainer/TitleLabel
@onready var dialog_label: RichTextLabel = $DialogControl/VBoxContainer/ScrollContainer/DialogLabel
@onready var next_button: Button = $DialogControl/VBoxContainer/ButtonContainer/NextButton
@onready var close_button: Button = $DialogControl/VBoxContainer/ButtonContainer/CloseButton

var dialog_lines: Array[String] = []
var current_line_index: int = 0
var item_name: String = ""

# Typing animation variables
var is_typing: bool = false
var typing_speed: float = 0.005  # Much faster - was 0.03
var current_text: String = ""
var target_text: String = ""

# Animation variables
var tween: Tween
var is_animating: bool = false

func _ready():
	# Connect button signals
	if next_button:
		next_button.pressed.connect(_on_next_button_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Create tween for animations
	tween = create_tween()
	tween.kill()  # Stop it initially
	
	# Hide dialog initially and set initial scale for pop animation
	dialog_control.visible = false
	dialog_control.scale = Vector2.ZERO
	
	# Set pivot to center for proper scaling animation
	await get_tree().process_frame  # Wait one frame for size to be calculated
	dialog_control.pivot_offset = dialog_control.size / 2

func _input(event):
	if not dialog_control.visible or is_animating:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("advance_dialog"):
		if is_typing:
			_finish_typing()
		else:
			_next_message()

func show_dialog(title: String, lines: Array[String]):
	if is_animating:
		return
		
	item_name = title
	dialog_lines = lines
	current_line_index = 0
	
	# Set title
	title_label.text = title
	
	# Show the dialog with pop-in animation
	_animate_dialog_in()

func _animate_dialog_in():
	is_animating = true
	dialog_control.visible = true
	dialog_control.scale = Vector2.ZERO
	
	# Set pivot to center for proper scaling animation
	dialog_control.pivot_offset = dialog_control.size / 2
	
	# Create new tween for pop-in animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animate scale from 0 to 1 with a bouncy effect
	tween.tween_property(dialog_control, "scale", Vector2.ONE, 0.4)
	
	# Wait for animation to complete, then display first message
	await tween.finished
	is_animating = false
	_display_current_message()

func _animate_dialog_out():
	if is_animating:
		return
		
	is_animating = true
	
	# Create new tween for pop-out animation
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animate scale from 1 to 0
	tween.tween_property(dialog_control, "scale", Vector2.ZERO, 0.3)
	
	# Wait for animation to complete, then hide dialog
	await tween.finished
	dialog_control.visible = false
	is_animating = false
	
	# Emit signals after animation completes
	dialog_closed.emit()
	dialog_finished.emit()

func _display_current_message():
	if current_line_index >= dialog_lines.size():
		close_dialog()
		return
	
	target_text = dialog_lines[current_line_index]
	_start_typing()

func _start_typing():
	is_typing = true
	current_text = ""
	dialog_label.text = ""
	_update_text()

func _update_text():
	if current_text.length() < target_text.length():
		var next_char = target_text[current_text.length()]
		current_text += next_char
		dialog_label.text = current_text
		
		# Variable delay based on character type
		var delay = typing_speed
		match next_char:
			".", "!", "?":
				delay = typing_speed * 2  # Much faster - was 8
			",", ";", ":":
				delay = typing_speed * 1.5  # Much faster - was 4
			" ":
				delay = typing_speed * 1  # Much faster - was 2
		
		await get_tree().create_timer(delay).timeout
		_update_text()
	else:
		_finish_typing()

func _finish_typing():
	is_typing = false
	current_text = target_text
	dialog_label.text = current_text

func _next_message():
	current_line_index += 1
	_display_current_message()

func close_dialog():
	if is_animating:
		return
	_animate_dialog_out()

func _on_next_button_pressed():
	if is_typing:
		_finish_typing()
	else:
		_next_message()

func _on_close_button_pressed():
	close_dialog()