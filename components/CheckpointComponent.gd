class_name CheckpointComponent
extends Node

## Component that handles checkpoint activation
## Attach to any Node3D with an Area3D child to create a checkpoint
## Can save progress or load the next level when activated

@export_group("Checkpoint Settings")
## The checkpoint ID from the CheckpointID enum
@export var checkpoint_id: CheckpointID.ID = CheckpointID.ID.NONE

## Can this checkpoint be activated multiple times?
@export var one_time_only: bool = true

## Move the spawn point to this checkpoint when activated
@export var update_spawn_point: bool = true

@export_group("Visual Feedback")
## Hide visual marker in game (only visible in editor)
@export var editor_only_visual: bool = true

## Path to visual mesh (leave empty for auto-detect)
@export var visual_mesh_path: NodePath = ""

@export_group("Node Paths")
## Path to Area3D trigger (leave empty for auto-detect)
@export var trigger_area_path: NodePath = ""

# Internal state
var _is_activated: bool = false
var _trigger_area: Area3D
var _visual_mesh: MeshInstance3D
var _original_material: Material

func _ready() -> void:
	# Validate checkpoint ID
	if checkpoint_id == CheckpointID.ID.NONE:
		push_error("CheckpointComponent: checkpoint_id is NONE. Please set a valid checkpoint ID.")
		return

	# Find trigger area
	_find_trigger_area()
	if not _trigger_area:
		push_error("CheckpointComponent: Could not find Area3D trigger")
		return

	# Connect to trigger area
	_trigger_area.body_entered.connect(_on_body_entered)
	print("CheckpointComponent '", CheckpointID.get_checkpoint_name(checkpoint_id), "' connected to trigger area")

	# Find visual mesh
	_find_visual_mesh()

	# Hide visual marker in game if editor_only_visual is enabled
	if _visual_mesh and editor_only_visual:
		_visual_mesh.hide()
		print("Checkpoint visual marker hidden (editor-only mode)")

	# Check if this checkpoint was already activated
	if CheckpointManager.is_checkpoint_activated(checkpoint_id):
		_is_activated = true

func _find_trigger_area() -> void:
	if not trigger_area_path.is_empty():
		_trigger_area = get_node_or_null(trigger_area_path)
		return

	# Auto-detect: search parent for Area3D
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is Area3D:
				_trigger_area = child
				return

func _find_visual_mesh() -> void:
	if not visual_mesh_path.is_empty():
		_visual_mesh = get_node_or_null(visual_mesh_path)
		return

	# Auto-detect: search parent for MeshInstance3D
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is MeshInstance3D:
				_visual_mesh = child
				return

func _on_body_entered(body: Node3D) -> void:
	print("CheckpointComponent '", CheckpointID.get_checkpoint_name(checkpoint_id), "' detected body: ", body.name, " (", body.get_class(), ")")

	# Check if it's the player
	if not body is CharacterBody3D:
		print("  -> Not a CharacterBody3D, ignoring")
		return

	# Check if already activated and one-time only
	if one_time_only and _is_activated:
		print("  -> Already activated (one-time only)")
		return

	# Activate checkpoint
	_activate_checkpoint(body)

func _activate_checkpoint(player: CharacterBody3D) -> void:
	print("Checkpoint activated: ", CheckpointID.get_checkpoint_name(checkpoint_id))

	# Mark as activated
	_is_activated = true

	# Save checkpoint progress
	var current_scene = get_tree().current_scene.scene_file_path
	var spawn_pos = get_parent().global_position
	CheckpointManager.activate_checkpoint(checkpoint_id, current_scene, spawn_pos)

	# Move spawn point to this checkpoint
	if update_spawn_point:
		_move_spawn_point()

func _move_spawn_point() -> void:
	# Find the SpawnPoint in the scene
	var spawn_point = get_tree().get_first_node_in_group("spawn_point")

	if not spawn_point:
		# Try to find it by searching for SpawnPoint nodes
		spawn_point = _find_spawn_point_in_scene()

	if spawn_point and spawn_point is Node3D:
		# Move it to this checkpoint's position
		spawn_point.global_position = get_parent().global_position
		print("SpawnPoint moved to checkpoint: ", CheckpointID.get_checkpoint_name(checkpoint_id), " at position: ", spawn_point.global_position)
	else:
		push_warning("CheckpointComponent: Could not find SpawnPoint in scene to update")

func _find_spawn_point_in_scene() -> Node3D:
	var root = get_tree().current_scene
	return _search_for_spawn_point(root)

func _search_for_spawn_point(node: Node) -> Node3D:
	if node.name == "SpawnPoint" or "SpawnPoint" in node.name:
		return node as Node3D

	for child in node.get_children():
		var result = _search_for_spawn_point(child)
		if result:
			return result

	return null


## Manually activate this checkpoint (useful for scripted events)
func activate() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_activate_checkpoint(player)
	else:
		push_warning("CheckpointComponent: Cannot find player to activate checkpoint")
