extends Area3D

@export var debug: bool = false

func _on_body_entered(body: Node3D) -> void:
	if debug: print("Weapon collided with: " + str(body))
