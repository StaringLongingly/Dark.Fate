extends Area3D
@export var debug: bool = false
@export var framepacer: Timer
@export_group("Hit Detection")
@export var animation_detection: bool = true
@export var body_enter_detection: bool = true

@export_group("Materials")
@export var mesh_instance: MeshInstance3D
@export var render_priorities: float = 2;

@export_group("Effect")
@export var trail: Trail3D
@export var effect_scene: PackedScene
@export var camera: Camera3D
var previous_tip_position := Vector3.ZERO

func _ready() -> void:
	framepacer.timeout.connect(_animation_hit)
	if trail == null: trail = find_child("Trail")
	if trail == null: printerr("Missing Trail3D for Weapon!") # Panic
	if mesh_instance == null: mesh_instance = find_child("Mesh")
	if mesh_instance == null: printerr("Missing Mesh for Weapon!") # Panic
	
	for surface_index: int in mesh_instance.mesh.get_surface_count():
		var material: StandardMaterial3D = mesh_instance.mesh.surface_get_material(surface_index)
		material.render_priority = 2
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _animation_hit() -> void:
	if not animation_detection or not monitoring: return
	var bodies: Array[Node3D] = get_overlapping_bodies()
	for body: Node3D in bodies: _damage(body, "animation")

func _physics_process(_delta: float) -> void:
	# Store previous position for effect calculation
	if trail and trail.tip_object:
		previous_tip_position = trail.tip_object.global_position
	
func _damage(body: Node3D, detection_type: String) -> void:
	if debug:
		print("Damaging:")
		print("  Body            : " + str(body))
		print("  Detection type  : " + detection_type)
	
	var did_it_hit_itsself: bool = body.find_child(name, true) == self
	if did_it_hit_itsself:
		if debug: print("  Self hit        : " + str(did_it_hit_itsself))
		return
	
	# Effect
	var effect: MeshInstance3D = effect_scene.instantiate()
	get_node("%Effects").add_child(effect)
	var effect_position: Vector3 = previous_tip_position
	if debug: print("  Effect Final Pos: " + str(effect_position))
	
	effect.global_position = effect_position
	effect.look_at(camera.global_position)

func _on_body_entered(body: Node3D) -> void:
	if not body_enter_detection: return
	_damage(body, "body entered")
