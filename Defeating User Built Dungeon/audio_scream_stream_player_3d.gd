extends AudioStreamPlayer3D

var run := false

func _ready() -> void:
	randomize()
	
func activate():
	get_child(0).wait_time = randf_range(0.9,5.9)
	run = true

func brat(wait):
	var playback : AudioStreamGeneratorPlayback = stream.instantiate_playback()
	playback.push_frame(Vector2( wait + get_child(0).wait_time * 60.0, wait + get_child(0).wait_time * 60.0))
	#stream.instantiate_playback()
	
func _physics_process(delta: float) -> void:
	if run:
		brat(delta)

func _on_timer_timeout() -> void:
	run = false
	pass # Replace with function body.
