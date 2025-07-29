extends XROrigin3D

func _ready() -> void:
	Globals.camera_instance = $XRCamera3D
	
# Called when the node enters the scene tree for the first time.


func _on_left_xr_controller_3d_button_pressed(_name: String) -> void:
	pass # Replace with function body.


func _on_right_xr_controller_3d_button_pressed(_name: String) -> void:
	pass # Replace with function body.
