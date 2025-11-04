extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = get_node_or_null("AnimatedSprite2D")

const lines: Array[String] = [
	"It's raining hard... I should check the television to see if there's a typhoon warning.",	
]

func _ready():
	# Fallbacks for different node names
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = get_node_or_null("Sprite")
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "window"

func _on_interact():
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		# Guard against missing sprite to avoid null instance errors
		if sprite != null:
			sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Play self-talk voice clip
		if AudioManager:
			AudioManager.play_sfx("res://retyphoon (2)/It’s raining hard… I should check the television to see if there’s a typhoon warning.wav", 4.0)
		
		# Show self-talk in bottom textbox via SelfTalkSystem
		var sys = get_tree().get_first_node_in_group("self_talk_system")
		if sys and sys.has_method("trigger_custom_self_talk"):
			sys.trigger_custom_self_talk(lines[0])
		
		# Wait for actual audio completion, then remove self-talk textbox
		await AudioManager.wait_sfx_finished()
		if sys and sys.has_method("hide_self_talk"):
			sys.hide_self_talk()
		elif sys and sys.has_method("clear_self_talk"):
			sys.clear_self_talk()
		
		# Show SimpleDialog safety tips after self-talk is removed
		await get_tree().create_timer(0.3).timeout
		SimpleDialogManager.show_safety_tips("window", global_position)
		
		# Follow-up self-talk message
		await get_tree().create_timer(2.0).timeout
		var sys2 = get_tree().get_first_node_in_group("self_talk_system")
		if sys2 and sys2.has_method("trigger_custom_self_talk"):
			sys2.trigger_custom_self_talk("I have to check the TV… maybe there's news about the typhoon.")
		
		# Complete the quest objective for window interaction
		var quest_node = get_node("../Quest")
		if quest_node and quest_node.has_method("on_window_interaction"):
			quest_node.on_window_interaction()
			print("Window: Quest objective completed!")
		
		print("Window: Safety tip shown!")
