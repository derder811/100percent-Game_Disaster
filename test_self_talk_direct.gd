extends Node2D

# Test script to directly trigger self-talk messages

func _ready():
	print("=== DIRECT SELF-TALK TEST ===")
	
	# Wait a moment for the scene to load
	await get_tree().create_timer(3.0).timeout
	
	# Find Player 3
	var player3 = get_tree().get_first_node_in_group("Player2")
	if player3:
		print("✓ Found Player 3: ", player3.name)
		
		# Test each item type
		var test_items = ["snacks", "fridge", "slurpee", "ice_cream_fridge", "meat_fridge", "hotdog_siopao"]
		
		for item in test_items:
			print("Testing item: ", item)
			if player3.has_method("trigger_item_self_talk"):
				player3.trigger_item_self_talk(item)
				await get_tree().create_timer(3.0).timeout  # Wait between tests
			else:
				print("✗ Player 3 missing trigger_item_self_talk method")
	else:
		print("✗ Player 3 not found")

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space key
		print("Manual test triggered")
		var player3 = get_tree().get_first_node_in_group("Player2")
		if player3 and player3.has_method("trigger_item_self_talk"):
			player3.trigger_item_self_talk("snacks")