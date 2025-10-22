# AI Chase System Documentation

## Overview

The AI chase system allows enemies to pursue the player using the same component-based movement system as the player. Enemies use `Walk3DComponent` for movement and `Jump3DComponent` for gravity, controlled by `AIChaseComponent` for intelligent pathfinding.

## Components

### AIChaseComponent
- **Attach to**: CharacterBody3D enemy with Walk3DComponent
- **Purpose**: Calculates direction to player and sends movement commands
- **Features**:
  - Automatic player detection via groups
  - Configurable chase and minimum distances
  - Smooth rotation to face target
  - Speed multiplier for different enemy types
  - Works seamlessly with existing Walk3DComponent

## Quick Start: Using the Death Enemy

The death enemy (`res://scenes/death.tscn`) is ready to drop into any level:

1. **Add to your level**: Drag `death.tscn` into your scene
2. **Position it**: Place it anywhere on the floor
3. **Done!** The enemy will automatically chase the player when within range

### How It Works

- **Detection**: Finds player by "player" group (already set up)
- **Chase Range**: Starts chasing when player is within 20 units
- **Min Distance**: Stops at 1.5 units from player
- **Movement**: Uses Walk3DComponent (same as player)
- **Gravity**: Uses Jump3DComponent to stay on ground
- **Rotation**: Smoothly rotates to face player while chasing
- **Kill on Contact**: Uses KillPlayerComponent - touching Death respawns player at last checkpoint

## Configuration

### AIChaseComponent Exports

#### Chase Settings
- **chase_range**: Max distance to start chasing (default: 20.0)
- **min_distance**: Minimum distance from target (default: 1.5)
- **speed_multiplier**: Multiplies Walk3DComponent speed (default: 1.0)
- **rotate_to_target**: Face target while chasing (default: true)
- **rotation_speed**: How fast to rotate (default: 5.0 rad/s)

#### Target Settings
- **target_group**: Group name to find target (default: "player")
- **manual_target**: Override with specific Node3D (optional)

#### Node Paths
- **walk_component_path**: Path to Walk3DComponent (auto-detected)

### Example Configurations

**Fast Aggressive Enemy:**
```gdscript
# In Inspector or via code
$Death/AIChaseComponent.chase_range = 30.0  # Detects from farther
$Death/AIChaseComponent.min_distance = 0.5  # Gets very close
$Death/Walk3DComponent.speed = 6.0  # Faster than player
$Death/AIChaseComponent.speed_multiplier = 1.5  # Even faster!
```

**Slow Lurker:**
```gdscript
$Death/AIChaseComponent.chase_range = 10.0  # Only chases when close
$Death/AIChaseComponent.min_distance = 3.0  # Keeps distance
$Death/Walk3DComponent.speed = 2.0  # Slower than player
$Death/AIChaseComponent.rotation_speed = 2.0  # Slow turn
```

**Patrol Guard (stops chasing):**
```gdscript
$Death/AIChaseComponent.set_enabled(false)  # Disable chasing
# Implement custom patrol logic
```

## Advanced: Creating Custom AI Enemies

To create your own AI enemy:

1. Create a **CharacterBody3D** root node
2. Add a **CollisionShape3D** child (capsule or box)
3. Add your 3D model/mesh
4. Add **Walk3DComponent** (controls horizontal movement)
5. Add **Jump3DComponent** (handles gravity)
6. Add **AIChaseComponent** (controls AI behavior)
7. Configure speeds and ranges

Example structure:
```
CharacterBody3D (root, groups=["enemy"])
├── CollisionShape3D (physics collision)
├── Walk3DComponent (movement)
├── Jump3DComponent (gravity)
├── AIChaseComponent (AI brain)
└── MeshInstance3D or Model (visual)
```

## Staying on Floor Tiles

The enemy automatically stays on the floor thanks to:

1. **Jump3DComponent**: Applies gravity to pull enemy down
2. **CharacterBody3D.is_on_floor()**: Detects ground contact
3. **move_and_slide()**: Handles collision with floor tiles

