class_name GameState
extends Resource

## Saveable game state resource
## Stores player progress, checkpoint data, and other persistent information

## The furthest checkpoint the player has reached
@export var furthest_checkpoint: CheckpointID.ID = CheckpointID.ID.NONE

## Scene path of the level where the furthest checkpoint is
@export var current_level_path: String = ""

## All checkpoints that have been activated (for visual feedback)
@export var activated_checkpoints: Array[int] = []

## Player position at the furthest checkpoint
@export var spawn_position: Vector3 = Vector3.ZERO

## Timestamp of when this save was created
@export var save_timestamp: int = 0

## Total playtime in seconds
@export var playtime_seconds: float = 0.0

## Custom data dictionary for additional game-specific data
@export var custom_data: Dictionary = {}


## Check if a checkpoint has been activated
func is_checkpoint_activated(checkpoint_id: CheckpointID.ID) -> bool:
	return checkpoint_id in activated_checkpoints


## Activate a checkpoint (add to list if not already there)
func activate_checkpoint(checkpoint_id: CheckpointID.ID) -> void:
	if not is_checkpoint_activated(checkpoint_id):
		activated_checkpoints.append(checkpoint_id)


## Update the furthest checkpoint if the new one is further
func update_furthest_checkpoint(checkpoint_id: CheckpointID.ID, level_path: String, position: Vector3) -> bool:
	# Always update if we don't have a checkpoint yet
	if furthest_checkpoint == CheckpointID.ID.NONE:
		furthest_checkpoint = checkpoint_id
		current_level_path = level_path
		spawn_position = position
		activate_checkpoint(checkpoint_id)
		return true

	# Update if the new checkpoint ID is greater (further in game)
	if checkpoint_id > furthest_checkpoint:
		furthest_checkpoint = checkpoint_id
		current_level_path = level_path
		spawn_position = position
		activate_checkpoint(checkpoint_id)
		return true

	# Otherwise just mark it as activated but don't update furthest
	activate_checkpoint(checkpoint_id)
	return false


## Reset the game state
func reset() -> void:
	furthest_checkpoint = CheckpointID.ID.NONE
	current_level_path = ""
	activated_checkpoints.clear()
	spawn_position = Vector3.ZERO
	save_timestamp = 0
	playtime_seconds = 0.0
	custom_data.clear()


## Get a summary of the save for display purposes
func get_save_summary() -> Dictionary:
	return {
		"has_save": furthest_checkpoint != CheckpointID.ID.NONE,
		"checkpoint_name": CheckpointID.get_checkpoint_name(furthest_checkpoint),
		"checkpoint_id": furthest_checkpoint,
		"level_path": current_level_path,
		"checkpoint_count": activated_checkpoints.size(),
		"playtime": playtime_seconds,
		"timestamp": save_timestamp
	}
