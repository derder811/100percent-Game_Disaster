extends Node2D

# Test script to debug interaction self-talk issues

func _ready():
	print("=== INTERACTION SELF-TALK DEBUG TEST ===")
	
	# Wait a moment for the scene to fully load
	await get_tree().process_frame
	await get_tree().process_frame
	
	test_player_and_self_talk_system()

func test_player_and_self_talk_system():
	print("\n--- Testing Player and Self-Talk System ---")
	
	# Find the player
	var player = get_tree().get_first_node_in_group("Player2")
	print("Player found: ", player != null)
	
	if player:
		print("Player name: ", player.name)
		print("Player position: ", player.global_position)
		print("Player has trigger_item_self_talk method: ", player.has_method("trigger_item_self_talk"))
		
		# Check if player has self_talk_system
		if player.has_method("get") and "self_talk_system" in player:
			var self_talk_system = player.self_talk_system
			print("Self-talk system found: ", self_talk_system != null)
			
			if self_talk_system:
				print("Self-talk system name: ", self_talk_system.name)
				print("Self-talk system has trigger_after_item_interact_talk: ", self_talk_system.has_method("trigger_after_item_interact_talk"))
				
				# Test the snacks message directly
				print("\n--- Testing Snacks Message ---")
				if self_talk_system.has_method("trigger_after_item_interact_talk"):
					print("Calling trigger_after_item_interact_talk('snacks')...")
					self_talk_system.trigger_after_item_interact_talk("snacks")
				else:
					print("ERROR: trigger_after_item_interact_talk method not found!")
			else:
				print("ERROR: self_talk_system is null!")
		else:
			print("ERROR: Player doesn't have self_talk_system property!")
	else:
		print("ERROR: Player not found in Player2 group!")
	
	# Check DialogManager
	print("\n--- Testing DialogManager ---")
	if DialogManager:
		print("DialogManager found: true")
		print("DialogManager is_dialog_active: ", DialogManager.is_dialog_active)
	else:
		print("ERROR: DialogManager not found!")
	
	# Find snacks section
	print("\n--- Testing Snacks Section ---")
	var snacks_section = get_tree().get_first_node_in_group("snacks_section")
	if not snacks_section:
		# Try to find by name
		snacks_section = find_node_by_name(get_tree().root, "snacks_section")
	
	print("Snacks section found: ", snacks_section != null)
	if snacks_section:
		print("Snacks section name: ", snacks_section.name)
		print("Snacks section has _on_interact method: ", snacks_section.has_method("_on_interact"))
		
		# Test interaction directly
		print("Testing direct interaction...")
		if snacks_section.has_method("_on_interact"):
			snacks_section._on_interact()
		else:
			print("ERROR: _on_interact method not found!")

func find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name.to_lower().contains(target_name.to_lower()):
		return node
	
	for child in node.get_children():
		var result = find_node_by_name(child, target_name)
		if result:
			return result
	
	return null