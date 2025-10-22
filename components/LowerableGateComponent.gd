class_name LowerableGateComponent
extends Node

## Component that lowers/raises a gate or fence
## Can be triggered by switches, checkpoints, or other events
## Attach to any Node3D (fence, gate, door, etc.)

# Signals
signal gate_lowered()
signal gate_raised()
signal gate_moving(progress: float)

@export_group("Gate Settings")
## How far to lower the gate (Y axis offset)
@export var lower_distance: float = 3.0

## Speed of lowering/raising animation
@export var animation_speed: float = 2.0

## Automatically lower when triggered (vs raise when triggered)
@export var lower_on_trigger: bool = true

## Start in lowered state
@export var start_lowered: bool = false

@export_group("Connection")
## Path to switch that controls this gate (leave empty to control manually)
@export var connected_switch_path: NodePath = ""

@export_group("Advanced")
## Easing type for animation
@export_enum("Linear", "Ease In", "Ease Out", "Ease In-Out") var easing_type: int = 3

# Internal state
var _gate_object: Node3D
var _original_position: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _current_position: Vector3 = Vector3.ZERO
var _is_lowered: bool = false
var _is_moving: bool = false
var _connected_switch: SwitchComponent = null

func _ready() -> void:
	# Get parent node (the gate/fence)
	_gate_object = get_parent() as Node3D
	if not _gate_object:
		push_error("LowerableGateComponent must be child of Node3D")
		return

	# Store original position
	_original_position = _gate_object.position
	_current_position = _original_position
	_target_position = _original_position

	# Set initial state
	if start_lowered:
		_is_lowered = true
		_current_position = _original_position + Vector3(0, -lower_distance, 0)
		_target_position = _current_position
		_gate_object.position = _current_position

	# Connect to switch if path is provided
	if not connected_switch_path.is_empty():
		_connect_to_switch()

	print("LowerableGateComponent initialized on ", _gate_object.name)

func _connect_to_switch() -> void:
	_connected_switch = get_node_or_null(connected_switch_path) as SwitchComponent

	if _connected_switch:
		_connected_switch.switch_toggled.connect(_on_switch_toggled)
		print("Gate connected to switch: ", _connected_switch.get_parent().name)
	else:
		push_warning("LowerableGateComponent: Could not find switch at path: ", connected_switch_path)

func _on_switch_toggled(is_active: bool) -> void:
	if lower_on_trigger:
		if is_active:
			lower()
		else:
			raise_gate()
	else:
		if is_active:
			raise_gate()
		else:
			lower()

func _process(delta: float) -> void:
	if not _gate_object:
		return

	# Animate position
	if _current_position.distance_to(_target_position) > 0.01:
		_is_moving = true

		# Apply easing
		var t = animation_speed * delta
		match easing_type:
			0:  # Linear
				_current_position = _current_position.lerp(_target_position, t)
			1:  # Ease In
				t = t * t
				_current_position = _current_position.lerp(_target_position, t)
			2:  # Ease Out
				t = 1.0 - (1.0 - t) * (1.0 - t)
				_current_position = _current_position.lerp(_target_position, t)
			3:  # Ease In-Out
				t = t * t * (3.0 - 2.0 * t)
				_current_position = _current_position.lerp(_target_position, t)

		_gate_object.position = _current_position

		# Calculate progress
		var total_distance = _original_position.distance_to(_original_position + Vector3(0, -lower_distance, 0))
		var current_distance = _original_position.distance_to(_current_position)
		var progress = current_distance / total_distance if total_distance > 0 else 0
		emit_signal("gate_moving", progress)

		# Snap when close enough
		if _current_position.distance_to(_target_position) < 0.01:
			_current_position = _target_position
			_gate_object.position = _target_position
			_is_moving = false

			# Emit completion signal
			if _is_lowered:
				emit_signal("gate_lowered")
			else:
				emit_signal("gate_raised")

## Lower the gate
func lower() -> void:
	if _is_lowered and not _is_moving:
		return

	_is_lowered = true
	_target_position = _original_position + Vector3(0, -lower_distance, 0)
	print("Lowering gate: ", _gate_object.name)

## Raise the gate
func raise_gate() -> void:
	if not _is_lowered and not _is_moving:
		return

	_is_lowered = false
	_target_position = _original_position
	print("Raising gate: ", _gate_object.name)

## Toggle gate state
func toggle() -> void:
	if _is_lowered:
		raise_gate()
	else:
		lower()

## Check if gate is currently lowered
func is_lowered() -> bool:
	return _is_lowered

## Check if gate is currently moving
func is_moving() -> bool:
	return _is_moving
