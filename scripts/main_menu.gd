extends Control

@onready var play_button = $Play_button
@onready var button_label = $Play_button/Label

@onready var closebutton = $CloseButton
@onready var closelabel = $CloseButton/Label


func _ready() -> void:
	# Tombol PLAY
	play_button.pressed.connect(_on_play_pressed)
	button_label.text = "PLAY"

	# Tombol KELUAR
	closebutton.pressed.connect(_on_close_pressed)
	closelabel.text = "Keluar"

	# Memutar musik Main Menu
	MusicManager.resume_music()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(
		"res://scenes/extra/LevelMenu.tscn"
	)


func _on_close_pressed() -> void:
	get_tree().quit()
