extends CanvasLayer

@export_file("*.tscn") var level_menu_path: String = ""

@onready var background: ColorRect = $Background
@onready var center_container: CenterContainer = $Background/CenterContainer

var is_showing: bool = false

func _ready() -> void:
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.visible = false
	background.modulate.a = 0.0

	center_container.pivot_offset = (
		center_container.size / 2.0
	)

	center_container.scale = Vector2(0.5, 0.5)

func show_victory() -> void:
	if is_showing:
		return

	is_showing = true
	background.visible = true

	# Jeda gameplay, tetapi animasi popup tetap berjalan.
	get_tree().paused = true

	# Animasi latar menggelap.
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		0.25
	)

	# Animasi popup membesar.
	tween.parallel().tween_property(
		center_container,
		"scale",
		Vector2(1.08, 1.08),
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		center_container,
		"scale",
		Vector2.ONE,
		0.10
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished

	# Tunggu 2 detik setelah animasi selesai.
	await get_tree().create_timer(2.0, true, false, true).timeout

	if not is_inside_tree():
		return

	# Buka kembali gameplay sebelum berpindah scene.
	get_tree().paused = false

	if level_menu_path.is_empty():
		push_warning("Path Menu Level belum diatur!")
		return

	get_tree().change_scene_to_file(level_menu_path)
