extends PanelContainer

var timeSinceStart := 0.0
@export var musicNum = 1



#func _process(delta):
#	if $LineItemMusic.playing:
#		timeSinceStart += delta
#		$MusicPlaying/Label2.text = "/ " + str(timeSinceStart).pad_decimals(2) + " /"
	
func _physics_process(delta):
	if $LineItemMusic.playing:
		$MusicPlaying/Label2.text = str(timeSinceStart).pad_decimals(2)
		timeSinceStart = $LineItemMusic.get_playback_position() + AudioServer.get_time_since_last_mix()
		if timeSinceStart > float($MusicPlaying/LineEdit.text):
			timeSinceStart = float($MusicPlaying/LineEdit2.text)
			$LineItemMusic.play(timeSinceStart)
		elif timeSinceStart < float($MusicPlaying/LineEdit2.text):
			timeSinceStart = float($MusicPlaying/LineEdit2.text)
			$LineItemMusic.play(timeSinceStart)
		$MusicPlaying/Button.text = "Stop"
	else:
		$MusicPlaying/Button.text = "Play"


func _on_Button_pressed():
	if $LineItemMusic.playing:
		$LineItemMusic.stop()
	else:
		$LineItemMusic.play(timeSinceStart)
	pass # Replace with function body.


func _on_h_slider_drag_ended(value_changed):
	if value_changed:
		$LineItemMusic.volume_db = $MusicPlaying/HSlider.value
	pass # Replace with function body.


func _on_selected_cb_toggled(toggled_on):
	pass # Replace with function body.


func _on_label_2_text_changed(new_text: String) -> void:
	$LineItemMusic.play(float(new_text))
	pass # Replace with function body.
