extends Control

@onready var bagContainer = $NinePatchRect
@onready var itemsInContainer = $NinePatchRect/MarginContainer/slotitem
@onready var toggle_button = $TextureButton

func _ready():
	# Ensure the bag UI starts hidden and clickable
	if toggle_button:
		toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
		toggle_button.disabled = false
	if bagContainer:
		bagContainer.visible = false
		bagContainer.z_index = 1
	# Move Bag to a dedicated top CanvasLayer so it is always clickable
	var scene = get_tree().current_scene
	if scene:
		var bag_layer: CanvasLayer = scene.get_node_or_null("UILayer_Bag")
		if not bag_layer:
			bag_layer = CanvasLayer.new()
			bag_layer.name = "UILayer_Bag"
			bag_layer.layer = 200
			scene.add_child(bag_layer)
		if get_parent() != bag_layer:
			var p = get_parent()
			if p:
				p.remove_child(self)
			bag_layer.add_child(self)
	print("Bag UI ready; click the backpack to toggle inventory.")

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
	]
	
	var emergency_count = 0
	for item in items:
		if item.has("name"):
			var item_name_lower = String(item["name"]).to_lower()
			if item_name_lower in emergency_item_names:
				emergency_count += 1
	print("Emergency items in bag: ", emergency_count)
	return emergency_count

func update_quest_progress():
	print("=== UPDATE QUEST PROGRESS CALLED ===")
	var emergency_count = get_emergency_items_count()
	var scene = get_tree().current_scene
	var quest_manager: Node = null
	if scene:
		# Try direct child lookup first
		for child in scene.get_children():
			if child.name == "Quest":
				quest_manager = child
				print("✓ Found quest node: ", child.name)
				break
		
		# If not found, search recursively
		if not quest_manager:
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

	# Update slot textures to reflect current items
	for i in range(allItemSlots.size()):
		if i < items.size():
			var itemData = items[i]
			if "icon" in itemData and itemData["icon"] != null:
				allItemSlots[i].texture = itemData["icon"]
				print("Setting slot ", i, " with item: ", itemData.get("name", "<unnamed>"))
			else:
				print("Item has no valid icon: ", itemData)
		else:
			# Clear remaining slots
			allItemSlots[i].texture = null

func _on_texture_button_pressed():
	# Toggle visibility and refresh contents
	bagContainer.visible = !bagContainer.visible
	refresh_ui()
	print("Bag visibility toggled: ", bagContainer.visible)
	if bagContainer.visible:
		print("Bag is now visible, showing ", items.size(), " items")
		print("Emergency items count: ", get_emergency_items_count())
