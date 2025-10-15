class_name PickupControllerComponent
extends Node

## Allows a character to pick up and drop objects with PickupableComponent
## Attach to CharacterBody3D (player) to enable pickup interactions

# Signals
signal object_picked_up(pickupable: PickupableComponent)
signal object_dropped(pickupable: PickupableComponent)
signal pickup_target_detected(pickupable: PickupableComponent)
signal pickup_target_lost()

# Export variables
@export var pickup_action: String = "pickup"  ## Input action for picking up/dropping
@export var pickup_range: float = 3.0  ## Maximum distance to pick up objects
@export var raycast_from_camera: bool = true  ## Use camera for raycasting (true) or character forward (false)

# Internal state
var character_body: CharacterBody3D = null
var camera: Camera3D = null
var held_object: PickupableComponent = null
var current_target: PickupableComponent = null

func _ready() -> void:
	# Get parent CharacterBody3D reference
	character_body = get_parent() as CharacterBody3D
	if not character_body:
		push_error("PickupControllerComponent must be child of CharacterBody3D")
		return

	# Find camera (needed for raycasting)
	camera = _find_camera(character_body)
	if not camera:
		push_warning("PickupControllerComponent: No Camera3D found. Raycasting from character forward.")
		raycast_from_camera = false

func _physics_process(_delta: float) -> void:
	# Check for pickupable objects in range
	if not held_object:
		_detect_pickup_target()

	# Handle pickup/drop input
	if Input.is_action_just_pressed(pickup_action):
		if held_object:
			drop_object()
		elif current_target and current_target.can_pickup():
			pickup_object(current_target)

## Picks up the specified PickupableComponent
func pickup_object(pickupable: PickupableComponent) -> void:
	if held_object or not pickupable or not pickupable.can_pickup():
		return

	held_object = pickupable
	pickupable.pickup(character_body, camera)
	emit_signal("object_picked_up", pickupable)

## Drops the currently held object
func drop_object() -> void:
	if not held_object:
		return

	var dropped = held_object
	held_object.drop()
	held_object = null
	emit_signal("object_dropped", dropped)

## Returns the currently held object, or null if not holding anything
func get_held_object() -> PickupableComponent:
	return held_object

## Returns whether currently holding an object
func is_holding_object() -> bool:
	return held_object != null

## Detects pickupable objects in front of the player
func _detect_pickup_target() -> void:
	var space_state = character_body.get_world_3d().direct_space_state

	# Determine raycast origin and direction
	var ray_origin: Vector3
	var ray_direction: Vector3

	if raycast_from_camera and camera:
		ray_origin = camera.global_position
		ray_direction = -camera.global_transform.basis.z
	else:
		ray_origin = character_body.global_position
		ray_direction = -character_body.global_transform.basis.z

	var ray_end = ray_origin + ray_direction * pickup_range

	# Perform raycast
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [character_body]  # Don't hit ourselves

	var result = space_state.intersect_ray(query)

	# Check if we hit a pickupable object
	var new_target: PickupableComponent = null
	if result:
		var hit_body = result.collider
		if hit_body:
			# Look for PickupableComponent in the hit object's children
			for child in hit_body.get_children():
				if child is PickupableComponent:
					new_target = child
					break

	# Update target and emit signals
	if new_target != current_target:
		if current_target:
			emit_signal("pickup_target_lost")

		current_target = new_target

		if current_target:
			emit_signal("pickup_target_detected", current_target)

## Helper function to find Camera3D in the character hierarchy
func _find_camera(node: Node) -> Camera3D:
	if node is Camera3D:
		return node

	for child in node.get_children():
		var found = _find_camera(child)
		if found:
			return found

	return null
