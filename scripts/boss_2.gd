
extends CharacterBody2D

# =========================
# HEALTH
# =========================
signal health_changed(current_health: int, maximum_health: int)

@export var max_health: int = 20
var health: int = 20

# =========================
# MOVEMENT
# =========================
@export var speed: float = 45.0
@export var chase_speed: float = 75.0
@export var detection_range: float = 350.0

# =========================
# COMBAT
# =========================
@export var attack_range: float = 75.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.5
@export var attack_hit_delay: float = 0.4
@export var vertical_attack_range: float = 65.0

# =========================
# PHYSICS
# =========================
const GRAVITY: float = 1200.0

# =========================
# NODES
# =========================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D

# =========================
# STATE
# =========================
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var hit_player: bool = false

var attack_timer: float = 0.0
var direction: float = -1.0
var player: CharacterBody2D = null
var next_attack: int = 1


func _ready() -> void:
	health = max_health

	# Grup mobs dipakai Player untuk menyerang musuh.
	add_to_group("mobs")

	# Grup khusus untuk HUD Boss 2.
	add_to_group("boss2")

	attack_shape.set_deferred("disabled", true)

	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)

	find_player()
	sprite.play("idle")

	# Kirim HP awal ke HUD.
	health_changed.emit(health, max_health)

	print("BOSS 2 SIAP")
	print("HP BOSS 2: ", health, "/", max_health)
	print("PLAYER DITEMUKAN: ", is_instance_valid(player))


func find_player() -> void:
	var found_player = get_tree().get_first_node_in_group("player")

	if found_player is CharacterBody2D:
		player = found_player
	else:
		player = null


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	# Gravitasi.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0

	if not is_instance_valid(player):
		find_player()

	# Pertahankan animasi hurt dan attack.
	if is_hurt or is_attacking:
		velocity.x = 0.0
		move_and_slide()
		return

	# Boss berhenti jika Player belum ditemukan atau mati.
	if not is_instance_valid(player) or player.is_dead:
		velocity.x = 0.0
		move_and_slide()
		play_idle_if_possible()
		return

	var difference: Vector2 = player.global_position - global_position
	var horizontal_distance: float = absf(difference.x)
	var vertical_distance: float = absf(difference.y)
	var total_distance: float = difference.length()

	# =========================
	# DETEKSI PLAYER
	# =========================
	if total_distance <= detection_range:
		if difference.x < 0.0:
			direction = -1.0
		elif difference.x > 0.0:
			direction = 1.0

		sprite.flip_h = direction < 0.0
		update_attack_area_position()

		# Serang jika Player cukup dekat.
		if (
			horizontal_distance <= attack_range
			and vertical_distance <= vertical_attack_range
			and attack_timer <= 0.0
		):
			start_attack()
			move_and_slide()
			return

		# Kejar Player.
		if horizontal_distance > attack_range * 0.7:
			velocity.x = direction * chase_speed
			play_animation("run")
		else:
			velocity.x = 0.0
			play_idle_if_possible()
	else:
		velocity.x = 0.0
		play_idle_if_possible()

	move_and_slide()


# =========================
# ATTACK AREA POSITION
# =========================
func update_attack_area_position() -> void:
	var offset: float = absf(attack_area.position.x)

	if offset < 1.0:
		offset = 35.0

	attack_area.position.x = offset * direction


# =========================
# ATTACK
# =========================
func start_attack() -> void:
	if is_dead or is_hurt or is_attacking:
		return

	if attack_timer > 0.0:
		return

	is_attacking = true
	hit_player = false
	velocity.x = 0.0
	attack_timer = attack_cooldown

	# Hadap ke arah Player.
	if is_instance_valid(player):
		direction = -1.0 if player.global_position.x < global_position.x else 1.0

	sprite.flip_h = direction < 0.0
	update_attack_area_position()

	attack_shape.set_deferred("disabled", true)

	# Ganti animasi serangan secara bergantian.
	var attack_animation: String

	if next_attack == 1:
		attack_animation = "attack1"
		next_attack = 2
	else:
		attack_animation = "attack2"
		next_attack = 1

	if not sprite.sprite_frames.has_animation(attack_animation):
		push_warning("Animasi Boss 2 tidak ditemukan: " + attack_animation)
		is_attacking = false
		return

	sprite.play(attack_animation)
	print("BOSS 2 MEMAKAI ANIMASI: ", attack_animation)

	# Tunggu sampai momen benturan.
	await get_tree().create_timer(attack_hit_delay).timeout

	if not is_inside_tree() or is_dead or not is_attacking:
		return

	apply_attack_damage()


func apply_attack_damage() -> void:
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

	if (
		player_in_front
		and absf(dx) <= attack_range + 25.0
		and dy <= vertical_attack_range
	):
		hit_player = true

		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			print("BOSS 2 MENYERANG PLAYER! DAMAGE: ", attack_damage)
	else:
		print("SERANGAN BOSS 2 MELESET")


# =========================
# ANIMATION HELPERS
# =========================
func play_animation(animation_name: String) -> void:
	if sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name:
			sprite.play(animation_name)


func play_idle_if_possible() -> void:
	if sprite.sprite_frames.has_animation("idle"):
		play_animation("idle")


func _on_animation_finished() -> void:
	if sprite.animation == "attack1" or sprite.animation == "attack2":
		is_attacking = false

	elif sprite.animation == "hurt":
		is_hurt = false

	elif sprite.animation == "dead":
		return


# =========================
# RECEIVE DAMAGE
# =========================
func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	health = maxi(health - amount, 0)

	# Perbarui HUD setiap menerima damage.
	health_changed.emit(health, max_health)

	print("BOSS 2 TERKENA SERANGAN! HP: ", health, "/", max_health)

	if health <= 0:
		die()
		return

	is_hurt = true
	is_attacking = false
	velocity.x = 0.0

	attack_shape.set_deferred("disabled", true)

	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
	else:
		is_hurt = false

# =========================
# DEATH
# =========================
func die() -> void:
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

	# Pastikan HUD menerima HP nol.
	health_changed.emit(0, max_health)

	# Mainkan animasi kematian Boss 2.
	if sprite.sprite_frames.has_animation("dead"):
		sprite.play("dead")
		print("BOSS 2 MATI")

		await sprite.animation_finished
	else:
		print("BOSS 2 MATI - animasi dead tidak ditemukan")

	# Tampilkan popup Victory setelah animasi kematian.
	if is_inside_tree():
		var popup = get_tree().current_scene.find_child(
			"VictoryPopup", true, false
		)

		if popup and popup.has_method("show_victory"):
			popup.show_victory()
			print("VICTORY POPUP BOSS 2 DITAMPILKAN")
		else:
			push_warning(
				"VictoryPopup tidak ditemukan di scene Boss Arena!"
			)

		# Hapus Boss 2 setelah popup dipanggil.
		queue_free()
