@abstract
class_name Weapon extends Area3D

@export_category("Stats")
var damage: float = 10.
var dot_duration: float = 0.
var dot_dps: float = 0.
var lifesteal: float = 0.

@export_group("Hit Detection")
@export var animation_detection: bool = true
@export var body_enter_detection: bool = true
enum DetectionType {ANIMATION, BODY_ENTER}

@export_category("Debug")
@export var debug: bool = false

@abstract
func try_dealing_damage(entity: Entity, detection_type: DetectionType) -> void

func _animation_hit() -> void:
	if not animation_detection or not monitoring: return
	for body: Node3D in get_overlapping_bodies():
		if body is Entity:
			if debug: print("Dealing damage to: "+str(body))
			try_dealing_damage(body, DetectionType.ANIMATION)
		else:
			non_entity_hit(DetectionType.BODY_ENTER, body)

func _on_body_entered(body: Node3D) -> void:
	if not body_enter_detection: return
	if body is Entity:
		try_dealing_damage(body, DetectionType.BODY_ENTER)
	else: 
		non_entity_hit(DetectionType.BODY_ENTER, body)

func non_entity_hit(detection_type: DetectionType, body: Node) -> void:
	printerr("Weapon hit on a non-entity!")
	printerr("  Weapon        : "+str(self))
	printerr("  Detection type: "+str(detection_type))
	printerr("  Body          : "+str(body))
	printerr("  Body Class    : "+str(body.get_class()))
