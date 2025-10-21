extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var popup: PopupPanel = $Background/PopupPanel
@onready var menu_container: VBoxContainer = $Background/PopupPanel/MenuContainer
@onready var row_center: CenterContainer = $Background/PopupPanel/MenuContainer/RowCenter
@onready var resume_button: TextureButton = $Background/PopupPanel/MenuContainer/RowCenter/ButtonsSplit/LeftCenter/ResumeButton
@onready var exit_button: TextureButton = $Background/PopupPanel/MenuContainer/RowCenter/ButtonsSplit/RightCenter/ExitButton
@onready var buttons_split: HBoxContainer = $Background/PopupPanel/MenuContainer/RowCenter/ButtonsSplit

var original_scales := {}
var fade_tween: Tween
var is_paused := false
var button_tweens := {}
var button_float_tweens := {}

func _center_layout() -> void:
	if popup:
		# Ensure homogeneous types when doing math (Vector2 vs Vector2i)
		var vp_size_v2: Vector2 = Vector2(get_viewport().get_visible_rect().size)
		var content_min_v2: Vector2 = Vector2(800, 280)
		if menu_container:
			content_min_v2 = menu_container.get_combined_minimum_size()
			if content_min_v2 == Vector2.ZERO:
				content_min_v2 = Vector2(800, 280)
		var required_size_v2 := content_min_v2 + Vector2(40, 40)
		# Clamp popup size to content and viewport to avoid giant scaling
		var max_size_v2 := vp_size_v2 - Vector2(20, 20)
		var final_size_v2 := required_size_v2
		final_size_v2.x = min(final_size_v2.x, max_size_v2.x)
		final_size_v2.y = min(final_size_v2.y, max_size_v2.y)
		popup.size = Vector2i(final_size_v2.round())
		# Center using the final popup size.
		var centered_pos_v2 := (vp_size_v2 - final_size_v2) * 0.5
		popup.position = Vector2i(centered_pos_v2.round())
	if menu_container:
		menu_container.alignment = BoxContainer.ALIGNMENT_CENTER

func _equalize_button_widths() -> void:
	# Cap button sizes to avoid giant textures dominating the layout.
	if buttons_split:
		buttons_split.add_theme_constant_override("separation", 20)
		buttons_split.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if row_center:
			row_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var left := buttons_split.get_node_or_null("LeftCenter")
		var right := buttons_split.get_node_or_null("RightCenter")
		if left:
			left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			left.size_flags_stretch_ratio = 1.0
		if right:
			right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			right.size_flags_stretch_ratio = 1.0
		# Compute a responsive, clamped target width/height for buttons.
		var vp_w: float = float(get_viewport().get_visible_rect().size.x)
		var target_w: float = clamp(vp_w * 0.28, 240.0, 420.0)
		var target_h: float = clamp(vp_w * 0.10, 90.0, 160.0)
		# Apply fixed sizes to buttons so textures are scaled down by stretch_mode.
		if resume_button:
			resume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			resume_button.custom_minimum_size = Vector2(target_w, target_h)
		if exit_button:
			exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			exit_button.custom_minimum_size = Vector2(target_w, target_h)
		# Ensure equal halves in the split, matching button widths.
		if left:
			left.custom_minimum_size.x = target_w
		if right:
			right.custom_minimum_size.x = target_w
		# Shrink the whole row to content width (2 buttons + gap).
		var sep := buttons_split.get_theme_constant("separation")
		buttons_split.custom_minimum_size.x = (target_w * 2.0) + sep

func _ready() -> void:
	# Start hidden; ensure buttons are not blocking when hidden
	if background:
		background.visible = false
	if menu_container:
		menu_container.visible = false
	# Cache original scales for hover effects and constrain buttons
	if resume_button:
		original_scales[resume_button] = resume_button.scale
		resume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# Ignore raw texture size so containers can size the button
		resume_button.set("ignore_texture_size", true)
	if exit_button:
		original_scales[exit_button] = exit_button.scale
		exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		# Ignore raw texture size so containers can size the button
		exit_button.set("ignore_texture_size", true)
	# Connect BUTTON actions (works for mouse and touch)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
	# Ensure pause menu processes input when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_equalize_button_widths()
	_center_layout()
	get_viewport().size_changed.connect(_on_viewport_resized)

func _handle_hover(pos: Vector2) -> void:
	for b in [resume_button, exit_button]:
		if b and b.get_global_rect().has_point(pos):
			_animate_button(b, 1.08, 0.12)
		elif b:
			_animate_button(b, 1.0, 0.12)

