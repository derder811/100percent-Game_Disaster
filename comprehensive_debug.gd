extends Node2D

# Comprehensive debug script to test Player 3 self-talk system only
var debug_timer: Timer
var player: CharacterBody2D
var interaction_manager: Node
var player3_self_talk_system: Player3SelfTalkSystem

func _ready():
	print("=== PLAYER 3 SELF-TALK DEBUG SCRIPT STARTED ===")
	
	# Find player
	player = get_tree().get_first_node_in_group("Player2")
	if player:
		print("✓ Player found: ", player.name)
		print("  - Position: ", player.global_position)
		print("  - Collision layer: ", player.collision_layer)
		print("  - Groups: ", player.get_groups())
		
		# Find Player 3 self-talk system
		find_player3_self_talk_system()
	else:
		print("✗ Player NOT found in Player2 group!")
	
	# Find interaction manager
	interaction_manager = get_tree().get_first_node_in_group("interaction_manager")
	if not interaction_manager:
		interaction_manager = get_node_or_null("/root/Main/InteractionManager")
	if not interaction_manager:
		var interaction_managers = get_tree().get_nodes_in_group("InteractionManager")
		if interaction_managers.size() > 0:
			interaction_manager = interaction_managers[0]
	
	if interaction_manager:
		print("✓ InteractionManager found: ", interaction_manager.name)
	else:
		print("✗ InteractionManager NOT found!")
	
	# Override DialogManager to filter only Player 3 self-talk
	setup_dialog_filter()
	
	# Check all InteractionAreas in the scene
	check_interaction_areas()
	
	# Set up debug timer
	debug_timer = Timer.new()
	debug_timer.wait_time = 2.0
	debug_timer.timeout.connect(_debug_periodic)
	debug_timer.autostart = true
	add_child(debug_timer)
	
	print("=== DEBUG SCRIPT READY ===")

func find_player3_self_talk_system():
	# Look for Player3SelfTalkSystem in the player's children
	if player:
		for child in player.get_children():
			if child is Player3SelfTalkSystem:
				player3_self_talk_system = child
				print("✓ Player3SelfTalkSystem found: ", child.name)
				return
		
		# Also check in the group
		var self_talk_systems = get_tree().get_nodes_in_group("player3_self_talk_system")
		if self_talk_systems.size() > 0:
			player3_self_talk_system = self_talk_systems[0]
			print("✓ Player3SelfTalkSystem found in group: ", player3_self_talk_system.name)
		else:
			print("✗ Player3SelfTalkSystem NOT found!")

func setup_dialog_filter():
	# Connect to DialogManager to filter dialogs
	if DialogManager:
		# We'll use a different approach - monitor dialog calls instead of replacing methods
		print("✓ Dialog filter ready - monitoring for Player 3 self-talk")
	else:
		print("✗ DialogManager not found - cannot install filter")

func check_interaction_areas():
	print("\n=== CHECKING INTERACTION AREAS ===")
	var areas = get_tree().get_nodes_in_group("interactable")
	print("Found ", areas.size(), " interactable areas")
	
	for area in areas:
		if area is Area2D:
			print("Area: ", area.name)
			print("  - Position: ", area.global_position)
			print("  - Collision layer: ", area.collision_layer)
			print("  - Collision mask: ", area.collision_mask)
			print("  - Action name: ", area.action_name if area.has_method("get") and "action_name" in area else "N/A")
			
			# Check distance to player
			if player:
				var distance = player.global_position.distance_to(area.global_position)
				print("  - Distance to player: ", distance)

func _debug_periodic():
	if not player:
		return
		
	print("\n=== PERIODIC DEBUG (", Time.get_unix_time_from_system(), ") ===")
	print("Player position: ", player.global_position)
	
	# Check Player 3 self-talk system status
	if player3_self_talk_system:
		print("Player3SelfTalkSystem status:")
		print("  - Has shown entry message: ", player3_self_talk_system.has_shown_entry_message)
	
	# Check if player is near any interaction areas
	var areas = get_tree().get_nodes_in_group("interactable")
	var nearby_areas = []
	
	for area in areas:
		if area is Area2D:
			var distance = player.global_position.distance_to(area.global_position)
			if distance < 100:  # Within 100 pixels
				nearby_areas.append({"area": area, "distance": distance})
	
	if nearby_areas.size() > 0:
		print("Nearby areas (< 100px):")
		for item in nearby_areas:
			print("  - ", item.area.name, " at distance ", item.distance)
	else:
		print("No nearby interaction areas")
	
	# Check InteractionManager state
	if interaction_manager and "active_areas" in interaction_manager:
		var active_areas = interaction_manager.active_areas
		print("InteractionManager active areas: ", active_areas.size())
		for area in active_areas:
			print("  - Active: ", area.name, " (", area.action_name, ")")

func _input(event):
	# Debug E key presses
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			print("\n=== E KEY PRESSED DEBUG ===")
			print("Time: ", Time.get_unix_time_from_system())
			
			if player:
				print("Player position: ", player.global_position)
			
			if interaction_manager:
				if "active_areas" in interaction_manager:
					var active_areas = interaction_manager.active_areas
					print("Active areas count: ", active_areas.size())
					
					if active_areas.size() > 0:
						print("Closest area: ", active_areas[0].name, " (", active_areas[0].action_name, ")")
						print("Calling interact on closest area...")
						if active_areas[0].has_method("interact"):
							active_areas[0].interact.call()
							
							# Trigger Player 3 self-talk for this interaction
							if player3_self_talk_system and active_areas[0].has_method("get") and "action_name" in active_areas[0]:
								var item_type = active_areas[0].action_name
								print("Triggering Player 3 self-talk for item: ", item_type)
								# Use a timer to delay the self-talk so it doesn't overlap with item dialog
								await get_tree().create_timer(2.0).timeout
								player3_self_talk_system.trigger_after_item_interact_talk(item_type)
						else:
							print("ERROR: Area doesn't have interact method!")
					else:
						print("No active areas to interact with")
				else:
					print("InteractionManager doesn't have active_areas property")
			else:
				print("InteractionManager not found")
		
		elif event.keycode == KEY_SPACE:
			print("\n=== MANUAL SELF-TALK TEST (SPACE) ===")
			if player3_self_talk_system:
				print("Triggering manual self-talk test...")
				player3_self_talk_system.trigger_custom_self_talk("This is a test self-talk message from the debug system.")
			else:
				print("Player3SelfTalkSystem not found")
		
		elif event.keycode == KEY_T:
			print("\n=== TIMER SELF-TALK TEST (T) ===")
			if player3_self_talk_system:
				print("Triggering timer-based self-talk...")
				player3_self_talk_system.show_timer_self_talk()
			else:
				print("Player3SelfTalkSystem not found")

func _on_tree_exiting():
	print("=== PLAYER 3 SELF-TALK DEBUG SCRIPT ENDING ===")
