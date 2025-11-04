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

# Pending self-talk voice path to play after text becomes visible
var pending_voice_path: String = ""
var pending_voice_category: String = ""
var has_played_pending_voice: bool = false

# Time-based visual highlight while voice plays
var _highlight_indicator: Control = null
var _highlight_timer: Timer = null

var letter_time = 0.005  # Much faster - was 0.02
var space_time = 0.01    # Much faster - was 0.04
var punctuation_time = 0.03  # Much faster - was 0.15

# Safety tips for different assets - combined into single messages
var safety_tips = {
	"window": [
		"Stay away from windows during a typhoon. Strong winds can shatter glass or blow debris inside."
	] as Array[String],
	"tv": [
		"Always monitor weather updates from PAGASA, NDRRMC, or local news for safety alerts and evacuation instructions."
	] as Array[String],
	"fuse_box": [
		"During a typhoon, turn off the main power switch if flooding begins or there's frequent lightning. "
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
	
	# Detect target self-talk lines and defer audio until text starts rendering
	var voice_info := _map_voice_for_text(text_to_display)
	pending_voice_path = voice_info.get("path", "")
	pending_voice_category = voice_info.get("category", "")
	has_played_pending_voice = false
	
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
	
	# Play pending voice line once after text starts rendering
	if not has_played_pending_voice and pending_voice_path != "":
		var audio_mgr = null
		if typeof(AudioManager) != TYPE_NIL:
			audio_mgr = AudioManager
		else:
			audio_mgr = get_tree().get_root().get_node_or_null("/root/AudioManager")
		if audio_mgr and audio_mgr.has_method("play_sfx"):
			audio_mgr.play_sfx(pending_voice_path, 4.0)
			var dur := _get_audio_length(pending_voice_path)
			_start_voice_highlight(pending_voice_category, dur)
			has_played_pending_voice = true
		else:
			print("AudioManager not found; cannot play pending voice line")
	
	letter_index += 1
	if letter_index >= text.length():
		finished_displaying.emit()
		is_text_complete = true
		# Show continue label when text is complete
		if continue_label:
			continue_label.visible = true
		
		# Start 2-second auto-hide timer for Player 3 self-talk
		if auto_hide_timer:
			auto_hide_timer.wait_time = 2.0
			auto_hide_timer.start()
			print("Started 2-second auto-hide timer for self-talk")
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

# ===== Time-based voice highlight helpers =====
func _map_voice_for_text(msg: String) -> Dictionary:
	var m := String(msg)
	# Default mapping
	var result := {"path": "", "category": ""}
	# Store entry
	if m.find("Oh hey, a convenience store") != -1 or m.find("I need to cover all areas of the store") != -1 or m.find("Maybe there's something useful here") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Store Entry) - Copy.mp3"
		result.category = "store_entry"
		return result
	# Exit
	if m.find("exit") != -1 or m.find("time to leave") != -1 or m.find("get out") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/i should head to the exit.mp3"
		result.category = "exit"
		return result
	# Food section
	if m.find("What's in this section") != -1 or m.find("food section") != -1 or m.find("whats in this section") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Food Section) - Copy.mp3"
		result.category = "food_section"
		return result
	# Snacks
	if m.find("snacks") != -1 or m.find("chips") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Snacks) - Copy.mp3"
		result.category = "snacks"
		return result
	# Ice cream
	if m.find("Ice cream") != -1 or m.find("frozen") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Ice Cream) - Copy.mp3"
		result.category = "ice_cream"
		return result
	# Meat
	if m.find("meat") != -1 or m.find("beef") != -1 or m.find("pork") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Meat) - Copy.mp3"
		result.category = "meat"
		return result
	# Hotdog/Siopao
	if m.find("hotdog") != -1 or m.find("siopao") != -1 or m.find("hotpao") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (HotPao) (1).mp3"
		result.category = "hotpao"
		return result
	# Slurpee
	if m.find("slurpee") != -1 or m.find("drink") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Slurpee) - Copy.mp3"
		result.category = "slurpee"
		return result
	# General fridge
	if m.find("fridge") != -1 or m.find("refrigerator") != -1:
		result.path = "res://PLayer insteraction Talking and pick up talking/Music/earthquakeSOUND/Self Talk (Fridge) (1).mp3"
		result.category = "fridge"
		return result
	return result

func _get_audio_length(path: String) -> float:
	var stream: AudioStream = load(path)
	if stream == null:
		return 2.0
	var len := 2.0
	if stream is AudioStreamMP3:
		len = (stream as AudioStreamMP3).get_length()
	elif stream is AudioStreamOggVorbis:
		len = (stream as AudioStreamOggVorbis).get_length()
	elif stream is AudioStreamWAV:
		len = (stream as AudioStreamWAV).get_length()
	return max(len, 0.5)

func _category_color(cat: String) -> Color:
	match cat:
		"ice_cream":
			return Color(0.4, 0.7, 1.0, 0.8)
		"meat":
			return Color(0.9, 0.3, 0.3, 0.8)
		"hotpao":
			return Color(0.95, 0.6, 0.2, 0.8)
		"snacks":
			return Color(1.0, 0.9, 0.2, 0.8)
		"food_section":
			return Color(0.3, 0.9, 0.6, 0.8)
		"fridge":
			return Color(0.6, 0.9, 1.0, 0.8)
		"slurpee":
			return Color(0.4, 0.4, 1.0, 0.8)
		"store_entry":
			return Color(0.8, 0.8, 0.8, 0.8)
		"exit":
			return Color(0.6, 0.6, 0.6, 0.8)
		_:
			return Color(1, 1, 1, 0.6)

func _start_voice_highlight(category: String, duration: float) -> void:
	_clear_voice_highlight()
	if category == "":
		return
	# Create a small pulsing color tag with category text
	var container := HBoxContainer.new()
	container.name = "VoiceHighlight"
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(container)
	# Position near top-left of the textbox
	container.position = Vector2(8, -28)
	var rect := ColorRect.new()
	rect.color = _category_color(category)
	rect.size = Vector2(110, 24)
	container.add_child(rect)
	var tag := Label.new()
	tag.text = category.capitalize().replace("_", " ")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.size = rect.size
	rect.add_child(tag)
	_highlight_indicator = container
	# Pulse tween
	var t := create_tween()
	t.set_loops(ceil(duration / 0.6))
	t.tween_property(rect, "modulate:a", 0.4, 0.3)
	t.tween_property(rect, "modulate:a", 0.9, 0.3)
	# Clear after duration
	_highlight_timer = Timer.new()
	_highlight_timer.one_shot = true
	_highlight_timer.wait_time = duration
	add_child(_highlight_timer)
	_highlight_timer.start()
	_highlight_timer.timeout.connect(_clear_voice_highlight)

func _clear_voice_highlight() -> void:
	if _highlight_timer != null and is_instance_valid(_highlight_timer):
		_highlight_timer.stop()
		_highlight_timer.queue_free()
		_highlight_timer = null
	if _highlight_indicator != null and is_instance_valid(_highlight_indicator):
		_highlight_indicator.queue_free()
		_highlight_indicator = null
