class_name Crouch3DComponent
extends Node

## Component that handles crouching for a CharacterBody3D
## Automatically adjusts collision shape height and camera position
## Works with player input or any system that calls set_crouching()

@export_group("Crouch Settings")
## Height multiplier when crouched (0.5 = half height)
@export var crouch_height_multiplier := 0.5
## Speed to transition between stand/crouch
@export var crouch_transition_speed := 10.0
## Movement speed multiplier when crouched (0.5 = half speed)
@export var crouch_speed_multiplier := 0.5

@export_group("Node Paths")
## Path to the CollisionShape3D (leave empty for auto-detect)
@export var collision_shape_path: NodePath = ""
## Path to the Camera3D (leave empty for auto-detect)
@export var camera_path: NodePath = ""

# Internal references
var character_body: CharacterBody3D
var collision_shape: CollisionShape3D
var camera: Camera3D
var walk_component: Walk3DComponent

# State
var is_crouching := false
var original_height: float = 0.0
var original_camera_y: float = 0.0
var original_speed: float = 0.0
var target_height: float = 0.0
var target_camera_y: float = 0.0

func _ready() -> void:
	# Get reference to parent CharacterBody3D
	character_body = get_parent() as CharacterBody3D
	if not character_body:
		push_error("Crouch3DComponent must be child of CharacterBody3D")
		return

	# Find collision shape
	_find_collision_shape()
	if not collision_shape:
		push_error("Crouch3DComponent: Could not find CollisionShape3D")
		return

	# Find camera
	_find_camera()
	if camera:
		original_camera_y = camera.position.y
		target_camera_y = original_camera_y

	# Find walk component to modify speed
	walk_component = character_body.get_node_or_null("Walk3DComponent")
	if walk_component:
		original_speed = walk_component.speed

	# Store original height
	if collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		original_height = capsule.height
		target_height = original_height
	elif collision_shape.shape is BoxShape3D:
		var box = collision_shape.shape as BoxShape3D
		original_height = box.size.y
		target_height = original_height

func _find_collision_shape() -> void:
	if not collision_shape_path.is_empty():
		collision_shape = get_node_or_null(collision_shape_path)
		return

	# Auto-detect: search for CollisionShape3D in siblings
	for child in character_body.get_children():
		if child is CollisionShape3D:
			collision_shape = child
			return

func _find_camera() -> void:
	if not camera_path.is_empty():
		camera = get_node_or_null(camera_path)
		return

	# Auto-detect: search for Camera3D in siblings
	for child in character_body.get_children():
		if child is Camera3D:
			camera = child
			return

func _physics_process(delta: float) -> void:
	if not collision_shape:
		return

	# Smoothly transition collision height
	var current_height = _get_current_height()
	if abs(current_height - target_height) > 0.01:
		var new_height = move_toward(current_height, target_height, crouch_transition_speed * delta)
		_set_height(new_height)

	# Smoothly transition camera height
	if camera and abs(camera.position.y - target_camera_y) > 0.01:
		camera.position.y = move_toward(camera.position.y, target_camera_y, crouch_transition_speed * delta)

func _get_current_height() -> float:
	if collision_shape.shape is CapsuleShape3D:
		return (collision_shape.shape as CapsuleShape3D).height
	elif collision_shape.shape is BoxShape3D:
		return (collision_shape.shape as BoxShape3D).size.y
	return 0.0

func _set_height(height: float) -> void:
	if collision_shape.shape is CapsuleShape3D:
		var capsule = collision_shape.shape as CapsuleShape3D
		capsule.height = height
		# Adjust collision shape position to keep feet on ground
		collision_shape.position.y = height / 2.0
	elif collision_shape.shape is BoxShape3D:
		var box = collision_shape.shape as BoxShape3D
		var old_y = box.size.y
		box.size.y = height
		# Adjust collision shape position to keep feet on ground
		collision_shape.position.y += (height - old_y) / 2.0

## Called by input component or any controller to set crouch state
func set_crouching(crouching: bool) -> void:
	if is_crouching == crouching:
		return

	is_crouching = crouching

	if is_crouching:
		# Crouch down
		target_height = original_height * crouch_height_multiplier
		if camera:
			target_camera_y = original_camera_y * crouch_height_multiplier
		if walk_component:
			walk_component.speed = original_speed * crouch_speed_multiplier
	else:
		# Stand up (check if there's space)
		if _can_stand_up():
			target_height = original_height
			if camera:
				target_camera_y = original_camera_y
			if walk_component:
				walk_component.speed = original_speed
		else:
			# Can't stand up, stay crouched
			is_crouching = true

## Check if there's enough space to stand up
func _can_stand_up() -> bool:
	if not character_body:
		return true

	# Create a shape query to check if we can stand
	var space_state = character_body.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()

	# Use the collision shape but at full height
	if collision_shape.shape is CapsuleShape3D:
		var test_shape = CapsuleShape3D.new()
		test_shape.radius = (collision_shape.shape as CapsuleShape3D).radius
		test_shape.height = original_height
		query.shape = test_shape
	elif collision_shape.shape is BoxShape3D:
		var test_shape = BoxShape3D.new()
		test_shape.size = Vector3(
			(collision_shape.shape as BoxShape3D).size.x,
			original_height,
			(collision_shape.shape as BoxShape3D).size.z
		)
		query.shape = test_shape

	# Position the query at where the player would be when standing
	query.transform = Transform3D(Basis(), character_body.global_position + Vector3(0, original_height / 2.0, 0))
	query.exclude = [character_body.get_rid()]

	var result = space_state.intersect_shape(query, 1)
	return result.is_empty()
