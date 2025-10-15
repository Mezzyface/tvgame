# Pickup System Documentation

## Overview

The pickup system allows players to pick up and carry objects in a first-person view. It consists of two main components that follow the project's component-based architecture.

## Components

### PickupableComponent

**Purpose**: Makes any RigidBody3D object pickupable

**Type**: `class_name PickupableComponent extends Node`

**Signals**:
- `picked_up(picker: Node3D)` - Emitted when object is picked up
- `dropped(position: Vector3)` - Emitted when object is dropped

**Exports**:
- `hold_distance` (float): Distance in front of player when held (default: 2.0)
- `hold_offset_vertical` (float): Vertical offset from camera center (default: -0.5, negative = lower, positive = higher)
- `hold_smoothing` (float): How smoothly object follows hold position and rotation (default: 10.0)
- `flip_away_from_player` (bool): Flip object 180 degrees to face away from player (default: false)

**Parent Requirements**: Must be a child of RigidBody3D

**Public Methods**:
- `pickup(picker: Node3D, camera: Camera3D = null)` - Picks up the object with optional camera reference
- `drop()` - Drops the object
- `can_pickup()` - Returns whether object can currently be picked up
- `is_being_held()` - Returns whether object is currently held

**Usage**:
```gdscript
# Attach to any RigidBody3D to make it pickupable
# The component handles:
# - Physics freezing while held
# - Collision exceptions with the picker
# - Smooth position and rotation following
# - Vertical offset positioning
```

---

### PickupControllerComponent

**Purpose**: Allows a character to pick up and drop objects with PickupableComponent

**Type**: `class_name PickupControllerComponent extends Node`

**Signals**:
- `object_picked_up(pickupable: PickupableComponent)` - Emitted when picking up an object
- `object_dropped(pickupable: PickupableComponent)` - Emitted when dropping an object
- `pickup_target_detected(pickupable: PickupableComponent)` - Emitted when looking at a pickupable
- `pickup_target_lost()` - Emitted when no longer looking at a pickupable

**Exports**:
- `pickup_action` (String): Input action for picking up/dropping (default: "pickup")
- `pickup_range` (float): Maximum distance to pick up objects (default: 3.0)
- `raycast_from_camera` (bool): Use camera for raycasting (default: true)

**Parent Requirements**: Must be a child of CharacterBody3D

**Public Methods**:
- `pickup_object(pickupable: PickupableComponent)` - Manually pick up an object
- `drop_object()` - Drop currently held object
- `get_held_object()` - Returns the currently held object, or null
- `is_holding_object()` - Returns whether currently holding an object

**Usage**:
```gdscript
# Attach to player CharacterBody3D
# Will automatically detect and pick up objects when E is pressed
```

---

## How It Works

1. **Detection**: PickupControllerComponent uses raycasting from the camera to detect pickupable objects in front of the player
2. **Pickup**: When the player presses E (pickup action) while looking at a pickupable object:
   - A collision exception is added so the object won't collide with the player
   - The object's physics is frozen
   - The object is positioned in front of the camera with vertical offset applied
   - The camera reference is passed to the PickupableComponent
   - Signals are emitted for both components
3. **Holding**: While held:
   - Object smoothly follows a position in front of the camera (not just the character body)
   - Vertical offset is applied relative to the camera's up vector
   - Object rotates to match the camera's orientation using spherical interpolation
   - The object maintains the same relative position and orientation as you look around
   - It looks like you're holding the object steady in front of you as you move your view
   - No collision with the player occurs while held
   - Physics remains frozen
4. **Drop**: When the player presses E again:
   - Collision exception is removed so the object can collide with the player again
   - Physics is re-enabled
   - Object is left at current position with current rotation
   - Camera reference is cleared
   - Signals are emitted

## Setup Instructions

### Making an Object Pickupable

1. Create a RigidBody3D scene
2. Add collision shape and mesh
3. Add PickupableComponent as child
4. Configure exports if needed:
   - `hold_distance` - How far in front to hold (default: 2.0)
   - `hold_offset_vertical` - Vertical position offset (default: -0.5)
   - `hold_smoothing` - Follow/rotation speed (default: 10.0)
   - `flip_away_from_player` - Rotate object 180 degrees (default: false)

Example scene structure:
```
PickupableBox (RigidBody3D)
├── CollisionShape3D
├── MeshInstance3D
└── PickupableComponent
```

### Adding Pickup to Player

The player already has PickupControllerComponent attached!

If you need to add it to another character:
1. Open the character scene
2. Add PickupControllerComponent as child of CharacterBody3D
3. Configure `pickup_range` if needed

## Input Configuration

The `pickup` action is mapped to the **E key** (physical keycode 69).

You can change this in `project.godot` under `[input]`:
```ini
pickup={
"deadzone": 0.5,
"events": [Object(InputEventKey, ... "physical_keycode":69 ...)]
}
```

## Testing the System

1. Open `scenes/test_level.tscn` in Godot
2. Run the scene (F5 or F6)
3. Walk up to the box using WASD
4. Look at the box with mouse
5. Press **E** to pick up the box
6. The box should now be held in front of you, maintaining its orientation relative to your view
7. Look around with the mouse - the box rotates with your camera, staying in front of your view
8. Move around with WASD - the box follows you smoothly
9. Press **E** again to drop the box at its current position

## Signals for Gameplay Features

You can connect to the component signals to add features:

