class_name AIChaseComponent
extends Node

## AI component that chases a target (usually the player)
## Sends movement input to Walk3DComponent
## Attach to CharacterBody3D with Walk3DComponent

@export_group("Chase Settings")
## Maximum distance to start chasing the player
@export var chase_range: float = 20.0

## Minimum distance to maintain from target
@export var min_distance: float = 1.5

## Speed multiplier (multiplies Walk3DComponent speed)
@export var speed_multiplier: float = 1.0

## Rotate to face target while chasing
@export var rotate_to_target: bool = true

## Always rotate toward target even when frozen/not moving
@export var always_rotate: bool = true

## Rotation speed (radians per second)
@export var rotation_speed: float = 5.0

@export_group("Target Settings")
## Tag or group name to find target (leave empty to find "Player")
@export var target_group: String = "player"

## Manually set target (overrides automatic detection)
@export var manual_target: Node3D = null

@export_group("Node Paths")
## Path to Walk3DComponent (leave empty for auto-detect)
@export var walk_component_path: NodePath = ""

## Path to NavigationAgent3D (leave empty for auto-detect)
@export var navigation_agent_path: NodePath = ""

@export_group("Navigation Settings")
## Use NavigationAgent3D for pathfinding (follows walls/paths)
@export var use_navigation: bool = true

## Distance from path to recalculate (NavigationAgent3D path_desired_distance)
@export var path_desired_distance: float = 0.5

## Distance to next waypoint before moving to next (NavigationAgent3D target_desired_distance)
@export var target_desired_distance: float = 0.5

# Internal references
var _walk_component: Walk3DComponent
var _character_body: CharacterBody3D
var _target: Node3D = null
var _original_speed: float = 0.0
var _navigation_agent: NavigationAgent3D = null

# State
var _is_chasing: bool = false
var _enabled: bool = true


func _ready() -> void:
	_character_body = get_parent() as CharacterBody3D
	if not _character_body:
		push_error("AIChaseComponent must be child of CharacterBody3D")
		return

	# Find Walk3DComponent
	_find_walk_component()
	if not _walk_component:
		push_error("AIChaseComponent: Could not find Walk3DComponent")
		return

	# Store original speed
	_original_speed = _walk_component.speed

	# Find and configure NavigationAgent3D
	if use_navigation:
		_find_navigation_agent()
		if _navigation_agent:
			_navigation_agent.path_desired_distance = path_desired_distance
			_navigation_agent.target_desired_distance = target_desired_distance
			# Wait for first navigation map to be ready
			call_deferred("_setup_navigation")
		else:
			push_warning("AIChaseComponent: Navigation enabled but no NavigationAgent3D found. Falling back to simple chase.")
			use_navigation = false

	# Find target
	_find_target()

	print("AIChaseComponent initialized on ", _character_body.name, " (Navigation: ", use_navigation, ")")


func _find_walk_component() -> void:
	if not walk_component_path.is_empty():
		_walk_component = get_node_or_null(walk_component_path) as Walk3DComponent
		return

	# Auto-detect in siblings
	for child in _character_body.get_children():
		if child is Walk3DComponent:
			_walk_component = child
			return


func _find_navigation_agent() -> void:
	if not navigation_agent_path.is_empty():
		_navigation_agent = get_node_or_null(navigation_agent_path) as NavigationAgent3D
		return

	# Auto-detect in siblings
	for child in _character_body.get_children():
		if child is NavigationAgent3D:
			_navigation_agent = child
			return


func _setup_navigation() -> void:
	if not _navigation_agent:
		return
	# Navigation is now ready
	# The agent will be updated in _physics_process


func _find_target() -> void:
	# Manual target overrides
	if manual_target:
		_target = manual_target
		return

	# Find by group
	if not target_group.is_empty():
		var targets = get_tree().get_nodes_in_group(target_group)
		if targets.size() > 0:
			_target = targets[0] as Node3D
			return

	# Fallback: Find any CharacterBody3D named "Player"
	for node in get_tree().get_nodes_in_group("player"):
		if node is CharacterBody3D:
			_target = node
			return


