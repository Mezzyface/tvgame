class_name LightFreezeComponent
extends Node

## Component that freezes an AI enemy when hit by light
## Attach to CharacterBody3D with AIChaseComponent
## Detects Area3D nodes tagged with "freeze_light" group

@export_group("Freeze Settings")
## Enable debug messages
@export var debug: bool = false

## Require line of sight to light source (raycast check)
@export var require_line_of_sight: bool = true

## Tag to detect light sources
@export var light_tag: String = "freeze_light"

@export_group("Node Paths")
## Path to AIChaseComponent to freeze (leave empty for auto-detect)
@export var ai_chase_path: NodePath = ""

## Path to Area3D for detection (leave empty for auto-detect)
@export var detection_area_path: NodePath = ""

# Internal references
var _ai_chase: AIChaseComponent = null
var _detection_area: Area3D = null
var _character_body: CharacterBody3D = null

# State
var _is_frozen: bool = false
var _light_sources_in_range: Array[Area3D] = []


func _ready() -> void:
	_character_body = get_parent() as CharacterBody3D
	if not _character_body:
		push_error("LightFreezeComponent must be child of CharacterBody3D")
		return

	# Find AIChaseComponent
	_find_ai_chase()
	if not _ai_chase:
		push_warning("LightFreezeComponent: Could not find AIChaseComponent")

	# Find or create detection Area3D
	_find_or_create_detection_area()
	if not _detection_area:
		push_error("LightFreezeComponent: Could not find or create detection Area3D")
		return

	# Connect signals
	_detection_area.area_entered.connect(_on_area_entered)
	_detection_area.area_exited.connect(_on_area_exited)

	if debug:
		print("LightFreezeComponent initialized on ", _character_body.name)
		print("  Detection area: ", _detection_area.name)
		print("  Detection area layer: ", _detection_area.collision_layer, " mask: ", _detection_area.collision_mask)
		print("  Looking for lights tagged: '", light_tag, "'")


func _find_ai_chase() -> void:
	if not ai_chase_path.is_empty():
		_ai_chase = get_node_or_null(ai_chase_path) as AIChaseComponent
		return

	# Auto-detect in siblings
	for child in _character_body.get_children():
		if child is AIChaseComponent:
			_ai_chase = child
			return


func _find_or_create_detection_area() -> void:
	if not detection_area_path.is_empty():
		_detection_area = get_node_or_null(detection_area_path) as Area3D
		return

	# Auto-detect in siblings
	for child in _character_body.get_children():
		if child is Area3D and child.name == "LightDetectionArea":
			_detection_area = child
			return

	# Create one if not found
	_detection_area = Area3D.new()
	_detection_area.name = "LightDetectionArea"
	_character_body.add_child(_detection_area)

	# Position at center of character (y=1 to match CollisionShape3D)
	_detection_area.position = Vector3(0, 1, 0)

	# Create a sphere collision for detection
	var collision = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0  # Detection sphere around enemy (increased from 1.0)
	collision.shape = sphere
	_detection_area.add_child(collision)

	# Set collision layers to only detect areas
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 16  # Layer 5 for light areas
	_detection_area.monitorable = false  # Don't detect this area
	_detection_area.monitoring = true  # But DO detect other areas

	if debug:
		print("Created LightDetectionArea on ", _character_body.name)


func _on_area_entered(area: Area3D) -> void:
	# Check if this is a freeze light
	if not area.is_in_group(light_tag):
		return

	if debug:
		print("Light area entered: ", area.name)

	# Add to tracking list
	if not _light_sources_in_range.has(area):
		_light_sources_in_range.append(area)

	_update_freeze_state()


func _on_area_exited(area: Area3D) -> void:
	# Remove from tracking list
	if _light_sources_in_range.has(area):
		_light_sources_in_range.erase(area)

		if debug:
			print("Light area exited: ", area.name)

		_update_freeze_state()


