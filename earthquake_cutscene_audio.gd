extends Node

func _ready():
	# Ensure any global store ambient stops when this cutscene scene loads
	if typeof(AudioManager) != TYPE_NIL:
		AudioManager.stop_ambient()