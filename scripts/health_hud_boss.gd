
extends CanvasLayer

@onready var health_label: Label = $HBoxContainer/HealthLabel

var current_boss: Node = null


func _ready() -> void:
	call_deferred("_connect_boss")


func _connect_boss() -> void:
	# Prioritaskan Boss 1 jika tersedia.
	var boss = get_tree().get_first_node_in_group("boss1")

	# Jika Boss 1 tidak ada, cari Boss 2.
	if boss == null:
		boss = get_tree().get_first_node_in_group("boss2")

	if boss == null:
		push_warning("HUD: Boss 1 atau Boss 2 tidak ditemukan.")
		return

	if not boss.has_signal("health_changed"):
		push_warning("HUD: Boss tidak memiliki signal health_changed.")
		return

	current_boss = boss

	if not current_boss.health_changed.is_connected(_on_health_changed):
		current_boss.health_changed.connect(_on_health_changed)

	# Tampilkan HP aktual boss saat HUD terhubung.
	_on_health_changed(
		current_boss.health,
		current_boss.max_health
	)

	print("HUD terhubung ke: ", current_boss.name)


func _on_health_changed(
	current_health: int,
	maximum_health: int
) -> void:
	health_label.text = str(current_health) + " / " + str(maximum_health)
