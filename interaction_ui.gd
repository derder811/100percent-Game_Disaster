extends CanvasLayer

@onready var ui_root: Control = $UIRoot
@onready var prompt_label: Label = $UIRoot/PromptLabel

# Runtime-created textbox for simple self-talk fallback
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_timer: Timer = null
var _textbox_active: bool = false

func _ready():
	# Allow other nodes to find this as a fallback UI
	add_to_group("interaction_ui")
	# Ensure timer exists
	_textbox_timer = Timer.new()
	_textbox_timer.one_shot = true
	_textbox_timer.timeout.connect(_hide_textbox)
	add_child(_textbox_timer)

	# Default prompt hidden until interaction manager updates it
	if prompt_label:
		prompt_label.visible = false

func _ensure_textbox():
	if _textbox_panel == null:
		_textbox_panel = Panel.new()
		# Anchor to top center
		_textbox_panel.anchor_left = 0.5
		_textbox_panel.anchor_right = 0.5
		_textbox_panel.anchor_top = 0.0
		_textbox_panel.anchor_bottom = 0.0
		_textbox_panel.offset_left = -220
		_textbox_panel.offset_right = 220
		_textbox_panel.offset_top = 20
		_textbox_panel.offset_bottom = 120
		_textbox_panel.visible = false
		# Slight transparency so it feels lightweight
		if _textbox_panel is CanvasItem:
			(_textbox_panel as CanvasItem).modulate = Color(1, 1, 1, 0.92)
		ui_root.add_child(_textbox_panel)

	if _textbox_label == null:
		_textbox_label = Label.new()
		_textbox_label.autowrap = true
		_textbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_textbox_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_textbox_label.offset_left = 12
		_textbox_label.offset_right = -12
		_textbox_label.offset_top = 12
		_textbox_label.offset_bottom = -12
		_textbox_panel.add_child(_textbox_label)

func show_self_talk(text: String, seconds: float = 4.0):
	# Minimal, non-blocking textbox shown at the top center
	_ensure_textbox()
	_textbox_label.text = text
	_textbox_panel.visible = true
	_textbox_active = true
	if seconds > 0:
		_textbox_timer.start(seconds)

func _hide_textbox():
	_textbox_active = false
	if _textbox_panel:
		_textbox_panel.visible = false

func hide_self_talk():
	_hide_textbox()

func show_interaction_prompt(interactable: Node) -> void:
	# Check if mobile controls are active
	var mobile_controls_active = false
	if GlobalInteractionManager:
		mobile_controls_active = GlobalInteractionManager.are_mobile_controls_active()
	
	# Only show prompt if mobile controls are not active
	if not mobile_controls_active:
		var name_text := ""
		if interactable and is_instance_valid(interactable):
			if interactable.has_method("get_interaction_prompt"):
				name_text = interactable.get_interaction_prompt()
			else:
				name_text = "Press (Interact) to examine %s" % interactable.name
		else:
			name_text = "Press (Interact) to examine"
		if prompt_label:
			prompt_label.text = name_text
			prompt_label.visible = true
	else:
		# Hide prompt when mobile controls are active
		if prompt_label:
			prompt_label.visible = false

func hide_interaction_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false
