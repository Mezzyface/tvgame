# Component System Documentation

## Overview

This project uses a component-based architecture for modular, reusable gameplay features. Components are Node scripts that can be attached to any scene to give it specific capabilities.

## Architecture Principles

- **Composition over Inheritance**: Build complex behaviors by combining simple components
- **Component Blindness**: Components don't directly know about siblings or parent (except physics components that need the CharacterBody3D reference)
- **Signal-Based Communication**: Components communicate through signals for loose coupling
- **Reusability**: Components work with both player input and AI controllers

## Existing Components

### MovementInputComponent.gd
**Purpose**: Handles player input for movement (WASD) and jumping (Space)

**Type**: `class_name MovementInputComponent extends Node`

**Signals**:
- `movement_input(direction: Vector2)` - Emitted every physics frame with normalized input direction
- `jump_requested()` - Emitted when jump key is pressed

**Exports**:
- `move_forward_action` (String): Input action name for forward movement (default: "move_forward")
- `move_back_action` (String): Input action name for backward movement (default: "move_back")
- `move_left_action` (String): Input action name for left movement (default: "move_left")
- `move_right_action` (String): Input action name for right movement (default: "move_right")
- `jump_action` (String): Input action name for jumping (default: "jump")

**Usage**:
```gdscript
# Attach to CharacterBody3D as child
# Connect signals to other components:
movement_input_component.movement_input.connect(walk_component.apply_movement)
movement_input_component.jump_requested.connect(jump_component.perform_jump)
```

**Notes**: Only processes input, doesn't modify any physics or movement directly

---

### Walk3DComponent.gd
**Purpose**: Handles horizontal 3D walking movement with acceleration/deceleration

**Type**: `class_name Walk3DComponent extends Node`

**Exports**:
- `speed` (float): Maximum walking speed (default: 5.0)
- `acceleration` (float): How fast character accelerates (default: 10.0)
- `deceleration` (float): How fast character stops (default: 10.0)

**Public Methods**:
- `apply_movement(input_direction: Vector2)` - Sets the current movement direction

**Parent Requirements**: Must be a child of CharacterBody3D

**Usage**:
```gdscript
# For player-controlled movement:
walk_component.apply_movement(input_direction)

# For AI-controlled movement:
var ai_direction = Vector2(1, 0) # Move right
walk_component.apply_movement(ai_direction)
```

**How it works**:
- Stores reference to parent CharacterBody3D in `_ready()`
- Converts 2D input to 3D movement relative to character's rotation
- Applies smooth acceleration/deceleration
- Calls `move_and_slide()` on the CharacterBody3D

---

### Jump3DComponent.gd
**Purpose**: Handles jumping physics and gravity

**Type**: `class_name Jump3DComponent extends Node`

**Exports**:
- `jump_velocity` (float): Upward velocity when jumping (default: 4.5)
- `gravity` (float): Gravity strength (default: 9.8)

**Public Methods**:
- `perform_jump()` - Triggers a jump if on floor

**Parent Requirements**: Must be a child of CharacterBody3D

**Usage**:
```gdscript
# For player-controlled jumping:
jump_component.perform_jump()

# For AI-controlled jumping:
if should_jump:
    jump_component.perform_jump()
```

**How it works**:
- Stores reference to parent CharacterBody3D in `_ready()`
- Applies gravity every physics frame when not on floor
- Only allows jumping when `is_on_floor()` returns true
- Directly modifies CharacterBody3D velocity.y

---

### MouseLookComponent.gd
**Purpose**: Handles mouse input for camera look rotation with enable/disable capability

**Type**: `class_name MouseLookComponent extends Node`

**Signals**:
- `look_input(pitch_delta: float, yaw_delta: float)` - Emitted when mouse moves with rotation deltas in radians

**Exports**:
- `mouse_sensitivity` (float): Mouse movement sensitivity multiplier (default: 0.002)
- `enabled` (bool): Whether mouse look is currently active (default: true)
- `capture_mouse_on_ready` (bool): Auto-capture mouse when scene loads (default: true)

