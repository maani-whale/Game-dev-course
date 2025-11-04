extends Node2D
class_name MovingPlatform

## Where to move to (global)
@export var end_position: Vector2
## Movement speed in pixels/sec
@export var move_speed: float = 120.0
## If true, platform starts moving immediately (for testing)
@export var start_active: bool = false
## If true, it will move back to start after reaching end
@export var ping_pong: bool = false

var _start_position: Vector2
var _is_active: bool = false
var _moving_to_end: bool = true


func _ready() -> void:
	_start_position = global_position
	if start_active:
		_is_active = true


func start_moving() -> void:
	_is_active = true


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	var target: Vector2 = end_position if _moving_to_end else _start_position
	var new_pos: Vector2 = global_position.move_toward(target, move_speed * delta)
	global_position = new_pos

	# check if reached
	if global_position.distance_to(target) < 1.0:
		if ping_pong:
			_moving_to_end = not _moving_to_end
		else:
			_is_active = false
