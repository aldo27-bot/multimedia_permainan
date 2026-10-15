extends Node2D

@onready var player = $Player

@export var death_y: float = 530.0

var spawn_position: Vector2
var respawning := false


func _ready():
	spawn_position = player.global_position

	print("SPAWN POSITION: ", spawn_position)


func _physics_process(_delta):
	if respawning:
		return

	if player.is_dead:
		return

	if player.global_position.y > death_y:
		player_die()


func player_die():
	respawning = true

	player.die()

	await get_tree().create_timer(3.0).timeout

	player.global_position = spawn_position
	player.velocity = Vector2.ZERO

	# Reset Player
	player.is_dead = false

	# Reset Sprite
	player.sprite.animation = "idle"
	player.sprite.frame = 0
	player.sprite.play("idle")

	respawning = false
