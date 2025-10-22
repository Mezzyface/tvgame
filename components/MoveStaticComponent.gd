class_name MoveStaticComponent
extends Node

## Component that handles movement for static/animatable bodies
## Attach to AnimatableBody3D or StaticBody3D to move them programmatically
## These bodies won't be pushed by collisions - they move on rails

# Movement parameters
@export var speed := 5.0
@export var acceleration := 10.0
@export var deceleration := 10.0

# Reference to the parent body
var parent_body: Node3D
var velocity := Vector3.ZERO

# Current movement direction (set externally via apply_movement)
var current_direction := Vector2.ZERO

func _ready() -> void:
	# Get reference to parent body
	parent_body = get_parent() as Node3D
	if not parent_body:
		push_error("MoveStaticComponent must be child of a Node3D")

func _physics_process(delta: float) -> void:
	if not parent_body:
		return

	# Apply horizontal movement based on current direction
	_apply_horizontal_movement(delta)

	# Move the body directly
	parent_body.global_position += velocity * delta

func _apply_horizontal_movement(delta: float) -> void:
	# Convert 2D input to 3D direction relative to body's rotation
	var direction := (parent_body.transform.basis * Vector3(current_direction.x, 0, current_direction.y)).normalized()

	if direction:
		# Accelerate towards target speed
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	else:
		# Decelerate when no input
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

# Called by any controller to set movement direction
# input_direction: Vector2 where x = left/right, y = forward/back (normalized)
func apply_movement(input_direction: Vector2) -> void:
	current_direction = input_direction
