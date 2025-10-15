class_name PickupableComponent
extends Node

## Makes an object pickupable by a PickupControllerComponent
## Attach to any RigidBody3D or StaticBody3D to make it interactive

# Signals
signal picked_up(picker: Node3D)
signal dropped(position: Vector3)

# Export variables
@export var hold_distance: float = 2.0  ## Distance in front of player when held
@export var hold_offset_vertical: float = -0.5  ## Vertical offset (negative = lower, positive = higher)
@export var hold_smoothing: float = 10.0  ## How smoothly the object follows the hold position
@export var flip_away_from_player: bool = false  ## Flip object 180 degrees to face away from player

# State
var is_held: bool = false
var holder: Node3D = null
var holder_camera: Camera3D = null
var original_parent: Node = null
var rigid_body: RigidBody3D = null

func _ready() -> void:
	# Get reference to parent rigid body
	rigid_body = get_parent() as RigidBody3D
	if not rigid_body:
		push_error("PickupableComponent must be child of RigidBody3D")
		return

	original_parent = rigid_body.get_parent()

func _physics_process(delta: float) -> void:
	if is_held and holder:
		# Calculate hold position and rotation based on camera
		var hold_position: Vector3
		var target_rotation: Basis

		if holder_camera:
			# Use camera forward direction so object moves with look direction
			hold_position = holder_camera.global_position + (-holder_camera.global_transform.basis.z * hold_distance)
			# Apply vertical offset (using camera's up vector)
			hold_position += holder_camera.global_transform.basis.y * hold_offset_vertical
			# Match camera rotation so object stays oriented the same relative to view
			target_rotation = holder_camera.global_transform.basis
		else:
			# Fallback to holder forward direction
			hold_position = holder.global_position + (-holder.global_transform.basis.z * hold_distance)
			hold_position += holder.global_transform.basis.y * hold_offset_vertical
			target_rotation = holder.global_transform.basis

		# Smoothly move to hold position
		rigid_body.global_position = rigid_body.global_position.lerp(hold_position, hold_smoothing * delta)

		# Apply flip rotation if enabled (180 degrees around up axis)
		if flip_away_from_player:
			target_rotation = target_rotation.rotated(target_rotation.y.normalized(), PI)

		# Smoothly rotate to match camera orientation
		rigid_body.global_transform.basis = rigid_body.global_transform.basis.slerp(target_rotation, hold_smoothing * delta)

		# Disable physics while held
		rigid_body.freeze = true
	else:
		# Re-enable physics when dropped
		if rigid_body:
			rigid_body.freeze = false

## Called by PickupControllerComponent to pick up this object
func pickup(picker: Node3D, camera: Camera3D = null) -> void:
	if is_held:
		return

	is_held = true
	holder = picker
	holder_camera = camera

	if rigid_body:
		# Disable collision with picker
		rigid_body.add_collision_exception_with(picker)
		# Freeze physics while held
		rigid_body.freeze = true
		# Reset velocity
		rigid_body.linear_velocity = Vector3.ZERO
		rigid_body.angular_velocity = Vector3.ZERO

	emit_signal("picked_up", picker)

## Called by PickupControllerComponent to drop this object
func drop() -> void:
	if not is_held:
		return

	is_held = false
	var drop_position = rigid_body.global_position
	var previous_holder = holder
	holder = null
	holder_camera = null

	if rigid_body:
		# Re-enable collision with picker
		if previous_holder:
			rigid_body.remove_collision_exception_with(previous_holder)
		# Re-enable physics
		rigid_body.freeze = false

	emit_signal("dropped", drop_position)

## Returns whether this object can currently be picked up
func can_pickup() -> bool:
	return not is_held and rigid_body != null

## Returns whether this object is currently being held
func is_being_held() -> bool:
	return is_held
