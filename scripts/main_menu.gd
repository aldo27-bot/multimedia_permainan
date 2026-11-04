extends Control

@onready var play_button = $Play_button
@onready var button_label = $Play_button/Label

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	button_label.text = "PLAY"

	# Memutar musik Main Menu
	MusicManager.resume_music()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/extra/LevelMenu.tscn")
