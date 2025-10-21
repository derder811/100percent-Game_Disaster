extends Area2D

func _ready():
	# Connect the area_entered signal to detect when player enters
	area_entered.connect(_on_area_entered)
	print("Food Section 1 initialized")

func _on_area_entered(area):
	# Check if the entering area is an InteractionArea
	if area.name == "InteractionArea":
		print("Player near Food Section 1 - interaction available")

func _on_interact():
	print("Examining Food Section 1...")
	# Add your interaction logic here
	
	# Trigger self-talk for Player 3 if they're the one interacting
	var player = get_tree().get_first_node_in_group("Player2")
	if player and player.has_method("trigger_item_self_talk"):
		player.trigger_item_self_talk("food_section")