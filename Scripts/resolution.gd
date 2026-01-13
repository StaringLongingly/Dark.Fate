extends Node

@onready var window: Window = get_window() 
@onready var base_size: Vector2i = window.content_scale_size

@export var debug: bool = false;
@export var is_widescreen: bool = false; 
var min_size = Vector2(640, 480)

func _ready():
	window.size_changed.connect(_on_window_size_changed) 
	min_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	min_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	window.min_size = Vector2i(min_size)
	_on_window_size_changed()

func _on_window_size_changed():
	var clamped_size = window.size
	var scale = clamped_size / base_size
	var scale_size = window.size / (scale.y if scale.y <= scale.x else scale.x)
	var scale_3d = min_size.y / clamped_size.y
	if debug:
		print("Window Updated!:")
		print("   New Window Size: " + str(clamped_size))
		print("   Scale Size     : " + str(scale_size))
		print("   3d Scale       : " + str(scale_3d))
	# $Fate/SubViewportContainer/SubViewport.scaling_3d_scale = scale_3d
	# window.content_scale_size = scale_size;
	if is_widescreen: window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH
