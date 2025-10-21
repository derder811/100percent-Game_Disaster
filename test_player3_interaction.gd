extends Node2D

# Simple test script to verify Player 3 interaction system

func _ready():
	print("=== PLAYER 3 INTERACTION TEST STARTED ===")
	
	# Wait a moment for the scene to load
	await get_tree().create_timer(1.0).timeout
	
	# Find Player 3 in the scene
	var player3 = get_tree().get_first_node_in_group("Player2")
	if player3:
		print("✓ Found Player 3: ", player3.name)
		print("✓ Player 3 position: ", player3.global_position)
		
		# Check if self-talk system exists
		if player3.has_method("trigger_item_self_talk"):
			print("✓ Player 3 has trigger_item_self_talk method")
			
			# Test the self-talk system directly
			print("=== TESTING SELF-TALK SYSTEM ===")
			player3.trigger_item_self_talk("snacks")
			
		else:
			print("✗ Player 3 missing trigger_item_self_talk method")
	else:
		print("✗ Player 3 not found in Player2 group")
	
	# Check InteractionManager
	var interaction_manager = get_tree().get_first_node_in_group("interaction_manager")
	if interaction_manager:
		print("✓ Found InteractionManager: ", interaction_manager.name)
	else:
		print("✗ InteractionManager not found")
	
	# Check DialogManager
	if DialogManager:
		print("✓ DialogManager is available")
		print("✓ Dialog active status: ", DialogManager.is_dialog_active)
	else:
		print("✗ DialogManager not available")
	
	print("=== TEST COMPLETED ===")

func _input(event):
	if event.is_action_pressed("interact"):
		print("DEBUG: E key pressed - interact action detected")
		
		# Find the closest interaction area manually
		var player3 = get_tree().get_first_node_in_group("Player2")
		if player3:
			var interaction_areas = get_tree().get_nodes_in_group("interaction_area")
			print("DEBUG: Found ", interaction_areas.size(), " interaction areas")
			
			for area in interaction_areas:
				if area.has_method("_on_interact"):
					print("DEBUG: Testing interaction with: ", area.name)
					area._on_interact()