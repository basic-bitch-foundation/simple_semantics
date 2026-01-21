extends Node

var bgm_player: AudioStreamPlayer
var click_player: AudioStreamPlayer
var typing_player: AudioStreamPlayer

var is_muted: bool = false
var master_volume: float = 1.0
var bgm_volume: float = 0.9
var bgm_started: bool = false  

func _ready():
	bgm_player = AudioStreamPlayer. new()
	add_child(bgm_player)
	
	click_player = AudioStreamPlayer.new()
	add_child(click_player)
	
	typing_player = AudioStreamPlayer.new()
	
	add_child(typing_player)
	
	if ResourceLoader.exists("res://bgm.wav"):
		bgm_player.stream = load("res://bgm.wav")
	if ResourceLoader.exists("res://click.wav"):
		click_player.  stream = load("res://click.wav")
	if ResourceLoader. exists("res://typing.wav"):
		typing_player. stream = load("res://typing.wav")
	
	

func _input(event):
	
	if not bgm_started and (event is InputEventMouseButton or event is InputEventKey):
		if event.pressed:
			_play_bgm()
			bgm_started = true

func _play_bgm():
	if bgm_player.stream and not is_muted:
		bgm_player.play()

func play_click():
	if click_player.stream and not is_muted:
		click_player.  play()
	
	if not bgm_started: 
		_play_bgm()
		bgm_started = true

func play_typing():
	if typing_player.stream and not is_muted and not typing_player.playing:
		typing_player. play()

func stop_typing():
	typing_player.stop()

func set_muted(muted: bool):
	is_muted = muted
	if is_muted: 
		bgm_player.stop()
		typing_player. stop()
	else:
		_play_bgm()

func set_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	
	
	var db = linear_to_db(master_volume)
	
	AudioServer.set_bus_volume_db(0, db)

func set_bgm_volume(volume:  float):
	bgm_volume = clamp(volume, 0.0, 1.0)
	bgm_player.volume_db = linear_to_db(bgm_volume)

func get_volume() -> float:
	return master_volume

func get_bgm_volume() -> float:
	return bgm_volume

func is_audio_muted() -> bool:
	return is_muted
	
	
