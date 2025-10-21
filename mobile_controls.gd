extends CanvasLayer

@export var deadzone_x: float = 0.20
@export var deadzone_y: float = 0.08
@export var max_radius: float = 80.0
@export var use_floating: bool = false
@export var smoothing: float = 0.30
@export var ease_power: float = 1.15
@export var ease_power_x: float = 1.15
@export var ease_power_y: float = 1.05
@export var vertical_gain: float = 1.20
@export var hide_when_idle: bool = false
@export var use_dpad: bool = true

@onready var ui_root: Control = $UIRoot
@onready var joystick_area: Control = $UIRoot/Joystick
@onready var joystick_base: Control = $UIRoot/Joystick/Base
@onready var joystick_knob: Control = $UIRoot/Joystick/Knob
@onready var interact_button: Button = $UIRoot/InteractButton
@onready var arrow_root: Control = $UIRoot/ArrowButtons
@onready var btn_up: Button = $UIRoot/ArrowButtons/Up
@onready var btn_down: Button = $UIRoot/ArrowButtons/Down
@onready var btn_left: Button = $UIRoot/ArrowButtons/Left
@onready var btn_right: Button = $UIRoot/ArrowButtons/Right

var stick_vector: Vector2 = Vector2.ZERO
var dragging: bool = false
var start_pos: Vector2 = Vector2.ZERO
var active_touch_index: int = -1

func _ready():
	if ui_root:
		ui_root.visible = true
	# Only connect joystick when not using D-pad
	if not use_dpad:
		if joystick_area:
			joystick_area.gui_input.connect(_on_joystick_gui_input)
		if joystick_base:
			joystick_base.gui_input.connect(_on_joystick_gui_input)
		# Initial visibility depending on hide_when_idle
		if joystick_base and joystick_knob:
			joystick_base.visible = not hide_when_idle
			joystick_knob.visible = not hide_when_idle
			# Center knob initially
			var center_container: Vector2 = joystick_base.position + joystick_base.size / 2.0
			joystick_knob.position = center_container - joystick_knob.size/2.0
	else:
		# Hide joystick visuals if using D-pad
		if joystick_area:
			joystick_area.visible = false
		if joystick_base:
			joystick_base.visible = false
		if joystick_knob:
			joystick_knob.visible = false
	# Connect arrow buttons for movement
	if arrow_root:
		arrow_root.visible = true
	if btn_left:
		btn_left.focus_mode = Control.FOCUS_NONE
		btn_left.button_down.connect(_on_arrow_down.bind("move_left"))
		btn_left.button_up.connect(_on_arrow_up.bind("move_left"))
	if btn_right:
		btn_right.focus_mode = Control.FOCUS_NONE
		btn_right.button_down.connect(_on_arrow_down.bind("move_right"))
		btn_right.button_up.connect(_on_arrow_up.bind("move_right"))
	if btn_up:
		btn_up.focus_mode = Control.FOCUS_NONE
		btn_up.button_down.connect(_on_arrow_down.bind("move_up"))
		btn_up.button_up.connect(_on_arrow_up.bind("move_up"))
	if btn_down:
		btn_down.focus_mode = Control.FOCUS_NONE
		btn_down.button_down.connect(_on_arrow_down.bind("move_down"))
		btn_down.button_up.connect(_on_arrow_up.bind("move_down"))
	# Interact button
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
	# When using D-pad, buttons directly press/release actions; skip joystick mapping
	if use_dpad:
		return
	# Map joystick vector to directional actions
	var v: Vector2 = stick_vector
	# Release all first (prevent stuck inputs)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("move_up")
	Input.action_release("move_down")
	# Apply presses based on vector
	if v.x < -deadzone_x:
		Input.action_press("move_left", clamp(-v.x, 0.0, 1.0))
	elif v.x > deadzone_x:
		Input.action_press("move_right", clamp(v.x, 0.0, 1.0))
	if v.y < -deadzone_y:
		# Up in screen-space is negative Y
		Input.action_press("move_up", clamp(-v.y, 0.0, 1.0))
	elif v.y > deadzone_y:
		Input.action_press("move_down", clamp(v.y, 0.0, 1.0))

func _on_joystick_gui_input(event: InputEvent) -> void:
	# Use consistent GLOBAL coordinates for all input types
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			active_touch_index = touch.index
			if use_floating:
				# Center base under finger
				joystick_base.global_position = touch.position - joystick_base.size / 2.0
			# Ensure visible when dragging
			if hide_when_idle:
				joystick_base.visible = true
				joystick_knob.visible = true
			# Reset knob to center of base
			var center_container: Vector2 = joystick_base.position + joystick_base.size / 2.0
			joystick_knob.position = center_container - joystick_knob.size/2.0
			dragging = true
			_update_stick(touch.position)
		else:
			# Only end drag if the same finger released
			if touch.index == active_touch_index:
				dragging = false
				active_touch_index = -1
				stick_vector = Vector2.ZERO
				# Reset knob to center of base
				var center_container: Vector2 = joystick_base.position + joystick_base.size / 2.0
				joystick_knob.position = center_container - joystick_knob.size/2.0
				if hide_when_idle:
					joystick_base.visible = false
					joystick_knob.visible = false
	elif event is InputEventScreenDrag and dragging:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.index == active_touch_index:
			_update_stick(drag.position)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			active_touch_index = -2  # mouse
			if use_floating:
				joystick_base.global_position = mb.position - joystick_base.size / 2.0
			if hide_when_idle:
				joystick_base.visible = true
				joystick_knob.visible = true
			# Reset knob to center
			var center_container: Vector2 = joystick_base.position + joystick_base.size / 2.0
			joystick_knob.position = center_container - joystick_knob.size/2.0
			dragging = true
			_update_stick(mb.position)
		else:
			if active_touch_index == -2:
				dragging = false
				active_touch_index = -1
				stick_vector = Vector2.ZERO
				var center_container: Vector2 = joystick_base.position + joystick_base.size / 2.0
				joystick_knob.position = center_container - joystick_knob.size/2.0
				if hide_when_idle:
					joystick_base.visible = false
					joystick_knob.visible = false
	elif event is InputEventMouseMotion and dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if active_touch_index == -2:
			_update_stick(motion.position)

func _apply_soft_deadzone(n: float, dz: float) -> float:
	var a: float = abs(n)
	if a < dz:
		return 0.0
	return sign(n) * (a - dz) / (1.0 - dz)

func _update_stick(world_pos: Vector2) -> void:
	# Compute delta relative to base center without using to_local on Control
	var center_local: Vector2 = joystick_base.size / 2.0
	var touch_local: Vector2 = world_pos - joystick_base.global_position
	var v: Vector2 = touch_local - center_local
	# Limit to max_radius
	if v.length() > max_radius:
		v = v.normalized() * max_radius
	# Update knob visual (container space, centered on base)
	joystick_knob.position = joystick_base.position + center_local - joystick_knob.size/2.0 + v
	# Map to output with soft deadzone, easing, gain, and smoothing
	var normalized: Vector2 = v / max_radius
	var ndx: float = _apply_soft_deadzone(normalized.x, deadzone_x)
	var ndy: float = _apply_soft_deadzone(normalized.y, deadzone_y)

	var eased: Vector2 = Vector2(
		sign(ndx) * pow(abs(ndx), ease_power_x),
		sign(ndy) * pow(abs(ndy), ease_power_y)
	)
	# Vertical gain to make up/down movement easier
	eased.y *= vertical_gain
	eased.x = clamp(eased.x, -1.0, 1.0)
	eased.y = clamp(eased.y, -1.0, 1.0)
	# Smooth towards eased
	stick_vector = stick_vector + (eased - stick_vector) * smoothing

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

func _on_arrow_down(action_name: String) -> void:
	Input.action_press(action_name, 1.0)

func _on_arrow_up(action_name: String) -> void:
	Input.action_release(action_name)
