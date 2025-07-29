extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.player_instance = $"XR Controller"

	var timer:Timer = Timer.new()

	add_child(timer)
	while Globals.nav_region == null: 
		timer.wait_time = 1
		timer.autostart = false
		timer.one_shot = false
		timer.start()
		await timer.timeout
		
	timer.queue_free()


			
	