The enemy will:
- ✅ Fall onto floor tiles from any height
- ✅ Walk across floor tiles smoothly
- ✅ Stop at edges (won't walk off cliffs)
- ✅ Climb small steps (CharacterBody3D default behavior)

### GridMap Support

If using a GridMap for your floors:
- Ensure GridMap has collision enabled
- Floor tiles in mesh library should have collision shapes
- Enemy will treat GridMap tiles as solid ground

## Navigation System (Pathfinding Around Obstacles)

By default, the AI now uses Godot's NavigationAgent3D for intelligent pathfinding. This means:
- ✅ AI follows walls to reach the player (no more getting stuck at edges)
- ✅ AI finds paths around obstacles and through doorways
- ✅ AI can navigate complex level layouts
- ✅ Multiple AI agents avoid each other

### Setting Up Navigation in Your Level

For the AI to pathfind properly, you need to set up a NavigationRegion3D in your level:

#### Step 1: Add NavigationRegion3D

1. Open your level scene (e.g., `test_level.tscn`)
2. Add a **NavigationRegion3D** node as a child of the level root
3. The NavigationRegion3D tells the AI where it can walk

#### Step 2: Create or Assign Navigation Mesh

**Option A: Automatic Baking (Recommended)**

1. Select the NavigationRegion3D node
2. In the Inspector, create a new **NavigationMesh** resource
3. Configure the NavigationMesh properties:
   - **Agent Height**: 2.0 (height of enemy)
   - **Agent Radius**: 0.5 (width of enemy)
   - **Agent Max Climb**: 0.5 (max step height)
4. Click **Bake NavigationMesh** button at the top of the 3D viewport
5. Godot will automatically generate walkable areas from your level geometry

**Option B: Manual NavigationMeshInstance3D**

1. As a child of NavigationRegion3D, add a **MeshInstance3D**
2. Create a mesh representing walkable areas (usually a plane matching your floor)
3. The navigation system uses this to determine where AI can walk

#### Step 3: Verify Navigation Setup

1. Run your level
2. Look for the console message: `AIChaseComponent initialized on Death (Navigation: true)`
3. If navigation is working, AI will pathfind around obstacles
4. If it says `Navigation: false`, check that:
   - NavigationRegion3D exists in the scene
   - NavigationMesh has been baked
   - The enemy has a NavigationAgent3D (already in death.tscn)

#### Troubleshooting Navigation

**AI stops at edges instead of going around:**
- Make sure you've baked the NavigationMesh
- Check that the baked mesh connects the enemy to the player
- Verify **use_navigation** is enabled in AIChaseComponent (default: true)

**AI still walks through walls:**
- Increase **Agent Radius** in NavigationMesh settings
- Rebake the NavigationMesh after changes
- Ensure walls have collision (StaticBody3D)

**AI gets stuck in corners:**
- Enable **avoidance_enabled** on NavigationAgent3D (already enabled in death.tscn)
- Increase **radius** on NavigationAgent3D
- Increase **Agent Radius** in NavigationMesh and rebake

### Navigation Configuration

AIChaseComponent has new navigation settings:

```gdscript
# In Inspector or via code
$Death/AIChaseComponent.use_navigation = true  # Enable pathfinding (default)
$Death/AIChaseComponent.path_desired_distance = 0.5  # Path accuracy
$Death/AIChaseComponent.target_desired_distance = 0.5  # Waypoint distance
```

NavigationAgent3D settings (already configured in death.tscn):
- **path_desired_distance**: 0.5
- **target_desired_distance**: 0.5
- **path_max_distance**: 3.0
- **avoidance_enabled**: true
- **radius**: 0.5

### Disabling Navigation (Fallback to Simple Chase)

If you want the old behavior (direct chase without pathfinding):

```gdscript
$Death/AIChaseComponent.use_navigation = false
```

This will use simple edge detection and direct movement toward the player.

## Signals and Methods

### AIChaseComponent Methods

```gdscript
# Check if currently chasing
if $Death/AIChaseComponent.is_chasing():
    print("Enemy is chasing!")

# Set a new target
$Death/AIChaseComponent.set_target($OtherPlayer)

# Get current target
var target = $Death/AIChaseComponent.get_target()

# Enable/disable chasing
$Death/AIChaseComponent.set_enabled(false)
```

## Integration with Other Systems

### Connecting to Custom Events

```gdscript
# In your level script
func _ready():
    # Make enemy chase a different target
    $Death/AIChaseComponent.set_target($ImportantNPC)

    # Disable chase when player hides
    $HideSpot.player_hidden.connect(_on_player_hidden)

func _on_player_hidden():
    $Death/AIChaseComponent.set_enabled(false)
```

### Multiple Enemies

Drop multiple death enemies into your level - they all work independently:

```gdscript
# Speed up all enemies when alarm triggers
func _on_alarm_triggered():
    for enemy in get_tree().get_nodes_in_group("enemy"):
        enemy.get_node("Walk3DComponent").speed *= 1.5
```

### Distance Checking

```gdscript
func _process(_delta):
    var player = $Player
    var enemy = $Death
    var distance = player.global_position.distance_to(enemy.global_position)

    if distance < 5.0:
        # Player is very close to enemy - trigger event
        print("Enemy is too close!")
```

## Troubleshooting

### Enemy doesn't chase player
- Ensure player is in "player" group (already done in player.tscn)
- Check **chase_range** is large enough
- Verify player is within range in the scene
- Check console for "AIChaseComponent initialized" message

### Enemy walks through walls
- Add CollisionShape3D to enemy (already in death.tscn)
- Ensure walls have StaticBody3D or similar collision
- CharacterBody3D automatically handles collision

### Enemy floats or falls through floor
- Ensure floor has collision (StaticBody3D with CollisionShape3D)
- Check Jump3DComponent is attached (handles gravity)
- Verify floor collision layers match enemy's mask

### Enemy doesn't rotate to face player
- Set **rotate_to_target** = true in AIChaseComponent
- Increase **rotation_speed** for faster turning
- Check enemy isn't stuck on geometry

### Enemy is too fast/slow
- Adjust **speed** in Walk3DComponent (base speed)
- Adjust **speed_multiplier** in AIChaseComponent (chase speed modifier)
- Typical speeds: Player = 5.0, Enemy = 3.0-6.0

## Performance Notes

- Each enemy runs pathfinding in `_physics_process` (60 FPS)
- Distance checks are very cheap (single Vector3 calculation)
- No navigation meshes required for simple chase AI
- Recommended: Up to 10-20 enemies per scene for good performance

## Death and Respawn

The Death enemy is equipped with **KillPlayerComponent** which:
- Detects when it touches the player
- Freezes the player and triggers death
- Respawns player at the last activated checkpoint
- Reloads the level to reset enemies and state

For more details, see `DEATH_RESPAWN_SYSTEM.md`.

## Future Enhancements

Suggested components to add:

- **AIPatrolComponent**: Walk between waypoints when not chasing
- **AIHealthComponent**: Take damage and die (for killing enemies)
- **AIVisionComponent**: Only chase if player is visible (line of sight)
- **AIHearingComponent**: Chase towards sounds
- **AIStateComponent**: Idle → Alert → Chase → Attack states
- **MultipleHitsComponent**: Require multiple touches to kill player (health system)

## See Also

- `COMPONENT_SYSTEM.md` - Component architecture overview
- `DEATH_RESPAWN_SYSTEM.md` - Death and checkpoint respawn system
- `components/Walk3DComponent.gd` - Movement system
- `components/Jump3DComponent.gd` - Gravity and jumping
- `components/AIChaseComponent.gd` - AI chase logic
- `components/KillPlayerComponent.gd` - Player death component
- `scenes/death.tscn` - Example AI enemy
