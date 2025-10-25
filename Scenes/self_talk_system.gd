extends Node2D
class_name SelfTalkSystem

# Self-talk messages for different scenarios
var self_talk_messages = {
	"game_start": [
		"It's early in the morning. Heavy rain pours outside as strong winds shake the trees. A typhoon is approaching, and you're the only one left at home. Your goal is to stay safe and prepare for the storm by gathering important items and taking the right precautions."
 
	] as Array[String],
	"timer_based": [
		"Its raining hard.",
		"It's really pouring out there...",
		"I know i kept some supplies somewhere...",
		"Feels a bit eerie being alone.",
		"I can hear the rain hitting the walls..."
	] as Array[String],
	"item_pickup": {
		"flashlight": "Good thing the flashlight still works.",
		"battery": "Extra batteries—perfect. I'll save these for the flashlight.",
		"documents": "These documents are important... Gonna keep them on my bag",
		"canned_food": "Good thing there are still some canned foods left.",
		"water_bottle": "I'll keep these bottled waters ready... the tap might get contaminated later.",
		"medkit": "Good.. Everything's here — bandages, alcohol, medicine.",
		"medicine_2": "Good thing I still have some antibiotics left... just in case anyone gets an infection after the storm.",
		"medicine_3": "Painkillers and cold meds, these might come in handy if anyone feels sick.",
		"mobile_phone": "Signal's weak... I'll keep my phone on me, just in case of any emergency or updates.",
		"powerbank": "This power bank will be useful to keep my phone charged during emergencies.",
		"go_bag": "Gonna find some food, water, and medicine… anything essential before things get worse.",
		"candle": "I'll use this if the power goes out... but maybe a flashlight is safer. I don't want to cause a fire."
	}
}

# Store-style after-interact messages (for scenes where items are browsed)
var after_item_interact_msgs := {
	"snacks": "Ooh, snacks! Always hard to choose... do I go salty or sweet?",
	"fridge": "Hmm... beverages.",
	"slurpee": "DROP COVER AND HOLD",
	"ice_cream_fridge": "Ice cream won't last long without power, but maybe there are other frozen goods.",
	"meat_fridge": "Frozen meat could be useful if I can cook it before the power goes out completely.",
	"hotdog_siopao": "Hotdog or siopao? Man, tough choice. Maybe HotPao?.",
	"food_section": "Let's see what they've got here... canned stuff, quick bites. Pretty standard."
}

# Map item keys to corresponding self-talk audio clip paths
var item_audio_paths := {
	"go_bag": "res://PLayer insteraction Talking and pick up talking/Self Talk (Bag).mp3",
	"battery": "res://PLayer insteraction Talking and pick up talking/Self Talk (Battery).mp3",
	"water_bottle": "res://PLayer insteraction Talking and pick up talking/Self Talk (Bottled Water).mp3",
	"candle": "res://PLayer insteraction Talking and pick up talking/Self Talk (Candle).mp3",
	"canned_food": "res://PLayer insteraction Talking and pick up talking/Self Talk (Canned Foods).mp3",
	"documents": "res://PLayer insteraction Talking and pick up talking/Self Talk (Documents).mp3",
	"medkit": "res://PLayer insteraction Talking and pick up talking/Self Talk (First Aid Kit).mp3",
	"fuse_box": "res://PLayer insteraction Talking and pick up talking/Self Talk (Fuse Box).mp3",
	"medicine_2": "res://PLayer insteraction Talking and pick up talking/Self-Talk-_Medicine-2_.mp3",
	"medicine_3": "res://PLayer insteraction Talking and pick up talking/Self Talk (Medicine 3).mp3",
	"mobile_phone": "res://PLayer insteraction Talking and pick up talking/Self Talk (Mobile Phone).mp3",
	"powerbank": "res://PLayer insteraction Talking and pick up talking/Self Talk (Power Bank).mp3",
	"tv": "res://PLayer insteraction Talking and pick up talking/Self Talk (TV).mp3",
	"bucket": "res://PLayer insteraction Talking and pick up talking/Self Talk (Water Bucket).mp3",
	"window": "res://PLayer insteraction Talking and pick up talking/Self Talk (Window).mp3",
	"flashlight": "res://PLayer insteraction Talking and pick up talking/Self-Talk-_Flash-Light_.mp3"
}

