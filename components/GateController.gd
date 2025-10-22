class_name GateController
extends Node

## Controls a gate/door by sending movement commands to MoveStaticComponent
## Attach to an AnimatableBody3D with MoveStaticComponent to create a moving gate

@export_group("Gate Settings")
## Direction the gate moves when opening (local space)
@export var open_direction: Vector2 = Vector2(0, 1)  # Forward by default

## Distance to move when opening
@export var open_distance: float = 5.0

## Speed of gate movement
@export var movement_speed: float = 2.0

## Time to keep gate open before auto-closing (0 = stay open)
@export var auto_close_time: float = 0.0

## Start in open position
@export var start_open: bool = false

@export_group("Node Paths")
## Path to MoveStaticComponent (leave empty for auto-detect)
@export var move_component_path: NodePath = ""

# Internal state
var _move_component: MoveStaticComponent
var _is_open: bool = false
var _is_moving: bool = false
var _target_position: Vector3
var _start_position: Vector3
var _open_position: Vector3
var _auto_close_timer: float = 0.0
var _gate_body: Node3D


func _ready() -> void:
	# Get reference to parent body
	_gate_body = get_parent() as Node3D
	if not _gate_body:
		push_error("GateController must be child of a Node3D")
		return

	# Find MoveStaticComponent
	_find_move_component()
	if not _move_component:
		push_error("GateController: Could not find MoveStaticComponent")
		return

	# Override the move component's speed
	_move_component.speed = movement_speed

	# Store starting position
	_start_position = _gate_body.global_position

	# Calculate open position
	var local_offset = Vector3(open_direction.x, 0, open_direction.y).normalized() * open_distance
	_open_position = _start_position + (_gate_body.global_transform.basis * local_offset)

	# Set initial state
	if start_open:
		_gate_body.global_position = _open_position
		_is_open = true
		_target_position = _open_position
	else:
		_target_position = _start_position

	print("GateController initialized: ", _gate_body.name)
	print("  Start position: ", _start_position)
	print("  Open position: ", _open_position)


func _find_move_component() -> void:
	if not move_component_path.is_empty():
		_move_component = get_node_or_null(move_component_path)
		return

	# Auto-detect in siblings
	for child in _gate_body.get_children():
		if child is MoveStaticComponent:
			_move_component = child
			return


func _physics_process(delta: float) -> void:
	if not _gate_body or not _move_component:
		return

	# Update movement if gate is moving
	if _is_moving:
		_update_movement()

	# Handle auto-close timer
	if _is_open and auto_close_time > 0.0 and _auto_close_timer > 0.0:
		_auto_close_timer -= delta
		if _auto_close_timer <= 0.0:
			close()


func _update_movement() -> void:
	# Calculate direction to target
	var direction_3d = (_target_position - _gate_body.global_position)
	var distance = direction_3d.length()

	# Check if we've reached the target
	if distance < 0.1:
		# Snap to target and stop
		_gate_body.global_position = _target_position
		_move_component.apply_movement(Vector2.ZERO)
		_is_moving = false
		print("Gate reached target: ", "open" if _is_open else "closed")

		# Start auto-close timer if just opened
		if _is_open and auto_close_time > 0.0:
			_auto_close_timer = auto_close_time
		return

	# Convert 3D direction to 2D movement input (relative to gate's rotation)
	direction_3d = direction_3d.normalized()
	var local_direction = _gate_body.global_transform.basis.inverse() * direction_3d
	var movement_input = Vector2(local_direction.x, local_direction.z)

	# Send movement command to MoveStaticComponent
	_move_component.apply_movement(movement_input)


## Open the gate
func open() -> void:
	set_open_progress(1.0)


## Close the gate
func close() -> void:
	set_open_progress(0.0)


## Set gate to a specific open progress (0.0 = closed, 1.0 = fully open)
func set_open_progress(progress: float) -> void:
	progress = clamp(progress, 0.0, 1.0)

	# Calculate target position based on progress
	_target_position = _start_position.lerp(_open_position, progress)

	# Update state
	_is_open = progress > 0.01
	_is_moving = true

	# Reset auto-close timer
	_auto_close_timer = 0.0

	print("Gate progress set to: ", progress * 100, "%")


## Toggle gate open/closed
func toggle() -> void:
	if _is_open:
		close()
	else:
		open()


## Check if gate is open
func is_open() -> bool:
	return _is_open


## Check if gate is currently moving
func is_moving() -> bool:
	return _is_moving


## Manually set the movement speed
func set_movement_speed(speed: float) -> void:
	movement_speed = speed
	if _move_component:
		_move_component.speed = speed
