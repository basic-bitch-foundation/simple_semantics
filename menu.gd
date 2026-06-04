extends Node2D

@onready var play_btn       = $play
@onready var settings_btn   = $settings
@onready var settings_panel = $settings2
@onready var apipop         = $apipop   

const savepath = "user://api.cfg"

func _ready():
	play_btn.pressed.connect(on_play)
	settings_btn.pressed.connect(on_settings)
	settings_panel.visible = false
	apipop.visible = false
	apipop.confirmed.connect(go_play)

func on_play():
	AudioManager.play_click()
	if not has_key():
		apipop.open()
	else:
		go_play()

func on_settings():
	AudioManager.play_click()
	settings_panel.visible = true

func go_play():
	get_tree().change_scene_to_file("res://message_alter.tscn")

func has_key():
	var cfg = ConfigFile.new()
	if cfg.load(savepath) != OK: return false
	return cfg.get_value("api", "key", "").strip_edges() != ""
