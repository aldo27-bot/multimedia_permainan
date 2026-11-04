extends CanvasLayer

@onready var quit_button: TextureButton = $QuitButton

const LEVEL_MENU_PATH := "res://scenes/extra/LevelMenu.tscn"

func _ready() -> void:
	quit_button.pressed.connect(_on_quit_pressed)

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_MENU_PATH)