**Public Methods**:
- `enable()` - Enable mouse look and capture the mouse cursor
- `disable()` - Disable mouse look and release the mouse cursor
- `capture_mouse()` - Capture the mouse cursor (hides it and locks to window)
- `release_mouse()` - Release the mouse cursor (shows it and allows free movement)

**Usage**:
```gdscript
# Connect to CameraControllerComponent:
mouse_look_component.look_input.connect(camera_controller.apply_rotation_delta)

# Disable for UI or interactions:
mouse_look_component.disable()

# Re-enable after interaction:
mouse_look_component.enable()
```

**Notes**:
- Only processes input when `enabled` is true
- Automatically captures mouse on scene load by default
- Perfect for toggling between gameplay and UI/menu modes

---

### CameraControllerComponent.gd
**Purpose**: Controls camera rotation from any input source (mouse, gamepad, AI, cinematics)

**Type**: `class_name CameraControllerComponent extends Node`

**Exports**:
- `min_pitch` (float): Minimum pitch angle in degrees (default: -89.0)
- `max_pitch` (float): Maximum pitch angle in degrees (default: 89.0)
- `camera_path` (NodePath): Path to the Camera3D node (auto-detects if not set)

**Public Methods**:
- `apply_rotation_delta(pitch_delta: float, yaw_delta: float)` - Apply relative rotation in radians
- `set_rotation(pitch: float, yaw: float)` - Set absolute rotation in radians (for cinematics)
- `get_pitch()` - Returns current pitch in radians
- `get_yaw()` - Returns current yaw in radians

**Parent Requirements**: Must be a child of CharacterBody3D

**Usage**:
```gdscript
# For mouse input (via signal):
camera_controller.apply_rotation_delta(pitch_delta, yaw_delta)

# For gamepad input:
camera_controller.apply_rotation_delta(gamepad_pitch, gamepad_yaw)

# For cinematics:
camera_controller.set_rotation(deg_to_rad(45), deg_to_rad(180))

# Query current rotation:
var current_pitch = camera_controller.get_pitch()
```

**How it works**:
- Yaw (left/right) rotates the CharacterBody3D
- Pitch (up/down) rotates the Camera3D with clamping
- Generic design allows input from any source
- Auto-detects Camera3D if camera_path not set

---

### SpawnerComponent.gd
**Purpose**: Spawns a scene at runtime with configurable position/rotation

**Type**: `class_name SpawnerComponent extends Node`

**Signals**:
- `spawned(instance: Node)` - Emitted when a scene is successfully spawned
- `spawn_failed(reason: String)` - Emitted when spawn fails with error reason

**Exports**:
- `scene_to_spawn` (String): Path to the .tscn file to spawn
- `spawn_on_ready` (bool): Automatically spawn when scene loads (default: false)
- `spawn_as_child` (bool): Spawn as sibling vs at scene root (default: false)
- `use_spawner_transform` (bool): Use spawner's position/rotation (default: true)
- `spawn_offset` (Vector3): Additional position offset (default: Vector3.ZERO)
- `spawn_rotation_offset` (Vector3): Additional rotation offset in degrees (default: Vector3.ZERO)
- `one_shot` (bool): Can only spawn once if true (default: false)

**Public Methods**:
- `spawn()` - Spawn the scene using spawner settings, returns instance or null
- `spawn_at(position: Vector3, rotation_degrees: Vector3)` - Spawn at specific position
- `can_spawn()` - Returns whether spawner can spawn again
- `reset()` - Reset spawner state (allows one_shot to spawn again)
- `get_last_spawned()` - Returns last spawned instance

**Parent Requirements**: Works with any Node, but parent should be Node3D for transform features

**Usage**:
```gdscript
# For player spawn points:
spawner.scene_to_spawn = "res://player.tscn"
spawner.spawn_on_ready = true
spawner.spawn()

# For checkpoints:
var player = spawner.spawn()  # Respawn player at checkpoint

# For item spawners:
var item = spawner.spawn_at(Vector3(10, 0, 5))

# For wave spawners:
if spawner.can_spawn():
    var enemy = spawner.spawn()
```

