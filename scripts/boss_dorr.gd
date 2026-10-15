
extends Area2D

@export_file("*.tscn") var boss_scene_path: String = "res://scenes/bossarena/BossArena1.tscn"

var player_in_range: bool = false


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
	if player_in_range and Input.is_action_just_pressed("interact"):
		if boss_scene_path != "" and ResourceLoader.exists(boss_scene_path):
			get_tree().change_scene_to_file(boss_scene_path)
		else:
			push_error("Path scene boss tidak ditemukan: " + boss_scene_path)
