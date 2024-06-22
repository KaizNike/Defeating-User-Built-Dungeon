extends PanelContainer

var timeSinceStart := 0.0

func _physics_process(delta):
	if float($MusicPlaying/Label2.text) >= float($MusicPlaying/LineEdit.text):
		$SineWave.reading = false
	if $SineWave.reading:
		$MusicPlaying/Button.text = "Stop"
		$MusicPlaying/Label2.text = "/ " + str(timeSinceStart).pad_decimals(2) + " /"
		timeSinceStart += delta
	else:
		$MusicPlaying/Button.text = "Play"


func _on_Button_pressed():
	if $MusicPlaying/Button.text == "Play":
		$SineWave.reading = true
		$SineWave.play()
	else:
		$SineWave.reading = false
	pass # Replace with function body.
