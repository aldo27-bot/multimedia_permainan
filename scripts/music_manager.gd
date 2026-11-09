
extends Node

const MUSIC_PATH: String = "res://assets/Audio/Backsound(2).mp3"

var music_player: AudioStreamPlayer


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.bus = "Master"
	music_player.volume_db = -8.0

	add_child(music_player)

	# Memuat musik secara otomatis
	if not ResourceLoader.exists(MUSIC_PATH):
		push_error("Musik tidak ditemukan: " + MUSIC_PATH)
		return

	var music = load(MUSIC_PATH) as AudioStream

	if music == null:
		push_error("Gagal memuat musik: " + MUSIC_PATH)
		return

	# Aktifkan looping
	music.loop = true

	music_player.stream = music
	music_player.play()


func resume_music() -> void:
	if music_player != null and not music_player.playing:
		music_player.play()


func stop_music() -> void:
	if music_player != null:
		music_player.stop()


func set_music_volume(value: float) -> void:
	if music_player != null:
		music_player.volume_db = linear_to_db(clampf(value, 0.0, 1.0))
