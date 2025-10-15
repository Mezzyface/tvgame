class_name Walk3DComponent
extends Node

## Component that handles horizontal 3D walking movement
## Attach to any CharacterBody3D to give it walking capabilities
## Works with player input, AI controllers, or any system that calls apply_movement()

# Movement parameters
@export var speed := 5.0
@export var acceleration := 10.0
@export var deceleration := 10.0

# Reference to the parent CharacterBody3D
var character_body: CharacterBody3D

# Current movement direction (set externally via apply_movement)
var current_direction := Vector2.ZERO

func _ready() -> void:
	# Get reference to parent CharacterBody3D
	character_body = get_parent() as CharacterBody3D
	if not character_body:
		push_error("Walk3DComponent must be child of CharacterBody3D")

func _physics_process(delta: float) -> void:
	if not character_body:
		return

	# Apply horizontal movement based on current direction
	_apply_horizontal_movement(delta)

	# Call move_and_slide on the parent
	character_body.move_and_slide()

func _apply_horizontal_movement(delta: float) -> void:
	# Convert 2D input to 3D direction relative to character's rotation
	var direction := (character_body.transform.basis * Vector3(current_direction.x, 0, current_direction.y)).normalized()

	if direction:
		# Accelerate towards target speed
		character_body.velocity.x = move_toward(character_body.velocity.x, direction.x * speed, acceleration * delta)
		character_body.velocity.z = move_toward(character_body.velocity.z, direction.z * speed, acceleration * delta)
	else:
		# Decelerate when no input
		character_body.velocity.x = move_toward(character_body.velocity.x, 0, deceleration * delta)
		character_body.velocity.z = move_toward(character_body.velocity.z, 0, deceleration * delta)

# Called by any controller (player input, AI, etc.) to set movement direction
# input_direction: Vector2 where x = left/right, y = forward/back (normalized)
func apply_movement(input_direction: Vector2) -> void:
	current_direction = input_direction
