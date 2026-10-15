
extends CharacterBody2D

enum MovementType {
	SMOOTH,
	JITTERY,
	DARTING,
	ERRATIC
}

@export var movement_type: MovementType = MovementType.SMOOTH

@export var move_speed: float = 120.0
@export var direction_change_time: float = 1.0
@export var arena_radius: float = 350.0

@export var grab_radius: float = 50.0
@export var grab_strength: float = 18.0
@export var grab_damping: float = 8.0

var target_velocity := Vector2.ZERO
var direction_timer := 0.0

var is_outside_arena := false
var is_grabbed := false
var grab_offset := Vector2.ZERO


func _ready():
	direction_timer = randf_range(0.1, direction_change_time)


func _physics_process(delta):

	direction_timer -= delta

	if direction_timer <= 0.0:
		change_direction()

	# Different movement smoothing
	var smoothing = 2.0

	match movement_type:
		MovementType.SMOOTH:
			smoothing = 2.0

		MovementType.JITTERY:
			smoothing = 12.0

		MovementType.DARTING:
			smoothing = 8.0

		MovementType.ERRATIC:
			smoothing = 18.0

	velocity = velocity.lerp(
		target_velocity,
		clampf(smoothing * delta, 0.0, 1.0)
	)

	handle_mouse_grab()

	if is_grabbed:
		apply_grab_force(delta)

	move_and_slide()

	check_arena_boundary()


func change_direction():

	var random_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	match movement_type:

		MovementType.SMOOTH:
			direction_timer = 1.0
			target_velocity = random_direction * move_speed

		MovementType.JITTERY:
			direction_timer = randf_range(0.08, 0.25)
			target_velocity = random_direction * move_speed * 1.2

		MovementType.DARTING:
			direction_timer = randf_range(0.5, 1.5)

			if randf() < 0.45:
				target_velocity = random_direction * move_speed * 3.0
			else:
				target_velocity = random_direction * move_speed * 0.5

		MovementType.ERRATIC:
			direction_timer = randf_range(0.15, 0.45)
			target_velocity = random_direction * move_speed * 2.0


func handle_mouse_grab():

	var mouse_position = get_global_mouse_position()
	var distance_to_mouse = global_position.distance_to(mouse_position)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		if not is_grabbed:

			if distance_to_mouse <= grab_radius:

				is_grabbed = true
				grab_offset = global_position - mouse_position

				print("ORB GRABBED")

	else:

		if is_grabbed:
			is_grabbed = false
			print("ORB RELEASED")


func apply_grab_force(delta):

	var mouse_position = get_global_mouse_position()
	var target_position = mouse_position + grab_offset
	var difference = target_position - global_position

	velocity += difference * grab_strength * delta
	velocity *= maxf(0.0, 1.0 - grab_damping * delta)


func check_arena_boundary():

	var distance_from_center = position.length()

	if distance_from_center > arena_radius:

		if not is_outside_arena:
			is_outside_arena = true
			print("ORB LEFT ARENA!")

	else:

		if is_outside_arena:
			is_outside_arena = false
			print("ORB RETURNED TO ARENA")