func _start_button_float(button: TextureButton, amplitude: float = 0.03, half_period: float = 0.9) -> void:
	if not button:
		return
	var base_scale: Vector2 = original_scales.get(button, button.scale)
	var ft: Tween = button_float_tweens.get(button)
	if ft and ft.is_running():
		ft.kill()
	ft = create_tween()
	ft.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	ft.tween_property(button, "scale", base_scale * (1.0 + amplitude), half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ft.tween_property(button, "scale", base_scale, half_period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ft.tween_callback(func():
		if is_paused and button.visible:
			_start_button_float(button, amplitude, half_period)
	)
	button_float_tweens[button] = ft

func _stop_button_float(button: TextureButton) -> void:
	var ft: Tween = button_float_tweens.get(button)
	if ft and ft.is_running():
		ft.kill()
	button_float_tweens.erase(button)
	if button:
		var base_scale: Vector2 = original_scales.get(button, button.scale)
		button.scale = base_scale

func _animate_button(b: TextureButton, scale_factor: float, duration: float = 0.12) -> void:
	if not b:
		return
	_stop_button_float(b)
	var base_scale: Vector2 = original_scales.get(b, b.scale)
	var t: Tween = button_tweens.get(b)
	if t and t.is_running():
		t.kill()
	t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(b, "scale", base_scale * scale_factor, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_tweens[b] = t
	t.tween_callback(func():
		if is_paused and b and b.visible:
			_start_button_float(b)
	)

func _handle_tap(pos: Vector2) -> void:
	for b in [resume_button, exit_button]:
		if b and b.get_global_rect().has_point(pos):
			_animate_button(b, 0.95, 0.08)
			b.emit_signal("pressed")
			break

func _show_menu() -> void:
	if background:
		background.visible = true
		background.modulate.a = 1.0
	if popup:
		popup.visible = true
		popup.set("mouse_filter", Control.MOUSE_FILTER_STOP)
	if menu_container:
		menu_container.visible = true
	if resume_button:
		resume_button.visible = true
		_start_button_float(resume_button)
	if exit_button:
		exit_button.visible = true
		_start_button_float(exit_button)
	_equalize_button_widths()
	_center_layout()

func _hide_menu() -> void:
	if popup:
		popup.visible = false
	if menu_container:
		menu_container.visible = false
	if background:
		background.visible = false
	if resume_button:
		_stop_button_float(resume_button)
		resume_button.visible = false
	if exit_button:
		_stop_button_float(exit_button)
		exit_button.visible = false

func _fade_in_menu() -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	fade_tween = create_tween()
	# Ensure tween continues while game is paused (Godot 4 API)
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if background:
		fade_tween.tween_property(background, "modulate:a", 1.0, 0.15)
		await fade_tween.finished

func _fade_out_menu() -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	fade_tween = create_tween()
	# Ensure tween continues while game is paused (Godot 4 API)
	fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if background:
		fade_tween.tween_property(background, "modulate:a", 0.0, 0.15)
		await fade_tween.finished

func _input(event: InputEvent) -> void:
	if is_paused:
		if event is InputEventMouseMotion:
			_handle_hover(get_viewport().get_mouse_position())
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_handle_tap(event.position)
		elif event is InputEventScreenTouch and event.pressed:
			_handle_tap(event.position)

func _animate_button_click(button: TextureButton, callback: Callable) -> void:
	if not button:
		callback.call()
		return
	_stop_button_float(button)
	var base_scale: Vector2 = original_scales.get(button, button.scale)
	var t: Tween = button_tweens.get(button)
	if t and t.is_running():
		t.kill()
	t = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(button, "scale", base_scale * 0.92, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", base_scale * 1.05, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", base_scale, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	button_tweens[button] = t
	await t.finished
	callback.call()

func _on_resume_pressed() -> void:
	_animate_button_click(resume_button, func():
		resume_game()
	)

func _on_exit_pressed() -> void:
	_animate_button_click(exit_button, func():
		_exit_to_main_menu()
	)


func pause_game() -> void:
	# Elevate pause UI and block other overlays by z-order; also disable their mouse capture
	_get_mobile_controls_blocking(true)
	_get_interaction_ui_blocking(true)
	_get_dialog_box_blocking(true)
	get_tree().paused = true
	is_paused = true
	_show_menu()
	_fade_in_menu()

func resume_game() -> void:
	get_tree().paused = false
	is_paused = false
	_fade_out_menu()
	_hide_menu()
	_get_mobile_controls_blocking(false)
	_get_interaction_ui_blocking(false)
	_get_dialog_box_blocking(false)


# --- Overlay management -----------------------------------------------------
func _get_mobile_controls() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("MobileControls")

func _get_interaction_ui() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("InteractionUI")

func _get_dialog_box() -> Node:
	var root := get_tree().root
	return root.get_node_or_null("DialogBox")

func _get_mobile_controls_blocking(block: bool) -> void:
	var mc := _get_mobile_controls()
	if mc:
		var ui_root := mc.get_node_or_null("UIRoot")
		if ui_root:
			ui_root.visible = not block
			ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			var interact := ui_root.get_node_or_null("InteractButton")
			if interact:
				interact.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			var joystick := ui_root.get_node_or_null("Joystick")
			if joystick:
				for c in [joystick, joystick.get_node_or_null("Base"), joystick.get_node_or_null("Knob")]:
					if c:
						c.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP

func _get_interaction_ui_blocking(block: bool) -> void:
	var iu := _get_interaction_ui()
	if iu:
		var ui_root := iu.get_node_or_null("UIRoot")
		if ui_root:
			ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			ui_root.visible = not block

func _get_dialog_box_blocking(block: bool) -> void:
	var db := _get_dialog_box()
	if db:
		var dlg := db.get_node_or_null("DialogControl")
		if dlg:
			dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE if block else Control.MOUSE_FILTER_STOP
			dlg.visible = not block


func _exit_to_main_menu() -> void:
	get_tree().paused = false
	var candidates := [
		"res://asset/button/Menu/main_menu.tscn",
		"res://GAME SELECTION.tscn",
		"res://game_selection.tscn"
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			get_tree().change_scene_to_file(path)
			return
	# Fallback: quit if no menu scene found
	get_tree().quit()

func _on_viewport_resized() -> void:
	_center_layout()
	_equalize_button_widths()

func _notification(what):
	# No-op; resize handled via Viewport.size_changed signal
	pass
