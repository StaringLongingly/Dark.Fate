class_name DirectedGPUParticles3D
extends GPUParticles3D

@export var target: Node3D
@export var attraction_strength: float = 5.0
@export var max_speed: float = 10.0
@export var damping: float = 0.98
@export var initial_speed: float = 2.0
@export var emission_direction_angle: float = 25.
@export var stretch_factor: float = 2.0
@export var despawn_distance: float = 0.2

var _initialized = false
var _previous_position: Vector3

func _ready():
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load("res://Shaders/blood_hit_particles.gdshader")
	process_material = shader_material
	
	local_coords = false
	draw_passes = 1
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	draw_pass_1 = sphere
	
	_previous_position = global_position
	emitting = false

func _process(_delta):
	if not _initialized:
		_initialized = true

		if process_material is ShaderMaterial and target:
			process_material.set_shader_parameter("target_position", target.global_position)
			process_material.set_shader_parameter("emitter_position", global_position)
			process_material.set_shader_parameter("emission_direction", global_basis.x)
			process_material.set_shader_parameter("emission_direction_angle", emission_direction_angle)
			process_material.set_shader_parameter("attraction_strength", attraction_strength)
			process_material.set_shader_parameter("max_speed", max_speed)
			process_material.set_shader_parameter("damping", damping)
			process_material.set_shader_parameter("initial_speed", initial_speed)
			process_material.set_shader_parameter("stretch_factor", stretch_factor)
			process_material.set_shader_parameter("despawn_distance", despawn_distance)
	elif target and process_material is ShaderMaterial:
		process_material.set_shader_parameter("target_position", target.global_position)
	
	_previous_position = global_position
