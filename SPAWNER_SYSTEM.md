# Spawner System Documentation

## Overview

The `SpawnerComponent` is a flexible, reusable component that can spawn any scene at runtime. It's perfect for spawning players at checkpoints, spawning objects, creating enemy spawn points, or any other dynamic scene instantiation needs.

## SpawnerComponent.gd

**Type**: `class_name SpawnerComponent extends Node`

**Purpose**: Spawns a scene at a specified location with configurable options

### Signals

- `spawned(instance: Node)` - Emitted when a scene is successfully spawned, returns the spawned instance
- `spawn_failed(reason: String)` - Emitted when spawn fails, includes error reason

### Export Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `scene_to_spawn` | String (file path) | `""` | Path to the .tscn file to spawn |
| `spawn_on_ready` | bool | `false` | Automatically spawn when scene loads |
| `spawn_as_child` | bool | `false` | If true, spawn as sibling of spawner. If false, spawn at scene root |
| `use_spawner_transform` | bool | `true` | If true, use spawner's position/rotation. If false, use scene's default |
| `spawn_offset` | Vector3 | `(0,0,0)` | Additional position offset from spawner |
| `spawn_rotation_offset` | Vector3 | `(0,0,0)` | Additional rotation offset in degrees |
| `one_shot` | bool | `false` | If true, can only spawn once, then disables itself |
| `hide_after_spawn` | bool | `false` | If true, hide all visual children after spawning |
| `node_to_hide` | NodePath | `NodePath()` | Specific node to hide after spawning (overrides hide_after_spawn) |

### Public Methods

#### `spawn() -> Node`
Spawns the configured scene using the spawner's settings.
- Returns the spawned instance on success, or `null` on failure
- Respects `one_shot` setting - won't spawn again if already spawned
- Emits `spawned` signal on success or `spawn_failed` on failure

```gdscript
# Basic spawn
var instance = spawner.spawn()
if instance:
    print("Spawned successfully!")
```

#### `spawn_at(position: Vector3, rotation_degrees: Vector3 = Vector3.ZERO) -> Node`
Spawns the scene at a specific position and rotation, overriding the spawner's transform.
- `position`: World position where the instance should spawn
- `rotation_degrees`: Rotation in degrees (Vector3)
- Returns the spawned instance or `null` on failure

```gdscript
# Spawn at specific location
var spawn_pos = Vector3(10, 0, 5)
var spawn_rot = Vector3(0, 90, 0)  # Face east
var instance = spawner.spawn_at(spawn_pos, spawn_rot)
```

#### `can_spawn() -> bool`
Returns whether this spawner can spawn again.
- Returns `false` if `one_shot` is true and already spawned
- Returns `false` if `scene_to_spawn` is empty
- Otherwise returns `true`

```gdscript
if spawner.can_spawn():
    spawner.spawn()
```

#### `reset() -> void`
Resets the spawner state, allowing `one_shot` spawners to spawn again.

```gdscript
# Reset checkpoint spawner after player respawns
spawner.reset()
```

#### `get_last_spawned() -> Node`
Returns the last spawned instance, or `null` if nothing has been spawned yet.

```gdscript
var last_player = spawner.get_last_spawned()
if last_player:
    print("Last spawned at: ", last_player.global_position)
```

### Parent Requirements

- **Recommended**: Parent should be a `Node3D` for position/rotation to work
- **Optional**: Can work with any Node, but `use_spawner_transform` won't function properly

## Usage Examples

### Example 1: Player Spawn Point (Auto-spawn on level start)

```gdscript
# In the Godot editor or .tscn file:
# 1. Create a Node3D called "PlayerSpawnPoint"
# 2. Add SpawnerComponent as child
# 3. Add a MeshInstance3D visual marker (optional, for editor visibility)
# 4. Configure:
#    - scene_to_spawn: "res://scenes/player.tscn"
#    - spawn_on_ready: true
#    - spawn_as_child: false (spawn at root)
#    - use_spawner_transform: true
#    - node_to_hide: "../VisualMarker" (to hide marker after spawn)
```

