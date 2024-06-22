extends AudioStreamPlayer

var reading = false
var playback # Will hold the AudioStreamGeneratorPlayback.
@onready var sample_hz = self.stream.mix_rate
var pulse_hz = 440.0 # The frequency of the sound wave.

func _ready():
	self.play()
	playback = self.get_stream_playback()
	fill_buffer()
	

func _process(delta):
	if reading:
		print(playback.get_frames_available())
		fill_buffer()
	else:
		stop()

func fill_buffer():
	var phase = 0.0
	var increment = pulse_hz / sample_hz
	var frames_available = playback.get_frames_available()

	for i in range(frames_available):
		playback.push_frame(Vector2.ONE * sin(phase * TAU))
		phase = fmod(phase + increment, 1.0)
