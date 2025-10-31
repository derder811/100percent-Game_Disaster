extends CanvasLayer

@onready var prompt_label: Label = $UIRoot/PromptLabel

func _ready():
	if prompt_label:
		prompt_label.visible = false

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