# New: Audio clips for timer-based self-talk (Typhoon movement-style lines)
var timer_audio_paths := [
	"res://typoon timer sound/Its raining hard.mp3",
	"res://typoon timer sound/It's really pouring out there... .mp3",
	"res://typoon timer sound/I know i kept some supplies somewhere... .mp3",
	"res://typoon timer sound/Feels a bit eerie being alone.mp3",
	"res://typoon timer sound/I can hear the rain hitting the walls... .mp3"
]
# Map specific timer-based text lines to their voice clips for exact pairing
var timer_audio_map := {
	"Its raining hard.": "res://typoon timer sound/Its raining hard.mp3",
	"It's really pouring out there...": "res://typoon timer sound/It's really pouring out there... .mp3",
	"I know i kept some supplies somewhere...": "res://typoon timer sound/I know i kept some supplies somewhere... .mp3",
	"Feels a bit eerie being alone.": "res://typoon timer sound/Feels a bit eerie being alone.mp3",
	"I can hear the rain hitting the walls...": "res://typoon timer sound/I can hear the rain hitting the walls... .mp3"
}

var has_shown_startup_message = false
var timer_self_talk_active = false
@onready var player = get_parent()

# Compact textbox UI
var _textbox_layer: CanvasLayer = null
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_active: bool = false
var _textbox_ttl_timer: Timer = null

func _ready():
	add_to_group("self_talk_system")
	await get_tree().create_timer(1.0).timeout
	show_startup_message()
	await get_tree().create_timer(2.0).timeout
	start_timer_self_talk()

func start_timer_self_talk():
	timer_self_talk_active = true
	_timer_self_talk_loop()

func stop_timer_self_talk():
	timer_self_talk_active = false

func _timer_self_talk_loop():
	while timer_self_talk_active:
		await get_tree().create_timer(30.0).timeout
		if not timer_self_talk_active:
			break
		if player == null or not is_instance_valid(player):
			continue
		# Safely check if any dialog is active; default to false if manager missing
		var dialog_active := false
		if typeof(DialogManager) != TYPE_NIL:
			dialog_active = DialogManager.is_dialog_active
		# Avoid overlapping with our own textbox being active
		if not dialog_active and not _textbox_active:
			show_timer_self_talk()

func show_timer_self_talk():
	var messages = self_talk_messages["timer_based"]
	var idx = randi() % messages.size()
	var message = messages[idx]
	print("TimerSelfTalk: showing message idx=", idx, " text=", message)
	_show_textbox(message)
	# Play the voice line mapped to the shown text; fallback to index mapping
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(message, "")
	if voice_path == "" and timer_audio_paths.size() > 0:
		var mapped_index = min(idx, timer_audio_paths.size() - 1)
		voice_path = timer_audio_paths[mapped_index]
	print("TimerSelfTalk: resolved voice_path=", voice_path)
	if voice_path != "":
		var audio_mgr = null
		if typeof(AudioManager) != TYPE_NIL:
			audio_mgr = AudioManager
		else:
			audio_mgr = get_tree().get_root().get_node_or_null("/root/AudioManager")
		if audio_mgr:
			print("TimerSelfTalk: playing SFX")
			audio_mgr.play_sfx(voice_path, 4.0)
			await audio_mgr.wait_sfx_finished()
		# After audio completes (or if none), show a simple tip near player
		_hide_textbox()
		var pos := Vector2.ZERO
		if player and is_instance_valid(player):
			pos = player.global_position + Vector2(0, -80)
		if typeof(SimpleDialogManager) != TYPE_NIL:
			SimpleDialogManager.start_dialog(pos, ["Keep essentials ready and avoid risky areas."])

