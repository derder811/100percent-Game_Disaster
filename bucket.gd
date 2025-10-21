extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = $WaterBucket

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "examine water bucket"

func _on_interact():
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Use SimpleDialogManager to show safety tips
		var dialog_position = global_position + Vector2(0, -50)  # Position dialog above water bucket
		SimpleDialogManager.show_safety_tips("bucket", dialog_position)
		
		# Complete the quest objective for water bucket interaction
		if QuestManager.has_method("complete_objective"):
			QuestManager.complete_objective("interact_with_bucket")
	else:
		# Fallback: use SimpleDialogManager directly if no overlapping bodies
		var dialog_position = global_position + Vector2(0, -50)
		SimpleDialogManager.show_safety_tips("bucket", dialog_position)
