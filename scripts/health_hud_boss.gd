
extends CanvasLayer

@onready var health_label: Label = $HBoxContainer/HealthLabel

func _ready() -> void:
	call_deferred("_connect_boss")


func _connect_boss() -> void:
	var boss = get_tree().get_first_node_in_group("mobs")

	if boss == null:
		return

	if not boss.has_signal("health_changed"):
		return

	if not boss.health_changed.is_connected(_on_health_changed):
		boss.health_changed.connect(_on_health_changed)

	_on_health_changed(boss.health, boss.max_health)


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	health_label.text = str(current_health) + " / " + str(maximum_health)
