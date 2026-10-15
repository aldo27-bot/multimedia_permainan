
extends CharacterBody2D

signal health_changed(current_health: int, maximum_health: int)

const GRAVITY: float = 1200.0

@export var max_health: int = 15
@export var detection_range: float = 400.0
@export var attack_range: float = 110.0
@export var move_speed: float = 85.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5
@export var attack_hit_delay: float = 0.35
@export var vertical_attack_range: float = 100.0
@export var attack_hit_range: float = 125.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

var health: int = 20
var player: CharacterBody2D = null

var is_hurt: bool = false
var is_dead: bool = false
var is_attacking: bool = false
var attack_has_hit: bool = false

var attack_timer: float = 0.0
var facing: float = -1.0


func _ready() -> void:
	health = max_health
	attack_shape.set_deferred("disabled", true)

	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

	# Kirim HP awal kepada HUD boss.
	health_changed.emit(health, max_health)

	find_player()
	update_attack_area_position()
	sprite.play("idle")


func find_player() -> void:
	var found: Node = get_tree().get_first_node_in_group("player")

	if found is CharacterBody2D:
		player = found as CharacterBody2D
	else:
		player = null


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if is_hurt or is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	if not is_instance_valid(player):
		find_player()

	if not is_instance_valid(player):
		velocity.x = 0.0
		move_and_slide()
		sprite.play("idle")
		return

	if player.is_dead:
		velocity.x = 0.0
		move_and_slide()
		sprite.play("idle")
		return

	var difference: Vector2 = player.global_position - global_position
	var distance: float = difference.length()

	if distance > detection_range:
		velocity.x = 0.0
		move_and_slide()
		sprite.play("idle")
		return

	# Boss menghadap ke arah Player.
	if difference.x != 0.0:
		facing = signf(difference.x)
		sprite.flip_h = facing < 0.0
		update_attack_area_position()

	# Serang jika Player berada dalam jangkauan.
	if absf(difference.x) <= attack_range \
	and absf(difference.y) <= vertical_attack_range \
	and attack_timer <= 0.0:
		start_attack()
		move_and_slide()
		return

	# Kejar Player.
	if absf(difference.x) > attack_range * 0.65:
		velocity.x = signf(difference.x) * move_speed
		sprite.play("Walk")
	else:
		velocity.x = 0.0
		sprite.play("idle")

	move_and_slide()


func update_attack_area_position() -> void:
	attack_area.position.x = facing * 75.0


func start_attack() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	is_attacking = true
	attack_has_hit = false
	attack_timer = attack_cooldown
	velocity.x = 0.0

	update_attack_area_position()
	attack_shape.set_deferred("disabled", false)
	sprite.play("Attack")

	await get_tree().create_timer(attack_hit_delay).timeout

	if not is_inside_tree() or is_dead or is_hurt:
		return

	if not is_instance_valid(player):
		find_player()

	if is_instance_valid(player) and not player.is_dead:
		var difference: Vector2 = player.global_position - global_position
		var in_front: bool = difference.x * facing >= 0.0
		var close_enough: bool = (
			absf(difference.x) <= attack_hit_range
			and absf(difference.y) <= vertical_attack_range
		)

		await get_tree().physics_frame

		if not is_inside_tree() or is_dead or is_hurt:
			return

		var player_in_hitbox: bool = false

		for body in attack_area.get_overlapping_bodies():
			if body == player:
				player_in_hitbox = true
				break

		# Gunakan hitbox atau pemeriksaan jarak sebagai alternatif.
		if (player_in_hitbox or (in_front and close_enough)) \
		and not attack_has_hit:
			if player.has_method("take_damage"):
				attack_has_hit = true
				player.take_damage(attack_damage)

	attack_shape.set_deferred("disabled", true)


func take_damage(amount: int = 1) -> void:
	if is_dead or is_hurt:
		return

	health = maxi(health - amount, 0)

	# Perbarui angka HP boss setiap menerima damage.
	health_changed.emit(health, max_health)

	if health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false
	velocity.x = 0.0

	attack_shape.set_deferred("disabled", true)
	sprite.play("Hurt")


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_hurt = false
	is_attacking = false
	velocity = Vector2.ZERO

	attack_shape.set_deferred("disabled", true)
	body_shape.set_deferred("disabled", true)

	sprite.speed_scale = 1.0
	sprite.play("Dead")


func _on_animation_finished() -> void:
	match sprite.animation:
		"Hurt":
			is_hurt = false
			sprite.play("idle")

		"Attack":
			is_attacking = false
			attack_shape.set_deferred("disabled", true)

			if not is_dead and not is_hurt:
				sprite.play("idle")

		"Dead":
			pass
