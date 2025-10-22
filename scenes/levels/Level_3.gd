extends Node3D

## Level 3 script - Spawns Death enemy when switch is activated
## Shows win screen when final checkpoint is reached

@export var win_screen_path: String = "res://scenes/win_screen.tscn"

@onready var death_enemy = $Death
@onready var switch_component = $Switch/SwitchComponent
@onready var final_checkpoint = $Checkpoint2/CheckpointComponent


func _ready() -> void:
	# Hide Death enemy initially
	if death_enemy:
		death_enemy.visible = false
		death_enemy.process_mode = Node.PROCESS_MODE_DISABLED
		print("Level_3: Death enemy hidden, waiting for switch activation")

	# Connect switch signal to spawn Death
	if switch_component:
		switch_component.switch_activated.connect(_on_switch_activated)
		print("Level_3: Switch connected to spawn Death enemy")
	else:
		push_warning("Level_3: Could not find Switch/SwitchComponent!")

	# Connect final checkpoint to show win screen
	if final_checkpoint:
		# We need to intercept the checkpoint activation before it processes
		# Get the trigger area from the checkpoint
		var trigger_area = final_checkpoint.get_node_or_null("../TriggerArea")
		if trigger_area:
			# Connect to body_entered with high priority (before CheckpointComponent)
			trigger_area.body_entered.connect(_on_final_checkpoint_reached, CONNECT_ONE_SHOT)
			print("Level_3: Final checkpoint connected to win screen")
		else:
			push_warning("Level_3: Could not find final checkpoint trigger area!")
	else:
		push_warning("Level_3: Could not find Checkpoint2/CheckpointComponent!")


func _on_switch_activated() -> void:
	print("Level_3: Switch activated! Spawning Death enemy...")

	if death_enemy:
		# Make Death enemy visible and active
		death_enemy.visible = true
		death_enemy.process_mode = Node.PROCESS_MODE_INHERIT
		print("Level_3: Death enemy spawned and active!")


func _on_final_checkpoint_reached(body: Node3D) -> void:
	# Check if it's the player
	if not body is CharacterBody3D:
		return

	print("Level_3: Final checkpoint reached! Showing win screen...")

	# Freeze the player
	if body:
		var spawn_scene = body.get_parent()
		if spawn_scene:
			spawn_scene.queue_free()
		else:
			body.queue_free()

	# Wait a frame for cleanup
	await get_tree().process_frame

	# Show win screen
	get_tree().change_scene_to_file(win_screen_path)
