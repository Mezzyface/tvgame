class_name CheckpointID

## Enum for all checkpoint IDs in the game
## Add new checkpoints here as you create them

enum ID {
	NONE = -1,

	# Level 1 checkpoints
	LEVEL_1_START = 0,
	LEVEL_1_CHECKPOINT_1 = 1,
	LEVEL_1_CHECKPOINT_2 = 2,
	LEVEL_1_END = 3,

	# Level 2 checkpoints
	LEVEL_2_START = 10,
	LEVEL_2_CHECKPOINT_1 = 11,
	LEVEL_2_CHECKPOINT_2 = 12,
	LEVEL_2_END = 13,

	# Level 3 checkpoints
	LEVEL_3_START = 20,
	LEVEL_3_CHECKPOINT_1 = 21,
	LEVEL_3_CHECKPOINT_2 = 22,
	LEVEL_3_END = 23,
}

## Get a human-readable name for a checkpoint ID
static func get_checkpoint_name(id: ID) -> String:
	match id:
		ID.NONE: return "None"
		ID.LEVEL_1_START: return "Level 1 - Start"
		ID.LEVEL_1_CHECKPOINT_1: return "Level 1 - Checkpoint 1"
		ID.LEVEL_1_CHECKPOINT_2: return "Level 1 - Checkpoint 2"
		ID.LEVEL_1_END: return "Level 1 - End"
		ID.LEVEL_2_START: return "Level 2 - Start"
		ID.LEVEL_2_CHECKPOINT_1: return "Level 2 - Checkpoint 1"
		ID.LEVEL_2_CHECKPOINT_2: return "Level 2 - Checkpoint 2"
		ID.LEVEL_2_END: return "Level 2 - End"
		ID.LEVEL_3_START: return "Level 3 - Start"
		ID.LEVEL_3_CHECKPOINT_1: return "Level 3 - Checkpoint 1"
		ID.LEVEL_3_CHECKPOINT_2: return "Level 3 - Checkpoint 2"
		ID.LEVEL_3_END: return "Level 3 - End"
		_: return "Unknown"
