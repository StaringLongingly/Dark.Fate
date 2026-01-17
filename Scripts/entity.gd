@abstract
class_name Entity extends CharacterBody3D

@export var hp: float = 100.
@export var model_animation_tree: AnimationTree
@export var movement_lock: bool = false

@export_category("Debug")
@export var general_debug: bool = false
@export var damage_debug: bool = false
@export var movement_debug: bool = false
@export var animation_debug: bool = false

var damages_over_time: Array[Vector2] # x is the duration, y is the dps
var animation_buffer: Array[String]

func _ready() -> void:
	if model_animation_tree:
		model_animation_tree.connect("animation_finished", _on_animation_finished)
		model_animation_tree.connect("animation_started", _on_animation_started)

@abstract func move(delta: float) -> void

func _process(delta: float) -> void:
	move(delta)

func apply_dot(delta: float) -> void:
	# Apply DoT
	for dot: Vector2 in damages_over_time:
		hp -= dot.y * delta
		dot.x -= delta
		if dot.x < 0.: damages_over_time.erase(dot) # DoT finished

func take_damage(dealer: Entity, damage: float = 0, dot_duration: float = 1, dot_dps: float = 0, lifesteal: float = 0):
	if damage_debug: 
		print("Entity Took Damage:")
		print("  dealer      : "+str(dealer))
		print("  reciever    : "+str(self))
		print("  damage      : "+str(damage))
		print("  dot_dps     : "+str(dot_dps))
		print("  dot_duration: "+str(dot_duration))
		print("  lifesteal   : "+str(lifesteal))
	hp -= damage
	if dot_duration > 0. and dot_dps != 0.: damages_over_time.append(Vector2(dot_duration, dot_dps))
	if lifesteal > 0:
		dealer.take_damage(self, -lifesteal)
	if hp <= 0:
		death()

func death():
	print("Entity Died: "+str(name))
	queue_free()

func _try_attacking() -> void:
	buffer_animation("start_attacking", "Sword LtR Heavy Attack")
	
func buffer_animation(condition: String, anim_name) -> void:
	animation_buffer.push_front(condition+":"+anim_name)
	model_animation_tree["parameters/conditions/"+condition] = true
	
func _on_animation_finished(anim_name: StringName) -> void:
	if animation_debug: print("Animation Finished: " + anim_name)
	if anim_name.contains("Attack"): movement_lock = false
		
func _on_animation_started(anim_name: StringName) -> void:
	if animation_debug: print("Animation Started: " + anim_name)
	if anim_name.contains("Attack"): movement_lock = true
	for queued_anim_name: String in animation_buffer:
		if queued_anim_name.contains(anim_name):
			var condition: String = queued_anim_name.get_slice(":", 0)
			model_animation_tree["parameters/conditions/"+condition] = false
			break
	animation_buffer.clear()
