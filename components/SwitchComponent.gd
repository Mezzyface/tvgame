class_name SwitchComponent
extends Node

## Component that makes an object interactable as a switch
## Can be pulled/activated by the player to trigger events
## Attach to any Node3D with an Area3D child for interaction detection

# Signals
signal switch_activated()
signal switch_deactivated()
signal switch_toggled(is_active: bool)
signal switch_angle_changed(angle: float, progress: float)  # angle in degrees, progress 0.0-1.0

@export_group("Switch Settings")
## Type of switch behavior
@export_enum("Toggle", "One-Time", "Hold") var switch_type: int = 0

## Is the switch currently active?
@export var is_active: bool = false

## Distance to interact with switch
@export var interaction_range: float = 3.0

## Animation to play when activated (leave empty to skip)
@export var activation_animation: String = "pull"

@export_group("Visual Settings")
## Maximum rotation angle when pulled (degrees, positive = down)
@export var max_rotation_angle: float = 90.0

## Original rotation (stored automatically)
var _original_rotation: Vector3 = Vector3.ZERO

## Animation speed (for snapping back)
@export var animation_speed: float = 5.0

@export_group("Drag Settings")
## Enable drag interaction (requires dragging to activate)
@export var require_drag: bool = true

## How much drag affects rotation (higher = more sensitive)
@export var drag_sensitivity: float = 0.5

## Minimum angle to keep switch in place (degrees)
@export var min_activation_angle: float = 45.0

@export_group("Node Paths")
## Path to the object to animate (leave empty to use parent)
@export var animated_object_path: NodePath = ""

## Path to a GateController to trigger when activated (optional)
@export var connected_gate_path: NodePath = ""

# Internal state
var _connected_gate: GateController = null
var _animated_object: Node3D
var _current_rotation: Vector3 = Vector3.ZERO
var _target_rotation: Vector3 = Vector3.ZERO
var _drag_rotation: float = 0.0  # Current rotation from drag
var _is_dragging: bool = false

func _ready() -> void:
	# Find animated object
	_find_animated_object()
	if _animated_object:
		_original_rotation = _animated_object.rotation_degrees
		_current_rotation = _original_rotation
		_target_rotation = _original_rotation

	# Connect to gate if path is provided
	if not connected_gate_path.is_empty():
		_connected_gate = get_node_or_null(connected_gate_path) as GateController
		if _connected_gate:
			# Connect angle changed signal to gate
			switch_angle_changed.connect(_on_angle_changed_update_gate)
			print("Switch connected to gate: ", _connected_gate.get_parent().name)
		else:
			push_warning("SwitchComponent: Could not find GateController at path: ", connected_gate_path)

	print("SwitchComponent initialized on ", get_parent().name)


func _on_angle_changed_update_gate(angle: float, progress: float) -> void:
	if _connected_gate and _is_dragging:
		# Update gate position in real-time during drag
		_connected_gate.set_open_progress(progress)

func _find_animated_object() -> void:
	if not animated_object_path.is_empty():
		_animated_object = get_node_or_null(animated_object_path)
		return

	# Default to parent
	_animated_object = get_parent() as Node3D

func _process(delta: float) -> void:
	# Animate rotation
	if _animated_object:
		if _is_dragging:
			# During drag, use drag rotation directly
			var drag_target = _original_rotation
			drag_target.x = _original_rotation.x + _drag_rotation
			_animated_object.rotation_degrees = drag_target
		elif _current_rotation != _target_rotation:
			# Normal animation when not dragging
			_current_rotation = _current_rotation.lerp(_target_rotation, animation_speed * delta)
			_animated_object.rotation_degrees = _current_rotation

			# Snap when close enough
			if _current_rotation.distance_to(_target_rotation) < 0.1:
				_current_rotation = _target_rotation
				_animated_object.rotation_degrees = _target_rotation

## Called when player interacts with switch
func interact() -> void:
	match switch_type:
		0:  # Toggle
			toggle()
		1:  # One-Time
			if not is_active:
				activate()
		2:  # Hold
			activate()

## Activate the switch (legacy method, opens fully)
func activate() -> void:
	if is_active and switch_type != 2:  # Hold type can re-activate
		return

	is_active = true
	_target_rotation = _original_rotation
	_target_rotation.x = _original_rotation.x + max_rotation_angle

	emit_signal("switch_activated")
	emit_signal("switch_toggled", true)
	print("Switch activated: ", get_parent().name)

	# Trigger connected gate (fully open)
	if _connected_gate:
		_connected_gate.set_open_progress(1.0)

## Deactivate the switch
func deactivate() -> void:
	if not is_active:
		return

	is_active = false
	_target_rotation = _original_rotation

	emit_signal("switch_deactivated")
	emit_signal("switch_toggled", false)
	print("Switch deactivated: ", get_parent().name)

	# Trigger connected gate
	if _connected_gate:
		_connected_gate.close()

## Toggle the switch state
func toggle() -> void:
	if is_active:
		deactivate()
	else:
		activate()

## Set switch state directly
func set_switch_state(active: bool) -> void:
	if active:
		activate()
	else:
		deactivate()


## Called during drag to update rotation
func update_drag(drag_delta: Vector2) -> void:
	if not require_drag:
		return

	_is_dragging = true

	# Convert drag distance to rotation
	# Positive Y (down) = positive rotation (pull down)
	var rotation_amount = drag_delta.y * drag_sensitivity

	# Clamp to max rotation range (0 to max_rotation_angle)
	rotation_amount = clamp(rotation_amount, 0, max_rotation_angle)

	_drag_rotation = rotation_amount

	# Calculate progress (0.0 = not pulled, 1.0 = fully pulled)
	var progress = _drag_rotation / max_rotation_angle

	# Emit angle change for connected systems (like gates)
	emit_signal("switch_angle_changed", _drag_rotation, progress)


## Called when drag ends
func complete_drag(success: bool) -> void:
	_is_dragging = false

	if success:
		# Check if pulled far enough to stay
		if _drag_rotation >= min_activation_angle:
			# Keep the switch at the current angle
			is_active = true
			_target_rotation = _original_rotation
			_target_rotation.x = _original_rotation.x + _drag_rotation
			_current_rotation = _target_rotation

			# Update connected gate to match final angle
			var progress = _drag_rotation / max_rotation_angle
			emit_signal("switch_angle_changed", _drag_rotation, progress)

			# Trigger gate if connected
			if _connected_gate:
				_connected_gate.set_open_progress(progress)

			emit_signal("switch_activated")
			emit_signal("switch_toggled", true)
			print("Switch set to angle: ", _drag_rotation, " (", progress * 100, "%)")
		else:
			# Not pulled enough, snap back
			_drag_rotation = 0.0
			_target_rotation = _original_rotation
			_current_rotation = _animated_object.rotation_degrees if _animated_object else _original_rotation
			print("Not pulled enough, snapping back")
	else:
		# Snap back to original position
		_drag_rotation = 0.0
		_target_rotation = _original_rotation
		_current_rotation = _animated_object.rotation_degrees if _animated_object else _original_rotation

		# Reset gate if connected
		if _connected_gate:
			_connected_gate.set_open_progress(0.0)
