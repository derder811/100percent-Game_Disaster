extends CanvasLayer

@onready var prompt_label: Label = $UIRoot/PromptLabel

func _ready():
	if prompt_label:
		prompt_label.visible = false

func show_interaction_prompt(interactable: Node) -> void:
	var name_text := ""
	if interactable and is_instance_valid(interactable):
		if interactable.has_method("get_interaction_prompt"):
			name_text = interactable.get_interaction_prompt()
		else:
			name_text = "Tap Interact to interact with %s" % interactable.name
	else:
		name_text = "Tap Interact to interact"
	if prompt_label:
		prompt_label.text = name_text
		prompt_label.visible = true

func hide_interaction_prompt() -> void:
	if prompt_label:
		prompt_label.visible = false