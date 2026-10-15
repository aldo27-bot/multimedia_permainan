
extends CanvasLayer

@onready var health_label: Label = $HBoxContainer/HealthLabel

var connected_player: Node = null


func _ready() -> void:
	call_deferred("_connect_player")


func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		push_warning("HealthHUD: Player tidak ditemukan dalam group 'player'.")
		return

	if not player.has_signal("health_changed"):
		push_warning("HealthHUD: Player belum memiliki signal health_changed.")
		return

	connected_player = player

	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)

	_on_health_changed(player.health, player.max_health)


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_label.text = str(current_health) + " / " + str(maximum_health)
