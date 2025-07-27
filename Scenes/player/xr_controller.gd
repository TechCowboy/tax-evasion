extends XROrigin3D


func _on_left_virtual_xr_controller_3d_button_pressed(p_name: String) -> void:
	Globals.controllers.emit("l-"+p_name)

func _on_right_virtual_xr_controller_3d_button_pressed(p_name: String) -> void:
	Globals.controllers.emit("r-"+p_name)
