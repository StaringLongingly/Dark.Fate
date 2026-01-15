class_name Trail3D extends MeshInstance3D
@export var debug: bool = false
@export var tip_object: Node3D
@export var base_object: Node3D
@export var framepacer: Timer
@export var dequeue_amount: int = 1
@export var trail_length: int = 4
@export var subdivisions: int = 2
@export var trail_material: Material
var tips: PackedVector3Array
var bases: PackedVector3Array

func _ready() -> void:
	top_level = true
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
	scale = Vector3.ONE
	
	update_trail()
	framepacer.timeout.connect(update_trail)

func enqueue(): 
	tips.append(tip_object.global_position)
	bases.append(base_object.global_position)

func dequeue(amount: int): 
	for _i in range(amount):
		if tips.size() > 0: tips.remove_at(0)
		if bases.size() > 0: bases.remove_at(0)

func update_trail() -> void:
	var active: bool = get_parent().monitoring
	if active: # Active frames of the sword
		enqueue()
		if tips.size() > trail_length:
			dequeue(1)
	else:
		dequeue(dequeue_amount)
	
	if tips.size() < 2:
		mesh = null
		return
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	
	# Calculate total number of segments (original + subdivisions)
	var total_segments = (tips.size() - 1) * (subdivisions + 1) + 1
	
	# Build vertices with interpolation
	for i in range(tips.size() - 1):
		for sub in range(subdivisions + 1):
			var t = float(sub) / float(subdivisions + 1)
			
			# Interpolate between current and next positions
			var tip_pos = tips[i].lerp(tips[i + 1], t)
			var base_pos = bases[i].lerp(bases[i + 1], t)
			
			vertices.append(tip_pos)
			vertices.append(base_pos)
			
			# Interpolate colors for smooth gradient
			var color_t = float(i * (subdivisions + 1) + sub) / float(total_segments - 1)
			colors.append(Color.RED.lerp(Color.RED * 0.5, color_t))
			colors.append(Color.BLUE.lerp(Color.BLUE * 0.5, color_t))
			
			# Calculate UV coordinates
			var u = float(i * (subdivisions + 1) + sub) / float(total_segments - 1)
			uvs.append(Vector2(u, 0.0))
			uvs.append(Vector2(u, 1.0))
	
	# Add the final segment
	vertices.append(tips[tips.size() - 1])
	vertices.append(bases[bases.size() - 1])
	colors.append(Color.RED * 0.5)
	colors.append(Color.BLUE * 0.5)
	uvs.append(Vector2(1.0, 0.0))
	uvs.append(Vector2(1.0, 1.0))
	
	# Calculate normals
	@warning_ignore("integer_division")
	for i in range(vertices.size() / 2):
		@warning_ignore("integer_division")
		if i < vertices.size() / 2 - 1:
			var tip_idx = i * 2
			var next_tip_idx = (i + 1) * 2
			var dir = (vertices[next_tip_idx] - vertices[tip_idx]).normalized()
			var up = (vertices[tip_idx] - vertices[tip_idx + 1]).normalized()
			var normal = dir.cross(up).normalized()
			
			if normal.length_squared() < 0.01:
				normal = Vector3.UP
			
			normals.append(normal)
			normals.append(normal)
		else:
			if normals.size() >= 2:
				normals.append(normals[normals.size() - 2])
				normals.append(normals[normals.size() - 2])
	
	# Create triangles
	@warning_ignore("integer_division")
	for i in range((vertices.size() / 2) - 1):
		var base_idx = i * 2
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		
		indices.append(base_idx + 1)
		indices.append(base_idx + 3)
		indices.append(base_idx + 2)
	
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	
	if trail_material:
		set_surface_override_material(0, trail_material)
	else:
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		set_surface_override_material(0, mat)
