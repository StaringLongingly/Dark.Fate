extends Area3D

@export var debug: bool = false

func _on_body_entered(body: Node3D) -> void:
	if debug: print("Weapon collided with: " + str(body))
	var did_it_hit_itsself: bool = body.find_child(name, true) == self
	if did_it_hit_itsself:
		if debug: print("Self damage detected, exiting")
		return
