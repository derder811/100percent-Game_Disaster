extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D

const lines: Array[String] = [
	
"This is a comfortable bed - essential for rest!"
	
]

func _ready():
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "examine bed"

func _on_interact():
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Show self-talk in bottom textbox via SelfTalkSystem
		var sys = get_tree().get_first_node_in_group("self_talk_system")
		if sys and sys.has_method("trigger_custom_self_talk"):
			sys.trigger_custom_self_talk(lines[0])
		
		# Show quest box when interacting with bed
		var quest_node = get_node("../Quest")
		if quest_node and quest_node.has_method("on_bed_interaction"):
			quest_node.on_bed_interaction()
			print("Bed: Quest box shown!")
