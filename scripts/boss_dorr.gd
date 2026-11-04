
extends Area2D

var player_in_range: bool = false
var is_transitioning: bool = false

const BOSS_1_PATH := "res://scenes/bossarena/BossArena1.tscn"
const BOSS_2_PATH := "res://scenes/bossarena/BossArena2.tscn"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		print("Dekat pintu. Tekan E untuk masuk.")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false


func _process(_delta: float) -> void:
	if not player_in_range or is_transitioning:
		return

	if Input.is_action_just_pressed("interact"):
		enter_boss_arena()


func enter_boss_arena() -> void:
	var current_scene := get_tree().current_scene
	var scene_name := current_scene.scene_file_path.get_file().to_lower()

	var target_path := ""

	if scene_name == "level_1.tscn":
		target_path = BOSS_1_PATH
	elif scene_name == "level2.tscn":
		target_path = BOSS_2_PATH
	else:
		push_error("Level tidak dikenali: " + scene_name)
		return

	if not ResourceLoader.exists(target_path):
		push_error("Arena boss tidak ditemukan: " + target_path)
		return

	is_transitioning = true

	var error := get_tree().change_scene_to_file(target_path)

	if error != OK:
		is_transitioning = false
		push_error("Gagal membuka arena boss: " + target_path)
