extends NinePatchRect

@onready var label = $MarginContainer/Label
@onready var timer = $Timer
@onready var auto_hide_timer = $AutoHideTimer
@onready var continue_label = $ContinueLabel

const MIN_WIDTH = 200
const MAX_WIDTH = 600
const PADDING = 32  # Extra padding for comfortable reading

var text = ""
var letter_index = 0
var is_text_complete = false
var is_being_freed = false  # Flag to prevent multiple queue_free calls

var letter_time = 0.005  # Much faster - was 0.02
var space_time = 0.01    # Much faster - was 0.04
var punctuation_time = 0.03  # Much faster - was 0.15

# Safety tips for different assets - combined into single messages
var safety_tips = {
	"window": [
		"Stay away from windows during a typhoon. Strong winds can shatter glass or blow debris inside, so it's safest to stay in the inner part of the house."
	] as Array[String],
	"tv": [
		"Always monitor weather updates from PAGASA, NDRRMC, or local news for safety alerts and evacuation instructions."
	] as Array[String],
	"fuse_box": [
		"During a typhoon, turn off the main power switch if flooding begins or there's frequent lightning. This helps prevent electrical shocks and fire hazards. Stay dry and use a flashlight instead of touching any wet electrical parts."
	] as Array[String],
	"go_bag": [
		"Prepare a Go Bag with water, food, medicine, flashlight, batteries, and important documents for quick evacuation."
	] as Array[String],
	"candle": [
		"Avoid using candles during a typhoon. Use a flashlight or battery-powered lamp to prevent fire accidents."
	] as Array[String],
	"flashlight": [
		"Keep a working flashlight ready at all times. Check batteries regularly. Avoid using candles."
	] as Array[String],
	"battery": [
		"Always prepare an extra batteries for your flashlight incase the power outage last long."
	] as Array[String],
	"documents": [
		"Store important documents like IDs and certificates in waterproof containers"
	] as Array[String],
	"canned_food": [
		"Stock up on non-perishable food like canned goods that don't need cooking."
	] as Array[String],
	"bottled_water": [
		"During typhoons, tap water can become unsafe to drink. Store clean bottled water ahead of time for drinking and basic needs."
	] as Array[String],
	"first_aid_kit": [
		"Keep a complete first aid kit in a waterproof container for injuries or emergencies if you have one."
	] as Array[String],
	"medicine_2": [
		"Always keep antibiotics and prescribed medicines incase you need them during typhoon."
	] as Array[String],
	"medicine_3": [
		"Always include basic medicine for pain, fever, or colds in your emergency supplies."
	] as Array[String],
	"mobile_phone": [
		"Keep your mobile phone charged and nearby during a typhoon for emergency alerts and communication. Save battery by using it only when needed."
	] as Array[String],
	"power_bank": [
		"Keep a fully charged power bank ready before the storm. It's essential for communication when electricity is down."
	] as Array[String],
	"bucket": [
		"Always keep clean water stored in a bucket before a typhoon incase the water supply gets cut off."
	] as Array[String],
	"e_fan": [
		"ELECTRICAL TIPS:
			 Check cords for damage before use. 
			 Keep electrical devices away from water. 
			 Don't overload electrical outlets. 
			 Have backup power sources ready.
			  Know how to shut off main electrical breaker."
	] as Array[String],
	"frying_pan": [
		"COOKING TIPS: 
			Never leave cooking unattended. 
			Keep pot handles turned inward. 
			Have a fire extinguisher nearby. 
			Know how to turn off gas/electricity quickly. 
			Keep flammable items away from heat sources."
	] as Array[String]
}

var current_asset_type = ""

signal finished_displaying()

func _ready():
	set_process_input(true)
	if continue_label:
		continue_label.visible = false

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and is_text_complete and not is_being_freed:
			print("Spacebar pressed - closing text box")
			# Stop the auto-hide timer if spacebar is pressed
			if auto_hide_timer and auto_hide_timer.time_left > 0:
				auto_hide_timer.stop()
				print("Stopped auto-hide timer due to spacebar press")
			is_being_freed = true
			queue_free()

func _show_safety_tips_dialog():
	print("Current asset type: ", current_asset_type)  # Debug print
	
	# Only show dialog if there's a valid asset type
	if current_asset_type == "":
		print("No asset type set - closing text box without showing dialog")
		if not is_being_freed:
			is_being_freed = true
			queue_free()
		return
	
	# Find the DialogBox node in the scene
	var dialog_box = get_tree().get_first_node_in_group("dialog_system")
	if dialog_box and dialog_box.has_method("show_dialog"):
		var tips: Array[String] = safety_tips.get(current_asset_type, ["No safety tips available for this item."] as Array[String])
		print("Safety tips found: ", tips)  # Debug print
		dialog_box.show_dialog("TIPS", tips)
	else:
		print("DialogBox not found or doesn't have show_dialog method")
	
	# Close the text box after showing safety tips
	if not is_being_freed:
		is_being_freed = true
		queue_free()

func display_text(text_to_display: String):
	print("display_text called with: ", text_to_display)
	text = text_to_display
	is_text_complete = false
	
	# Hide continue label initially
	if continue_label:
		continue_label.visible = false
	
	# Set text temporarily to measure size
	label.text = text_to_display
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	# Force update to get accurate size
	await get_tree().process_frame
	
	# Calculate optimal width based on label size
	var text_width = label.get_theme_font("font").get_string_size(
		text_to_display, 
		HORIZONTAL_ALIGNMENT_LEFT, 
		-1, 
		label.get_theme_font_size("font_size")
	).x
	
	var optimal_width = text_width + PADDING * 2
	optimal_width = clamp(optimal_width, MIN_WIDTH, MAX_WIDTH)
	
	# Set the size
	custom_minimum_size.x = optimal_width
	size.x = optimal_width
	
	# Enable word wrap and set proper sizing
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	await get_tree().process_frame
	custom_minimum_size.y = label.size.y + 24  # Add vertical padding
	
	# Position the dialog box
	global_position.x -= size.x / 2
	global_position.y -= size.y + 24
	
	print("Text box positioned at: ", global_position, " with size: ", size)
	
	# Clear text and start letter-by-letter display
	label.text = ""
	letter_index = 0
	_display_letter()

func _display_letter():
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		is_text_complete = true
		# Show continue label when text is complete
		if continue_label:
			continue_label.visible = true
		
		# Start 7-second auto-hide timer for Player 3 self-talk
		if auto_hide_timer:
			auto_hide_timer.wait_time = 7.0
			auto_hide_timer.start()
			print("Started 7-second auto-hide timer for self-talk")
		return
	
	match text[letter_index]:
		"!", ".", ",", "?":
			if timer:  # Add null check
				timer.start(punctuation_time)
		" ":
			if timer:  # Add null check
				timer.start(space_time)
		_:
			if timer:  # Add null check
				timer.start(letter_time)
			

func _on_timer_timeout() -> void:
	_display_letter()

func _on_auto_hide_timer_timeout() -> void:
	# Auto-hide after 7 seconds for Player 3 self-talk
	print("Auto-hide timer expired - closing text box")
	if not is_being_freed:
		is_being_freed = true
		queue_free()
