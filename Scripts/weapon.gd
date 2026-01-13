extends Area3D

@export var debug: bool = false
@export var framepacer: Timer

#func _ready() -> void:
#	framepacer.timeout.connect(_hit)

#func _hit() -> void:
#	pass

func _on_body_entered(body: Node3D) -> void:
	if debug: print("Weapon collided with: " + str(body) + ", monitoring: " + str(monitoring))
	var did_it_hit_itsself: bool = body.find_child(name, true) == self
	if did_it_hit_itsself:
		if debug: print("Self damage detected, exiting")
		return
