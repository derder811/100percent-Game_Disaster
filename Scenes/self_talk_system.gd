extends Node2D
class_name SelfTalkSystem

# Self-talk messages for different scenarios
var self_talk_messages = {
	"game_start": [
		"It's early in the morning. Heavy rain pours outside as strong winds shake the trees. A typhoon is approaching, and you're the only one left at home. Your goal is to stay safe and prepare for the storm."

	] as Array[String],
	"timer_based": [
		"It’s raining hard… I should check the window.",
		"It’s really pouring out there… I hope the roof holds up.",
		"I can hear the rain hitting the roof…"
	] as Array[String],
	"item_pickup": {
		"flashlight": "Flashlight. This should help.",
		"battery": "Got a spare battery.",
		"documents": "Got some papers, might be important.",
		"canned_food": "Canned food. This should last a while.",
		"water_bottle": "Bottled water secured.",
		"medkit": "Got a med kit!",
		"medicine_3": "Painkillers and cold meds, these might come in handy if anyone feels sick.",
		"mobile_phone": "Signal’s weak… I’ll keep my phone on me, just in case of any emergency or updates.",
		"powerbank": "Got a power bank. Might need this later.",
		"go_bag": "Good, my emergency bag’s here. I’ll start packing the essentials.",
		"candle": "Candle could start a fire… I should grab the flashlight instead."
	}
}

# Store-style after-interact messages (for scenes where items are browsed)
var after_item_interact_msgs := {
	"snacks": "Ooh, snacks! Always hard to choose... do I go salty or sweet?",
	"fridge": "Hmm... beverages.",
	"slurpee": "DROP COVER AND HOLD",
	"ice_cream_fridge": "Hmm... kinda craving something sweet. Do I have room for ice cream though?",
	"meat_fridge": "Meat looks fresh. Probably not grabbing any today, but noted.",
	"hotdog_siopao": "Hotdog or siopao? Man, tough choice. Maybe HotPao?.",
	"food_section": "Let's see what they've got here... canned stuff, quick bites. Pretty standard."
}

# Map item keys to corresponding self-talk audio clip paths
var item_audio_paths := {
	"go_bag": "res://retyphoon (2)/Good, my emergency bag’s here. I’ll start packing the essentials.wav",
	"battery": "res://retyphoon (2)/Got a spare battery.wav",
	"water_bottle": "res://retyphoon (2)/Bottled water secured.wav",
	"candle": "res://PLayer insteraction Talking and pick up talking/Self Talk (Candle).mp3",
	"canned_food": "res://retyphoon (2)/Canned food. This should last a while.wav",
	"documents": "res://retyphoon (2)/Got some papers, might be important.wav",
	"medkit": "res://retyphoon (2)/Got a med kit!.wav",
	"fuse_box": "res://retyphoon (2)/Power’s down.wav",
	"medicine_3": "res://PLayer insteraction Talking and pick up talking/Self Talk (Medicine 3).mp3",
	"mobile_phone": "res://retyphoon (2)/Signal’s weak… I’ll keep my phone on me, just in case of any emergency or updates.wav",
	"powerbank": "res://retyphoon (2)/Got a power bank. Might need this later.wav",
	"tv": "res://retyphoon (2)/It’s raining nonstop… I’ll check the news to see if there’s a typhoon signal in our area.wav",
	"bucket": "res://retyphoon (2)/Great… The bucket is full. At least I’ve got some clean water ready.wav",
	"window": "res://retyphoon (2)/It’s raining hard… I should check the window.wav",
	"flashlight": "res://retyphoon (2)/Flashlight. This should help.wav",
	"meat_fridge": "res://retyphoon (2)/ReEarthquake/Meat looks fresh. Probably not grabbing any today, but noted.wav"
}

