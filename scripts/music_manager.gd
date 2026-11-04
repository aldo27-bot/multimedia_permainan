extends Node

const MUSIC_PATH: String = "res://assets/Audio/Backsound.ogg"

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	music_player.bus = "Master"
	music_player.volume_db = -8.0

	add_child(music_player)

	var music = load(MUSIC_PATH) as AudioStreamOggVorbis

	if music == null:
		push_error("Musik tidak ditemukan: " + MUSIC_PATH)
		return

	music.loop = true
	music_player.stream = music

func resume_music() -> void:
	if not music_player.playing:
		music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_music_volume(value: float) -> void:
	music_player.volume_db = linear_to_db(clampf(value, 0.0, 1.0))
