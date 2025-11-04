class_name Enemy
extends CharacterBody2D

## Movement
@export_range(0, 1000, 10, "suffix:px/s") var speed: float = 100.0:
	set = _set_speed
@export var fall_off_edge: bool = false
@export var player_loses_life: bool = true
@export var squashable: bool = true
@export_enum("Left:0", "Right:1") var start_direction: int = 0

## Attack settings
@export_group("Attack")
@export var can_attack: bool = true
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.2
@export var attack_only_if_player_in_front: bool = true

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: int

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _left_ray: RayCast2D = %LeftRay
@onready var _right_ray: RayCast2D = %RightRay
@onready var _hitbox: Area2D = %Hitbox
@onready var _attack_area: Area2D = get_node_or_null("AttackArea")
@onready var _attack_cooldown_timer: Timer = get_node_or_null("AttackCooldownTimer")

var _player_in_attack_range: bool = false
var _is_attacking: bool = false


func _set_speed(new_speed: float) -> void:
	speed = new_speed
	if not is_node_ready():
		await ready
	if _sprite:
		_sprite.speed_scale = speed / 100.0 if speed != 0.0 else 0.0


func _ready() -> void:
	direction = -1 if start_direction == 0 else 1

	if _hitbox:
		_hitbox.body_entered.connect(_on_hitbox_body_entered)
	if _attack_area:
		_attack_area.body_entered.connect(_on_attack_area_body_entered)
		_attack_area.body_exited.connect(_on_attack_area_body_exited)
	if _attack_cooldown_timer:
		_attack_cooldown_timer.one_shot = true
	else:
		push_warning("Enemy: Missing AttackCooldownTimer")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if not fall_off_edge:
		if direction == -1 and _left_ray and not _left_ray.is_colliding():
			direction = 1
		elif direction == 1 and _right_ray and not _right_ray.is_colliding():
			direction = -1

	if is_on_wall():
		direction *= -1

	velocity.x = direction * speed

	if _sprite:
		_sprite.flip_h = velocity.x < 0

	move_and_slide()

	# Attempt attack if player nearby
	if can_attack and _player_in_attack_range:
		_try_attack()


# ======================
# Touch / stomp logic
# ======================
func _on_hitbox_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	if squashable and body is CharacterBody2D:
		var player_body := body as CharacterBody2D
		if player_body.velocity.y > 0.0 and player_body.global_position.y < global_position.y:
			if player_body.has_method("stomp"):
				player_body.stomp()
			queue_free()
			return

	if player_loses_life:
		if body.has_method("take_damage"):
			body.take_damage(1)


# ======================
# Enemy attack system
# ======================
func _on_attack_area_body_entered(body: Node) -> void:
	if _is_player(body):
		_player_in_attack_range = true


func _on_attack_area_body_exited(body: Node) -> void:
	if _is_player(body):
		_player_in_attack_range = false


func _try_attack() -> void:
	if _attack_cooldown_timer and not _attack_cooldown_timer.is_stopped():
		return

	var player := _get_player_from_attack_area()
	if attack_only_if_player_in_front and player and not _is_player_in_front(player):
		return

	_do_attack()


func _do_attack() -> void:
	_is_attacking = true
	if _sprite and _sprite.sprite_frames.has_animation("attack"):
		_sprite.play("attack")

	var player := _get_player_from_attack_area()
	if player and player.has_method("take_damage"):
		player.take_damage(attack_damage)

	if _attack_cooldown_timer:
		_attack_cooldown_timer.start(attack_cooldown)

	_is_attacking = false


func _get_player_from_attack_area() -> Node:
	if not _attack_area:
		return null
	for body in _attack_area.get_overlapping_bodies():
		if _is_player(body):
			return body
	return null


# ======================
# Utility
# ======================
func take_damage(amount: int = 1) -> void:
	queue_free()


func _is_player(body: Node) -> bool:
	# Checks based on class_name or node name
	if body is CharacterBody2D and body.get_class() == "Player":
		return true
	if body.name.to_lower().contains("player"):
		return true
	return false


func _is_player_in_front(player: Node) -> bool:
	return (direction == 1 and player.global_position.x > global_position.x) \
		or (direction == -1 and player.global_position.x < global_position.x)