func _physics_process(_delta: float) -> void:
	# Debug: Check for nearby freeze lights manually
	if debug and Engine.get_frames_drawn() % 60 == 0:  # Every 60 frames
		print("\n=== FREEZE DEBUG ===")
		print("Death position: ", _character_body.global_position)
		print("Detection area position: ", _detection_area.global_position)
		print("Detection area monitoring: ", _detection_area.monitoring)
		print("Detection area monitorable: ", _detection_area.monitorable)

		# Check overlapping areas
		var nearby_areas = _detection_area.get_overlapping_areas()
		print("Overlapping areas: ", nearby_areas.size())
		for area in nearby_areas:
			print("  - ", area.name, " (parent: ", area.get_parent().name, ")")

		# Check all freeze_light areas in scene
		var all_freeze_lights = get_tree().get_nodes_in_group(light_tag)
		print("Freeze lights in scene: ", all_freeze_lights.size())
		for light in all_freeze_lights:
			if is_instance_valid(light) and light is Area3D:
				var light_area = light as Area3D
				print("  - Light: ", light_area.name)
				print("    Type: ", light_area.get_class())
				print("    Position: ", light_area.global_position)
				print("    Layer: ", light_area.collision_layer, " Mask: ", light_area.collision_mask)
				print("    Monitoring: ", light_area.monitoring, " Monitorable: ", light_area.monitorable)
				var distance = _character_body.global_position.distance_to(light_area.global_position)
				print("    Distance: ", distance)
			else:
				print("  - Invalid or non-Area3D light instance!")

		print("Currently frozen: ", _is_frozen)
		print("Lights in range: ", _light_sources_in_range.size())

	# Continuously check if we should be frozen
	if _light_sources_in_range.size() > 0:
		_update_freeze_state()


func _update_freeze_state() -> void:
	var should_freeze = false

	# Check if any light source has line of sight
	for light_area in _light_sources_in_range:
		if not is_instance_valid(light_area):
			continue

		if require_line_of_sight:
			if _has_line_of_sight_to_light(light_area):
				should_freeze = true
				break
		else:
			should_freeze = true
			break

	# Update freeze state
	if should_freeze and not _is_frozen:
		_freeze()
	elif not should_freeze and _is_frozen:
		_unfreeze()


func _add_gridmaps_to_exclude(node: Node, exclude_list: Array) -> void:
	if node.get_class() == "GridMap":
		exclude_list.append(node)
	for child in node.get_children():
		_add_gridmaps_to_exclude(child, exclude_list)


func _has_line_of_sight_to_light(light_area: Area3D) -> bool:
	if not is_instance_valid(light_area):
		return false

	# Get light position (use SpotLight3D if available, otherwise Area3D position)
	var light_position = light_area.global_position
	var light_node = light_area.get_parent()

	# Try to find SpotLight3D in parent or siblings
	if light_node:
		for child in light_node.get_children():
			if child is SpotLight3D:
				light_position = child.global_position
				break

	# Raycast from light to enemy
	var from = light_position
	var to = _character_body.global_position + Vector3(0, 1, 0)  # Aim for center of enemy

	var space_state = _character_body.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)

	# Build exclude list - exclude light itself and any GridMaps (floors)
	var exclude_list = [light_area, light_node]

	# Find all GridMaps in the scene and exclude them
	for node in get_tree().get_nodes_in_group("gridmap"):
		exclude_list.append(node)

	# Also check for GridMap by type in root
	var root = get_tree().root
	for child in root.get_children():
		_add_gridmaps_to_exclude(child, exclude_list)

	query.exclude = exclude_list

	var result = space_state.intersect_ray(query)

	if result:
		# Check if we hit the enemy (success!)
		if result.collider == _character_body:
			if debug:
				print("Line of sight to light: YES")
			return true
		# Check if we hit a GridMap (ignore it - treat as success)
		elif result.collider.get_class() == "GridMap":
			if debug:
				print("Line of sight: YES (ignoring GridMap floor)")
			return true
		else:
			if debug:
				print("Line of sight blocked by: ", result.collider.name, " (", result.collider.get_class(), ")")
			return false

	# No collision means nothing in the way
	if debug:
		print("Line of sight to light: YES (no obstruction)")
	return true


func _freeze() -> void:
	_is_frozen = true

	# Disable AI
	if _ai_chase:
		_ai_chase.set_enabled(false)

	if debug:
		print(_character_body.name, " FROZEN by light!")


func _unfreeze() -> void:
	_is_frozen = false

	# Enable AI
	if _ai_chase:
		_ai_chase.set_enabled(true)

	if debug:
		print(_character_body.name, " UNFROZEN - back to chasing!")


## Check if currently frozen
func is_frozen() -> bool:
	return _is_frozen


## Manually freeze/unfreeze
func set_frozen(frozen: bool) -> void:
	if frozen:
		_freeze()
	else:
		_unfreeze()
