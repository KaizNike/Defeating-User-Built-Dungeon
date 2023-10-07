extends PanelContainer

var timeSinceStart := 0.0

#func _process(delta):
#	if $LineItemMusic.playing:
#		timeSinceStart += delta
#		$MusicPlaying/Label2.text = "/ " + str(timeSinceStart).pad_decimals(2) + " /"
	
func _physics_process(delta):
	if $LineItemMusic.playing:
		timeSinceStart += delta
		$MusicPlaying/Label2.text = "/ " + str(timeSinceStart).pad_decimals(2) + " /"