# New: Audio clips for timer-based self-talk (Typhoon movement-style lines)
var timer_audio_paths := [
	"res://retyphoon (2)/It’s raining hard… I should check the window.wav",
	"res://retyphoon (2)/It’s really pouring out there… I hope the roof holds up.wav",
	"res://retyphoon (2)/I can hear the rain hitting the roof….wav"
]
# Map specific timer-based text lines to their voice clips
var timer_audio_map := {
	"It’s raining hard… I should check the window.": "res://retyphoon (2)/It’s raining hard… I should check the window.wav",
	"It’s really pouring out there… I hope the roof holds up.": "res://retyphoon (2)/It’s really pouring out there… I hope the roof holds up.wav",
	"I can hear the rain hitting the roof…": "res://retyphoon (2)/I can hear the rain hitting the roof….wav",
	"It's raining nonstop... I'll check the news to see if there's a typhoon signal in our area.": "res://retyphoon (2)/It’s raining nonstop… I’ll check the news to see if there’s a typhoon signal in our area.wav",
	"It's raining hard... I should check the television to see if there's a typhoon warning.": "res://retyphoon (2)/It’s raining hard… I should check the television to see if there’s a typhoon warning.wav"
}

var has_shown_startup_message = false
var timer_self_talk_active = false
@onready var player = get_parent()
@onready var voice_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Compact textbox UI
var _textbox_layer: CanvasLayer = null
var _textbox_panel: Panel = null
var _textbox_label: Label = null
var _textbox_header_label: Label = null
var _textbox_active: bool = false
var _textbox_ttl_timer: Timer = null

func _ready():
	add_to_group("self_talk_system")
	# Dedicated voice player to avoid conflicts with global SFX
	voice_player.name = "SelfTalkVoicePlayer"
	voice_player.bus = "SFX"
	add_child(voice_player)
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
		# Suppress timer-based self talk when interacting with or near an asset
		var interacting := false
		if typeof(GlobalInteractionManager) != TYPE_NIL:
			var cur_type = GlobalInteractionManager.get_current_object_type()
			interacting = cur_type != GlobalInteractionManager.ObjectType.NONE
		# Avoid overlapping with our own textbox being active
		if not dialog_active and not _textbox_active and not interacting:
			show_timer_self_talk()

func show_timer_self_talk():
	var messages = self_talk_messages["timer_based"]
	var idx = randi() % messages.size()
	var message = messages[idx]
	print("TimerSelfTalk: showing message idx=", idx, " text=", message)
	_show_textbox(message, 0.0)
	# Play the voice line mapped to the shown text; fallback to index mapping
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(message, "")
	if voice_path == "" and timer_audio_paths.size() > 0:
		var mapped_index = min(idx, timer_audio_paths.size() - 1)
		voice_path = timer_audio_paths[mapped_index]
	print("TimerSelfTalk: resolved voice_path=", voice_path)
	if voice_path != "":
		print("TimerSelfTalk: playing voice via dedicated player")
		await _play_voice_and_wait(voice_path, 4.0)
		# After audio completes (or if none), simply hide the textbox without pausing the game
		_hide_textbox()

func show_startup_message():
	if has_shown_startup_message:
		return
	has_shown_startup_message = true
	var dialog_box = get_tree().get_first_node_in_group("dialog_system")
	if dialog_box and dialog_box.has_method("show_dialog"):
		# Enable auto-dismiss for welcome dialog (2 seconds)
		dialog_box.show_dialog("WELCOME", self_talk_messages["game_start"], true)
		if not dialog_box.dialog_finished.is_connected(_on_startup_dialog_finished):
			dialog_box.dialog_finished.connect(_on_startup_dialog_finished)
	else:
		print("DialogBox not found for startup message")

func _on_startup_dialog_finished():
	await get_tree().create_timer(2.0).timeout
	show_self_talk_message()

func show_self_talk_message():
	# Use a mapped timer-based line and play its audio
	var first_message = "It’s raining hard… I should check the window."
	_show_textbox(first_message, 0.0)
	# Attempt to play matching audio for this line
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(first_message, "")
	if voice_path == "" and timer_audio_paths.size() > 0:
		voice_path = timer_audio_paths[0]
	if voice_path != "":
		await _play_voice_and_wait(voice_path, 4.0)
		# Hide the self-talk textbox to avoid overlap
		_hide_textbox()
		# Do not show a follow-up dialog for time-based self talk to avoid pausing
	else:
		# If no audio was played, still show the dialog after a short delay
		await get_tree().create_timer(1.0).timeout
		# No follow-up dialog; keep gameplay uninterrupted