func _physics_process(_delta: float) -> void:
	if not _character_body or not _walk_component:
		return

	# Try to find target if we don't have one yet
	if not _target:
		_find_target()
		if not _target:
			return
		else:
			print("AIChaseComponent on ", _character_body.name, " found target: ", _target.name)

	# Calculate distance to target
	var distance = _character_body.global_position.distance_to(_target.global_position)

	# Always rotate toward target if enabled (even when AI is disabled/frozen)
	if always_rotate and rotate_to_target:
		var target_pos = _target.global_position
		var current_pos = _character_body.global_position
		var direction_3d = Vector3(
			target_pos.x - current_pos.x,
			0,  # Ignore Y difference
			target_pos.z - current_pos.z
		).normalized()
		_rotate_towards_target(_delta, direction_3d)

	# Only chase if enabled (can be disabled by LightFreezeComponent)
	if not _enabled:
		# Stop moving when disabled
		_walk_component.apply_movement(Vector2.ZERO)
		_is_chasing = false
		return

	# Check if should chase
	if distance <= chase_range and distance > min_distance:
		if not _is_chasing:
			print("AIChaseComponent: Starting chase! Distance: ", distance)

		# Update navigation target if using navigation
		if use_navigation and _navigation_agent:
			_navigation_agent.target_position = _target.global_position

		_chase_target(_delta)
		_is_chasing = true
	else:
		if _is_chasing:
			print("AIChaseComponent: Stopping chase. Distance: ", distance, " (range: ", chase_range, ")")
		# Stop moving
		_walk_component.apply_movement(Vector2.ZERO)
		_is_chasing = false


func _chase_target(delta: float) -> void:
	var current_pos = _character_body.global_position
	var direction_3d: Vector3
	var use_nav_this_frame = false

	# Try to use navigation if available and enabled
	if use_navigation and _navigation_agent:
		# Check if we have a valid navigation map
		if _navigation_agent.is_navigation_finished():
			# Navigation finished or no path - this is expected when very close to target
			# Fall through to direct chase
			pass
		elif _navigation_agent.is_target_reachable():
			# We have a valid path, use it!
			var next_position = _navigation_agent.get_next_path_position()

			# Calculate direction to next waypoint
			direction_3d = Vector3(
				next_position.x - current_pos.x,
				0,  # Ignore Y difference
				next_position.z - current_pos.z
			).normalized()

			use_nav_this_frame = true
		else:
			# Target not reachable - this usually means no NavigationMesh is baked
			if not _is_chasing or Engine.get_frames_drawn() % 60 == 0:  # Print once per second
				print("AIChaseComponent: Navigation target not reachable. Is NavigationMesh baked?")

	# Fall back to direct chase if navigation not used
	if not use_nav_this_frame:
		var target_pos = _target.global_position
		direction_3d = Vector3(
			target_pos.x - current_pos.x,
			0,  # Ignore Y difference
			target_pos.z - current_pos.z
		).normalized()

		# Check for edges when not using navigation
		if not _is_ground_ahead(direction_3d):
			# Stop moving if there's an edge ahead and no navigation path
			_walk_component.apply_movement(Vector2.ZERO)
			return

	# Convert to local space relative to character's current rotation
	var local_direction = _character_body.global_transform.basis.inverse() * direction_3d
	var movement_input = Vector2(local_direction.x, local_direction.z).normalized()

	# Apply speed multiplier
	_walk_component.speed = _original_speed * speed_multiplier

	# Send movement command
	_walk_component.apply_movement(movement_input)

	# Rotation is now handled in _physics_process for always_rotate


func _rotate_towards_target(delta: float, direction: Vector3) -> void:
	if direction.length() < 0.01:
		return

	# Calculate target rotation
	var target_rotation = atan2(direction.x, direction.z)

	# Get current rotation
	var current_rotation = _character_body.rotation.y

	# Interpolate rotation
	var new_rotation = lerp_angle(current_rotation, target_rotation, rotation_speed * delta)
	_character_body.rotation.y = new_rotation


## Check if currently chasing target
func is_chasing() -> bool:
	return _is_chasing


## Set a new target to chase
func set_target(new_target: Node3D) -> void:
	_target = new_target


## Get current target
func get_target() -> Node3D:
	return _target


## Enable/disable chasing
func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled and _walk_component:
		_walk_component.apply_movement(Vector2.ZERO)


## Check if there's ground ahead in the movement direction
func _is_ground_ahead(direction: Vector3) -> bool:
	if not _character_body:
		return true

	# Cast a ray ahead and down to check for ground
	var check_distance = 1.5  # How far ahead to check (in meters)
	var down_distance = 2.0    # How far down to raycast

	# Start position: slightly ahead of the enemy
	var start_pos = _character_body.global_position + (direction * check_distance)
	start_pos.y += 0.5  # Start slightly above ground level

	# End position: down from start position
	var end_pos = start_pos + Vector3(0, -down_distance, 0)

	# Perform raycast
	var space_state = _character_body.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	query.exclude = [_character_body]  # Don't hit self
	query.collision_mask = 1  # Only check physical objects (layer 1)

	var result = space_state.intersect_ray(query)

	# If we hit something, there's ground ahead
	if result:
		return true

	# No ground detected - there's an edge!
	return false
