extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var animated_sprite = $CharacterBody2D/AnimatedSprite2D

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "examine electric fan"

func _on_interact():
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		# Start the fan animation
		animated_sprite.play("default")
		
		# Use SimpleDialogManager to show safety tips
		var dialog_position = global_position + Vector2(0, -50)  # Position dialog above fan
		SimpleDialogManager.show_safety_tips("e_fan", dialog_position)
		
		# Complete the quest objective for e_fan interaction
		if QuestManager.has_method("complete_objective"):
			QuestManager.complete_objective("interact_with_e_fan")