**In .tscn format:**
```
[node name="PlayerSpawnPoint" type="Node3D"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 0)

[node name="SpawnerComponent" type="Node" parent="."]
script = ExtResource("res://components/SpawnerComponent.gd")
scene_to_spawn = "res://scenes/player.tscn"
spawn_on_ready = true
spawn_as_child = false
use_spawner_transform = true
node_to_hide = NodePath("../VisualMarker")

[node name="VisualMarker" type="MeshInstance3D" parent="."]
# Visual marker - visible in editor, hidden at runtime
```

### Example 2: Checkpoint System (Spawn player on death)

```gdscript
# checkpoint.gd
extends Node3D

@onready var spawner = $SpawnerComponent

func _ready():
    # Configure spawner
    spawner.scene_to_spawn = "res://scenes/player.tscn"
    spawner.use_spawner_transform = true
    # Don't spawn on ready - wait for player to reach checkpoint

func activate():
    # Called when player reaches this checkpoint
    print("Checkpoint activated!")
    # Could save this checkpoint as the active respawn point

func respawn_player():
    # Called when player dies
    var player = spawner.spawn()
    if player:
        print("Player respawned at checkpoint")
    return player
```

### Example 3: Item Spawner (Spawn pickupable objects)

```gdscript
# item_spawner.gd
extends Node3D

@onready var spawner = $SpawnerComponent

func _ready():
    spawner.scene_to_spawn = "res://scenes/pickupable_box.tscn"
    spawner.spawn_on_ready = true
    spawner.spawn_offset = Vector3(0, 1, 0)  # Spawn 1 meter above spawner

func spawn_item():
    if spawner.can_spawn():
        var item = spawner.spawn()
        return item
    return null
```

### Example 4: Enemy Wave Spawner (Multiple spawns)

```gdscript
# enemy_wave_spawner.gd
extends Node3D

@onready var spawner = $SpawnerComponent
var enemies_to_spawn = 5
var spawn_interval = 2.0
var spawn_timer = 0.0

func _ready():
    spawner.scene_to_spawn = "res://scenes/enemy.tscn"
    spawner.use_spawner_transform = true
    spawner.one_shot = false  # Can spawn multiple times

func _process(delta):
    if enemies_to_spawn > 0:
        spawn_timer += delta
        if spawn_timer >= spawn_interval:
            spawn_enemy()
            spawn_timer = 0.0

func spawn_enemy():
    var enemy = spawner.spawn()
    if enemy:
        enemies_to_spawn -= 1
        print("Enemy spawned! Remaining: ", enemies_to_spawn)
```

### Example 5: Random Position Spawner

```gdscript
# random_spawner.gd
extends Node3D

@onready var spawner = $SpawnerComponent

func _ready():
    spawner.scene_to_spawn = "res://scenes/collectible.tscn"

func spawn_random():
    # Spawn at random position in a radius
    var random_pos = global_position + Vector3(
        randf_range(-5, 5),
        0,
        randf_range(-5, 5)
    )
    var instance = spawner.spawn_at(random_pos)
    return instance

func _on_timer_timeout():
    spawn_random()
```

### Example 6: Using Signals

```gdscript
# spawn_manager.gd
extends Node

@onready var spawner = $SpawnPoint/SpawnerComponent

func _ready():
    # Connect to spawner signals
    spawner.spawned.connect(_on_spawned)
    spawner.spawn_failed.connect(_on_spawn_failed)

func _on_spawned(instance: Node):
    print("Successfully spawned: ", instance.name)
    # Could track spawned instances, update UI, etc.

func _on_spawn_failed(reason: String):
    push_error("Spawn failed: " + reason)
    # Could show error message to player, log to analytics, etc.
```

## Scene Structure Examples

### Basic Spawn Point
```
SpawnPoint (Node3D)
└── SpawnerComponent (Node)
    - scene_to_spawn: "res://scenes/player.tscn"
    - spawn_on_ready: true
```

### Checkpoint with Visual Marker
```
Checkpoint (Node3D)
├── SpawnerComponent (Node)
│   - scene_to_spawn: "res://scenes/player.tscn"
├── MeshInstance3D (visual marker)
├── Area3D (to detect player)
│   └── CollisionShape3D
└── CheckpointScript (script)
```

