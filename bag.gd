extends Control

@onready var bagContainer = $NinePatchRect
@onready var itemsInContainer = $NinePatchRect/MarginContainer/slotitem

var items = []

func get_items(itemData):
	items.append(itemData)
	print("=== BAG DEBUG ===")
	print("Item received in bag: ", itemData)
	print("Total items in bag: ", items.size())
	print("Emergency items count: ", get_emergency_items_count())
	print("=================")
	refresh_ui()
	
	# Update quest progress when items are added
	update_quest_progress()

func add_item(item_data: Dictionary):
	print("=== BAG ADD_ITEM DEBUG ===")
	print("Adding item to bag: ", item_data)
	print("Item has 'name' key: ", "name" in item_data)
	if "name" in item_data:
		print("Item name: '", item_data["name"], "'")
		print("Item name type: ", typeof(item_data["name"]))
	print("Current items count before adding: ", items.size())
	
	items.append(item_data)
	print("Current items count after adding: ", items.size())
	print("All items in bag:")
	for i in range(items.size()):
		print("  Item ", i, ": ", items[i])
	
	# Update quest progress after adding item
	update_quest_progress()
	print("=========================")

func get_emergency_items_count():
	print("=== GET_EMERGENCY_ITEMS_COUNT DEBUG ===")
	print("Total items in bag: ", items.size())
	
	# Emergency item names - exact names from scripts (case-insensitive)
	var emergency_item_names = [
		"powerbank",
		"phone",
		"documents", 
		"first aid kit",
		"battery",
		"flashlight",
		"canned food",
		"water bottle",
		"medicine 3"
	]
	
	print("Looking for emergency items: ", emergency_item_names)
	
	var count = 0
	for i in range(items.size()):
		var item = items[i]
		print("Checking item ", i, ": ", item)
		
		if "name" in item:
			var item_name = item["name"].to_lower()
			print("  Item name (lowercase): '", item_name, "'")
			
			# Check if the item name matches any emergency item (case-insensitive)
			var is_emergency = false
			for emergency_name in emergency_item_names:
				if item_name == emergency_name:
					print("  MATCH FOUND! '", item_name, "' matches '", emergency_name, "'")
					is_emergency = true
					break
			
			if is_emergency:
				count += 1
				print("  Emergency item count increased to: ", count)
			else:
				print("  Not an emergency item")
		else:
			print("  Item has no 'name' key")
	
	print("Final emergency items count: ", count)
	print("======================================")
	return count

func update_quest_progress():
	print("=== UPDATE_QUEST_PROGRESS DEBUG ===")
	var emergency_count = get_emergency_items_count()
	print("Emergency items count: ", emergency_count)
	
	# Find the quest node in the scene tree
	var quest_manager = null
	var scene = get_tree().current_scene
	
	if scene:
		print("Current scene: ", scene.name)
		print("Scene children:")
		for child in scene.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
			if child.get_script() and child.get_script().get_path().ends_with("quest.gd"):
				quest_manager = child
				print("✓ Found quest node: ", child.name)
				break
		
		# If not found directly, search recursively
		if not quest_manager:
			quest_manager = scene.find_child("Quest", true, false)
			if quest_manager:
				print("✓ Found Quest node via find_child")
			else:
				# Try to find any node with quest.gd script
				quest_manager = _find_quest_node_recursive(scene)
				if quest_manager:
					print("✓ Found quest node recursively: ", quest_manager.name)
	
	if quest_manager and quest_manager.has_method("update_emergency_items_ui"):
		print("✓ Quest manager found, calling update_emergency_items_ui()")
		print("Emergency items count being sent: ", emergency_count)
		quest_manager.update_emergency_items_ui()
	else:
		print("✗ ERROR: Quest manager not found or doesn't have update_emergency_items_ui method")
		print("quest_manager exists: ", quest_manager != null)
		if quest_manager:
			print("Available methods: ", quest_manager.get_method_list())
	print("==================================")
	refresh_ui()

func _find_quest_node_recursive(node: Node) -> Node:
	# Check if this node has the quest script
	if node.get_script() and node.get_script().get_path().ends_with("quest.gd"):
		return node
	
	# Check children recursively
	for child in node.get_children():
		var result = _find_quest_node_recursive(child)
		if result:
			return result
	
	return null

func refresh_ui():
	var allItemSlots = itemsInContainer.get_children()
	print("Number of slots: ", allItemSlots.size())
	print("Number of items: ", items.size())
	
	for i in len(items):
		if i < allItemSlots.size():
			var itemData = items[i]
			if "icon" in itemData and itemData["icon"] != null:
				allItemSlots[i].texture = itemData["icon"]
				print("Setting slot ", i, " with item: ", itemData["name"])
			else:
				print("Item ", itemData["name"], " has no valid icon")

func _on_texture_button_pressed():
	bagContainer.visible = !bagContainer.visible
	print("Bag visibility toggled: ", bagContainer.visible)
	if bagContainer.visible:
		print("Bag is now visible, showing ", items.size(), " items")
		print("Emergency items count: ", get_emergency_items_count())
