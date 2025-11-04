@tool
class_name Player
extends CharacterBody2D

const PLAYER_ACTIONS := {
	"jump": "player_1_jump",
	"left": "player_1_left",
	"right": "player_1_right",
	"attack": "player_1_attack",
	"up": "player_1_up",
}

@export var speed: float = 500.0:
	set = _set_speed
@export var acceleration: float = 5000.0
@export var jump_velocity: float = -880.0
@export var jump_cut_factor: float = 20.0
@export var coyote_time: float = 5.0 / 60.0
@export var jump_buffer: float = 5.0 / 60.0
@export var double_jump: bool = false

@export_group("Attack")
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.6
@export var attack_anim_speed: float = 2.0 

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var double_jump_armed: bool = false
var is_attacking: bool = false
var is_attack_up: bool = false
var _prev_sprite_speed_scale: float = 1.0
  # you can tweak this in inspector


var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var original_position: Vector2

@onready var _sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _double_jump_particles: CPUParticles2D = %DoubleJumpParticles
@onready var _attack_hitbox: Area2D = get_node_or_null("AttackHitbox")
@onready var _attack_collision_shape: CollisionShape2D = (
	_attack_hitbox.get_node_or_null("AttackCollisionShape") if _attack_hitbox else null
)
@onready var _attack_duration_timer: Timer = get_node_or_null("AttackDurationTimer")
@onready var _attack_cooldown_timer: Timer = get_node_or_null("AttackCooldownTimer")

var _attack_hitbox_default_pos: Vector2
var _attack_hitbox_default_rot: float
var _attack_hitbox_default_scale: Vector2


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return

	if _attack_hitbox:
		_attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
		_attack_hitbox_default_pos = _attack_hitbox.position
		_attack_hitbox_default_rot = _attack_hitbox.rotation
		_attack_hitbox_default_scale = _attack_hitbox.scale

		# put attack on layer 4, looking only at layer 5 (answer boxes)
		_attack_hitbox.collision_layer = 1 << 3
		_attack_hitbox.collision_mask = 1 << 4
	else:
		push_error("Missing AttackHitbox node")

	if _attack_duration_timer:
		_attack_duration_timer.one_shot = true
		_attack_duration_timer.timeout.connect(_on_attack_duration_timeout)
	if _attack_cooldown_timer:
		_attack_cooldown_timer.one_shot = true

	if _attack_collision_shape:
		_attack_collision_shape.disabled = true

	original_position = position
	_set_speed(speed)


func _set_speed(new_speed: float) -> void:
	speed = new_speed
	if not is_node_ready():
		await ready
	if _sprite:
		_sprite.speed_scale = (speed / 500.0) if speed != 0.0 else 0.0


func _jump() -> void:
	velocity.y = jump_velocity
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	if double_jump_armed:
		double_jump_armed = false
		if _double_jump_particles:
			_double_jump_particles.emitting = true
	elif double_jump:
		double_jump_armed = true


func _start_attack() -> void:
	if is_attacking:
		return
	if _attack_cooldown_timer and not _attack_cooldown_timer.is_stopped():
		return
	if not (_attack_collision_shape and _attack_duration_timer and _attack_cooldown_timer):
		return

	is_attacking = true
	is_attack_up = Input.is_action_pressed(PLAYER_ACTIONS["up"])

	_configure_hitbox_for_attack()
	_attack_collision_shape.disabled = false

	_attack_cooldown_timer.start(attack_cooldown)

	# 🎞️ Play the full attack animation smoothly
	if _sprite and _sprite.sprite_frames:
		_prev_sprite_speed_scale = _sprite.speed_scale

		if _sprite.sprite_frames.has_animation("attack"):
			# make sure animation runs at normal speed
			_sprite.speed_scale = 1.0
			_sprite.play("attack")

			# calculate animation duration = frame_count / fps
			var anim_length := float(_sprite.sprite_frames.get_frame_count("attack")) / \
				float(_sprite.sprite_frames.get_animation_speed("attack"))

			# sync attack duration timer with animation
			if _attack_duration_timer:
				_attack_duration_timer.start(anim_length)



