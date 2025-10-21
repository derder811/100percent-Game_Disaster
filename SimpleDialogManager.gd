extends Node

@onready var dialog_scene = preload("res://SimpleDialog.tscn")
var current_dialog = null

# Safety tips for different assets
var safety_tips = {
	"window": "Stay away from windows during a typhoon. Strong winds can shatter glass or blow debris inside, so it's \n safest to stay in the inner part of the house.",
	"tv": "Always monitor weather updates from PAGASA, NDRRMC, or local news for safety alerts and evacuation \n instructions.",
	"fuse_box": "During a typhoon, turn off the main power switch if flooding begins or there's frequent lightning. This \n helps prevent electrical shocks and fire hazards. Stay dry and use a flashlight instead of touching any wet \n electrical parts.",
	"go_bag": "Prepare a Go Bag with water, food, medicine, flashlight, batteries, and important documents for quick evacuation.",
	"candle": "Avoid using candles during a typhoon. Use a flashlight or battery-powered lamp to prevent fire accidents.\n\nStore important documents like IDs and certificates in waterproof containers.",
	"flashlight": "Keep a working flashlight ready at all times. Check batteries regularly. Avoid using candles.",
	"battery": "Always prepare an extra batteries for your flashlight incase the power outage last long.",
	"documents": "Store important documents like IDs and certificates in waterproof containers",
	"canned_food": "Stock up on non-perishable food like canned goods that don't need cooking.",
	"bottled_water": "During typhoons, tap water can become unsafe to drink. Store clean bottled water ahead of time for \n drinking and basic needs.",
	"first_aid_kit": "Keep a complete first aid kit in a waterproof container for injuries or emergencies.",
	"medicine_2": "Always keep antibiotics and prescribed medicines incase you need them during typhoon. ",
	"medicine_3": "Always include basic medicine for pain, fever, or colds in your emergency supplies.",
	"mobile_phone": "Keep your mobile phone charged and nearby during a typhoon for emergency alerts and communication. \n Save battery by using it only when needed.",
	"power_bank": "Keep a fully charged power bank ready before the storm. It's essential for communication when electricity is down.",
	"bucket": "• Store clean water in buckets before a typhoon in case water supply gets cut off\n• Collect rainwater during the storm for non-drinking purposes\n• Keep containers covered to prevent contamination",
	"e_fan": "ELECTRICAL TIPS:\n• Check cords for damage before use\n• Keep electrical devices away from water\n• Don't overload electrical outlets\n• Have backup power sources ready\n• Know how to shut off main electrical breaker",
	"frying_pan": "COOKING TIPS:\n• Never leave cooking unattended\n• Keep pot handles turned inward\n• Have a fire extinguisher nearby\n• Know how to turn off gas/electricity quickly\n• Keep flammable items away from heat sources",
	"earthquake_welcome": "It’s a calm afternoon. The sun is high, and the street feels peaceful as people go about their day. You stop in front of a small grocery store, thinking of picking up a few items before heading home."
}

func show_safety_tips(asset_type: String, position: Vector2, header: String = "TIPS", footer_hint: String = "Close(Space)"):
	print("SimpleDialogManager.show_safety_tips called for: ", asset_type)
	
	# Close existing dialog if any
	if current_dialog:
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null
	
	# Get safety tip for this asset
	var tip = safety_tips.get(asset_type, "No safety information available for this item.")
	
	# Create and show dialog
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(tip, position, header, footer_hint)
	
	print("Safety tips dialog created and shown")

func show_item_dialog(item_name: String, position: Vector2):
	print("SimpleDialogManager.show_item_dialog called for: ", item_name)
	
	# Close existing dialog if any
	if current_dialog:
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null
	
	# Get safety tip for this item
	var tip = safety_tips.get(item_name, "No safety information available for this item.")
	var dialog_text = "Item picked up: " + item_name.capitalize() + "\n\nTip: " + tip
	
	# Create and show dialog
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(dialog_text, position)
	
	print("Dialog created and shown")

func hide_current_dialog():
	if current_dialog:
		current_dialog.hide_dialog()
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null