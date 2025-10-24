extends Node

@onready var dialog_scene = preload("res://SimpleDialog.tscn")
var current_dialog: Node

var safety_tips = {
	# Interactive assets (Scenario 1)
	"window": "Close windows securely to prevent water and wind damage.",
	"tv": "Monitor reliable news sources for weather advisories and evacuation.",
	"fuse_box": "Cut power if flooding risk rises to avoid electrocution.",
	"candle": "Avoid candles during storms; use flashlights to prevent fires.",
	"bucket": "Use buckets to manage leaks and keep floors dry.",
	"e_fan": "Unplug electric fans if water is present to avoid shocks.",
	"frying_pan": "Turn off heat and secure cookware to prevent accidents.",

	# Pickable / inventory items (keys used across scripts)
	"go_bag": "Prepare a go bag with essentials: water, food, meds, documents.",
	"mobile_phone": "Keep your phone charged to receive emergency alerts.",
	"phone": "Keep your phone charged to receive emergency alerts.",
	"powerbank": "Charge a power bank to keep devices powered during outages.",
	"power_bank": "Charge a power bank to keep devices powered during outages.",
	"battery": "Stock spare batteries for flashlights and radios.",
	"flashlight": "Use a flashlight instead of candles to avoid fire hazards.",
	"documents": "Store IDs and important papers in waterproof containers.",
	"canned_food": "Choose non-perishable food; check expirations and avoid damaged cans.",
	"water_bottle": "Store bottled water; aim for at least 3 liters per person per day.",
	"bottled_water": "Store bottled water; aim for at least 3 liters per person per day.",
	"first_aid_kit": "Keep a first-aid kit accessible for minor injuries.",
	"medkit": "Keep a first-aid kit accessible for minor injuries.",
	"medicine_2": "Secure maintenance meds and check expirations.",
	"medicine_3": "Pack prescription meds and dosage instructions.",
}

func show_safety_tips(asset_type: String, position: Vector2, header: String = "TIPS", footer_hint: String = "Close (Space / Interact)"):
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

# Optional: expose a start_dialog API for systems expecting DialogManager-like interface
func start_dialog(position: Vector2, lines: Array[String], header: String = "TIPS", footer_hint: String = "Close (Space / Interact)") -> Node:
	# Close existing dialog if any
	if current_dialog:
		if is_instance_valid(current_dialog):
			current_dialog.queue_free()
		current_dialog = null
	# Combine lines into text
	var text := "".join(lines)
	if text == "":
		text = ""
	# Create and show dialog
	current_dialog = dialog_scene.instantiate()
	get_tree().root.add_child(current_dialog)
	current_dialog.show_dialog(text, position, header, footer_hint)
	return current_dialog

# Helpers to reposition current dialog when following player
func set_current_dialog_position(pos: Vector2):
	if current_dialog and is_instance_valid(current_dialog):
		current_dialog.global_position = pos

func move_dialog_to(pos: Vector2):
	set_current_dialog_position(pos)