func show_startup_message():
	if has_shown_startup_message:
		return
	has_shown_startup_message = true
	var dialog_box = get_tree().get_first_node_in_group("dialog_system")
	if dialog_box and dialog_box.has_method("show_dialog"):
		dialog_box.show_dialog("WELCOME", self_talk_messages["game_start"])
		if not dialog_box.dialog_finished.is_connected(_on_startup_dialog_finished):
			dialog_box.dialog_finished.connect(_on_startup_dialog_finished)
	else:
		print("DialogBox not found for startup message")

func _on_startup_dialog_finished():
	await get_tree().create_timer(2.0).timeout
	show_self_talk_message()

func show_self_talk_message():
	# Use a mapped timer-based line and play its audio
	var first_message = "Its raining hard."
	_show_textbox(first_message)
	# Attempt to play matching audio for this line
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(first_message, "")
	if voice_path == "" and timer_audio_paths.size() > 0:
		voice_path = timer_audio_paths[0]
	if voice_path != "":
		var audio_mgr = null
		if typeof(AudioManager) != TYPE_NIL:
			audio_mgr = AudioManager
		else:
			audio_mgr = get_tree().get_root().get_node_or_null("/root/AudioManager")
		if audio_mgr:
			audio_mgr.play_sfx(voice_path, 4.0)
			await audio_mgr.wait_sfx_finished()
		else:
			print("SelfTalk startup: AudioManager not found; cannot play SFX")
			await get_tree().create_timer(1.0).timeout
		# Hide the self-talk textbox to avoid overlap
		_hide_textbox()
		# Determine dialog position near player
		var pos := Vector2.ZERO
		if player and is_instance_valid(player):
			pos = player.global_position + Vector2(0, -80)
		# Show a simple follow-up dialog near the player
		if typeof(SimpleDialogManager) != TYPE_NIL:
			SimpleDialogManager.start_dialog(pos, ["Stay calm and check essentials nearby."])
	else:
		# If no audio was played, still show the dialog after a short delay
		await get_tree().create_timer(1.0).timeout
		var pos2 := Vector2.ZERO
		if player and is_instance_valid(player):
			pos2 = player.global_position + Vector2(0, -80)
		if typeof(SimpleDialogManager) != TYPE_NIL:
			SimpleDialogManager.start_dialog(pos2, ["Stay calm and check essentials nearby."])

func trigger_custom_self_talk(custom_message: String):
	# Show text and try to play audio if the line is mapped
	_show_textbox(custom_message)
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(custom_message, "")
	if voice_path != "":
		var audio_mgr = null
		if typeof(AudioManager) != TYPE_NIL:
			audio_mgr = AudioManager
		else:
			audio_mgr = get_tree().get_root().get_node_or_null("/root/AudioManager")
			audio_mgr.play_sfx(voice_path, 4.0)

func trigger_self_talk(message_type: String = "timer_based"):
	if message_type in self_talk_messages:
		var messages = self_talk_messages[message_type]
		var idx = randi() % messages.size()
		var random_message = messages[idx]
		print("SelfTalk trigger: type=", message_type, " idx=", idx, " text=", random_message)
		_show_textbox(random_message)
		# If it's timer-based, use text→audio mapping; fallback to index mapping
		if message_type == "timer_based":
			var voice_path: String = ""
			if typeof(timer_audio_map) != TYPE_NIL:
				voice_path = timer_audio_map.get(random_message, "")
			if voice_path == "" and timer_audio_paths.size() > 0:
				var mapped_index = min(idx, timer_audio_paths.size() - 1)
				voice_path = timer_audio_paths[mapped_index]
			print("SelfTalk trigger: resolved voice_path=", voice_path)
			if voice_path != "":
				var audio_mgr = null
				if typeof(AudioManager) != TYPE_NIL:
					audio_mgr = AudioManager
				else:
					audio_mgr = get_tree().get_root().get_node_or_null("/root/AudioManager")
				if audio_mgr:
					print("SelfTalk trigger: playing SFX")
					audio_mgr.play_sfx(voice_path, 4.0)
				else:
					print("SelfTalk trigger: AudioManager not found; cannot play SFX")

