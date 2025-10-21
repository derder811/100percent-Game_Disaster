extends Control

var is_paused: bool = false
var original_scales := {}

@onready var background: ColorRect = $Background
@onready var popup_panel: PopupPanel = $Background/PopupPanel
@onready var menu_container: VBoxContainer = $Background/PopupPanel/MenuContainer
@onready var resume_button: TextureButton = $Background/PopupPanel/MenuContainer/ResumeButton
@onready var settings_button: TextureButton = $Background/PopupPanel/MenuContainer/SettingsButton

@onready var mobile_controls_layer: CanvasLayer = get_tree().root.get_node_or_null("MobileControls")
@onready var settings_button_layer: CanvasLayer = get_tree().root.get_node_or_null("SettingsButton")
@onready var interaction_ui_layer: CanvasLayer = get_tree().root.get_node_or_null("InteractionUI")

func _ready() -> void:
	# Ensure pause menu can receive input when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if background:
		background.mouse_filter = Control.MOUSE_FILTER_STOP
	# PopupPanel does not support mouse_filter in this version; skip setting it
	if menu_container:
		menu_container.mouse_filter = Control.MOUSE_FILTER_STOP
	if resume_button:
		resume_button.mouse_filter = Control.MOUSE_FILTER_STOP
		original_scales[resume_button] = resume_button.scale
	if settings_button:
		settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
		original_scales[settings_button] = settings_button.scale
 	
