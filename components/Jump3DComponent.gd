class_name Jump3DComponent
extends Node

## Component that handles jumping and gravity
## Attach to any CharacterBody3D to give it jumping capabilities
## Works with player input, AI controllers, or any system that calls perform_jump()

# Jump parameters
@export var jump_velocity := 4.5
@export var gravity := 9.8

# Reference to the parent CharacterBody3D
var character_body: CharacterBody3D

func _ready() -> void:
	# Get reference to parent CharacterBody3D
	character_body = get_parent() as CharacterBody3D
	if not character_body:
		push_error("Jump3DComponent must be child of CharacterBody3D")

func _physics_process(delta: float) -> void:
	if not character_body:
		return

	# Apply gravity when not on floor
	if not character_body.is_on_floor():
		character_body.velocity.y -= gravity * delta

# Called by any controller (player input, AI, etc.) to trigger a jump
func perform_jump() -> void:
	if character_body and character_body.is_on_floor():
		character_body.velocity.y = jump_velocity
