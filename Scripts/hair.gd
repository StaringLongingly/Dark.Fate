extends MeshInstance3D

@onready var skeleton_parent = $".."

func _process(_delta):
	# Get bone's global transform
	var bone_idx = skeleton_parent.find_bone("mixamorig_Head")
	var bone_global_pose = skeleton_parent.get_bone_global_pose(bone_idx)
	var bone_transform = skeleton_parent.global_transform * Transform3D(bone_global_pose)
	
	var reference_world_pos = bone_transform.origin
	
	# Get inverse rotation matrix (to transform from world to bone local space)
	var reference_rotation = bone_transform.basis.inverse()
	
	# Update shader uniforms
	var material = get_active_material(0)
	material.set_shader_parameter("reference_point", reference_world_pos)
	material.set_shader_parameter("reference_rotation", reference_rotation)
