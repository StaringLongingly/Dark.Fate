@tool
extends EditorPlugin

var gizmo_plugin: BezierCurveGizmoPlugin

func _enter_tree():
	gizmo_plugin = BezierCurveGizmoPlugin.new()
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_node_3d_gizmo_plugin(gizmo_plugin)

# ============================================================================
# Gizmo Plugin
# ============================================================================

class BezierCurveGizmoPlugin extends EditorNode3DGizmoPlugin:
	
	func _init():
		create_material("lines", Color(1.0, 0.0, 1.0, 1.0), false, false)
		create_material("caged_lines", Color(0.0, 1.0, 1.0, 1.0), false, false)
		create_handle_material("handles", false, preload("res://addons/bezier_curve_editor/curve_small.png"))
		create_handle_material("mirror_handles", false, preload("res://addons/bezier_curve_editor/mirror_small.png"))
	
	func _get_gizmo_name():
		return "BezierCurveGizmo"
	
	func _has_gizmo(node):
		if node is MeshInstance3D:
			var material = node.get_active_material(0)
			if material and material is ShaderMaterial:
				var shader = material.shader
				if shader and shader.code.contains("x_point_0"):
					return true
		return false
	
	func _create_gizmo(node):
		return BezierCurveGizmo.new()

# ============================================================================
# Gizmo Implementation
# ============================================================================

