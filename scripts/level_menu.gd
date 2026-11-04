extends Control

const LEVEL_1_PATH: String = "res://scenes/main/level_1.tscn"
const LEVEL_2_PATH: String = "res://scenes/main/level2.tscn"
const MAIN_MENU_PATH: String = "res://scenes/extra/Main_menu.tscn"

@onready var level_1_button: BaseButton = $LevelCards/Boss1Card/PlayButton
@onready var level_2_button: BaseButton = $LevelCards/Boss2Card/PlayButton
@onready var back_button: BaseButton = $Backbutton

func _ready() -> void:
	level_1_button.pressed.connect(_on_level_1_pressed)
	level_2_button.pressed.connect(_on_level_2_pressed)
	back_button.pressed.connect(_on_back_pressed)

	MusicManager.resume_music()
	
func _on_level_1_pressed() -> void:
	open_level(LEVEL_1_PATH)

func _on_level_2_pressed() -> void:
	open_level(LEVEL_2_PATH)

func open_level(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("Scene tidak ditemukan: " + scene_path)
		return

	# Hentikan musik sebelum masuk ke level
	MusicManager.stop_music()

	var error: Error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Gagal membuka scene: " + scene_path)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
