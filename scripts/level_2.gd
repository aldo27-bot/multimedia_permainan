
extends Node2D

@onready var player = $Player

@export var death_y: float = 530.0
@export var min_fall_distance: float = 120.0

var spawn_position: Vector2
var fall_start_y: float = 0.0
var fall_started: bool = false
var respawning: bool = false


func _ready() -> void:
	spawn_position = player.global_position
	print("LEVEL 2 SPAWN: ", spawn_position)


func _physics_process(_delta: float) -> void:
	if respawning or player.is_dead:
		return

	if not player.is_on_floor():
		if not fall_started:
			fall_started = true
			fall_start_y = player.global_position.y

		var fall_distance: float = (
			player.global_position.y - fall_start_y
		)

		if player.global_position.y >= death_y \
		and fall_distance >= min_fall_distance:
			player_die()
	else:
		fall_started = false


func player_die() -> void:
	if respawning:
		return

	respawning = true

	# Hentikan gerakan dan mulai animasi mati.
	player.is_dead = true
	player.is_hurt = false
	player.is_attacking = false
	player.velocity = Vector2.ZERO

	player.attack_shape.set_deferred("disabled", true)
	player.walk_sound.stop()
	player.slash_sound.stop()

	player.sprite.speed_scale = 1.0
	player.sprite.play("dead")

	# Tunggu 3 detik, lalu respawn di Level 2.
	await get_tree().create_timer(3.0).timeout

	if not is_instance_valid(player):
		return

	player.global_position = spawn_position
	player.velocity = Vector2.ZERO

	player.health = player.max_health
	player.health_changed.emit(
		player.health,
		player.max_health
	)

	player.is_dead = false
	player.is_hurt = false
	player.is_attacking = false
	player.is_respawning = false
	player.hit_mobs.clear()
	player.next_attack = 1

	player.visible = true
	player.sprite.visible = true
	player.sprite.speed_scale = 1.0
	player.sprite.flip_h = false
	player.sprite.play("idle")

	player.attack_shape.set_deferred("disabled", true)

	fall_started = false
	fall_start_y = 0.0
	respawning = false
