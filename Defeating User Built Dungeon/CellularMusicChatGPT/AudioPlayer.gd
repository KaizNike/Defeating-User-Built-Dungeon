extends Control

var currentSongs := []

var Stream = AudioStreamOggVorbis.new()
var MP3Stream = AudioStreamMP3.new()
#var videoStreamW = VideoStreamWebm.new()
var videoStreamT = VideoStreamTheora.new()
var openFile = FileAccess
@export var musicLineScene := PackedScene.new()

var videoInside = false

func _ready():
#	randomize()
	#get_tree().connect("files_dropped", Callable(self, "_files_dropped"))
	get_viewport().files_dropped.connect(_files_dropped)
	#$VideoPopup.popup()
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

func _files_dropped(files):
	var fileIndex = 0
	var extensions = ["ogg", "ogv", "mp3"]
	for file in files:
#		if fileIndex > 1:
#			print("Only one music for now.")
#			return
		if file.get_extension() in extensions:
			pass
		else:
			continue
		match file.get_extension():
			#"webm":
				#videoStreamW.set_file(file)
				#$VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.stream = videoStreamW
				#$VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.play()
				#print("I do not work well!")
##				print("thanks!")
			"ogv":
				videoStreamT.set_file(file)
				$VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.stream = videoStreamT
				$VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.play()
#				print("I do not work well!")
#				print("thanks!")
			"ogg":
				var newLine = musicLineScene.instantiate()
				var lineAudio = newLine.get_node("LineItemMusic")
				var lineTitle = newLine.get_node("MusicPlaying/Label")
				var endTime = newLine.get_node("MusicPlaying/LineEdit")
				newLine.musicNum = currentSongs.size() + 1
				lineTitle.text = file.get_file().get_slice(".ogg",0)
		#		Will need changes
				currentSongs.append(file.get_file().get_slice(".ogg",0))
				$VSplitContainer/HBoxContainer/CurrentSongLabel.text = currentSongs[currentSongs.size()-1]
				print(lineAudio)
				#var openFile = FileAccess.open(file, FileAccess.READ)
				var stream = AudioStreamOggVorbis.load_from_file(file)
				lineAudio.stream = stream
				#openFile.close()
				endTime.text = str(lineAudio.stream.get_length()).pad_decimals(2)
				$VSplitContainer/ScrollContainer/VBoxContainer.add_child(newLine)
				lineAudio.play()
				print(lineAudio.playing)
			"mp3":
				var newLine = musicLineScene.instantiate()
				var lineAudio = newLine.get_node("LineItemMusic")
				var lineTitle = newLine.get_node("MusicPlaying/Label")
				var endTime = newLine.get_node("MusicPlaying/LineEdit")
				newLine.musicNum = currentSongs.size() + 1
				lineTitle.text = file.get_file().get_slice(".mp3",0)
		#		Will need changes
				currentSongs.append(file.get_file().get_slice(".mp3",0))
				$VSplitContainer/HBoxContainer/CurrentSongLabel.text = currentSongs[currentSongs.size()-1]
				print(lineAudio)
				var openFile = FileAccess.open(file, FileAccess.READ)
				var stream = AudioStreamMP3.new()
				stream.data = openFile.get_buffer(openFile.get_length())
				lineAudio.stream = stream
				#openFile.close()
				endTime.text = str(lineAudio.stream.get_length()).pad_decimals(2)
				$VSplitContainer/ScrollContainer/VBoxContainer.add_child(newLine)
				lineAudio.play()
				print(lineAudio.playing)


func _on_video_popup_popup_hide():
	$VideoPopup/VideoContainer.get_child(0).reparent($VSplitContainer/HBoxContainer/VideoScreen)
	videoInside = false
	pass # Replace with function body.


func _on_video_stream_player_mouse_entered():
	if not videoInside:
		if $VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.is_playing():
				$VSplitContainer/HBoxContainer/VideoScreen/Label.visible = true
	pass # Replace with function body.


func _on_video_stream_player_mouse_exited():
	$VSplitContainer/HBoxContainer/VideoScreen/Label.visible = false
	pass # Replace with function body.


func _on_video_stream_player_gui_input(event):
	if event.is_action_pressed("lmb"):
		$VSplitContainer/HBoxContainer/VideoScreen/VideoStreamPlayer.reparent($VideoPopup/VideoContainer)
		#$VideoPopup.get_child(0).owner = get_tree().current_scene
		#$VideoPopup.get_child(0).stop()
		#$VideoPopup.get_child(0).play()
		#$VideoPopup.get_child(0).expand = true
		$VideoPopup.popup()
		videoInside = true
		pass
	pass # Replace with function body.
