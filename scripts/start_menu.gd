extends Control

@onready var continue_button = $CenterContainer/VBoxContainer/ContinueButton

func _ready():
	# Show mouse cursor for menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Check if there's a save to continue from
	if continue_button:
		var has_save = CheckpointManager.has_save()
		continue_button.disabled = not has_save
		continue_button.visible = has_save

		# Optional: Show save info for debugging
		if has_save:
			var save_info = CheckpointManager.get_save_info()
			print("Save found: ", save_info.checkpoint_name)

func _on_start_button_pressed():
	# Start a new game
	CheckpointManager.new_game("res://scenes/test_level.tscn")

func _on_continue_button_pressed():
	# Load from last checkpoint
	if not CheckpointManager.continue_game():
		push_warning("Failed to continue game")

func _on_quit_button_pressed():
	# Quit the game
	get_tree().quit()