**How it works**:
- Loads and instantiates the configured scene file
- Positions instance at spawner location (or custom location with spawn_at)
- Adds instance to scene tree
- Emits signals for success/failure
- Perfect for player spawn points, checkpoints, item spawners, enemy waves

**Documentation**: See `SPAWNER_SYSTEM.md` for complete guide with examples

---

### FlickerLightComponent.gd
**Purpose**: Makes a Light3D node flicker randomly for atmospheric lighting effects

**Type**: `class_name FlickerLightComponent extends Node`

**Exports**:
- `base_energy` (float): Base light energy level (default: 1.0)
- `flicker_amount` (float): How much the light flickers from base (default: 0.3)
- `flicker_speed` (float): Speed of flicker oscillation (default: 10.0)

**Parent Requirements**: Must be a child of Light3D (OmniLight3D, SpotLight3D, DirectionalLight3D)

**Usage**:
```gdscript
# Attach as child of any Light3D node
# Configure the flicker parameters:
flicker_component.base_energy = 2.0
flicker_component.flicker_amount = 0.5  # Flicker +/- 0.5 from base
flicker_component.flicker_speed = 15.0  # Faster flicker

# For TV screen flicker effect:
flicker_component.base_energy = 2.0
flicker_component.flicker_amount = 0.2
flicker_component.flicker_speed = 20.0
```

**How it works**:
- Automatically finds parent Light3D node in `_ready()`
- Uses sine/cosine combination for natural-looking flicker
- Each instance has random time offset so multiple lights don't sync
- Continuously modulates `light.light_energy` in `_process()`
- Perfect for candles, torches, TVs, broken lights, or campfires

---

## Input Actions Configuration

Configured in `project.godot` under `[input]`:

| Action Name     | Key | Physical Keycode | Use Case          |
|-----------------|-----|------------------|-------------------|
| move_forward    | W   | 87              | Move forward      |
| move_back       | S   | 83              | Move backward     |
| move_left       | A   | 65              | Move left         |
| move_right      | D   | 68              | Move right        |
| jump            | Space | 32            | Jump              |

## Player Scene Structure

```
Player (CharacterBody3D) - Root node with physics
├── CollisionShape3D - Capsule collision
├── MeshInstance3D - Capsule visual mesh
├── Camera3D - First-person camera at Y=1.7
├── MovementInputComponent - Handles WASD/Space input
├── Walk3DComponent - Handles walking
├── Jump3DComponent - Handles jumping and gravity
├── MouseLookComponent - Handles mouse input
└── CameraControllerComponent - Handles camera rotation
```

**Signal Connections**:
- `MovementInputComponent.movement_input` → `Walk3DComponent.apply_movement`
- `MovementInputComponent.jump_requested` → `Jump3DComponent.perform_jump`
- `MouseLookComponent.look_input` → `CameraControllerComponent.apply_rotation_delta`

## Creating New Components

### Step 1: Create the Component Script

```gdscript
class_name MyNewComponent
extends Node

## Brief description of what this component does

# Export variables for configuration
@export var some_parameter := 10.0

# Signals for communication
signal something_happened()

# Reference to parent (if needed)
var character_body: CharacterBody3D

func _ready() -> void:
    # Get parent reference if needed
    character_body = get_parent() as CharacterBody3D
    if not character_body:
        push_error("MyNewComponent must be child of CharacterBody3D")

func _physics_process(delta: float) -> void:
    # Component logic here
    pass

# Public methods that other components or controllers can call
func do_something() -> void:
    # Perform action
    emit_signal("something_happened")
```

### Step 2: Add Component to Scene

1. Open the scene in Godot editor (or edit .tscn file directly)
2. Add as child of the appropriate parent node
3. Set the script property to your component

Example .tscn addition:
```
[ext_resource type="Script" path="res://MyNewComponent.gd" id="4_xxxxx"]

[node name="MyNewComponent" type="Node" parent="."]
script = ExtResource("4_xxxxx")
```

