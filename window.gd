extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = get_node_or_null("AnimatedSprite2D")

# Local minimal textbox fallback (used if no UI systems are present)
var _local_textbox_layer: CanvasLayer = null
var _local_textbox_panel: Panel = null
var _local_textbox_label: Label = null
var _local_textbox_timer: Timer = null

const lines: Array[String] = [
	"It's raining hard... I should check the television to see if there's a typhoon warning.",	
]

func _ready():
	print("Window: Setting up interaction area")
	# Fallbacks for different node names
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = get_node_or_null("Sprite")
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "window"
	print("Window: Ready for E key interaction!")

	# Prepare local textbox timer
	_local_textbox_timer = Timer.new()
	_local_textbox_timer.one_shot = true
	_local_textbox_timer.timeout.connect(_hide_local_textbox)
	add_child(_local_textbox_timer)

func _on_interact():
	print("Window: E key interaction triggered!")
	# Safety check; flip sprite if we detect an overlapping body
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0 and sprite != null:
		sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x

	# Play self-talk voice clip
	if AudioManager:
		AudioManager.play_sfx("res://retyphoon (2)/It’s raining hard… I should check the television to see if there’s a typhoon warning.wav", 4.0)

	# Show self-talk via SelfTalkSystem; fallback to InteractionUI if unavailable
	var sys = get_tree().get_first_node_in_group("self_talk_system")
	var shown_via_system = false
	if sys and sys.has_method("trigger_custom_self_talk"):
		# Force display to bypass SelfTalkSystem's 'raining hard' dedupe
		sys.trigger_custom_self_talk(lines[0], true)
		shown_via_system = true
	else:
		var ui = get_tree().get_first_node_in_group("interaction_ui")
		if ui and ui.has_method("show_self_talk"):
			ui.show_self_talk(lines[0], 4.0)
		else:
			_show_local_textbox(lines[0], 4.0)

	# Wait for actual audio completion, then remove self-talk textbox if needed
	if AudioManager:
		await AudioManager.wait_sfx_finished()
	if shown_via_system and sys and sys.has_method("hide_self_talk"):
		sys.hide_self_talk()
	elif shown_via_system and sys and sys.has_method("clear_self_talk"):
		sys.clear_self_talk()
	else:
		var ui_hide = get_tree().get_first_node_in_group("interaction_ui")
		if ui_hide and ui_hide.has_method("hide_self_talk"):
			ui_hide.hide_self_talk()
		else:
			_hide_local_textbox()

	# Show SimpleDialog safety tips after self-talk is removed
	await get_tree().create_timer(0.3).timeout
	SimpleDialogManager.show_safety_tips("window", global_position)

	# Follow-up self-talk message (wait longer so tips remain visible)
	await get_tree().create_timer(6.0).timeout
	var sys2 = get_tree().get_first_node_in_group("self_talk_system")
	if sys2 and sys2.has_method("trigger_custom_self_talk"):
		sys2.trigger_custom_self_talk("I have to check the TV… maybe there's news about the typhoon.")
	else:
		var ui2 = get_tree().get_first_node_in_group("interaction_ui")
		if ui2 and ui2.has_method("show_self_talk"):
			ui2.show_self_talk("I have to check the TV… maybe there's news about the typhoon.", 4.0)
		else:
			_show_local_textbox("I have to check the TV… maybe there's news about the typhoon.", 4.0)

	# Complete the quest objective for window interaction
	var quest_node = get_node("../Quest")
	if quest_node and quest_node.has_method("on_window_interaction"):
		quest_node.on_window_interaction()
		print("Window: Quest objective completed!")

	print("Window: Safety tip shown!")

func _ensure_local_textbox():
	if _local_textbox_layer == null:
		_local_textbox_layer = CanvasLayer.new()
		add_child(_local_textbox_layer)
	if _local_textbox_panel == null:
		_local_textbox_panel = Panel.new()
		_local_textbox_panel.anchor_left = 0.5
		_local_textbox_panel.anchor_right = 0.5
		_local_textbox_panel.anchor_top = 0.0
		_local_textbox_panel.anchor_bottom = 0.0
		_local_textbox_panel.offset_left = -220
		_local_textbox_panel.offset_right = 220
		_local_textbox_panel.offset_top = 20
		_local_textbox_panel.offset_bottom = 120
		_local_textbox_panel.visible = false
		_local_textbox_layer.add_child(_local_textbox_panel)
	if _local_textbox_label == null:
		_local_textbox_label = Label.new()
		_local_textbox_label.autowrap = true
		_local_textbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_local_textbox_label.offset_left = 12
		_local_textbox_label.offset_right = -12
		_local_textbox_label.offset_top = 12
		_local_textbox_label.offset_bottom = -12
		_local_textbox_panel.add_child(_local_textbox_label)

func _show_local_textbox(text: String, seconds: float = 4.0):
	_ensure_local_textbox()
	_local_textbox_label.text = text
	_local_textbox_panel.visible = true
	if seconds > 0:
		_local_textbox_timer.start(seconds)

func _hide_local_textbox():
	if _local_textbox_panel:
		_local_textbox_panel.visible = false
