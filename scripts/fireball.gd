extends Area2D

@export var speed: float = 300.0
@export var damage: int = 1
@export var direction: Vector2 = Vector2.LEFT
@export var respawn_delay: float = 1.0
@export var lifetime: float = 6.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fire_attack: AudioStreamPlayer2D = $"Fire Attack"

var has_hit: bool = false
var start_position: Vector2

var lifetime_timer: float = 0.0
var respawn_timer: float = 0.0
var is_active: bool = false


func _ready() -> void:
	start_position = global_position
	direction = direction.normalized()

	body_entered.connect(_on_body_entered)

	start_fireball()


func start_fireball() -> void:
	global_position = start_position

	has_hit = false
	is_active = true

	lifetime_timer = lifetime
	respawn_timer = 0.0

	visible = true
	monitoring = true
	set_physics_process(true)

	animated_sprite.play("attack")
	fire_attack.play()


func _physics_process(delta: float) -> void:

	# Fireball sedang tidak aktif: hitung respawn
	if not is_active:
		respawn_timer -= delta

		if respawn_timer <= 0.0:
			start_fireball()

		return

	# Gerakkan Fireball
	if not has_hit:
		global_position += direction * speed * delta

	# Hitung waktu hidup Fireball
	lifetime_timer -= delta

	if lifetime_timer <= 0.0:
		hide_fireball()


func _on_body_entered(body: Node2D) -> void:
	if has_hit or not is_active:
		return

	if body.is_in_group("player"):
		has_hit = true

		if body.has_method("take_damage"):
			body.take_damage(damage)

		hide_fireball()


func hide_fireball() -> void:
	if not is_active:
		return

	is_active = false
	has_hit = true

	set_physics_process(true)
	set_deferred("monitoring", false)

	visible = false

	respawn_timer = respawn_delay
