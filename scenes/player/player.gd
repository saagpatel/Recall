class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 4.0
const SPRINT_SPEED: float = 6.5
const MOUSE_SENSITIVITY: float = 0.002
const GRAVITY: float = 9.8
const HEAD_BOB_AMPLITUDE: float = 0.03
const HEAD_BOB_WALK_FREQ: float = 2.4
const HEAD_BOB_SPRINT_FREQ: float = 3.2

@export var head_bob_enabled: bool = true
@export var invert_y: bool = false

@onready var camera: Camera3D = $Camera3D
@onready var interaction_manager: Node3D = $Camera3D/InteractionManager

var _head_bob_time: float = 0.0
var _camera_base_y: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_camera_base_y = camera.position.y


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		var y_modifier: float = -1.0 if invert_y else 1.0
		rotate_y(-mouse_event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-mouse_event.relative.y * MOUSE_SENSITIVITY * y_modifier)
		camera.rotation.x = clampf(camera.rotation.x, -PI / 2.0, PI / 2.0)

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_movement()
	_apply_head_bob(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _apply_movement() -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var speed: float = SPRINT_SPEED if is_sprinting else WALK_SPEED

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)


func _apply_head_bob(delta: float) -> void:
	if not head_bob_enabled:
		camera.position.y = _camera_base_y
		return

	var horizontal_velocity: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_velocity < 0.1 or not is_on_floor():
		# Smoothly return to base position when not moving
		camera.position.y = lerpf(camera.position.y, _camera_base_y, 10.0 * delta)
		return

	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var freq: float = HEAD_BOB_SPRINT_FREQ if is_sprinting else HEAD_BOB_WALK_FREQ
	_head_bob_time += delta * freq * TAU
	camera.position.y = _camera_base_y + sin(_head_bob_time) * HEAD_BOB_AMPLITUDE
