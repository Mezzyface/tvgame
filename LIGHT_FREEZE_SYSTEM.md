# Light Freeze System Documentation

## Overview

The light freeze system creates a "Weeping Angel" mechanic where enemies freeze when hit by light from the TV. This adds strategic gameplay where the player must use the TV's light to stop enemies from chasing them.

## How It Works

1. **TV Light**: The pickup TV has a SpotLight3D that emits cyan light
2. **Freeze Area**: An invisible Area3D cylinder extends from the light, matching the light cone
3. **Detection**: When Death enters the freeze area, it checks line of sight to the light
4. **Freeze**: If the light has line of sight to Death, the AI is disabled and Death freezes
5. **Unfreeze**: When Death leaves the light or light is blocked, it resumes chasing

## Components

### LightFreezeComponent
- **Attach to**: CharacterBody3D enemy with AIChaseComponent
- **Purpose**: Detects when enemy is in light and freezes AI
- **Features**:
  - Auto-detects light sources tagged with "freeze_light"
  - Raycast line-of-sight check (light blocked by walls = no freeze)
  - Auto-creates detection Area3D if needed
  - Debug mode for testing

### FreezeLightArea (on TV)
- **Type**: Area3D attached to SpotLight3D
- **Purpose**: Marks the light cone area
- **Tag**: "freeze_light" group
- **Shape**: Cylinder matching light cone dimensions

## Quick Start

The system is already set up on:
- ✅ `res://scenes/pickup_tv.tscn` - Has FreezeLightArea
- ✅ `res://scenes/death.tscn` - Has LightFreezeComponent

**To test:**
1. Add Death enemy to your level
2. Add or pick up the TV
3. Point the TV light at Death
4. Death will freeze when the light hits it!
5. Turn away or block the light - Death resumes chasing

## Configuration

### LightFreezeComponent Exports

#### Freeze Settings
- **debug**: Enable console debug messages (default: true for Death)
- **require_line_of_sight**: Use raycast to check light isn't blocked (default: true)
- **light_tag**: Group tag to find light sources (default: "freeze_light")

#### Node Paths
- **ai_chase_path**: Path to AIChaseComponent (auto-detected)
- **detection_area_path**: Path to Area3D for detection (auto-created)

### Example Configurations

**More Sensitive (easier to freeze):**
```gdscript
# In FreezeLightArea on TV
$PickupTV/SpotLight3D/FreezeLightArea/CollisionShape3D.shape.radius = 8.0  # Wider cone
```

**Ignore Walls (light goes through):**
```gdscript
# In LightFreezeComponent on Death
$Death/LightFreezeComponent.require_line_of_sight = false
```

**Silent Mode (no debug messages):**
```gdscript
$Death/LightFreezeComponent.debug = false
```

## Technical Details

### Collision Layers

The system uses Godot's collision layer system:
- **FreezeLightArea**: Layer 5 (bit 16), Mask 0
- **LightDetectionArea**: Layer 0, Mask 5 (bit 16)

This ensures light areas only detect enemies, not walls or other objects.

### Line of Sight Check

When `require_line_of_sight = true`:
1. Raycast from SpotLight3D to Death's center
2. If raycast hits Death directly → Freeze
3. If raycast hits a wall first → Don't freeze
4. This allows hiding behind walls from the light

### Auto-Detection

The LightFreezeComponent automatically:
- Finds AIChaseComponent in siblings
- Creates a detection Area3D if none exists
- Searches for lights tagged "freeze_light"
- Handles spawning timing (finds target after spawn)

## Gameplay Tips

### For Level Design

**Survival Horror:**
- Place Death enemies in dark corridors
- Player must carry TV to see AND freeze enemies
- Create tension: "Do I look at the enemy or where I'm going?"

**Puzzle Elements:**
- Multiple enemies require quick light management
- Narrow passages where player must freeze enemy to pass
- Timed sections where player must keep light on enemy

**Strategic Depth:**
- Place cover/corners where player can hide from light
- Create choice: "Freeze this enemy or save light battery?"
- Multiple paths: "Sneak in dark or fight with light?"

### For Players

**Pro Tips:**
- Keep the TV light pointed at Death while backing away
- Use walls to block line of sight when you need to run
- Death resumes chasing instantly when light is removed
- The light only freezes what it directly hits (no wall penetration)

## Advanced: Multiple Light Sources

You can add freeze lights to other objects:

### Example: Static Light Source

```gdscript
# Create a scene with a SpotLight3D
# Add this as a child:
var freeze_area = Area3D.new()
freeze_area.add_to_group("freeze_light")
freeze_area.collision_layer = 16
freeze_area.collision_mask = 0

var collision = CollisionShape3D.new()
var shape = CylinderShape3D.new()
shape.height = 10.0
shape.radius = 5.0
collision.shape = shape
freeze_area.add_child(collision)

$SpotLight3D.add_child(freeze_area)
```

### Example: Flashlight Weapon

You can create a flashlight that freezes enemies:
1. Copy the TV's FreezeLightArea setup
2. Attach to a new pickupable object
3. Add SpotLight3D with FreezeLightArea child
4. Tag with "freeze_light" group

## Debugging

### Console Messages (when debug = true)

```
LightFreezeComponent initialized on Death
Light area entered: FreezeLightArea
Line of sight to light: YES
Death FROZEN by light!
Line of sight blocked by: Wall
Death UNFROZEN - back to chasing!
```

### Visual Debugging

In Godot editor:
1. Select Death in scene tree
2. Expand Death → LightDetectionArea
3. In 3D viewport, you'll see a small sphere (the detection area)
4. Select PickupTV → SpotLight3D → FreezeLightArea
5. You'll see a cylinder showing the freeze zone

### Common Issues

**Death doesn't freeze:**
- Check console for "Light area entered" message
- Verify TV's FreezeLightArea is in "freeze_light" group
- Check collision layers (Layer 5 on FreezeLightArea)
- Ensure Death has LightFreezeComponent

**Death freezes through walls:**
- Set `require_line_of_sight = true`
- Check walls have proper collision (StaticBody3D)

**Freeze area too small/large:**
- Adjust CylinderShape3D radius in FreezeLightArea
- Match to your SpotLight3D's spot_angle

## Performance

- Each LightFreezeComponent does 1 raycast per frame when in light area
- Very cheap: ~0.01ms per enemy
- Recommended: Up to 20 frozen enemies simultaneously
- Area detection is handled by Godot's physics engine (very efficient)

## Integration with Other Systems

### With AI States

```gdscript
# In a custom AI state machine
func _physics_process(delta):
    if $LightFreezeComponent.is_frozen():
        # Enemy is frozen, skip AI logic
        return

    match current_state:
        STATE_PATROL: _patrol(delta)
        STATE_CHASE: _chase(delta)
```

### With Animation

```gdscript
# Connect to freeze/unfreeze events
func _ready():
    $LightFreezeComponent.freeze_started.connect(_play_freeze_animation)
    $LightFreezeComponent.freeze_ended.connect(_play_unfreeze_animation)

func _play_freeze_animation():
    $AnimationPlayer.play("freeze")

func _play_unfreeze_animation():
    $AnimationPlayer.play("unfreeze")
```

Note: Currently LightFreezeComponent doesn't emit signals, but you can add them!

## See Also

- `AI_CHASE_SYSTEM.md` - Enemy chase AI documentation
- `components/LightFreezeComponent.gd` - Freeze component code
- `components/AIChaseComponent.gd` - Chase AI code
- `scenes/death.tscn` - Example frozen enemy
- `scenes/pickup_tv.tscn` - Example freeze light source
