extends Area3D

@export var debug: bool = false
@export var framepacer: Timer

@export_category("Hit Detection")
@export var animation_detection: bool = true
@export var body_enter_detection: bool = true

func _ready() -> void:
	framepacer.timeout.connect(_animation_hit)

func _animation_hit() -> void:
	if not animation_detection: return
	var bodies: Array[Node3D] = get_overlapping_bodies()
	for body: Node3D in bodies: _damage(body, "animation")
	
func _damage(body: Node3D, detection_type: String) -> void:
	if debug:
		print("Damaging:")
		print("  Body          : " + str(body))
		print("  Detection type: " + detection_type)
	var did_it_hit_itsself: bool = body.find_child(name, true) == self
	if did_it_hit_itsself:
		if debug: print("  Self hit      : " + str(did_it_hit_itsself))
		return

func _on_body_entered(body: Node3D) -> void:
	if not body_enter_detection: return
	_damage(body, "body entered")
