extends StaticBody2D

@onready var interaction_area = $InteractionArea
@onready var sprite = $Sprite2D

const lines: Array[String] = [
	"I'll use this if the power goes out... but maybe a flashlight is safer. I don't want to cause a fire.",
	"Avoid using candles during a typhoon. Use a flashlight or battery-powered lamp to prevent fire accidents."
]

func _ready():
	print("Candle: Setting up interaction area")
	# Check if interaction_area exists
	if interaction_area == null:
		print("ERROR: InteractionArea not found in candle!")
		return
	
	# Check if sprite exists
	if sprite == null:
		print("Warning: Sprite2D node not found in candle!")
	
	interaction_area.interact = Callable(self, "_on_interact")
	interaction_area.action_name = "candle"
	print("Candle: Ready for E key interaction!")

func _on_interact():
	print("Candle: E key interaction triggered!")
	# Safety check for overlapping bodies
	var overlapping_bodies = interaction_area.get_overlapping_bodies()
	if overlapping_bodies.size() > 0:
		if sprite != null:
			sprite.flip_h = overlapping_bodies[0].global_position.x < global_position.x
		
		# Trigger self-talk first using the self-talk system
		var self_talk_system = get_tree().get_first_node_in_group("self_talk_system")
		if self_talk_system and self_talk_system.has_method("trigger_item_pickup_self_talk"):
			self_talk_system.trigger_item_pickup_self_talk("candle")

		# Wait for self-talk audio to finish before showing the dialog box
		# Fallback to a short delay if AudioManager isn't available
		if typeof(AudioManager) != TYPE_NIL and AudioManager:
			await AudioManager.wait_sfx_finished()
		else:
			await get_tree().create_timer(3.0).timeout

		# Optionally hide any self-talk textbox to prevent overlap (if exposed)
		if self_talk_system and self_talk_system.has_method("_hide_textbox"):
			self_talk_system._hide_textbox()
		SimpleDialogManager.show_safety_tips("candle", global_position)
		
		# Complete the quest objective for candle interaction
		var quest_node = get_node("../Quest")
		if quest_node and quest_node.has_method("on_candle_interaction"):
			quest_node.on_candle_interaction()
			print("Candle: Quest objective completed!")
		
		print("Candle: Fire safety tip shown!")