### Step 3: Wire Up Signals (if needed)

Either in the .tscn file:
```
[connection signal="something_happened" from="MyNewComponent" to="OtherComponent" method="on_something_happened"]
```

Or in a parent script:
```gdscript
func _ready() -> void:
    $MyNewComponent.something_happened.connect(_on_something_happened)
```

## Component Ideas for Future Implementation

### InteractionComponent
- Detect interactable objects via raycast
- Emit signals when interaction is possible
- Could highlight nearby interactive objects

### HealthComponent
- Track entity health
- Emit signals on damage/death
- Could be used for players, enemies, destructible objects

### StaminaComponent
- Track stamina for sprinting/actions
- Regenerate over time
- Emit signals when depleted/recovered

### SprintComponent
- Modify Walk3DComponent speed when active
- Consume stamina (if StaminaComponent exists)
- Listen to sprint input

### CrouchComponent
- Modify collision shape height
- Reduce movement speed
- Could affect camera position

### InventoryComponent
- Store items
- Emit signals on item add/remove
- Generic for players and containers

### AIControllerComponent
- Replace MovementInputComponent for AI entities
- Calculate movement directions based on AI logic
- Call walk_component.apply_movement() with AI decisions

## Best Practices

1. **Single Responsibility**: Each component should do one thing well
2. **Export Configuration**: Use @export for values that should be tweakable
3. **Use Signals**: Don't call methods on sibling components directly
4. **Error Checking**: Always check if parent is correct type in _ready()
5. **Documentation**: Add clear comments explaining what the component does
6. **Type Safety**: Use `class_name` to enable type checking
7. **Test Independently**: Components should work without specific sibling components

## Testing Components

### Testing with Player Input
Attach MovementInputComponent and test with keyboard input

### Testing with AI
Create a simple AI script that calls component methods directly:
```gdscript
extends Node

@onready var walk_component = get_parent().get_node("Walk3DComponent")

func _physics_process(delta):
    # AI logic determines direction
    var direction = Vector2(1, 0)
    walk_component.apply_movement(direction)
```

## Debugging Tips

- Use `push_warning()` to log component state
- Check signal connections in Godot's Node tab
- Verify parent node types in `_ready()`
- Use Remote Inspector to check values at runtime
- Print current_direction in Walk3DComponent to verify input flow

## File Locations

- Components: `C:\game-dev\halloween\components\*.gd`
- Scenes: `C:\game-dev\halloween\scenes\*.tscn`
- Player Scene: `C:\game-dev\halloween\scenes\player.tscn`
- Test Level: `C:\game-dev\halloween\scenes\test_level.tscn`
- Input Configuration: `C:\game-dev\halloween\project.godot` → `[input]` section

## Common Issues and Solutions

### Character doesn't move
- Check that Walk3DComponent is child of CharacterBody3D
- Verify signal connections between MovementInputComponent and Walk3DComponent
- Check input actions are configured in project.godot

### Character doesn't stop moving
- Ensure MovementInputComponent emits Vector2.ZERO when no input
- Check deceleration value in Walk3DComponent

### Jump doesn't work
- Verify Jump3DComponent is child of CharacterBody3D
- Check signal connection from MovementInputComponent to Jump3DComponent
- Ensure character is on floor (check collision setup)

### Mesh doesn't move with character
- CharacterBody3D must be the root node or parent of visual elements
- All visual nodes must be children of the CharacterBody3D

### Camera doesn't follow player
- Camera3D must be a child of the CharacterBody3D (or player root)
- Positioned at approximately Y=1.7 for eye level on standard capsule

### Mouse look doesn't work
- Verify MouseLookComponent is enabled (`enabled = true`)
- Check signal connection to CameraControllerComponent
- Ensure mouse is captured (should happen automatically on ready)
- Check mouse_sensitivity value if rotation is too slow/fast

### Camera rotation is jerky or inverted
- Adjust mouse_sensitivity in MouseLookComponent
- Check that pitch_delta and yaw_delta calculations use correct sign
- Verify min_pitch and max_pitch values in CameraControllerComponent
