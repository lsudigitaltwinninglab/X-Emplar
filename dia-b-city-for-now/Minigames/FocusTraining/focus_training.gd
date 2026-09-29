extends Node2D

@onready var exit_button: Button = $UI/ExitButton
@onready var mouse_reticle: Sprite2D = $MouseReticle
@onready var circle_visual: Sprite2D = $Arena/Circle
@onready var orb: CharacterBody2D = $Arena/Orb

#arena shrinking variables
@export var starting_arena_radius: float = 350.0
@export var final_arena_radius: float = 210.0

@export var shrink_delay: float = 20
@export var shrink_duration: float = 30

#exit button
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


	# shrink timer (delay before shrinking arena)
	await get_tree().create_timer(shrink_delay).timeout

	shrink_arena()


func _process(_delta):

	# Make the custom cursor follow the mouse
	mouse_reticle.global_position = get_global_mouse_position()


#arena shrinking 
func shrink_arena():
	print("SHRINKING ARENA!")

	var target_scale = starting_circle_scale * 0.6

	var tween = create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		circle_visual,
		"scale",
		target_scale,
		shrink_duration
	)


	#update gameplay arena when shrinking visual
	tween.tween_method(
		update_arena_radius,
		starting_arena_radius,
		final_arena_radius,
		shrink_duration
	)


func update_arena_radius(new_radius: float):

	current_arena_radius = new_radius

	# tells the orb what the new playable radius is
	orb.arena_radius = current_arena_radius


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
