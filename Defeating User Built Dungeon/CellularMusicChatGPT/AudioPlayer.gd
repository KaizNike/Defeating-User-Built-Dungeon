extends Control

var currentSongs := []

var Stream = AudioStreamOGGVorbis.new()
var videoStreamW = VideoStreamWebm.new()
var videoStreamT = VideoStreamTheora.new()
var openFile = File.new()
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

func _files_dropped(files, screen):
	var fileIndex = 0
	var extensions = ["ogg", "ogv", "webm"]
	for file in files:
#		if fileIndex > 1:
#			print("Only one music for now.")
#			return
		if file.get_extension() in extensions:
			pass
		else:
			continue
		match file.get_extension():
			"webm":
				videoStreamW.set_file(file)
				$VSplitContainer/HBoxContainer/VideoScreen/VideoPlayer.stream = videoStreamW
				$VSplitContainer/HBoxContainer/VideoScreen/VideoPlayer.play()
				print("I do not work well!")
#				print("thanks!")
			"ogv":
				videoStreamT.set_file(file)
				$VSplitContainer/HBoxContainer/VideoScreen/VideoPlayer.stream = videoStreamT
				$VSplitContainer/HBoxContainer/VideoScreen/VideoPlayer.play()
#				print("I do not work well!")
#				print("thanks!")
			"ogg":
				var newLine = musicLineScene.instance()
				var lineAudio = newLine.get_node("LineItemMusic")
				var lineTitle = newLine.get_node("MusicPlaying/Label")
				var endTime = newLine.get_node("MusicPlaying/LineEdit")
				newLine.musicNum = currentSongs.size() + 1
				lineTitle.text = file.get_file().get_slice(".ogg",0)
		#		Will need changes
				currentSongs.append(file.get_file().get_slice(".ogg",0))
				$VSplitContainer/HBoxContainer/CurrentSongLabel.text = currentSongs[currentSongs.size()-1]
				print(lineAudio)
				openFile.open(file, File.READ)
				Stream.set_data(openFile.get_buffer(openFile.get_len()))
				lineAudio.stream = Stream
				openFile.close()
				endTime.text = str(lineAudio.stream.get_length()).pad_decimals(2)
				$VSplitContainer/ScrollContainer/VBoxContainer.add_child(newLine)
				lineAudio.playing = true
				print(lineAudio.playing)