func _configure_hitbox_for_attack() -> void:
	if not _attack_hitbox:
		return
	if is_attack_up:
		_attack_hitbox.rotation = deg_to_rad(-90.0)
		_attack_hitbox.scale = Vector2.ONE
		var offset: float = abs(_attack_hitbox_default_pos.x)
		_attack_hitbox.position = Vector2(0.0, -offset)
	else:
		_attack_hitbox.rotation = _attack_hitbox_default_rot
		_attack_hitbox.position = _attack_hitbox_default_pos
		if _sprite and _sprite.flip_h:
			_attack_hitbox.scale = Vector2(-abs(_attack_hitbox_default_scale.x), _attack_hitbox_default_scale.y)
		else:
			_attack_hitbox.scale = Vector2(abs(_attack_hitbox_default_scale.x), _attack_hitbox_default_scale.y)


func _on_attack_duration_timeout() -> void:
	is_attacking = false
	if _attack_collision_shape:
		_attack_collision_shape.disabled = true
	_restore_hitbox_transform()

	# restore normal animation speed
	if _sprite:
		_sprite.speed_scale = _prev_sprite_speed_scale



func _restore_hitbox_transform() -> void:
	if not _attack_hitbox:
		return
	_attack_hitbox.position = _attack_hitbox_default_pos
	_attack_hitbox.rotation = _attack_hitbox_default_rot
	_attack_hitbox.scale = _attack_hitbox_default_scale


func _player_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(PLAYER_ACTIONS[action])

func _player_just_released(action: String) -> bool:
	return Input.is_action_just_released(PLAYER_ACTIONS[action])

func _get_player_axis(action_a: String, action_b: String) -> float:
	return Input.get_axis(PLAYER_ACTIONS[action_a], PLAYER_ACTIONS[action_b])


func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return

	if is_on_floor():
		coyote_timer = coyote_time
		double_jump_armed = false

	if _player_just_pressed("jump"):
		jump_buffer_timer = jump_buffer

	if jump_buffer_timer > 0.0 and (coyote_timer > 0.0 or double_jump_armed):
		_jump()

	if _player_just_released("jump") and velocity.y < 0.0:
		velocity.y *= (1.0 - (jump_cut_factor / 100.0))

	if coyote_timer <= 0.0:
		velocity.y += gravity * delta

	if _player_just_pressed("attack"):
		_start_attack()

	var direction: float = _get_player_axis("left", "right")
	if not is_attacking:
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, sign(direction) * speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)

	if not is_attacking and _sprite:
		if velocity.length() == 0.0:
			_play_if_has("idle")
		else:
			if not is_on_floor():
				if velocity.y > 0.0:
					_play_if_has("jump_down")
				else:
					_play_if_has("jump_up")
			else:
				_play_if_has("walk")

		if velocity.x != 0.0:
			_sprite.flip_h = velocity.x < 0.0

	move_and_slide()
	coyote_timer -= delta
	jump_buffer_timer -= delta


func _play_if_has(anim_name: StringName) -> void:
	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		if _sprite.animation != anim_name:
			_sprite.play(anim_name)


func reset() -> void:
	position = original_position
	velocity = Vector2.ZERO
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	is_attacking = false
	double_jump_armed = false
	if _attack_collision_shape:
		_attack_collision_shape.call_deferred("set_disabled", true)
	if _attack_duration_timer:
		_attack_duration_timer.stop()
	if _attack_cooldown_timer:
		_attack_cooldown_timer.stop()
	_restore_hitbox_transform()


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	print("⚔️ Attack hit:", area.name, " (", area.get_path(), ")")

	# ignore anything that belongs to this player
	if _is_mine(area):
		print("➡️ Ignored: area is part of player")
		return

	var parent: Node = area.get_parent()

	if parent and _is_mine(parent):
		print("➡️ Ignored: parent is part of player")
		return

	if parent and parent.has_method("take_damage"):
		print("✅ Damaging: ", parent.name)
		parent.take_damage(1)
	else:
		print("❓ Hit something without take_damage(): ", parent)


func take_damage(amount: int = 1) -> void:
	push_warning("🚨 PLAYER take_damage() CALLED! amount = %d" % amount)
	print_stack()  # this will show which script/function called this

	# TEMP: comment this out so you don’t actually lose lives while debugging
	# if Global.lives > 0:
	#     Global.lives -= amount



func _is_mine(node: Node) -> bool:
	var current: Node = node
	while current:
		if current == self:
			return true
		current = current.get_parent()
	return false
