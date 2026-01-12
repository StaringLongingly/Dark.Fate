extends Node3D


@export var face_offset: Vector3 = Vector3.ZERO
@onready var skeleton_parent = $".."
@export var target_bone: BoneAttachment3D

func _ready() -> void: visible = true

func _process(_delta):
	# Get bone's global transform
	var previous_scale = scale
	var bone_idx = skeleton_parent.find_bone("mixamorig_HeadTop_End")
	var bone_global_pose: Transform3D = skeleton_parent.get_bone_global_pose(bone_idx)
	transform = bone_global_pose
	scale = previous_scale
