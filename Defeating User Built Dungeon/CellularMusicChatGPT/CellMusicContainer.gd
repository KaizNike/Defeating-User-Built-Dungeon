extends PanelContainer

var timeSinceStart := 0.0

func _physics_process(delta):
	if float($MusicPlaying/Label2.text) >= float($MusicPlaying/LineEdit.text):
		$CellMusicChatGPT3.reading = false
	if $CellMusicChatGPT3.reading:
		$MusicPlaying/Button.text = "Stop"
		$MusicPlaying/Label2.text = "/ " + str(timeSinceStart).pad_decimals(2) + " /"
		timeSinceStart += delta
	else:
		$MusicPlaying/Button.text = "Play"


func _on_Button_pressed():
	if $MusicPlaying/Button.text == "Play":
		$CellMusicChatGPT3.reading = true
	else:
		$CellMusicChatGPT3.reading = false
	pass # Replace with function body.
