class_name SpawnerComponent
extends Node

## Spawns a scene at a specified location
## Can be used for spawning players, objects, checkpoints, enemies, etc.
## Attach to any Node3D to use it as a spawn point

# Signals
signal spawned(instance: Node)  ## Emitted when a scene is spawned
signal spawn_failed(reason: String)  ## Emitted when spawn fails

# Export variables
@export_file("*.tscn") var scene_to_spawn: String = ""  ## The scene file to spawn
@export var spawn_on_ready: bool = false  ## Automatically spawn when scene loads
@export var spawn_as_child: bool = false  ## If true, spawn as child of this node's parent. If false, spawn at scene root
@export var use_spawner_transform: bool = true  ## If true, use spawner's position/rotation. If false, use scene's default transform
@export var spawn_offset: Vector3 = Vector3.ZERO  ## Additional position offset from spawner
@export var spawn_rotation_offset: Vector3 = Vector3.ZERO  ## Additional rotation offset in degrees
@export var one_shot: bool = false  ## If true, can only spawn once, then disables itself
@export var hide_after_spawn: bool = false  ## If true, hide the spawner's visual children after spawning
@export var node_to_hide: NodePath = NodePath()  ## Specific node to hide after spawning (overrides hide_after_spawn)

# State
var has_spawned: bool = false
var spawner_node: Node3D = null
var last_spawned_instance: Node = null

func _ready() -> void:
	# Get reference to parent node (should be a Node3D for position/rotation)
	spawner_node = get_parent() as Node3D
	if not spawner_node:
		push_warning("SpawnerComponent parent is not a Node3D. Position/rotation will not work correctly.")

	# Validate scene path
	if scene_to_spawn.is_empty():
		push_warning("SpawnerComponent has no scene_to_spawn set")

	# Auto-spawn if configured (deferred to avoid parent busy error)
	if spawn_on_ready:
		spawn.call_deferred()

## Spawn the configured scene
## Returns the spawned instance or null if spawn failed
func spawn() -> Node:
	# Check one-shot restriction
	if one_shot and has_spawned:
		emit_signal("spawn_failed", "SpawnerComponent is one_shot and has already spawned")
		return null

	# Validate scene path
	if scene_to_spawn.is_empty():
		emit_signal("spawn_failed", "No scene_to_spawn configured")
		push_error("SpawnerComponent: Cannot spawn - scene_to_spawn is empty")
		return null

	# Load the scene
	var scene = load(scene_to_spawn)
	if not scene:
		emit_signal("spawn_failed", "Failed to load scene: " + scene_to_spawn)
		push_error("SpawnerComponent: Failed to load scene: " + scene_to_spawn)
		return null

	# Instance the scene
	var instance = scene.instantiate()
	if not instance:
		emit_signal("spawn_failed", "Failed to instantiate scene: " + scene_to_spawn)
		push_error("SpawnerComponent: Failed to instantiate scene: " + scene_to_spawn)
		return null

	# Determine where to add the instance
	var parent_node: Node
	if spawn_as_child and spawner_node:
		parent_node = spawner_node.get_parent()
	else:
		parent_node = get_tree().root

	if not parent_node:
		emit_signal("spawn_failed", "Could not determine parent node for spawned instance")
		push_error("SpawnerComponent: Could not determine parent node")
		instance.queue_free()
		return null

	# Add to scene tree
	parent_node.add_child(instance)

	# Set transform if the instance is a Node3D
	# Note: For spawning in _ready(), transforms must be set after node is fully in tree
	# We use call_deferred for spawn_on_ready to handle this
	if use_spawner_transform and spawner_node and instance is Node3D:
		# Apply spawner's transform plus offsets
		instance.global_position = spawner_node.global_position + spawn_offset
		instance.global_rotation_degrees = spawner_node.global_rotation_degrees + spawn_rotation_offset

	# Update state
	has_spawned = true
	last_spawned_instance = instance

	# Hide nodes if configured
	if not node_to_hide.is_empty():
		# Hide specific node if path is set
		var target_node = get_node_or_null(node_to_hide)
		if target_node:
			target_node.hide()
		else:
			push_warning("SpawnerComponent: node_to_hide path is invalid: " + str(node_to_hide))
	elif hide_after_spawn and spawner_node:
		# Fallback to hiding all visual children
		_hide_visual_children(spawner_node)

	# Emit success signal
	emit_signal("spawned", instance)

	return instance

## Hide all visual children of the spawner (MeshInstance3D, etc.)
func _hide_visual_children(node: Node) -> void:
	for child in node.get_children():
		# Hide visual nodes but keep the SpawnerComponent and other logic nodes
		if child is MeshInstance3D or child is Sprite3D or child is CSGShape3D:
			child.hide()
		# Recursively check children
		if child.get_child_count() > 0:
			_hide_visual_children(child)

## Spawn at a specific position and rotation (overrides spawner transform)
## rotation_degrees: Rotation in degrees (Vector3)
func spawn_at(position: Vector3, rotation_degrees: Vector3 = Vector3.ZERO) -> Node:
	# Temporarily override transform settings
	var original_use_transform = use_spawner_transform
	var original_offset = spawn_offset
	var original_rotation_offset = spawn_rotation_offset

	use_spawner_transform = true

	# Create temporary spawn point if needed
	if not spawner_node:
		spawner_node = Node3D.new()

	var original_position = spawner_node.global_position
	var original_rotation = spawner_node.global_rotation_degrees

	spawner_node.global_position = position
	spawner_node.global_rotation_degrees = rotation_degrees
	spawn_offset = Vector3.ZERO
	spawn_rotation_offset = Vector3.ZERO

	# Spawn
	var instance = spawn()

	# Restore settings
	use_spawner_transform = original_use_transform
	spawn_offset = original_offset
	spawn_rotation_offset = original_rotation_offset
	spawner_node.global_position = original_position
	spawner_node.global_rotation_degrees = original_rotation

	return instance

## Returns whether this spawner can spawn again
func can_spawn() -> bool:
	if one_shot and has_spawned:
		return false
	return not scene_to_spawn.is_empty()

## Reset the spawner (allows one_shot spawners to spawn again)
func reset() -> void:
	has_spawned = false
	last_spawned_instance = null

## Get the last spawned instance
func get_last_spawned() -> Node:
	return last_spawned_instance
