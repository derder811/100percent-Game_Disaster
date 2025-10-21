extends Node2D

func _ready():
	print("Test dialog script ready")
	# Wait a moment then test dialog
	await get_tree().create_timer(1.0).timeout
	test_dialog()

func test_dialog():
	print("Testing DialogManager...")
	var test_position = Vector2(400, 300)  # Center of screen
	var test_lines = ["This is a test dialog", "Testing safety tip display"]
	
	DialogManager.start_dialog(test_position, test_lines, "power_bank")
	print("Dialog test initiated")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			print("T key pressed - testing dialog again")
			test_dialog()