@tool
extends Node3D

## Helper script for CameraSnapshot visual indicator
## Shows the indicator in editor, hides it during gameplay

@export var show_in_editor: bool = true:
	set(value):
		show_in_editor = value
		_update_visibility()

@export var show_in_game: bool = false:
	set(value):
		show_in_game = value
		_update_visibility()


func _ready() -> void:
	_update_visibility()


func _update_visibility() -> void:
	var should_show = false

	if Engine.is_editor_hint():
		# In editor
		should_show = show_in_editor
	else:
		# In game
		should_show = show_in_game

	visible = should_show
