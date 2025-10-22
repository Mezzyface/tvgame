extends Control

## Win screen shown when player completes the game

@export var auto_return_delay: float = 5.0  # Seconds before auto-returning to menu
@export var main_menu_path: String = "res://scenes/start_menu.tscn"

@onready var timer_label = $CenterContainer/VBoxContainer/TimerLabel

var _time_remaining: float = 0.0


func _ready():
	# Show mouse cursor
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Start countdown
	_time_remaining = auto_return_delay

	# Update timer label
	_update_timer_label()

	print("Win screen displayed! Returning to menu in ", auto_return_delay, " seconds...")


func _process(delta: float):
	if _time_remaining > 0:
		_time_remaining -= delta
		_update_timer_label()

		if _time_remaining <= 0:
			_return_to_menu()


func _update_timer_label():
	if timer_label:
		var seconds = ceili(_time_remaining)
		timer_label.text = "Returning to menu in " + str(seconds) + "..."


func _on_menu_button_pressed():
	_return_to_menu()


func _return_to_menu():
	print("Returning to main menu...")
	# Clear save data so next playthrough starts fresh
	CheckpointManager.clear_save()
	# Return to main menu
	get_tree().change_scene_to_file(main_menu_path)
