extends AudioStreamPlayer

var playback: AudioStreamPlayback = null

var sample_rate = 22050
var buffer_size = 35500
var automaton_iterations = buffer_size / 2
var automaton_rule = 28
var steps = randi() % 128 + 1

## filter parameters
#var cutoff_freq = 50
#var a = 0.1

var low_pass_filter
var cutoff_freq = 3000.0

var automaton = []
var scale = []
var notes = []
var array = []
var buffer = PoolVector2Array()
var input_history = []
var output_history = []

func _ready():
	randomize()
#	if OS.get_name() == "HTML5":
#		buffer_size -= 30000
	# Initialize automaton, scale, and notes arrays
	for i in range(64):
#		automaton.append(0)
		scale.append(i)
		notes.append(60 + i % 12)
	
#	# Initialize array with a single "on" cell in the middle
#	for i in range(64):
#		if i == 31:
#			array.append(1)
#
#		else:
#			array.append(0)

	# Initialize array with a random seed
#	var Seed = randi()
#	for i in range(automaton.size()):
#		automaton[i] = Seed & 1
#		Seed = Seed >> 1
#		if i == 31:
#			array.append(1)
#
#		else:
#			array.append(0)
#			automaton[i] = 0
	
	# Set up audio stream
#	stream.stream_format = AudioStream.FORMAT_S16_LE
#	stream.stream_channels = 2
	# Set up low-pass filter
#	get_bus("Master").AudioEffectFilter.cutoff_freq = cutoff_freq
#	low_pass_filter = cutoff_freq
#	stream.add_filter(low_pass_filter)
	stream.mix_rate = sample_rate
	for i in range(buffer_size):
		buffer.append(Vector2.ZERO)

	# Start playing audio stream
	playback = get_stream_playback()
	set_bus("Master")
#	yield("init_automatons", "completed")
	play()

func init_automatons(actorsArray : Array, cells : Vector2) -> bool:
	automaton.clear()
	clear_buffer()
	for i in cells.y:
		for j in cells.x:
			automaton.append(0)
	for actor in actorsArray:
		if actor.Char == "@":
			continue
		else:
			automaton[actor.Loc.y*cells.y+actor.Loc.x] = 1
	return true

func _process(delta):
	_fill_buffer()


var output = 0.0
var alpha = 0.0

func _init():
	update_alpha()

func update_alpha():
	var dt = 1.0 / sample_rate
	var rc = 1.0 / (2.0 * PI * cutoff_freq)
	alpha = dt / (rc + dt)

#func process_sample(input: float) -> float:
#	output = (1.0 - alpha) * output + alpha * input
#	return output

func process_sample(input: float) -> float:
	var output_highpass = input - output
	var input_prev
	if input_history.size() > 0:
		input_prev = input_history.pop_front()
	else:
		input_prev = input
#	var input_prev = input_history.size() > 0 ? input_history.pop_front() : input
	var output_prev
	if output_history.size() > 0:
		output_prev = output_history.pop_front()
	else:
		output_prev = output_highpass
#	var output_prev = output_history.size() > 0 ? output_history.pop_front() : output_highpass

	var input_filtered = (input * alpha) + (input_prev * (1.0 - alpha))
	var output_filtered = (output_highpass * alpha) + (output_prev * (1.0 - alpha))

	input_history.push_back(input_filtered)
	output_history.push_back(output_filtered)

	output = input_filtered

	return output_filtered

func set_cutoff_freq(freq: float):
	cutoff_freq = freq
	update_alpha()

func clear_buffer():
	buffer.clear()
	for i in range(buffer_size):
		buffer.append(Vector2.ZERO)

func _fill_buffer():
	if not automaton:
		return
	var randI = randi()
	# Generate automaton
	for i in range(automaton_iterations):
		var left = automaton[(i - 1 + automaton.size()) % automaton.size()]
		var center = automaton[i%automaton.size()]
		var right = automaton[(i + 1) % automaton.size()]
		var pattern = left * 4 + center * 2 + right
		if randI % steps == i:
			automaton_rule = randi() % 256
			steps = randi() % 128 + 1
		automaton[i%automaton.size()] = (automaton_rule >> pattern) & 1
	
	# Generate audio buffer
	for i in range(buffer_size):
		var note = notes[scale[automaton[i % automaton.size()]]]
		var freq = pow(2, (note - 69) / 12) * 440
		var sample = sin(i * 1 * PI / sample_rate * freq)
		# Apply low-pass filter
#		var filter = ButterworthFilter.new()
#		filter.cutoff_hz = 1000
#		sample = filter.process(sample, 1.0 / sample_rate)
#		# apply low-pass filter
#		sample = a * sample + (1 - a) * buffer[i].x
		var volume = (automaton[i%automaton.size()]) * 0.5 + 0.5
#		buffer.set(i, Vector2(sample, sample))
		sample = process_sample(sample)
		buffer.set(i, Vector2(volume, volume)*sample)
	
	# Push buffer to audio stream
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(buffer[to_fill%buffer_size])
		to_fill -= 1
