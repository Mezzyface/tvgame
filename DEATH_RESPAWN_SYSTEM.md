# Death and Respawn System Documentation

## Overview

The death and respawn system allows enemies and hazards to kill the player, sending them back to the last activated checkpoint. This creates challenge and stakes for the gameplay.

## How It Works

When the player touches an enemy (like Death):
1. **KillPlayerComponent** detects the collision
2. Player is frozen/disabled
3. Short delay (0.5 seconds)
4. **CheckpointManager** reloads the current level
5. Player respawns at the last checkpoint they activated
6. All level state is reset (enemies, switches, etc.)

## Components

### KillPlayerComponent

**Purpose**: Kills the player on contact and triggers respawn

**Attach to**: Any enemy or hazard that should kill the player

**Requirements**:
- Must have an **Area3D** child named "KillArea" (or specify path)
- Area3D must have a CollisionShape3D for detection

**Exports**:
- `respawn_delay`: Time before respawning (default: 0.5 seconds)
- `debug`: Show debug messages (default: false)
- `kill_area_path`: Path to Area3D trigger (auto-detects "KillArea")

**How it works**:
1. Detects when a body enters the KillArea
2. Checks if the body is in the "player" group
3. Freezes the player
4. Waits for respawn_delay
5. Calls CheckpointManager.respawn_at_checkpoint()

### CheckpointManager.respawn_at_checkpoint()

**Purpose**: Reloads the current level at the last saved checkpoint

**What it does**:
1. Prints death message to console
2. Gets the saved checkpoint and level path
3. Reloads the level using `change_scene_to_file()`
4. Player spawns at the checkpoint position

**Fallback**: If no checkpoint is saved, starts a new game from Level 1

## Using the Death Enemy

The Death enemy (`res://scenes/death.tscn`) is already configured with KillPlayerComponent:

### Death Enemy Structure
```
Death (CharacterBody3D)
├── CollisionShape3D (physics collision)
├── Walk3DComponent (movement)
├── Jump3DComponent (gravity)
├── NavigationAgent3D (pathfinding)
├── AIChaseComponent (chase AI)
├── LightFreezeComponent (freeze in light)
├── LightDetectionArea (Area3D for light)
├── KillArea (Area3D for player death)
│   └── CollisionShape3D (capsule, radius: 0.7)
├── KillPlayerComponent (triggers respawn)
└── Death2 (3D model)
```

### Quick Setup

**To use Death in your level:**
1. Drag `res://scenes/death.tscn` into your level
2. Position it where you want the enemy
3. Done! It will chase and kill the player

**Player touches Death:**
- Console: `"Player killed by Death!"`
- Console: `"Player died! Respawning at last checkpoint..."`
- Level reloads at the last checkpoint

## Creating Custom Hazards

You can add KillPlayerComponent to any hazard or trap:

### Example: Deadly Spike Trap

```gdscript
# Scene structure
StaticBody3D (Spikes)
├── MeshInstance3D (spike model)
├── KillArea (Area3D)
│   └── CollisionShape3D (box shape)
└── KillPlayerComponent
```

**Setup steps:**
1. Create a StaticBody3D or Node3D
2. Add your hazard model/mesh
3. Add an **Area3D** child named "KillArea"
4. Add a **CollisionShape3D** to KillArea with appropriate shape
5. Add **KillPlayerComponent** as a child
6. Set collision layer/mask:
   - KillArea collision_layer = 0 (doesn't collide with anything)
   - KillArea collision_mask = 1 (detects layer 1, which includes player)

## Configuration

### Adjusting Kill Range

To change how close Death needs to be to kill:

1. Select **Death → KillArea → CollisionShape3D** in editor
2. Adjust the **CapsuleShape3D** radius:
   - Smaller radius = closer contact needed
   - Larger radius = kills from farther away
   - Default: 0.7 meters

### Adjusting Respawn Delay

To change the delay before respawning:

1. Select **Death → KillPlayerComponent** in editor
2. Change **respawn_delay** value:
   - 0.0 = instant respawn (can be jarring)
   - 0.5 = default (gives player time to react)
   - 1.0+ = dramatic death pause

### Debug Mode

Enable debug messages to see when player is killed:

1. Select **Death → KillPlayerComponent**
2. Enable **debug** checkbox

You'll see messages like:
```
KillPlayerComponent: Player touched! Triggering death...
Player killed by Death!
```

## Checkpoint System Integration

The death system relies on the checkpoint system:

- **First checkpoint**: Player must activate at least one checkpoint
- **Death before checkpoint**: If player dies before activating any checkpoint, they restart from Level 1
- **Checkpoint activated**: Player respawns at the last checkpoint they touched
- **Level progression**: Checkpoints persist across deaths until level is completed

## Console Messages

When player dies, you'll see:

```
Player killed by Death!
Player died! Respawning at last checkpoint...
  Reloading level: res://scenes/levels/Level_1.tscn
  Checkpoint: Level 1 - Checkpoint 1
```

## Gameplay Flow Example

**Level 1 - First Playthrough:**
1. Player spawns at start
2. Player reaches Checkpoint 1 → Saved!
3. Death enemy chases player
4. Player gets caught → Respawns at Checkpoint 1
5. Player reaches Checkpoint 2 → Saved!
6. Player reaches exit → Loads Level 2

**Level 2 - With Death:**
1. Player spawns at Level 2 start
2. Player activates checkpoint
3. Death spawns and chases
4. Player dies → Respawns at Level 2 checkpoint
5. Player tries different path
6. Reaches exit → Loads Level 3

## Performance Notes

- KillArea uses Area3D detection (very efficient)
- Only triggers once per death (prevents multiple respawns)
- Level reload is fast (Godot's scene system is optimized)
- No memory leaks (old level is fully unloaded)

## Advanced: Creating Kill Zones

For instant-death areas (like pits or lava):

```gdscript
# Create a large Area3D covering the danger zone
Area3D (KillZone)
├── CollisionShape3D (BoxShape3D covering entire pit)
└── KillPlayerComponent
```

This creates an invisible death zone - player falls in and respawns!

## Troubleshooting

### Player doesn't die when touching Death
- Check Death has **KillArea** Area3D
- Verify KillArea has **CollisionShape3D**
- Ensure collision_mask = 1 (detects player layer)
- Enable debug mode to see if contact is detected

### Player respawns at wrong location
- Verify you activated the checkpoint you expect
- Check console for "Checkpoint activated: ..." messages
- Make sure checkpoint has `update_spawn_point` enabled

### Respawn causes error
- Ensure CheckpointManager is in autoload (Project Settings → Autoload)
- Verify level scene path is correct
- Check that checkpoint was properly saved

### Multiple deaths trigger at once
- This is prevented by `_is_killing` flag
- If it still happens, check you don't have multiple KillPlayerComponents

## See Also

- `COMPONENT_SYSTEM.md` - Component architecture overview
- `AI_CHASE_SYSTEM.md` - Death enemy chase behavior
- `components/KillPlayerComponent.gd` - Kill component code
- `components/CheckpointManager.gd` - Checkpoint/respawn system
- `scenes/death.tscn` - Death enemy scene
