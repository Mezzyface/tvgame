# Switch System Documentation

## Overview

The switch system provides interactive levers that players can pull down with their mouse to trigger doors, gates, and other events. The system uses a component-based architecture with drag interaction.

## Components

### MouseInteractionComponent
- **Attach to**: Player CharacterBody3D (already included in `player.tscn`)
- **Purpose**: Detects mouse clicks and drag gestures on switches
- **Features**:
  - Raycasts to detect switches in the world
  - Tracks mouse drag distance and direction
  - Temporarily shows mouse cursor during drag
  - Validates drag distance and direction

### SwitchComponent
- **Attach to**: Any StaticBody3D switch object
- **Purpose**: Handles switch behavior, animation, and events
- **Features**:
  - Animates switch lever based on drag
  - Emits signals for activation and angle changes
  - Can connect directly to gates/doors
  - Three modes: Toggle, One-Time, Hold

## Quick Start: Using the Switch Scene

### 1. Add Switch to Your Level

The switch scene (`res://scenes/interactions/switch.tscn`) is ready to drop into any level:

1. In Godot, drag `switch.tscn` into your level scene
2. Position it where you want the switch
3. The switch is now functional and can be pulled by the player!

### 2. Connect Switch to a Gate

To make the switch open a gate/door:

1. Add a gate scene (e.g., `res://scenes/sliding_gate.tscn`) to your level
2. Select the Switch node in your level
3. In the Inspector, find **SwitchComponent** > **Node Paths** > **Connected Gate Path**
4. Click the assign button and select the gate's **GateController** node
5. The switch will now control the gate when pulled!

**Example path**: `../SlidingGate/GateController`

### 3. Player Interaction

To pull the switch:
1. Look at the switch (within 10 units)
2. Click and hold left mouse button on the switch
3. Drag downward to pull the switch
4. Release when pulled down enough
5. The switch stays down and triggers connected gates

## Configuration

### SwitchComponent Exports

#### Switch Settings
- **switch_type**: Behavior mode
  - `Toggle`: Pull once to activate, pull again to deactivate
  - `One-Time`: Can only be activated once (puzzle switch)
  - `Hold`: Must be held down (returns when released)
- **is_active**: Starting state (default: false)
- **interaction_range**: Max distance to interact (default: 3.0)

#### Visual Settings
- **max_rotation_angle**: How far switch rotates when fully pulled (default: -90°)
- **animation_speed**: Speed of snap-back animation (default: 5.0)

#### Drag Settings
- **require_drag**: Must drag to activate (default: true)
- **drag_sensitivity**: How much drag affects rotation (default: 0.5)
- **min_activation_angle**: Minimum pull angle to keep switch down (default: -45°)

#### Node Paths
- **animated_object_path**: Path to the object to animate (default: parent)
- **connected_gate_path**: Path to GateController to trigger (optional)

### MouseInteractionComponent Exports

- **interaction_range**: Max raycast distance (default: 10.0)
- **min_drag_distance**: Minimum pixels to drag (default: 20.0)
- **show_debug**: Print debug info to console (default: false)

## Signals

### SwitchComponent Signals

```gdscript
signal switch_activated()
signal switch_deactivated()
signal switch_toggled(is_active: bool)
signal switch_angle_changed(angle: float, progress: float)
```

### Usage Example

```gdscript
# Connect to switch signals in your level script
func _ready():
    var switch = $Switch/SwitchComponent
    switch.switch_activated.connect(_on_switch_pulled)

func _on_switch_pulled():
    print("Switch was activated!")
    # Trigger custom events here
```

## Advanced: Custom Switch Scene

To create your own switch:

1. Create a **StaticBody3D** root node
2. Add a **CollisionShape3D** child (for raycast detection)
3. Add a **SwitchComponent** child
4. Add your 3D model (base and lever)
5. Set **animated_object_path** to point to the lever mesh
6. Configure rotation angles and drag settings

Example structure:
```
StaticBody3D (root)
├── CollisionShape3D (interaction area)
├── SwitchComponent
├── Base (MeshInstance3D or Scene)
└── Lever (MeshInstance3D or Scene) <- animated_object_path points here
```

## Advanced: Connecting to Custom Systems

### Manual Gate Control

Instead of using `connected_gate_path`, you can manually control gates:

```gdscript
# In your level script
func _ready():
    var switch = $Switch/SwitchComponent
    var gate = $MyGate/GateController

    # Option 1: Full open/close
    switch.switch_activated.connect(gate.open)
    switch.switch_deactivated.connect(gate.close)

    # Option 2: Real-time drag control
    switch.switch_angle_changed.connect(_on_switch_angle_changed)

func _on_switch_angle_changed(angle: float, progress: float):
    var gate = $MyGate/GateController
    gate.set_open_progress(progress)  # 0.0 to 1.0
```

### Custom Events

Connect to any system using signals:

```gdscript
func _ready():
    $Switch/SwitchComponent.switch_activated.connect(_unlock_door)
    $Switch/SwitchComponent.switch_activated.connect(_spawn_enemies)
    $Switch/SwitchComponent.switch_angle_changed.connect(_dim_lights)

func _unlock_door():
    $Door.unlock()

func _spawn_enemies():
    $EnemySpawner.spawn()

func _dim_lights(angle: float, progress: float):
    $Light.light_energy = 1.0 - progress
```

## Troubleshooting

### Switch doesn't respond to clicks
- Ensure player has **MouseInteractionComponent** (it's in `player.tscn`)
- Check switch has a **CollisionShape3D** for raycast detection
- Verify switch is within **interaction_range** (default 10 units)
- Check console for "Started dragging switch" message

### Lever doesn't animate
- Verify **animated_object_path** points to the correct node
- Check the path in Inspector (e.g., `../bone_C2`)
- Ensure the target node is a Node3D

### Gate doesn't open
- Verify **connected_gate_path** points to the **GateController** node (not the gate itself)
- Check console for "Switch connected to gate" message
- Ensure gate has both **Walk3DComponent** and **GateController**

### Switch snaps back immediately
- Increase **drag_sensitivity** for easier pulling
- Decrease **min_activation_angle** (e.g., -30 instead of -45)
- Check you're dragging downward (positive Y direction)

## Performance Notes

- Each switch requires one raycast check per click (very cheap)
- Drag updates only during active drag (minimal overhead)
- No physics simulation required for switch animation
- Switches are StaticBody3D (no continuous physics calculations)

## See Also

- `COMPONENT_SYSTEM.md` - Overview of component architecture
- `components/SwitchComponent.gd` - Full component code
- `components/MouseInteractionComponent.gd` - Interaction system
- `components/GateController.gd` - Gate/door control system
