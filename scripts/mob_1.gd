
extends CharacterBody2D

@export var max_health: int = 3
@export var speed: float = 40.0
@export var chase_speed: float = 65.0
@export var patrol_distance: float = 80.0
@export var detection_range: float = 220.0
@export var attack_range: float = 55.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.2

@export var jump_force: float = -420.0
@export var jump_height_threshold: float = 45.0
@export var jump_cooldown: float = 0.8

# Waktu dari awal animasi sampai kapak mengenai sasaran.
@export var attack_hit_delay: float = 0.45

const GRAVITY: float = 1200.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

var health: int
var start_x: float
var direction: float = -1.0

var is_dead: bool = false
var is_attacking: bool = false
var is_hurt: bool = false
var hit_player: bool = false

var attack_timer: float = 0.0
var jump_timer: float = 0.0
var player: CharacterBody2D = null


func _ready():
	health = max_health
	start_x = global_position.x

	# Damage tidak menggunakan sinyal body_entered lagi.
	attack_shape.set_deferred("disabled", true)

	find_player()

	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

	sprite.play("idle")

	print("ORC SIAP")
	print("PLAYER DITEMUKAN: ", is_instance_valid(player))


func find_player():
	var found_player = get_tree().get_first_node_in_group("player")

	if found_player is CharacterBody2D:
		player = found_player
	else:
		player = null


func _physics_process(delta):
	if is_dead:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if jump_timer > 0.0:
		jump_timer -= delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jangan ganggu animasi serangan atau terluka.
	if is_attacking or is_hurt:
		velocity.x = 0.0
		move_and_slide()
		return

	if not is_instance_valid(player):
		find_player()

	# ==================================
	# DETEKSI DAN KEJAR PLAYER
	# ==================================
	if is_instance_valid(player) and not player.is_dead:
		var difference: Vector2 = player.global_position - global_position
		var horizontal_distance: float = absf(difference.x)
		var vertical_distance: float = absf(difference.y)

		if difference.length() <= detection_range:
			if difference.x < 0.0:
				direction = -1.0
			elif difference.x > 0.0:
				direction = 1.0

			sprite.flip_h = direction < 0.0

			if horizontal_distance <= attack_range \
			and vertical_distance <= 45.0 \
			and attack_timer <= 0.0:
				start_attack()
				move_and_slide()
				return

			# Lompat untuk mengejar Player yang lebih tinggi.
			if is_on_floor() \
			and difference.y < -jump_height_threshold \
			and jump_timer <= 0.0:
				velocity.y = jump_force
				jump_timer = jump_cooldown
				print("ORC MELOMPAT")

			if horizontal_distance > attack_range:
				velocity.x = direction * chase_speed
			else:
				velocity.x = 0.0

			move_and_slide()
			update_movement_animation()
			return

	# ==================================
	# PATROLI
	# ==================================
	if direction < 0.0 and global_position.x <= start_x - patrol_distance:
		direction = 1.0
	elif direction > 0.0 and global_position.x >= start_x + patrol_distance:
		direction = -1.0

	velocity.x = direction * speed
	sprite.flip_h = direction < 0.0

	move_and_slide()
	update_movement_animation()


func update_movement_animation():
	if is_dead or is_attacking or is_hurt:
		return

	if not is_on_floor():
		sprite.play("jump")
	elif absf(velocity.x) > 1.0:
		sprite.play("run")
	else:
		sprite.play("idle")


func start_attack():
	if is_dead or is_attacking or is_hurt:
		return

	is_attacking = true
	hit_player = false
	attack_timer = attack_cooldown
	velocity.x = 0.0

	# Kunci arah ketika serangan dimulai.
	if is_instance_valid(player):
		direction = -1.0 if player.global_position.x < global_position.x else 1.0

	sprite.flip_h = direction < 0.0
	sprite.play("attack1")

	print("ORC MULAI MENYERANG")

	# Tunggu sampai kapak mencapai frame benturan.
	await get_tree().create_timer(attack_hit_delay).timeout

	if not is_inside_tree() or is_dead or not is_attacking:
		return

	# Damage hanya diperiksa pada momen benturan ini.
	apply_attack_damage()


func apply_attack_damage():
	if hit_player or is_dead or not is_attacking:
		return

	if not is_instance_valid(player) or player.is_dead:
		return

	var dx: float = player.global_position.x - global_position.x
	var dy: float = absf(player.global_position.y - global_position.y)

	var player_in_front: bool = (
		(direction > 0.0 and dx >= 0.0)
		or (direction < 0.0 and dx <= 0.0)
	)

	if player_in_front \
	and absf(dx) <= attack_range + 25.0 \
	and dy <= 45.0:
		hit_player = true
		player.take_damage(attack_damage)
		print("ORC MENYERANG PLAYER! DAMAGE: ", attack_damage)
	else:
		print("SERANGAN ORC MELeset")


func _on_animation_finished():
	if sprite.animation == "attack1":
		is_attacking = false

	elif sprite.animation == "hurt":
		is_hurt = false


func take_damage(amount: int = 1):
	if is_dead:
		return

	health = maxi(health - amount, 0)
	print("ORC TERKENA SERANGAN! HP: ", health)

	if health <= 0:
		die()
	else:
		is_hurt = true
		is_attacking = false
		sprite.play("hurt")


func die():
	if is_dead:
		return

	is_dead = true
	is_attacking = false
	is_hurt = false
	velocity = Vector2.ZERO

	collision_layer = 0
	collision_mask = 0
	body_shape.set_deferred("disabled", true)
	attack_shape.set_deferred("disabled", true)

	sprite.play("dead")

	await get_tree().create_timer(1.0).timeout

	if is_inside_tree():
		queue_free()
