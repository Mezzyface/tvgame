extends Node

## Global checkpoint manager (autoload singleton)
## Handles saving/loading game state using GameState resource

# Signals
signal checkpoint_activated(checkpoint_id: CheckpointID.ID)
signal game_loaded()
signal save_completed()
signal load_completed()

# Save file path
const SAVE_FILE_PATH = "user://game_save.tres"

# Current game state
var game_state: GameState = null

# Track playtime
var _session_start_time: float = 0.0


func _ready() -> void:
	# Initialize with a new game state
	game_state = GameState.new()
	_session_start_time = Time.get_ticks_msec() / 1000.0
	print("CheckpointManager initialized")


## Activate a checkpoint and save if it's the furthest
func activate_checkpoint(checkpoint_id: CheckpointID.ID, level_path: String, spawn_pos: Vector3) -> void:
	if not game_state:
		game_state = GameState.new()

	# Update playtime
	_update_playtime()

	# Update furthest checkpoint
	var is_new_furthest = game_state.update_furthest_checkpoint(checkpoint_id, level_path, spawn_pos)

	if is_new_furthest:
		print("New furthest checkpoint: ", CheckpointID.get_checkpoint_name(checkpoint_id))
	else:
		print("Checkpoint activated: ", CheckpointID.get_checkpoint_name(checkpoint_id), " (not furthest)")

	# Always save when activating a checkpoint
	save_game()

	emit_signal("checkpoint_activated", checkpoint_id)


## Save the current game state to disk
func save_game() -> bool:
	if not game_state:
		push_error("CheckpointManager: No game state to save")
		return false

	# Update timestamp
	game_state.save_timestamp = Time.get_unix_time_from_system()
	_update_playtime()

	# Save using ResourceSaver
	var error = ResourceSaver.save(game_state, SAVE_FILE_PATH)

	if error == OK:
		print("Game saved successfully to: ", SAVE_FILE_PATH)
		emit_signal("save_completed")
		return true
	else:
		push_error("Failed to save game state. Error code: ", error)
		return false


## Load game state from disk
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found at: ", SAVE_FILE_PATH)
		return false

	# Load using ResourceLoader
	var loaded_state = ResourceLoader.load(SAVE_FILE_PATH)

	if loaded_state and loaded_state is GameState:
		game_state = loaded_state
		print("Game loaded successfully")
		print("  Furthest checkpoint: ", CheckpointID.get_checkpoint_name(game_state.furthest_checkpoint))
		print("  Level: ", game_state.current_level_path)
		print("  Activated checkpoints: ", game_state.activated_checkpoints.size())
		emit_signal("load_completed")
		return true
	else:
		push_error("Failed to load game state from: ", SAVE_FILE_PATH)
		return false


## Load the game and change to the saved level
func continue_game() -> bool:
	if not load_game():
		return false

	if game_state.current_level_path.is_empty():
		push_warning("No level path in save file")
		return false

	if game_state.furthest_checkpoint == CheckpointID.ID.NONE:
		push_warning("No checkpoint saved")
		return false

	# Change to the saved level
	get_tree().change_scene_to_file(game_state.current_level_path)
	emit_signal("game_loaded")
	return true


## Start a new game (clear save)
func new_game(starting_level_path: String) -> void:
	game_state = GameState.new()
	_session_start_time = Time.get_ticks_msec() / 1000.0

	# Delete old save file
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

	print("Started new game")

	# Load the starting level
	if not starting_level_path.is_empty():
		get_tree().change_scene_to_file(starting_level_path)


## Check if a save file exists
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


## Check if a checkpoint has been activated
func is_checkpoint_activated(checkpoint_id: CheckpointID.ID) -> bool:
	if not game_state:
		return false
	return game_state.is_checkpoint_activated(checkpoint_id)


## Get the spawn position from the current game state
func get_spawn_position() -> Vector3:
	if game_state:
		return game_state.spawn_position
	return Vector3.ZERO


## Get the furthest checkpoint ID
func get_furthest_checkpoint() -> CheckpointID.ID:
	if game_state:
		return game_state.furthest_checkpoint
	return CheckpointID.ID.NONE


## Get save info for display (menu, etc.)
func get_save_info() -> Dictionary:
	if not has_save():
		return {
			"has_save": false,
			"checkpoint_name": "",
			"checkpoint_id": CheckpointID.ID.NONE,
			"level_path": "",
			"checkpoint_count": 0,
			"playtime": 0.0,
			"timestamp": 0
		}

	# Try to load and get info
	if load_game() and game_state:
		return game_state.get_save_summary()

	return {"has_save": false}


## Update playtime
func _update_playtime() -> void:
	if game_state:
		var current_time = Time.get_ticks_msec() / 1000.0
		var session_time = current_time - _session_start_time
		game_state.playtime_seconds += session_time
		_session_start_time = current_time


## Clear all save data
func clear_save() -> void:
	game_state = GameState.new()
	_session_start_time = Time.get_ticks_msec() / 1000.0

	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

	print("Save data cleared")


## Respawn player at last checkpoint (reload current level)
func respawn_at_checkpoint() -> void:
	print("Player died! Respawning at last checkpoint...")

	# If we have a saved checkpoint, reload the level
	if game_state and game_state.furthest_checkpoint != CheckpointID.ID.NONE:
		var current_level = game_state.current_level_path
		if current_level.is_empty():
			current_level = get_tree().current_scene.scene_file_path

		print("  Reloading level: ", current_level)
		print("  Checkpoint: ", CheckpointID.get_checkpoint_name(game_state.furthest_checkpoint))

		# Reload the current level (preserves checkpoint progress)
		get_tree().change_scene_to_file(current_level)
	else:
		push_warning("No checkpoint to respawn at! Starting new game.")
		new_game("res://scenes/levels/Level_1.tscn")
