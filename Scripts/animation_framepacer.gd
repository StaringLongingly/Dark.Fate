extends Timer

@onready var animation_tree: AnimationTree = $".."
@export var fps: float = 12.;

func _ready() -> void:
	wait_time = 1./fps
	start()

func _on_timeout() -> void:
	animation_tree.advance(wait_time)
