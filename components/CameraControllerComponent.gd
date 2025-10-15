class_name CameraControllerComponent
extends Node

## Component that controls camera rotation
## Generic component that can receive rotation commands from any source:
## - MouseLookComponent
## - GamepadLookComponent
## - Cinematic sequences
## - AI camera control

# Configurable parameters
@export var min_pitch := -89.0 ## Minimum pitch angle in degrees (looking down)
@export var max_pitch := 89.0 ## Maximum pitch angle in degrees (looking up)
@export var camera_path: NodePath ## Path to the Camera3D node

# References
var camera: Camera3D
var character_body: CharacterBody3D
var current_pitch := 0.0

func _ready() -> void:
	# Get camera reference
	if camera_path:
		camera = get_node(camera_path) as Camera3D
	else:
		# Try to find Camera3D in parent or siblings
		camera = get_parent().find_child("Camera3D", true, false) as Camera3D

	if not camera:
		push_error("CameraControllerComponent: No Camera3D found. Set camera_path or add Camera3D as sibling.")
		return

	# Get CharacterBody3D reference for yaw rotation
	character_body = get_parent() as CharacterBody3D
	if not character_body:
		push_error("CameraControllerComponent must be child of CharacterBody3D")
		return

## Apply relative camera rotation (delta values)
## Can be called by any input source (mouse, gamepad, AI, etc.)
## pitch_delta: Rotation around X axis (up/down) in radians
## yaw_delta: Rotation around Y axis (left/right) in radians
func apply_rotation_delta(pitch_delta: float, yaw_delta: float) -> void:
	if not camera or not character_body:
		return

	# Apply yaw (left/right) to the character body
	character_body.rotate_y(yaw_delta)

	# Apply pitch (up/down) to the camera with clamping
	current_pitch += pitch_delta
	current_pitch = clamp(current_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

	# Set camera rotation (only pitch, yaw is handled by character body rotation)
	camera.rotation.x = current_pitch

## Set absolute camera rotation (for cinematics or teleporting)
## pitch: Absolute rotation around X axis (up/down) in radians
## yaw: Absolute rotation around Y axis (left/right) in radians
func set_rotation(pitch: float, yaw: float) -> void:
	if not camera or not character_body:
		return

	# Set yaw on character body
	character_body.rotation.y = yaw

	# Set pitch on camera with clamping
	current_pitch = clamp(pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	camera.rotation.x = current_pitch

## Get current camera pitch in radians
func get_pitch() -> float:
	return current_pitch

## Get current camera yaw in radians
func get_yaw() -> float:
	if character_body:
		return character_body.rotation.y
	return 0.0