func trigger_item_pickup_self_talk(item_name: String):
	if "item_pickup" in self_talk_messages and item_name in self_talk_messages["item_pickup"]:
		_show_textbox(self_talk_messages["item_pickup"][item_name])
	# Play associated self-talk audio if available
	var audio_path: String = item_audio_paths.get(item_name, "")
	if audio_path != "" and AudioManager:
		AudioManager.play_sfx(audio_path, 4.0)

func trigger_after_item_interact_talk(item_type: String):
	if after_item_interact_msgs.has(item_type):
		_show_textbox(after_item_interact_msgs[item_type])
	# Play associated self-talk audio if available for this interaction type
	var audio_path: String = item_audio_paths.get(item_type, "")
	if audio_path != "" and AudioManager:
		AudioManager.play_sfx(audio_path, 4.0)

# -----------------------------
# Centered-top textbox implementation
# -----------------------------
func _ensure_textbox_nodes():
	if _textbox_layer == null:
		_textbox_layer = CanvasLayer.new()
		_textbox_layer.layer = 150
		add_child(_textbox_layer)
	if _textbox_panel == null:
		_textbox_panel = Panel.new()
		# Anchor to top center
		_textbox_panel.anchor_left = 0.5
		_textbox_panel.anchor_right = 0.5
		_textbox_panel.anchor_top = 0.0
		_textbox_panel.anchor_bottom = 0.0
		# 560x160 box below the top HUD
		_textbox_panel.offset_left = -280
		_textbox_panel.offset_right = 280
		_textbox_panel.offset_top = 24
		_textbox_panel.offset_bottom = 184
		_textbox_panel.custom_minimum_size = Vector2(560, 160)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.75)
		sb.corner_radius_top_left = 10
		sb.corner_radius_top_right = 10
		sb.corner_radius_bottom_left = 10
		sb.corner_radius_bottom_right = 10
		_textbox_panel.add_theme_stylebox_override("panel", sb)
		_textbox_panel.visible = false
		# Allow bag clicks to pass through this overlay
		_textbox_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_textbox_layer.add_child(_textbox_panel)
	if _textbox_label == null:
		_textbox_label = Label.new()
		_textbox_label.anchor_left = 0.0
		_textbox_label.anchor_right = 1.0
		_textbox_label.anchor_top = 0.0
		_textbox_label.anchor_bottom = 1.0
		_textbox_label.offset_left = 18
		_textbox_label.offset_right = -18
		_textbox_label.offset_top = 12
		_textbox_label.offset_bottom = -12
		_textbox_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_textbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_textbox_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))
		_textbox_panel.add_child(_textbox_label)
	if _textbox_ttl_timer == null:
		_textbox_ttl_timer = Timer.new()
		_textbox_ttl_timer.one_shot = true
		_textbox_ttl_timer.timeout.connect(_hide_textbox)
		add_child(_textbox_ttl_timer)

func _update_textbox_style(is_urgent: bool):
	if _textbox_panel == null:
		return
	var sb := StyleBoxFlat.new()
	if is_urgent:
		sb.bg_color = Color(0.10, 0.00, 0.00, 0.85)
	else:
		sb.bg_color = Color(0, 0, 0, 0.75)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	_textbox_panel.add_theme_stylebox_override("panel", sb)
	if _textbox_label != null:
		_textbox_label.add_theme_color_override("font_color", Color(1,1,1,1))

func _show_textbox(message: String, seconds: float = 4.0, urgent: bool = false):
	_ensure_textbox_nodes()
	_update_textbox_style(urgent)
	_textbox_label.text = message
	_textbox_panel.visible = true
	_textbox_active = true
	if _textbox_ttl_timer != null:
		if seconds > 0.0:
			_textbox_ttl_timer.start(seconds)
		else:
			_textbox_ttl_timer.stop()

func _hide_textbox():
	_textbox_active = false
	if _textbox_panel != null:
		_textbox_panel.visible = false
