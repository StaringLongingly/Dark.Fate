@tool
extends BoneAttachment3D

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and not override_pose:
		var skel: Skeleton3D
		if get_use_external_skeleton():
			skel = get_node(get_external_skeleton())
		else:
			skel = get_parent()
			if skel is Skeleton3D and bone_idx < skel.get_bone_count():
				var xform: Transform3D = skel.get_bone_global_pose(bone_idx)
				global_transform = skel.global_transform * xform
