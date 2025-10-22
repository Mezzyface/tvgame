class_name MouseInteractionComponent
extends Node

## Handles mouse-based drag interaction with objects in the world
## Click and drag to interact with switches
## Attach to the player CharacterBody3D

@export_group("Interaction Settings")
## Maximum distance for interaction
@export var interaction_range: float = 10.0

## Minimum drag distance required to keep switch in place (pixels)
@export var min_drag_distance: float = 20.0

## Show debug raycast line
@export var show_debug: bool = false

@export_group("Node Paths")
## Path to the camera (leave empty for auto-detect)
@export var camera_path: NodePath = ""

# Internal references
var _camera: Camera3D
var _player: CharacterBody3D

# Drag state
var _is_dragging: bool = false
var _drag_start_position: Vector2 = Vector2.ZERO
var _current_drag_position: Vector2 = Vector2.ZERO
var _dragged_switch: SwitchComponent = null


func _ready() -> void:
	_player = get_parent() as CharacterBody3D
	if not _player:
		push_error("MouseInteractionComponent must be child of CharacterBody3D")
		return

	# Find camera
	_find_camera()
	if not _camera:
		push_error("MouseInteractionComponent: Could not find Camera3D")
		return

	print("MouseInteractionComponent initialized")


func _find_camera() -> void:
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path)
		return

	# Auto-detect camera in siblings
	for child in _player.get_children():
		if child is Camera3D:
			_camera = child
			return


func _input(event: InputEvent) -> void:
	# Handle mouse button press
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_start_drag(mouse_event.position)
			else:
				_end_drag()
			# Mark as handled so MouseLook doesn't interfere
			if _is_dragging or _dragged_switch:
				get_viewport().set_input_as_handled()

	# Handle mouse motion while dragging
	elif event is InputEventMouseMotion and _is_dragging:
		_update_drag(event.position)
		# Consume the event to prevent camera movement during drag
		get_viewport().set_input_as_handled()


func _start_drag(mouse_position: Vector2) -> void:
	if not _camera:
		return

	# Raycast to see what we're clicking on
	var from = _camera.project_ray_origin(mouse_position)
	var to = from + _camera.project_ray_normal(mouse_position) * interaction_range

	var space_state = _player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [_player]

	var result = space_state.intersect_ray(query)

	if result:
		var switch_component = _find_switch_component(result.collider)
		if switch_component:
			_is_dragging = true
			_drag_start_position = mouse_position
			_current_drag_position = mouse_position
			_dragged_switch = switch_component

			# Set mouse mode to visible during drag
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

			print("Started dragging switch: ", result.collider.name)
			print("Start position: ", mouse_position)


func _update_drag(mouse_position: Vector2) -> void:
	if not _dragged_switch:
		return

	_current_drag_position = mouse_position

	# Calculate drag delta
	var drag_delta = _current_drag_position - _drag_start_position

	# Send drag update to switch
	_dragged_switch.update_drag(drag_delta)

	if show_debug:
		print("Drag delta: ", drag_delta)


func _end_drag() -> void:
	if not _is_dragging or not _dragged_switch:
		_is_dragging = false
		_dragged_switch = null
		# Restore mouse capture for camera look
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# Calculate total drag distance
	var drag_delta = _current_drag_position - _drag_start_position
	var drag_distance = drag_delta.length()

	print("Drag ended. Start: ", _drag_start_position, " End: ", _current_drag_position)
	print("Drag delta: ", drag_delta, " Distance: ", drag_distance)

	# Check if dragged enough
	if drag_distance >= min_drag_distance:
		# Check if dragged in correct direction (downward for pulling)
		if drag_delta.y > 0:  # Positive Y = downward
			_dragged_switch.complete_drag(true)
			print("Switch activated by drag!")
		else:
			_dragged_switch.complete_drag(false)
			print("Dragged wrong direction")
	else:
		_dragged_switch.complete_drag(false)
		print("Drag distance too short")

	# Reset drag state
	_is_dragging = false
	_dragged_switch = null

	# Restore mouse capture for camera look
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _find_switch_component(node: Node) -> SwitchComponent:
	# Check if the node itself has a SwitchComponent
	for child in node.get_children():
		if child is SwitchComponent:
			return child

	# Check parent (in case we hit a mesh child)
	if node.get_parent():
		for child in node.get_parent().get_children():
			if child is SwitchComponent:
				return child

	return null
