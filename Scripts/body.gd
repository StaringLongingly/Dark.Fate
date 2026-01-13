extends MeshInstance3D

@export var debug: bool = false

@export var head: BoneAttachment3D;
@export var left_hand: Node3D;
@export var right_hand: Node3D;
@export var left_foot: BoneAttachment3D;
@export var right_foot: BoneAttachment3D;

func _process(_delta):
	# Update shader uniforms
	var material = get_active_material(0) # Chainmail armor
	if debug: print("Setting appendiges for material: " + str(material))
	material.set_shader_parameter("head_pos", head.global_position)
	material.set_shader_parameter("left_hand_pos", left_hand.global_position)
	material.set_shader_parameter("right_hand_pos", right_hand.global_position)
	material.set_shader_parameter("left_foot_pos", left_foot.global_position)
	material.set_shader_parameter("right_foot_pos", right_foot.global_position)
