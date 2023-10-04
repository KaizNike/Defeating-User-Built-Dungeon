extends AudioStreamPlayer

var playback: AudioStreamPlayback = null

var sample_rate = 22050
var buffer_size = 35500
var automaton_iterations = buffer_size / 2
var automaton_rule = 28
var steps = randi() % 128 + 1

var low_pass_filter
var cutoff_freq = 12000.0

var automaton = []
var scale = []
var notes = []
var buffer = PoolVector2Array()
var input_history = []
var output_history = []
var openFile = File.new()
var Stream = AudioStreamOGGVorbis.new()
var reading = false

export (PackedScene) var musicLineScene

func _ready():
#	randomize()
	get_tree().connect("files_dropped", self, "_files_dropped")
#	for i in range(64):
#		scale.append(i)
#		notes.append(60 + i % 12)
#	stream.mix_rate = sample_rate
#	for i in range(buffer_size):
#		buffer.append(Vector2.ZERO)
#	# Start playing audio stream
#	playback = get_stream_playback()
#	set_bus("Master")
##	yield("init_automatons", "completed")
#	play()
	pass

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
	if reading:
#		var Buffer = openFile.get_buffer(buffer_size)
		pass
	else:
#		_fill_buffer()
		pass


var output = 0.0
var alpha = 0.0

func _init():
	update_alpha()

func _files_dropped(files, screen):
	var fileIndex = 0
	var extensions = "ogg"
	for file in files:
#		if fileIndex > 1:
#			print("Only one music for now.")
#			return
		if file.get_extension() != extensions:
			continue
#		self.playing = false
#		openFile = file
		var newLine = musicLineScene.instance()
		var lineAudio = newLine.get_node("LineItemMusic")
		var lineTitle = newLine.get_node("MusicPlaying/Label")
		lineTitle.text = file.get_file()
		print(lineAudio)
		openFile.open(file, File.READ)
		Stream.set_data(openFile.get_buffer(openFile.get_len()))
		lineAudio.stream = Stream
		openFile.close()
		$Control/VSplitContainer/VBoxContainer.add_child(newLine)
		lineAudio.playing = true
		print(lineAudio.playing)
#		fileIndex += 1
#		reading = true
#	self.playing = true

func update_alpha():
	var dt = 1.0 / sample_rate
	var rc = 1.0 / (2.0 * PI * cutoff_freq)
	alpha = dt / (rc + dt)

func process_sample(input: float) -> float:
	var output_highpass = input - output
	var input_prev
	if input_history.size() > 0:
		input_prev = input_history.pop_front()
	else:
		input_prev = input
	var output_prev
	if output_history.size() > 0:
		output_prev = output_history.pop_front()
	else:
		output_prev = output_highpass
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
		var sample = sin(i * PI / sample_rate * freq)
		var volume = (automaton[i%automaton.size()]) * 0.5 + 0.5
		sample = process_sample(sample)
		buffer.set(i, Vector2(volume, volume)*sample)
	
	# Push buffer to audio stream
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(buffer[to_fill%buffer_size])
		to_fill -= 1
