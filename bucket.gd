extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = get_node_or_null("AnimatedSprite2D")

const lines: Array[String] = [
	"Water bucket is full. Better store drinking water in sealed containers.",
]

func _ready():
	# Fallbacks for different node names
	if sprite == null:
		sprite = get_node_or_null("WaterBucket")
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = get_node_or_null("Sprite")
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "inspect water bucket"

func _on_interact():
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		# Guard against missing sprite to avoid null instance errors
		if sprite != null:
			sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Play self-talk voice clip with boosted volume
		if AudioManager:
			AudioManager.play_sfx("res://PLayer insteraction Talking and pick up talking/Self Talk (Water Bucket).mp3", 4.0)
		
		# Show self-talk then safety tips
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
		SimpleDialogManager.show_safety_tips("bucket", global_position)
		
		# Example quest progression hook (kept null-safe)
		var quest_node = get_node_or_null("../Quest")
		if quest_node and quest_node.has_method("on_bucket_interaction"):
			quest_node.on_bucket_interaction()
			print("Bucket: Quest objective completed!")
		
		print("Bucket: Safety tip shown!")
