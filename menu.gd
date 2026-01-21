extends Node2D

@onready var play_btn = $play
@onready var settings_btn = $settings
@onready var settings_panel = $settings2  

func _ready():
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	
	
	settings_panel.visible = false

func _on_play_pressed():
	
	
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://message_alter.tscn")

func _on_settings_pressed():
	AudioManager.play_click()
	
	settings_panel.visible = true
	