func trigger_custom_self_talk(custom_message: String):
	# Show text and try to play audio if the line is mapped
	_show_textbox(custom_message, 0.0)
	var voice_path: String = ""
	if typeof(timer_audio_map) != TYPE_NIL:
		voice_path = timer_audio_map.get(custom_message, "")
	if voice_path != "":
		await _play_voice_and_wait(voice_path, 4.0)
		_hide_textbox()
	else:
		await get_tree().create_timer(4.0).timeout
		_hide_textbox()

func trigger_self_talk(message_type: String = "timer_based"):
	if message_type in self_talk_messages:
		var messages = self_talk_messages[message_type]
		var idx = randi() % messages.size()
		var random_message = messages[idx]
		print("SelfTalk trigger: type=", message_type, " idx=", idx, " text=", random_message)
		_show_textbox(random_message, 0.0)
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
				await _play_voice_and_wait(voice_path, 4.0)
				_hide_textbox()
			else:
				await get_tree().create_timer(4.0).timeout
				_hide_textbox()

func trigger_item_pickup_self_talk(item_name: String):
	if "item_pickup" in self_talk_messages and item_name in self_talk_messages["item_pickup"]:
		_show_textbox(self_talk_messages["item_pickup"][item_name], 0.0)
	# Play associated self-talk audio if available
	var audio_path: String = item_audio_paths.get(item_name, "")
	if audio_path != "":
		await _play_voice_and_wait(audio_path, 4.0)
		_hide_textbox()
	else:
		await get_tree().create_timer(4.0).timeout
		_hide_textbox()

func trigger_after_item_interact_talk(item_type: String):
	if after_item_interact_msgs.has(item_type):
		_show_textbox(after_item_interact_msgs[item_type], 0.0)
	# Play associated self-talk audio if available for this interaction type
	var audio_path: String = item_audio_paths.get(item_type, "")
	if audio_path != "":
		await _play_voice_and_wait(audio_path, 4.0)
		_hide_textbox()
	else:
		await get_tree().create_timer(4.0).timeout
		_hide_textbox()

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
	if _textbox_header_label == null:
		_textbox_header_label = Label.new()
		_textbox_header_label.anchor_left = 0.0
		_textbox_header_label.anchor_right = 1.0
		_textbox_header_label.anchor_top = 0.0
		_textbox_header_label.anchor_bottom = 0.0
		_textbox_header_label.offset_left = 18
		_textbox_header_label.offset_right = -18
		_textbox_header_label.offset_top = 6
		_textbox_header_label.offset_bottom = 34
		_textbox_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_textbox_header_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_textbox_header_label.add_theme_color_override("font_color", Color(1,1,1,1))
		_textbox_header_label.add_theme_font_size_override("font_size", 18)
		_textbox_header_label.visible = false
		_textbox_panel.add_child(_textbox_header_label)
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
	# Ensure header is hidden for normal self-talk
	if _textbox_header_label != null:
		_textbox_header_label.visible = false
		# Restore default content offsets when header hidden
		_textbox_label.offset_top = 12
		_textbox_label.offset_bottom = -12
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
	if _textbox_header_label != null:
		_textbox_header_label.visible = false

# Show tips using the same textbox format, with a "TIPS" header at the top
func show_tips_textbox(text: String, seconds: float = 4.0):
	_ensure_textbox_nodes()
	_update_textbox_style(false)
	if _textbox_header_label != null:
		_textbox_header_label.text = "TIPS"
		_textbox_header_label.visible = true
		# Push content down slightly to make room for header
		_textbox_label.offset_top = 42
		_textbox_label.offset_bottom = -12
	_textbox_label.text = text
	_textbox_panel.visible = true
	_textbox_active = true
	if _textbox_ttl_timer != null:
		if seconds > 0.0:
			_textbox_ttl_timer.start(seconds)
		else:
			_textbox_ttl_timer.stop()

# Dedicated voice playback to avoid interference from global SFX
func _play_voice_and_wait(path: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("SelfTalkSystem: voice stream not found -> %s" % path)
		return
	# Ensure no loop and play on local player
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	voice_player.stop()
	voice_player.stream = stream
	voice_player.volume_db = volume_db
	voice_player.play()
	await voice_player.finished
