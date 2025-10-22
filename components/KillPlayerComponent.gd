class_name KillPlayerComponent
extends Node

## Component that kills the player on contact and respawns them at last checkpoint
## Attach to any Node3D with an Area3D child for detection
## Useful for enemies, hazards, traps, etc.

@export_group("Kill Settings")
## Show debug messages
@export var debug: bool = false

@export_group("Node Paths")
## Path to Area3D trigger (leave empty for auto-detect)
@export var kill_area_path: NodePath = ""

# Internal references
var _kill_area: Area3D
var _is_killing: bool = false


func _ready() -> void:
	# Find kill area
	_find_kill_area()
	if not _kill_area:
		push_error("KillPlayerComponent: Could not find Area3D for kill detection")
		return

	# Connect to area signals
	_kill_area.body_entered.connect(_on_body_entered)

	if debug:
		print("KillPlayerComponent initialized on ", get_parent().name)


func _find_kill_area() -> void:
	if not kill_area_path.is_empty():
		_kill_area = get_node_or_null(kill_area_path) as Area3D
		return

	# Auto-detect: search parent for Area3D
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is Area3D and child.name == "KillArea":
				_kill_area = child
				return


func _on_body_entered(body: Node3D) -> void:
	# Only kill once
	if _is_killing:
		return

	# Check if it's the player
	if not body.is_in_group("player"):
		return

	if debug:
		print("KillPlayerComponent: Player touched! Triggering death...")

	# Mark as killing to prevent multiple triggers
	_is_killing = true

	# Trigger death
	_kill_player(body)


func _kill_player(player: Node3D) -> void:
	print("Player killed by ", get_parent().name, "!")

	# Remove the player scene before reloading (just like level transitions)
	if player:
		print("Removing player before respawn...")
		# Find and remove the entire spawn_scene (player + TV)
		var spawn_scene = player.get_parent()
		if spawn_scene:
			spawn_scene.queue_free()
		else:
			# Fallback: just remove the player
			player.queue_free()

	# Wait one frame for cleanup
	await get_tree().process_frame

	# Reload the level at the checkpoint
	CheckpointManager.respawn_at_checkpoint()
