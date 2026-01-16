extends Timer

@onready var animation_tree: AnimationTree = $".."
@export var default_fps: int = 12;
@export var attack_fps: int = 24;
var player: AnimationPlayer

func _ready() -> void:
	player = animation_tree.get_node(animation_tree.anim_player)
	animation_tree.animation_started.connect(_on_animation_started)
	_on_animation_started("")
	start()

func _on_animation_started(animation_name: String):
	var fps = default_fps
	if animation_name.contains("Attack"):
		fps = attack_fps
	wait_time = 1./float(fps)

func _on_timeout() -> void:
	animation_tree.advance(wait_time)
