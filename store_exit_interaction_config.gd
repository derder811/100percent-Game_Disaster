extends Node

@onready var interaction_area: InteractionArea = $InteractionArea

func _ready():
	# Configure the child InteractionArea for the store exit
	if interaction_area:
		interaction_area.action_name = "exit"
		interaction_area.interact = Callable(self, "_on_exit_interact")
		print("Store Exit: InteractionArea configured")
	else:
		print("ERROR: Store Exit InteractionArea child not found")

func _on_exit_interact() -> void:
	# Only allow exit when EarthquakeQuest is active
	var quest = get_tree().current_scene.find_child("EarthquakeQuest", true, false)
	if quest and quest.has_method("complete_via_exit_interaction"):
		quest.complete_via_exit_interaction()
		return
	# Quest not active: show a hint and do nothing
	var sts = get_tree().get_first_node_in_group("player3_self_talk_system")
	if sts and sts.has_method("trigger_custom_self_talk"):
		sts.trigger_custom_self_talk("I can’t exit yet — complete the earthquake quest first.")
	else:
		var dialog_box = get_tree().root.get_node_or_null("DialogBox")
		if dialog_box and dialog_box.has_method("show_dialog"):
			dialog_box.show_dialog("INFO", ["You can't exit yet. Trigger the earthquake quest first."])