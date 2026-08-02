class_name AudioDirector
extends Node

enum MusicMode { TITLE, EXPLORATION, COMBAT }

const SAMPLE_RATE := 22050.0
const NOTE_TABLE := {
	48: 130.81, 50: 146.83, 51: 155.56, 53: 174.61, 55: 196.00,
	60: 261.63, 62: 293.66, 63: 311.13, 65: 349.23, 67: 392.00,
}
const TRACKS := {
	MusicMode.TITLE: [48, 0, 51, 0, 55, 0, 53, 0],
	MusicMode.EXPLORATION: [48, 48, 51, 0, 50, 50, 53, 0, 48, 48, 55, 53, 51, 0, 50, 0],
	MusicMode.COMBAT: [48, 55, 51, 55, 50, 55, 53, 55, 48, 60, 51, 55, 50, 62, 53, 63],
}

var music_player := AudioStreamPlayer.new()
var effects_player := AudioStreamPlayer.new()
var music_playback: AudioStreamGeneratorPlayback
var effects_playback: AudioStreamGeneratorPlayback
var mode := MusicMode.TITLE
var sample_cursor := 0
var effect_samples_remaining := 0
var effect_phase := 0.0
var effect_frequency := 440.0
var effect_volume := 0.0


func _ready() -> void:
	add_to_group("audio_director")
	_setup_player(music_player, "Music")
	_setup_player(effects_player, "Effects")
	music_playback = music_player.get_stream_playback() as AudioStreamGeneratorPlayback
	effects_playback = effects_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	_fill_music()
	_fill_effects()


func set_music_mode(next_mode: int) -> void:
	mode = clampi(next_mode, MusicMode.TITLE, MusicMode.COMBAT)
	sample_cursor = 0


func play_ui() -> void:
	_start_effect(660.0, 0.06, 0.13)


func play_move() -> void:
	_start_effect(330.0, 0.10, 0.16)


func play_hit(critical: bool = false) -> void:
	_start_effect(110.0 if critical else 165.0, 0.14, 0.24)


func play_heal() -> void:
	_start_effect(523.25, 0.18, 0.18)


func _setup_player(player: AudioStreamPlayer, bus_name: String) -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.35
	player.stream = generator
	player.bus = bus_name
	add_child(player)
	player.play()


func _fill_music() -> void:
	if music_playback == null:
		return
	var frames := music_playback.get_frames_available()
	var track: Array = TRACKS[mode]
	var step_samples := int(SAMPLE_RATE * (0.24 if mode == MusicMode.COMBAT else 0.38))
	for index in frames:
		var step := (sample_cursor / step_samples) % track.size()
		var note: int = track[step]
		var amplitude := 0.0
		if note != 0:
			var frequency: float = NOTE_TABLE[note]
			var phase := fmod(float(sample_cursor) * frequency / SAMPLE_RATE, 1.0)
			amplitude = (0.045 if phase < 0.5 else -0.045)
			if mode == MusicMode.COMBAT and fmod(float(sample_cursor), SAMPLE_RATE * 0.24) < 180.0:
				amplitude += 0.035
		music_playback.push_frame(Vector2(amplitude, amplitude))
		sample_cursor += 1


func _fill_effects() -> void:
	if effects_playback == null:
		return
	for index in effects_playback.get_frames_available():
		var value := 0.0
		if effect_samples_remaining > 0:
			var envelope := minf(1.0, float(effect_samples_remaining) / (SAMPLE_RATE * 0.03))
			value = sin(effect_phase) * effect_volume * envelope
			effect_phase += TAU * effect_frequency / SAMPLE_RATE
			effect_samples_remaining -= 1
		effects_playback.push_frame(Vector2(value, value))


func _start_effect(frequency: float, duration: float, volume: float) -> void:
	effect_frequency = frequency
	effect_samples_remaining = int(SAMPLE_RATE * duration)
	effect_volume = volume
	effect_phase = 0.0
