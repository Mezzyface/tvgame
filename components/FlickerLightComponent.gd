class_name FlickerLightComponent
extends Node

## Component that makes a Light3D flicker randomly
## Attach to any Light3D node to add flickering effect

@export var base_energy: float = 1.0
@export var flicker_amount: float = 0.3
@export var flicker_speed: float = 10.0

var light: Light3D
var time_offset: float = 0.0

func _ready() -> void:
	# Get parent light
	if get_parent() is Light3D:
		light = get_parent() as Light3D
		# Random time offset so multiple lights don't flicker in sync
		time_offset = randf() * 100.0
	else:
		push_error("FlickerLightComponent must be child of Light3D node")

func _process(delta: float) -> void:
	if not light:
		return

	# Use noise-like function for natural flicker
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	var flicker = sin(time * flicker_speed) * cos(time * flicker_speed * 1.3)
	flicker = (flicker + 1.0) * 0.5  # Normalize to 0-1

	# Apply flicker to light energy
	light.light_energy = base_energy + (flicker * flicker_amount * 2.0 - flicker_amount)
