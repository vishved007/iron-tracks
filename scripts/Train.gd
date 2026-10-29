extends Node2D

signal reached_target()
signal derailed(reason)

@export var speed: float = 350.0
var path_points: Array = []
var target_station_pos: Vector2 = Vector2.ZERO
var current_target_idx: int = 0
var is_running: bool = false

@onready var sprite = $Sprite2D

func start_run(points: Array, station_pos: Vector2):
	path_points = points
	target_station_pos = station_pos
	current_target_idx = 0
	if path_points.size() > 0:
		global_position = path_points[0]
		is_running = true
		SoundManager.play_sound("whistle")

func _process(delta):
	if not is_running or path_points.is_empty():
		return
	
	var target = path_points[current_target_idx]
	var dir = (target - global_position).normalized()
	var dist = global_position.distance_to(target)
	
	if dist > 4.0:
		global_position += dir * speed * delta
		sprite.rotation = lerp_angle(sprite.rotation, dir.angle(), 0.3)
	else:
		global_position = target
		current_target_idx += 1
		if current_target_idx >= path_points.size():
			is_running = false
			emit_signal("reached_target")
