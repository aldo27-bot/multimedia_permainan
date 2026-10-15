
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)

const SPEED := 160.0
const JUMP_FORCE := -450.0
const GRAVITY := 1200.0
const RESPAWN_DELAY := 3.0
const LEVEL_1_SCENE: String = "res://scenes/main/Level_1.tscn"

@export var max_health: int = 5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var walk_sound: AudioStreamPlayer2D = $WalkSound
@onready var slash_sound: AudioStreamPlayer2D = $SlashSound

var health: int = 5
var is_hurt: bool = false
var is_dead: bool = false
var is_attacking: bool = false
var is_respawning: bool = false
var hit_mobs: Array[Node2D] = []
var next_attack: int = 1
var spawn_position: Vector2


func _ready() -> void:
	health = max_health
	spawn_position = global_position

	attack_shape.disabled = true

	if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
		attack_area.body_entered.connect(_on_attack_area_body_entered)

	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

	# Kirim HP awal ke HUD.
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_hurt:
		velocity.x = 0.0

		if not is_on_floor():
			velocity.y += GRAVITY * delta

		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_FORCE

	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()

	move_and_slide()

	if not is_attacking:
		update_animation(direction)


func update_animation(direction: float) -> void:
	if is_dead or is_attacking or is_hurt:
		return

	if not is_on_floor():
		sprite.play("Jump")
	elif direction != 0.0:
		sprite.play("run")
	else:
		sprite.play("idle")

	if direction != 0.0:
		sprite.flip_h = direction < 0.0

	if is_on_floor() and direction != 0.0:
		if not walk_sound.playing:
			walk_sound.play()
	else:
		walk_sound.stop()


func start_attack() -> void:
	if is_dead or is_attacking or is_hurt:
		return

	is_attacking = true
	hit_mobs.clear()

	attack_area.position.x = -25.0 if sprite.flip_h else 25.0
	attack_shape.set_deferred("disabled", false)

	sprite.speed_scale = 1.5

	if next_attack == 1:
		sprite.play("attack1")
	else:
		sprite.play("attack2")

	walk_sound.stop()
	slash_sound.stop()
	slash_sound.play()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not is_attacking or is_dead or is_hurt:
		return

	if body.is_in_group("mobs") and body not in hit_mobs:
		hit_mobs.append(body)

		if body.has_method("take_damage"):
			body.take_damage(1)


func _on_animation_finished() -> void:
	if sprite.animation == "attack1":
		next_attack = 2
		finish_attack()

	elif sprite.animation == "attack2":
		next_attack = 1
		finish_attack()

	elif sprite.animation == "hurt":
		is_hurt = false
		sprite.speed_scale = 1.0

	elif sprite.animation == "dead":
		sprite.speed_scale = 1.0


func finish_attack() -> void:
	attack_shape.set_deferred("disabled", true)
	is_attacking = false
	sprite.speed_scale = 1.0


func take_damage(amount: int = 1) -> void:
	if is_dead or is_hurt:
		return

	health = maxi(health - amount, 0)

	# Perbarui angka HP di HUD setiap menerima damage.
	health_changed.emit(health, max_health)

	if health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false
	attack_shape.set_deferred("disabled", true)
	sprite.speed_scale = 1.0
	sprite.play("hurt")


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_hurt = false
	is_attacking = false
	velocity = Vector2.ZERO

	attack_shape.set_deferred("disabled", true)
	sprite.speed_scale = 1.0

	walk_sound.stop()
	slash_sound.stop()

	sprite.play("dead")
	respawn_player()


func respawn_player() -> void:
	if is_respawning:
		return

	is_respawning = true

	await get_tree().create_timer(RESPAWN_DELAY).timeout

	if not is_inside_tree():
		return

	var current_scene := get_tree().current_scene

	if current_scene == null:
		is_respawning = false
		return

	var current_path: String = current_scene.scene_file_path

	# Jika kalah di arena Boss, kembali ke Level 1.
	if current_path != LEVEL_1_SCENE:
		get_tree().change_scene_to_file(LEVEL_1_SCENE)
		return

	# Jika mati di Level 1, respawn di posisi awal.
	global_position = spawn_position
	velocity = Vector2.ZERO
	health = max_health

	# Perbarui HUD setelah HP dipulihkan.
	health_changed.emit(health, max_health)

	is_dead = false
	is_hurt = false
	is_attacking = false
	is_respawning = false

	hit_mobs.clear()
	next_attack = 1

	visible = true
	sprite.visible = true
	sprite.speed_scale = 1.0
	sprite.flip_h = false
	sprite.play("idle")
