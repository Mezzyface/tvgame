class_name GateTrigger
extends Node

## Triggers a gate to open when player enters an Area3D
## Attach to a gate that has a GateController and an Area3D child

@export_group("Trigger Settings")
## Automatically open when player enters
@export var open_on_enter: bool = true

## Automatically close when player exits
@export var close_on_exit: bool = false

## Only trigger once
@export var one_time_trigger: bool = false

@export_group("Node Paths")
## Path to GateController (leave empty for auto-detect)
@export var gate_controller_path: NodePath = ""

## Path to Area3D trigger (leave empty for auto-detect)
@export var trigger_area_path: NodePath = ""

# Internal state
var _gate_controller: GateController
var _trigger_area: Area3D
var _has_triggered: bool = false


func _ready() -> void:
	# Find gate controller
	_find_gate_controller()
	if not _gate_controller:
		push_error("GateTrigger: Could not find GateController")
		return

	# Find trigger area
	_find_trigger_area()
	if not _trigger_area:
		push_error("GateTrigger: Could not find Area3D trigger")
		return

	# Connect signals
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)

	print("GateTrigger initialized for: ", get_parent().name)


func _find_gate_controller() -> void:
	if not gate_controller_path.is_empty():
		_gate_controller = get_node_or_null(gate_controller_path)
		return

	# Auto-detect in siblings
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is GateController:
				_gate_controller = child
				return


func _find_trigger_area() -> void:
	if not trigger_area_path.is_empty():
		_trigger_area = get_node_or_null(trigger_area_path)
		return

	# Auto-detect in siblings
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is Area3D:
				_trigger_area = child
				return


func _on_body_entered(body: Node3D) -> void:
	# Check if it's the player
	if not body is CharacterBody3D:
		return

	# Check one-time trigger
	if one_time_trigger and _has_triggered:
		return

	print("GateTrigger: Player entered")

	# Open gate
	if open_on_enter and _gate_controller:
		_gate_controller.open()
		_has_triggered = true


func _on_body_exited(body: Node3D) -> void:
	# Check if it's the player
	if not body is CharacterBody3D:
		return

	print("GateTrigger: Player exited")

	# Close gate
	if close_on_exit and _gate_controller:
		_gate_controller.close()


## Manually trigger the gate to open
func trigger_open() -> void:
	if _gate_controller:
		_gate_controller.open()


## Manually trigger the gate to close
func trigger_close() -> void:
	if _gate_controller:
		_gate_controller.close()
