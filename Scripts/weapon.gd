class_name Weapon extends Area3D
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
		material.render_priority = render_priorities
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _animation_hit() -> void:
	if not animation_detection or not monitoring: return
	var bodies: Array[Node3D] = get_overlapping_bodies()
	for body: Node3D in bodies: _damage(body, "animation")
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
	
	damage_effect()

func damage_effect():
	var effect: MeshInstance3D = effect_scene.instantiate()
	get_node("%Effects").add_child(effect)
	var tip_position: Vector3 = trail.tip_object.global_position
	var average_position: Vector3 = lerp(previous_tip_position, tip_position, .5)
	var effect_plane := Plane(
			(average_position-camera.global_position).normalized(),
			average_position)
	var effect_position: Vector3 = effect_plane.project(previous_tip_position)
	var effect_target_position: Vector3 = effect_plane.project(tip_position)

	var effect_scale = effect.scale

	var x_axis = (effect_position-effect_target_position).normalized()
	var z_axis = (camera.global_position-effect_target_position).normalized()
	var y_axis = x_axis.cross(z_axis).normalized()
	z_axis = y_axis.cross(x_axis).normalized()  # Ensure perfect perpendicularity

	effect.global_transform.basis = Basis(x_axis, y_axis, z_axis)
	effect.global_position = effect_position
	
	effect.scale = effect_scale * (effect_target_position-effect_position).length()
	
	# Effect Particles
	var particles: DirectedGPUParticles3D = effect.find_child("DirectedGPUParticles3D")
	particles.target = self
	
	var animation_player: AnimationPlayer = effect.find_child("AnimationPlayer")
	if animation_player: animation_player.play("Hit")

func _on_body_entered(body: Node3D) -> void:
	if not body_enter_detection: return
	_damage(body, "body entered")
