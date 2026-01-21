extends Node2D

@onready var github_btn = $GH
@onready var back_btn = $bck
@onready var mute_btn = $mute
@onready var volume_slider = $HSlider

const GITHUB_URL = "https://github.com/basic-bitch-foundation/simple_semantics"

func _ready():
	github_btn.pressed.connect(_on_github_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	mute_btn.pressed.connect(_on_mute_pressed)
	volume_slider.value_changed. connect(_on_volume_changed)
	
	volume_slider.min_value = 0.0
	
	volume_slider.max_value = 1.0
	volume_slider.step = 0.1
	
	volume_slider.value = AudioManager.get_bgm_volume()
	
	_update_mute_icon()
	
	
	self.visible = false

func _on_github_pressed():
	AudioManager.play_click()
	OS.shell_open(GITHUB_URL)

func _on_back_pressed():
	AudioManager.play_click()
	
	self.visible = false

func _on_mute_pressed():
	AudioManager.play_click()
	AudioManager.set_muted(not AudioManager.is_audio_muted())
	_update_mute_icon()

func _on_volume_changed(value: float):
	AudioManager.set_bgm_volume(value) 

func _update_mute_icon():
	
	
	if AudioManager.is_audio_muted():
		
		if ResourceLoader.exists("res://image/mute.png"):
			mute_btn.icon = load("res://image/mute.png")
	else:
		if ResourceLoader. exists("res://image/unmute.png"):
			mute_btn.icon = load("res://image/unmute.png")
