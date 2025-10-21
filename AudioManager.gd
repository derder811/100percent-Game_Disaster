extends Node

var bgm_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = _preferred_bus(["Music", "Master"]) 
	add_child(bgm_player)

	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = _preferred_bus(["Ambience", "Ambient", "Master"]) 
	add_child(ambient_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = _preferred_bus(["SFX", "Effects", "Master"]) 
	add_child(sfx_player)

func _preferred_bus(names: Array[String]) -> String:
	for n in names:
		var idx := AudioServer.get_bus_index(n)
		if idx != -1:
			return n
	return "Master"

func play_bgm(path: String, loop: bool = true, volume_db: float = 0.0) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: BGM stream not found -> %s" % path)
		return
	_set_loop(stream, loop)
	bgm_player.stop()
	bgm_player.stream = stream
	bgm_player.volume_db = volume_db
	bgm_player.play()

func stop_bgm() -> void:
	if bgm_player.playing:
		bgm_player.stop()

func play_ambient(path: String, loop: bool = true, volume_db: float = 0.0) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: Ambient stream not found -> %s" % path)
		return
	_set_loop(stream, loop)
	ambient_player.stop()
	ambient_player.stream = stream
	ambient_player.volume_db = volume_db
	ambient_player.play()

func stop_ambient() -> void:
	if ambient_player.playing:
		ambient_player.stop()

func play_sfx(path: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = load(path)
	if stream == null:
		push_warning("AudioManager: SFX stream not found -> %s" % path)
		return
	_set_loop(stream, false)
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.play()

func stop_all() -> void:
	stop_bgm()
	stop_ambient()
	sfx_player.stop()

func _set_loop(stream: AudioStream, should_loop: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = should_loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = should_loop
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED