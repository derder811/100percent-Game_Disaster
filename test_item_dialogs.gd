extends Node2D

func _ready():
	print("Test item dialogs script ready")
	# Wait a moment then test dialogs
	await get_tree().create_timer(1.0).timeout
	test_all_item_dialogs()

func test_all_item_dialogs():
	print("Testing all item dialogs...")
	
	# Test powerbank dialog
	print("Testing powerbank dialog...")
	SimpleDialogManager.show_item_dialog("powerbank", Vector2(400, 300))
	
	await get_tree().create_timer(3.0).timeout
	
	# Test other items
	var items_to_test = [
		"phone",
		"battery", 
		"flashlight",
		"documents",
		"water_bottle",
		"canned_food",
		"medicine_2"
	]
	
	for item in items_to_test:
		print("Testing ", item, " dialog...")
		SimpleDialogManager.show_item_dialog(item, Vector2(400, 300))
		await get_tree().create_timer(2.0).timeout

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Space or Enter
		print("Testing powerbank dialog on demand...")
		SimpleDialogManager.show_item_dialog("powerbank", Vector2(400, 300))