```gdscript
# In player script or other component:
func _ready():
    var pickup_controller = $PickupControllerComponent

    # Show UI prompt when looking at pickupable
    pickup_controller.pickup_target_detected.connect(_on_can_pickup)
    pickup_controller.pickup_target_lost.connect(_on_cannot_pickup)

    # Play sound effects
    pickup_controller.object_picked_up.connect(_on_picked_up)
    pickup_controller.object_dropped.connect(_on_dropped)

func _on_can_pickup(pickupable: PickupableComponent):
    # Show "Press E to pick up" UI
    pass

func _on_cannot_pickup():
    # Hide UI prompt
    pass

func _on_picked_up(pickupable: PickupableComponent):
    # Play pickup sound
    pass

func _on_dropped(pickupable: PickupableComponent):
    # Play drop sound
    pass
```

## Customization Options

### Adjusting Hold Distance
Change `hold_distance` on PickupableComponent to adjust how far in front of the camera the object is held:
- Smaller values (1.0-1.5): Held close to player
- Default (2.0): Comfortable arm's length
- Larger values (3.0+): Held far from player

### Adjusting Vertical Position
Change `hold_offset_vertical` on PickupableComponent to adjust the vertical position relative to the camera center:
- Negative values (e.g., -0.5, -1.0): Object is held lower, more like waist or hip level
- Zero (0.0): Object is held at camera center (eye level)
- Positive values (e.g., 0.5, 1.0): Object is held higher, above your view
- Default (-0.5): Slightly below center for a natural carrying position
- The offset uses the camera's up vector, so it stays relative to your view direction

### Adjusting Smoothing
Change `hold_smoothing` on PickupableComponent to adjust how quickly the object follows and rotates:
- Smaller values (5.0): More floaty, delayed movement and rotation
- Default (10.0): Smooth but responsive movement and rotation
- Larger values (20.0+): Snaps quickly to position and rotation
- This value affects both position lerp and rotation slerp (spherical interpolation)

### Adjusting Pickup Range
Change `pickup_range` on PickupControllerComponent to adjust detection distance:
- Smaller values (1.5-2.0): Must be very close
- Default (3.0): Standard interaction range
- Larger values (5.0+): Can pick up from far away

### Flipping Objects Away From Player
Enable `flip_away_from_player` on PickupableComponent to rotate objects 180 degrees:
- **False (default)**: Object faces same direction as camera (normal behavior)
- **True**: Object is rotated 180 degrees around the up axis to face away from player
- **Use cases**:
  - TVs/Monitors: Screen faces away so others can see it
  - Signs: Text faces outward instead of toward you
  - Mirrors: Reflective surface faces forward
  - Flashlights: Light points away from you
  - Cameras: Lens faces away from you
- The flip is applied smoothly using the `hold_smoothing` value
- The object still follows camera rotation, just rotated 180 degrees relative to the view

## Advanced Usage

### Throwing Objects
You can extend the system to throw objects by adding velocity when dropping:

```gdscript
# In a custom component or player script:
func throw_held_object():
    var pickup_controller = $PickupControllerComponent
    var held = pickup_controller.get_held_object()

    if held:
        pickup_controller.drop_object()
        # Add velocity to the RigidBody3D
        held.rigid_body.linear_velocity = -camera.global_transform.basis.z * throw_force
```

### Weight System
You could add different weights by adjusting the RigidBody3D mass:
- Light objects (0.5-2.0 kg): Easy to pick up and hold
- Medium objects (2.0-10.0 kg): Default
- Heavy objects (10.0+ kg): Could slow player movement (would need custom logic)

### Interaction Prompts
Connect to `pickup_target_detected` and `pickup_target_lost` signals to show/hide UI prompts.

## File Locations

- PickupableComponent: `C:\game-dev\halloween\components\PickupableComponent.gd`
- PickupControllerComponent: `C:\game-dev\halloween\components\PickupControllerComponent.gd`
- Example Pickupable: `C:\game-dev\halloween\scenes\pickupable_box.tscn`
- Test Level: `C:\game-dev\halloween\scenes\test_level.tscn`
- Player Scene: `C:\game-dev\halloween\scenes\player.tscn`

## Troubleshooting

### Box doesn't get picked up
- Check that PickupableComponent is a child of RigidBody3D
- Verify input action "pickup" is configured (E key)
- Ensure you're within `pickup_range` (default 3.0 units)
- Check that you're looking directly at the box

### Box is jittery when held
- Increase `hold_smoothing` value on PickupableComponent
- Check that the box's RigidBody3D mass is reasonable (1.0-10.0)

### Box collides with player when picked up
- This should be fixed automatically via collision exceptions
- If still occurring, check that the picker is a CharacterBody3D or PhysicsBody3D
- Verify that `add_collision_exception_with()` is being called in the pickup method

### Box falls through floor when dropped
- Verify collision layers are set correctly
- Check that the floor has a collision shape
- Ensure RigidBody3D has a collision shape

### Can't pick up box through other objects
- This is expected behavior - raycasting stops at first hit
- Position the box where it's directly visible

### Box doesn't rotate with camera
- Verify that the camera reference is being passed in `pickup_object()` call
- Check that `holder_camera` is not null in PickupableComponent
- Ensure the Camera3D is found correctly in PickupControllerComponent's `_ready()`

### Box rotates strangely
- The object uses the camera's full basis (orientation) for rotation
- If you want only horizontal rotation, you'd need to modify the target_rotation calculation
- Current behavior: object rotates with all camera movements (pitch + yaw)

## Future Enhancements

Possible additions to the pickup system:
- **ThrowComponent**: Add ability to throw held objects
- **WeightComponent**: Different objects affect movement speed
- **InventoryComponent**: Store picked up items in inventory instead of holding
- **StackableComponent**: Stack multiple items on top of each other
- **InteractionPromptComponent**: UI to show "Press E to pick up" hints