class BezierCurveGizmo extends EditorNode3DGizmo:
	var material: ShaderMaterial
	var mesh_instance: MeshInstance3D
	
	func _redraw():
		clear()
		
		var node = get_node_3d()
		if not node is MeshInstance3D:
			return
		if not material or not material is ShaderMaterial:
			return
		
		mesh_instance = node
		material = mesh_instance.get_active_material(0)
			
		var mesh_size = material.get_shader_parameter("mesh_size")
		if mesh_size == null: return
		
		var x_p0: Vector2 = material.get_shader_parameter("x_point_0")
		var x_p1: Vector2 = material.get_shader_parameter("x_point_1")
		var x_p2: Vector2 = material.get_shader_parameter("x_point_2")
		var x_p3: Vector2 = material.get_shader_parameter("x_point_3")
		var y_p0: Vector2 = material.get_shader_parameter("y_point_0")
		var y_p1: Vector2 = material.get_shader_parameter("y_point_1")
		var y_p2: Vector2 = material.get_shader_parameter("y_point_2")
		var y_p3: Vector2 = material.get_shader_parameter("y_point_3")
		
		# Check for mirrors and adjust the points
		if material.get_shader_parameter("x_mirror"):
			x_p2 = Vector2(-x_p1.x, x_p1.y)
			x_p3 = Vector2(-x_p0.x, x_p0.y)
			
		if material.get_shader_parameter("y_mirror"):
			y_p2 = Vector2(-y_p1.x, y_p1.y)
			y_p3 = Vector2(-y_p0.x, y_p0.y)
		
		if x_p0 == null or x_p1 == null or x_p2 == null or x_p3 == null or y_p0 == null or y_p1 == null or y_p2 == null or y_p3 == null or mesh_size == null:
			return
		
		# Add handles for all 8 control points (each is 2D)
		var handles = PackedVector3Array()
		var mirror_handles = PackedVector3Array()
		handles.append(Vector3(x_p0.x, 0, x_p0.y))  # 0: X-axis P0
		handles.append(Vector3(x_p1.x, 0, x_p1.y))  # 1: X-axis P1
		if not material.get_shader_parameter("x_mirror"):
			handles.append(Vector3(x_p2.x, 0, x_p2.y))  # 2: X-axis P2
			handles.append(Vector3(x_p3.x, 0, x_p3.y))  # 3: X-axis P3
		else:
			mirror_handles.append(Vector3(x_p2.x, 0, x_p2.y))  # 2: X-axis Mirrored P2
			mirror_handles.append(Vector3(x_p3.x, 0, x_p3.y))  # 3: X-axis Mirrored P3
		handles.append(Vector3(0, y_p0.x, y_p0.y))  # 4: Y-axis P0
		handles.append(Vector3(0, y_p1.x, y_p1.y))  # 5: Y-axis P1
		if not material.get_shader_parameter("y_mirror"):
			handles.append(Vector3(0, y_p2.x, y_p2.y))  # 6: Y-axis P2
			handles.append(Vector3(0, y_p3.x, y_p3.y))  # 7: Y-axis P3
		else:
			mirror_handles.append(Vector3(0, y_p2.x, y_p2.y))  # 6: Y-axis Mirrored P2
			mirror_handles.append(Vector3(0, y_p3.x, y_p3.y))  # 7: Y-axis Mirrored P3
		
		var handle_ids := PackedInt32Array()
		for i in handles.size():
			handle_ids.append(i)

		add_handles(
			handles,
			get_plugin().get_material("handles", self),
			handle_ids,
			false,
			false
		)

		if mirror_handles.size() > 0:
			var mirror_ids := PackedInt32Array()
			for i in mirror_handles.size():
				mirror_ids.append(handles.size() + i) # unique IDs

			add_handles(
				mirror_handles,
				get_plugin().get_material("mirror_handles", self),
				mirror_ids,
				false,
				false
			)

		# Draw the bezier curve visualization
		draw_curve_preview(x_p0, x_p1, x_p2, x_p3, y_p0, y_p1, y_p2, y_p3, mesh_size)
	
	func polyline_to_segments(points: PackedVector3Array) -> PackedVector3Array:
		var segments := PackedVector3Array()
		for i in range(points.size() - 1):
			segments.append(points[i])
			segments.append(points[i + 1])
		return segments
	
	func draw_curve_preview(x_p0: Vector2, x_p1: Vector2, x_p2: Vector2, x_p3: Vector2, y_p0: Vector2, y_p1: Vector2, y_p2: Vector2, y_p3: Vector2, mesh_size: Vector2):
		var line_mat = get_plugin().get_material("lines", self)
		var cage_mat = get_plugin().get_material("caged_lines", self)
		
		# Convert 2D points to 3D for visualization
		var x_3d_p0 = Vector3(x_p0.x, 0, x_p0.y)
		var x_3d_p1 = Vector3(x_p1.x, 0, x_p1.y)
		var x_3d_p2 = Vector3(x_p2.x, 0, x_p2.y)
		var x_3d_p3 = Vector3(x_p3.x, 0, x_p3.y)
		
		# Control cage for X curve
		var x_cage = PackedVector3Array()
		x_cage.append(x_3d_p0)
		x_cage.append(x_3d_p1)
		x_cage.append(x_3d_p1)
		x_cage.append(x_3d_p2)
		x_cage.append(x_3d_p2)
		x_cage.append(x_3d_p3)
		add_lines(x_cage, cage_mat, false)
		
		# X-axis curve
		var x_points = PackedVector3Array()
		var steps = 20
		for i in range(steps + 1):
			var t = float(i) / float(steps)
			var pos = bezier_cubic_2d(t, x_p0, x_p1, x_p2, x_p3)
			x_points.append(Vector3(pos.x, 0, pos.y))
		add_lines(polyline_to_segments(x_points), line_mat, false)
		
		# Convert 2D points to 3D for Y curve
		var y_3d_p0 = Vector3(0, y_p0.x, y_p0.y)
		var y_3d_p1 = Vector3(0, y_p1.x, y_p1.y)
		var y_3d_p2 = Vector3(0, y_p2.x, y_p2.y)
		var y_3d_p3 = Vector3(0, y_p3.x, y_p3.y)
		
		# Control cage for Y curve
		var y_cage = PackedVector3Array()
		y_cage.append(y_3d_p0)
		y_cage.append(y_3d_p1)
		y_cage.append(y_3d_p1)
		y_cage.append(y_3d_p2)
		y_cage.append(y_3d_p2)
		y_cage.append(y_3d_p3)
		add_lines(y_cage, cage_mat, false)
		
		# Y-axis curve
		var y_points = PackedVector3Array()
		for i in range(steps + 1):
			var t = float(i) / float(steps)
			var pos = bezier_cubic_2d(t, y_p0, y_p1, y_p2, y_p3)
			y_points.append(Vector3(0, pos.x, pos.y))
		add_lines(polyline_to_segments(y_points), line_mat, false)
	
	func bezier_cubic_2d(t: float, p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> Vector2:
		var u = 1.0 - t
		var tt = t * t
		var uu = u * u
		var uuu = uu * u
		var ttt = tt * t
		return uuu * p0 + 3.0 * uu * t * p1 + 3.0 * u * tt * p2 + ttt * p3
	
	func bezier_cubic(t: float, p0: float, p1: float, p2: float, p3: float) -> float:
		var u = 1.0 - t
		var tt = t * t
		var uu = u * u
		var uuu = uu * u
		var ttt = tt * t
		return uuu * p0 + 3.0 * uu * t * p1 + 3.0 * u * tt * p2 + ttt * p3
	
	func _get_handle_value(handle_id: int, secondary: bool):
		if not material:
			return null
		
		var cp1 = material.get_shader_parameter("control_point_1")
		var cp2 = material.get_shader_parameter("control_point_2")
		
		if cp1 == null or cp2 == null:
			return null
		
		match handle_id:
			0: return cp1.x
			1: return cp2.x
			2: return cp1.y
			3: return cp2.y
		return null
	
	func _set_handle(handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2):
		if not material or not mesh_instance:
			return
		
		# Get the handle position in 3D space
		var handle_pos = _get_handle_pos(handle_id)
		var global_handle_pos = mesh_instance.global_transform * handle_pos
		
		# Create a ray from camera
		var ray_from = camera.project_ray_origin(screen_pos)
		var ray_dir = camera.project_ray_normal(screen_pos)
		
		# Create a plane perpendicular to the camera's forward direction
		var camera_forward = -camera.global_transform.basis.z
		var plane = Plane(camera_forward, global_handle_pos)
		
		# Intersect ray with plane
		var intersection = plane.intersects_ray(ray_from, ray_dir)
		
		if intersection == null:
			return
		
		var local_pos = mesh_instance.global_transform.affine_inverse() * intersection
		
		# Apply the change - each handle controls a 2D point
		match handle_id:
			0: material.set_shader_parameter("x_point_0", Vector2(local_pos.x, local_pos.z))
			1: material.set_shader_parameter("x_point_1", Vector2(local_pos.x, local_pos.z))
			2: if not material.get_shader_parameter("x_mirror"): material.set_shader_parameter("x_point_2", Vector2(local_pos.x, local_pos.z))
			3: if not material.get_shader_parameter("x_mirror"): material.set_shader_parameter("x_point_3", Vector2(local_pos.x, local_pos.z))
			4: material.set_shader_parameter("y_point_0", Vector2(local_pos.y, local_pos.z))
			5: material.set_shader_parameter("y_point_1", Vector2(local_pos.y, local_pos.z))
			6: if not material.get_shader_parameter("y_mirror"): material.set_shader_parameter("y_point_2", Vector2(local_pos.y, local_pos.z))
			7: if not material.get_shader_parameter("y_mirror"): material.set_shader_parameter("y_point_3", Vector2(local_pos.y, local_pos.z))
	
	func _commit_handle(handle_id: int, secondary: bool, restore, cancel: bool):
		if not material:
			return
			
		if cancel and restore != null:
			if restore is Array and restore.size() >= 8:
				material.set_shader_parameter("x_point_0", restore[0])
				if not material.get_shader_parameter("x_mirror"):
					material.set_shader_parameter("x_point_1", restore[1])
					material.set_shader_parameter("x_point_2", restore[2])
				material.set_shader_parameter("x_point_3", restore[3])
				
				material.set_shader_parameter("y_point_0", restore[4])
				if not material.get_shader_parameter("y_mirror"): 
					material.set_shader_parameter("y_point_1", restore[5])
					material.set_shader_parameter("y_point_2", restore[6])
				material.set_shader_parameter("y_point_3", restore[7])
		
		_redraw()
	
	func _get_handle_pos(handle_id: int) -> Vector3:
		if not material:
			return Vector3.ZERO
		
		var x_p0 = material.get_shader_parameter("x_point_0")
		var x_p1 = material.get_shader_parameter("x_point_1")
		var x_p2 = material.get_shader_parameter("x_point_2")
		var x_p3 = material.get_shader_parameter("x_point_3")
		var y_p0 = material.get_shader_parameter("y_point_0")
		var y_p1 = material.get_shader_parameter("y_point_1")
		var y_p2 = material.get_shader_parameter("y_point_2")
		var y_p3 = material.get_shader_parameter("y_point_3")
		
		if x_p0 == null or x_p1 == null or x_p2 == null or x_p3 == null or y_p0 == null or y_p1 == null or y_p2 == null or y_p3 == null:
			return Vector3.ZERO
		
		match handle_id:
			0: return Vector3(x_p0.x, 0, x_p0.y)
			1: return Vector3(x_p1.x, 0, x_p1.y)
			2: return Vector3(x_p2.x, 0, x_p2.y)
			3: return Vector3(x_p3.x, 0, x_p3.y)
			4: return Vector3(0, y_p0.x, y_p0.y)
			5: return Vector3(0, y_p1.x, y_p1.y)
			6: return Vector3(0, y_p2.x, y_p2.y)
			7: return Vector3(0, y_p3.x, y_p3.y)
		
		return Vector3.ZERO
