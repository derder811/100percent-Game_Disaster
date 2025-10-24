extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D

const lines: Array[String] = [
	"It's raining nonstop... I'll check the news to see if there's a typhoon signal in our area.",	
]

func _ready():
	print("TV: Setting up interaction area")
	# Check if sprite node exists
	if sprite == null:
		print("Warning: Sprite2D node not found in TV! Looking for alternative sprite node...")
		# Try to find sprite with different possible names
		sprite = get_node_or_null("Sprite")
		if sprite == null:
			print("Error: No sprite node found in TV!")
	
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "watch TV"
	print("TV: Ready for E key interaction!")

func _on_interact():
	print("TV: E key interaction triggered!")
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		# Check if sprite exists before accessing flip_h property
		if sprite != null:
			sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Play self-talk voice clip
		if AudioManager:
			AudioManager.play_sfx("res://PLayer insteraction Talking and pick up talking/Self Talk (TV).mp3", 4.0)
		
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
		SimpleDialogManager.show_safety_tips("tv", global_position)
		
		# Follow-up self-talk message
		await get_tree().create_timer(2.0).timeout
		var sys2 = get_tree().get_first_node_in_group("self_talk_system")
		if sys2 and sys2.has_method("trigger_custom_self_talk"):
			sys2.trigger_custom_self_talk("The storm's getting worse… I should cut the power off.")
		
		# Complete the quest objective for TV interaction
		var quest_node = get_node("../Quest")
		if quest_node and quest_node.has_method("on_tv_interaction"):
			quest_node.on_tv_interaction()
			print("TV: Quest objective completed!")
		
		print("TV: Weather safety tip shown!")
	else:
		print("TV: No overlapping bodies found!")
