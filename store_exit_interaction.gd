extends InteractionArea

func _ready():
	# Configure as an interaction area for the store exit
	action_name = "store exit"
	interact = Callable(self, "_on_interact")
	super._ready()

func _on_interact() -> void:
	# When player interacts at the exit, complete the earthquake quest and show Survive scene
	var quest = get_tree().current_scene.find_child("EarthquakeQuest", true, false)
	if quest and quest.has_method("complete_via_exit_interaction"):
		quest.complete_via_exit_interaction()
	else:
		# If quest isn't present (fallback), directly load Survive scene
		if get_tree():
			get_tree().change_scene_to_file("res://Survive.tscn")
