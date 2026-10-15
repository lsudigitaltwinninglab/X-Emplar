extends Node2D

@onready var exit_button: Button = $UI/ExitButton
@onready var mouse_reticle: Sprite2D = $MouseReticle
@onready var circle_visual: Sprite2D = $Arena/Circle
@onready var orb: CharacterBody2D = $Arena/Orb

#arena shrinking variables
@export var starting_arena_radius: float = 450
@export var final_arena_radius: float = 210.0

@export var shrink_delay: float = 20
@export var shrink_duration: float = 30

# orb spawning variables (orb is its own scene)
@export var orb_scene: PackedScene

@export var spawn_delay: float = 20.0
@export var spawn_interval: float = 5.0
@export var max_orbs: int = 8

@export var min_orb_scale: float = 0.5
@export var max_orb_scale: float = 1.4

var spawned_orbs: Array[CharacterBody2D] = []
var spawning_started := false

#exit button variables
var normal_scale := Vector2(1.0, 1.0)
var hover_scale := Vector2(1.15, 1.15)
var pressed_scale := Vector2(1.08, 1.08)

var scale_tween: Tween

# arena variables
var current_arena_radius: float
var starting_circle_scale: Vector2


func _ready():

	current_arena_radius = starting_arena_radius

	starting_circle_scale = circle_visual.scale

	exit_button.pressed.connect(_on_exit_button_pressed)

	exit_button.mouse_entered.connect(_on_exit_button_mouse_entered)
	exit_button.mouse_exited.connect(_on_exit_button_mouse_exited)
	exit_button.button_down.connect(_on_exit_button_button_down)
	exit_button.button_up.connect(_on_exit_button_button_up)

	exit_button.pivot_offset = exit_button.size / 2.0
	
	# wait 20 or 30(?) seconds before increasing difficulty
	await get_tree().create_timer(shrink_delay).timeout

	# begin shrinking the arena
	shrink_arena()

	# begin spawning new orbs
	start_orb_spawning()

func _process(_delta):

	# custom cursor will follow the player's mouse
	mouse_reticle.global_position = get_global_mouse_position()


func start_orb_spawning():

	spawning_started = true

	print("ORB SPAWNING STARTED!")

	while spawning_started:

		await get_tree().create_timer(spawn_interval).timeout

		if not is_inside_tree():
			return

		if spawned_orbs.size() + 1 < max_orbs:
			spawn_random_orb()


func spawn_random_orb():

	if orb_scene == null:
		push_warning("Orb scene has not been assigned!")
		return

	var new_orb = orb_scene.instantiate() as CharacterBody2D

	if new_orb == null:
		push_warning("Orb scene root must be CharacterBody2D!")
		return

	$Arena.add_child(new_orb)

	# random place inside of the arena
	var spawn_radius = current_arena_radius * 0.7
	var random_angle = randf_range(0.0, TAU)
	var random_distance = sqrt(randf()) * spawn_radius

	new_orb.position = Vector2(
		cos(random_angle),
		sin(random_angle)
	) * random_distance

	# random orb size
	var random_scale = randf_range(
		min_orb_scale,
		max_orb_scale
	)

	new_orb.scale = Vector2.ONE * random_scale

	# random movement behavior
	new_orb.movement_type = randi_range(0, 3)

	# give each orb a slightly different speed
	new_orb.move_speed = randf_range(90.0, 160.0)

	# match the current arena radius
	new_orb.arena_radius = current_arena_radius

	spawned_orbs.append(new_orb)

	print("NEW ORB SPAWNED!")
	print("Movement type: ", new_orb.movement_type)
	print("Size: ", random_scale)


func shrink_arena():

	print("SHRINKING ARENA!")

	var target_scale = starting_circle_scale * (
		final_arena_radius / starting_arena_radius
	)

	var tween = create_tween()

	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		circle_visual,
		"scale",
		target_scale,
		shrink_duration
	)

	tween.tween_method(
		update_arena_radius,
		starting_arena_radius,
		final_arena_radius,
		shrink_duration
	)


func update_arena_radius(new_radius: float):

	current_arena_radius = new_radius

	# update the original orb
	orb.arena_radius = current_arena_radius

	# update every spawned orb
	for spawned_orb in spawned_orbs:

		if is_instance_valid(spawned_orb):
			spawned_orb.arena_radius = current_arena_radius

# exit button
func _on_exit_button_mouse_entered():
	_scale_button(hover_scale)


func _on_exit_button_mouse_exited():
	_scale_button(normal_scale)


func _on_exit_button_button_down():
	_scale_button(pressed_scale)


func _on_exit_button_button_up():
	_scale_button(hover_scale)


func _scale_button(new_scale: Vector2):

	if scale_tween:
		scale_tween.kill()

	scale_tween = create_tween()

	scale_tween.tween_property(
		exit_button,
		"scale",
		new_scale,
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_exit_button_pressed():

	print("EXIT BUTTON PRESSED")

	SceneManager.return_to_previous_scene()
