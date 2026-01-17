class_name Player extends Entity

const SPEED_FORWARD = 4.0
const SPEED_STRAFE = 1.5
const SPEED_BACK = 2.0
const INERTIA = .3
const TURN_SPEED = 10
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.005
const ANIMATION_BLEND_DECAY = 16

@onready var camera_parent: Node3D = $Camera
var animation_blend_position: Vector2 = Vector2.ZERO

# Capture in HTML5
func _input(_event):
	if Input.is_action_just_pressed("Normal Attack"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			_try_attacking()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_parent.rotate_y(-event.relative.x * SENSITIVITY)
		# camera_parent.rotate_x(-event.relative.y * SENSITIVITY)
		camera_parent.rotation.x = clamp(camera_parent.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func exp_decay(a: float, b: float, decay: float, delta: float) -> float:
	return b+(a-b)*exp(-decay*delta)

func move(delta: float) -> void:
	if not is_on_floor(): # Gravity
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("Move Left", "Move Right", "Move Forward", "Move Backward")
	var direction := (camera_parent.transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	animation_blend_position = Vector2(
		exp_decay(animation_blend_position.x, input_dir.x, ANIMATION_BLEND_DECAY, delta),
		exp_decay(animation_blend_position.y, -input_dir.y, ANIMATION_BLEND_DECAY, delta))
	if direction and not movement_lock:
		# Animations
		model_animation_tree["parameters/conditions/moving"] = true
		model_animation_tree["parameters/Walk/blend_position"] = animation_blend_position
		if movement_debug: print("Blend Position: " + str(animation_blend_position))
		
		# Movement
		var final_speed_horizontal: float = abs(input_dir.x * SPEED_STRAFE) # Horizontal
		var final_speed_forward: float = 0.
		if input_dir.y < 0.: final_speed_forward = SPEED_FORWARD # Forward
		elif input_dir.y > 0.: final_speed_forward = + SPEED_BACK # Backward
		
		var final_speed: float = 0.
		if not final_speed_horizontal == 0. and not final_speed_forward == 0.:
			final_speed = final_speed_forward/2. + final_speed_horizontal/2.
		else: final_speed = final_speed_forward + final_speed_horizontal
		
		if movement_debug: print("Moving with speed: " + str(final_speed))
		velocity.x = direction.x * final_speed
		velocity.z = direction.z * final_speed
		
		# Rotation of Model
		var model: Node3D = $Model
		var model_position_previous = model.position
		var forward: Vector3 = -model.global_transform.basis.z
		var camera_forward: Vector3 = camera_parent.global_transform.basis.z
		if movement_debug: print("Foward: " + str(camera_forward))
		var target_vector: Vector3 = Vector3(
			exp_decay(forward.x, -camera_forward.x, TURN_SPEED, delta),
			0.,
			exp_decay(forward.z, -camera_forward.z, TURN_SPEED, delta)).normalized()
		model.look_at_from_position(Vector3.ZERO, target_vector)
		if movement_debug: print("Target   : " + str(target_vector))
		if movement_debug: print("Direction: " + str(camera_forward))
		model.position = model_position_previous # Fix Position Changes by look_at
		
	else:
		model_animation_tree["parameters/conditions/moving"] = false;
		velocity.x = move_toward(velocity.x, 0, INERTIA)
		velocity.z = move_toward(velocity.z, 0, INERTIA)

	move_and_slide()
