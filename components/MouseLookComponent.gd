class_name MouseLookComponent
extends Node

## Component that handles mouse input for camera look rotation
## Can be enabled/disabled for interactions that take over the mouse
## Emits signals for pitch and yaw changes that CameraControllerComponent can use

# Signals
signal look_input(pitch_delta: float, yaw_delta: float)

# Configurable parameters
@export var mouse_sensitivity := 0.002
@export var enabled := true ## Whether mouse look is currently active
@export var capture_mouse_on_ready := true ## Auto-capture mouse when scene loads

func _ready() -> void:
	if capture_mouse_on_ready:
		capture_mouse()

func _input(event: InputEvent) -> void:
	# Only process mouse motion when enabled
	if not enabled:
		return

	if event is InputEventMouseMotion:
		# Calculate rotation deltas
		var pitch_delta = -event.relative.y * mouse_sensitivity
		var yaw_delta = -event.relative.x * mouse_sensitivity

		# Emit signal for other components to handle
		emit_signal("look_input", pitch_delta, yaw_delta)

## Enable mouse look and capture the mouse cursor
func enable() -> void:
	enabled = true
	capture_mouse()

## Disable mouse look and release the mouse cursor
func disable() -> void:
	enabled = false
	release_mouse()

## Capture the mouse cursor (hides it and locks to window)
func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Release the mouse cursor (shows it and allows free movement)
func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
