extends CanvasLayer

@export var deadzone: float = 0.15
@export var max_radius: float = 60.0

@onready var ui_root: Control = $UIRoot
@onready var joystick_area: Control = $UIRoot/Joystick
@onready var joystick_base: ColorRect = $UIRoot/Joystick/Base
@onready var joystick_knob: ColorRect = $UIRoot/Joystick/Knob
@onready var interact_button: Button = $UIRoot/InteractButton

var stick_vector: Vector2 = Vector2.ZERO
var dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO

func _ready():
	if ui_root:
		ui_root.visible = true
	if joystick_area:
		joystick_area.gui_input.connect(_on_joystick_gui_input)
	if joystick_base:
		joystick_base.gui_input.connect(_on_joystick_gui_input)
	if interact_button:
		interact_button.pressed.connect(_on_interact_pressed)
		interact_button.button_up.connect(_on_interact_released)
		interact_button.focus_mode = Control.FOCUS_NONE
		interact_button.custom_minimum_size = Vector2(160, 60)
		interact_button.add_theme_color_override("font_color", Color(1,1,1))
		interact_button.add_theme_color_override("font_pressed_color", Color(0.9,0.9,0.9))
		interact_button.add_theme_color_override("font_hover_color", Color(1,1,1))
		interact_button.add_theme_color_override("font_disabled_color", Color(0.7,0.7,0.7))

func _process(_delta):
	# Map joystick vector to directional actions
	var v := stick_vector
	# Release all first (prevent stuck inputs)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")

	# Apply presses based on vector
	if v.x < -deadzone:
		Input.action_press("move_left", clamp(-v.x, 0.0, 1.0))
	elif v.x > deadzone:
		Input.action_press("move_right", clamp(v.x, 0.0, 1.0))
	if v.y < -deadzone:
		# Up in screen-space is negative Y
		Input.action_press("move_up", clamp(-v.y, 0.0, 1.0))
	elif v.y > deadzone:
		Input.action_press("move_down", clamp(v.y, 0.0, 1.0))

func _on_joystick_gui_input(event: InputEvent) -> void:
	# Use consistent GLOBAL coordinates for all input types
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			start_pos = joystick_base.global_position + joystick_base.size / 2.0
			dragging = true
			_update_stick(touch.position)
		else:
			dragging = false
			stick_vector = Vector2.ZERO
			# Reset knob to center of base
			var center_local := joystick_base.position + joystick_base.size/2.0
			joystick_knob.position = center_local - joystick_knob.size/2.0
	elif event is InputEventScreenDrag and dragging:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		_update_stick(drag.position)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			start_pos = joystick_base.global_position + joystick_base.size / 2.0
			dragging = true
			_update_stick(mb.position)
		else:
			dragging = false
			stick_vector = Vector2.ZERO
			var center_local := joystick_base.position + joystick_base.size/2.0
			joystick_knob.position = center_local - joystick_knob.size/2.0
	elif event is InputEventMouseMotion and dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_update_stick(motion.position)

func _update_stick(world_pos: Vector2) -> void:
	# Compute delta relative to base center without using to_local on Control
	var center_local: Vector2 = joystick_base.size / 2.0
	var touch_local: Vector2 = world_pos - joystick_base.global_position
	var v: Vector2 = touch_local - center_local
	# Limit to max_radius
	if v.length() > max_radius:
		v = v.normalized() * max_radius
	# Update knob visual (local space)
	joystick_knob.position = center_local - joystick_knob.size/2.0 + v
	# Normalize to [-1,1]
	stick_vector = v / max_radius

func _on_interact_pressed() -> void:
	# Emit as actual input events so _input(event) sees them
	if InputMap.has_action("advance_dialog"):
		var e_adv: InputEventAction = InputEventAction.new()
		e_adv.action = "advance_dialog"
		e_adv.pressed = true
		Input.parse_input_event(e_adv)
	if InputMap.has_action("interact"):
		var e_int: InputEventAction = InputEventAction.new()
		e_int.action = "interact"
		e_int.pressed = true
		Input.parse_input_event(e_int)
	else:
		var e_accept: InputEventAction = InputEventAction.new()
		e_accept.action = "ui_accept"
		e_accept.pressed = true
		Input.parse_input_event(e_accept)

func _on_interact_released() -> void:
	if InputMap.has_action("advance_dialog"):
		var e_adv: InputEventAction = InputEventAction.new()
		e_adv.action = "advance_dialog"
		e_adv.pressed = false
		Input.parse_input_event(e_adv)
	if InputMap.has_action("interact"):
		var e_int: InputEventAction = InputEventAction.new()
		e_int.action = "interact"
		e_int.pressed = false
		Input.parse_input_event(e_int)
	else:
		var e_accept: InputEventAction = InputEventAction.new()
		e_accept.action = "ui_accept"
		e_accept.pressed = false
		Input.parse_input_event(e_accept)
