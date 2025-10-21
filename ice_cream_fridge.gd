extends Area2D

func _ready():
	# Configure the existing InteractionArea child
	var interaction_area = $InteractionArea
	if interaction_area:
		interaction_area.action_name = "examine ice cream fridge"
		interaction_area.interact = Callable(self, "_on_interact")
		print("Ice cream fridge interaction area configured")
	else:
		print("ERROR: InteractionArea not found in ice cream fridge")

func _on_interact():
	print("DEBUG: _on_interact called in ice_cream_fridge.gd")
	print("Examining the ice cream fridge...")
	# Add your interaction logic here
	
	# Trigger self-talk for Player 3 if they're the one interacting
	var player = get_tree().get_first_node_in_group("Player2")
	print("DEBUG: Found player: ", player != null)
	if player and player.has_method("trigger_item_self_talk"):
		print("DEBUG: Player has trigger_item_self_talk method, calling it")
		player.trigger_item_self_talk("ice_cream_fridge")
	else:
		print("DEBUG: Player not found or doesn't have trigger_item_self_talk method")
	
	# Update StoreQuest objective
	var store_quest = get_tree().current_scene.find_child("StoreQuest", true, false)
	if store_quest and store_quest.has_method("on_ice_cream_fridge_interaction"):
		store_quest.on_ice_cream_fridge_interaction()