### Multi-Point Spawner
```
SpawnManager (Node)
├── SpawnPoint1 (Node3D)
│   └── SpawnerComponent
├── SpawnPoint2 (Node3D)
│   └── SpawnerComponent
├── SpawnPoint3 (Node3D)
│   └── SpawnerComponent
└── ManagerScript (chooses which spawner to use)
```

## Hiding Visual Markers

Spawn points often need visual markers in the editor to see where objects will spawn, but you don't want these markers visible during gameplay.

### Option 1: Hide Specific Node (Recommended)
```gdscript
# Set node_to_hide to point to your visual marker
spawner.node_to_hide = NodePath("../VisualMarker")
```

**Benefits:**
- Marker stays visible in editor for easy positioning
- Only hides at runtime after spawning
- Precise control over what gets hidden

### Option 2: Auto-hide All Visual Children
```gdscript
# Enable hide_after_spawn to automatically hide all visual nodes
spawner.hide_after_spawn = true
```

**Auto-hides:**
- MeshInstance3D nodes
- Sprite3D nodes
- CSGShape3D nodes

**Note:** This searches recursively through all children, so it may hide more than intended if you have complex spawn point structures.

### Example Setup
```
SpawnPoint (Node3D) - position this where you want to spawn
├── SpawnerComponent (Node)
│   └── node_to_hide = "../VisualMarker"
└── VisualMarker (MeshInstance3D) - visible in editor, hidden at runtime
```

## Best Practices

1. **Scene Organization**: Create dedicated spawn point scenes that include the SpawnerComponent pre-configured
2. **Visual Markers**: Add a visible mesh in editor and use `node_to_hide` to hide it at runtime
3. **Error Handling**: Always check if `spawn()` returns `null` and handle failures gracefully
4. **Performance**: Use `one_shot = true` for spawners that only need to spawn once (saves checking)
5. **Transform Setup**: Position your spawn point Node3D exactly where you want objects to appear
6. **Signal Usage**: Connect to `spawned` signal to initialize the spawned instance (set properties, add to tracking lists, etc.)
7. **Editor Visibility**: Use `node_to_hide` instead of `hide_after_spawn` to keep markers visible while editing

## Common Use Cases

### Checkpoint System
- Place spawn points throughout level
- Set `spawn_on_ready = false`
- Call `spawn()` when player dies
- Only spawn at last activated checkpoint

### Object Pooling
- Use multiple spawners with same scene
- Disable auto-spawn
- Call `spawn()` when needed
- Track instances for later reuse

### Procedural Generation
- Use `spawn_at()` with calculated positions
- Loop through spawn grid
- Randomize positions/rotations

### Wave-Based Enemies
- Multiple spawners around arena
- Timer-based spawning
- Track spawned enemies
- Increase difficulty per wave

## Debugging Tips

- **Nothing spawns**: Check that `scene_to_spawn` path is correct (use `res://` prefix)
- **Wrong position**: Ensure parent is Node3D and `use_spawner_transform = true`
- **Spawns at origin**: Check that spawn point Node3D has correct transform
- **One_shot not working**: Use `reset()` method to re-enable spawner
- **Signals not firing**: Ensure signals are connected in `_ready()` after node is in tree

## Integration with Other Components

The SpawnerComponent works well with:
- **PickupableComponent**: Spawn pickupable objects at item spawn points
- **HealthComponent**: Spawn new enemies when old ones die
- **Checkpoint systems**: Respawn player at last checkpoint
- **AI systems**: Spawn AI-controlled entities at predetermined points

## File Locations

- Component Script: `C:\game-dev\halloween\components\SpawnerComponent.gd`
- Example Scenes:
  - `C:\game-dev\halloween\scenes\spawn_point.tscn`
  - `C:\game-dev\halloween\scenes\checkpoint.tscn`
- Documentation: `C:\game-dev\halloween\SPAWNER_SYSTEM.md`

## Future Enhancements

Possible additions to consider:
- **Spawn pools**: Track and limit number of active spawned instances
- **Respawn timers**: Auto-respawn after a delay
- **Spawn conditions**: Only spawn if certain conditions are met
- **Spawn effects**: Play particle effects or sounds on spawn
- **Batch spawning**: Spawn multiple instances at once
- **Formation spawning**: Spawn in patterns (circle, grid, line)
