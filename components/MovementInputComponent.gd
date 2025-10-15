class_name MovementInputComponent
extends Node

## Component that handles movement input (WASD and jump)
## Attach to any scene to give it player-controlled movement input
## Emits signals that Movement3DComponent can listen to

# Signals
signal movement_input(direction: Vector2)
signal jump_requested()

# Configurable action names
@export var move_forward_action := "move_forward"
@export var move_back_action := "move_back"
@export var move_left_action := "move_left"
@export var move_right_action := "move_right"
@export var jump_action := "jump"

func _physics_process(_delta: float) -> void:
	# Get WASD input as a 2D vector (x = left/right, y = forward/back)
	var input_vector := Input.get_vector(
		move_left_action,
		move_right_action,
		move_forward_action,
		move_back_action
	)

	# Normalize to prevent faster diagonal movement
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()

	# Always emit movement input (even if zero) to allow smooth stopping
	emit_signal("movement_input", input_vector)

	# Check for jump input (one-time action)
	if Input.is_action_just_pressed(jump_action):
		emit_signal("jump_requested")
