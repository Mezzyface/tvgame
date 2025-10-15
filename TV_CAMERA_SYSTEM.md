# TV Camera System Documentation

## Overview

The TV Camera System allows you to capture a **one-time snapshot** from a specific viewpoint and display it on the TV screen with a static/noise effect overlay. The camera takes a single photo on startup with its own light, then immediately disappears, leaving only the frozen image on the TV screen. This creates an atmospheric surveillance camera or found-footage aesthetic perfect for horror games.

## Components

### CameraSnapshotComponent

**Purpose:** Captures a one-time snapshot from a camera positioned in the scene, then disappears.

**Usage:**
1. Place a `camera_snapshot.tscn` node in your level at the desired viewpoint
2. Rotate it to face what you want to capture
3. The component automatically captures on startup with its built-in light
4. After capturing, the camera and light automatically disappear

**Exports:**
- **capture_resolution** (Vector2i): Resolution of captured image (default: 512x512)
  - Higher = better quality but more memory
- **auto_capture** (bool): Capture automatically on ready (default: true)
- **capture_delay** (float): Delay before capture in seconds (default: 0.2)
  - Ensures scene is fully loaded before capturing
- **camera_fov** (float): Field of view (default: 75.0)
- **camera_near** (float): Near clipping plane (default: 0.05)
- **camera_far** (float): Far clipping plane (default: 4000.0)

**Methods:**
- `capture_snapshot()` - Manually trigger a new snapshot
- `get_captured_texture()` - Get the currently captured texture
- `update_camera_transform()` - Update camera to match parent's position/rotation

**Signals:**
- `snapshot_captured(texture: Texture2D)` - Emitted when snapshot is captured

**How It Works:**
1. Creates a SubViewport with a Camera3D child
2. Positions the camera at the parent Node3D's transform
3. Waits 0.2 seconds for scene to fully load
4. Captures one frame using the built-in SpotLight3D
5. Disables viewport rendering (frozen snapshot)
6. Hides the camera node and light
7. Broadcasts the frozen texture via signal to all listening TVs

**Built-in Light:**
- Includes a SpotLight3D that illuminates the capture area
- Light energy: 1.5
- Spot range: 20 meters
- Spot angle: 60°
- Automatically disappears after photo is taken

---

### TVScreenComponent

**Purpose:** Displays a captured image on the TV screen mesh with animated static effect using the original `tv_static.gdshader`.

**Usage:**
1. Attach to a TV node (already done in `pickup_tv.tscn`)
2. Component auto-finds the "screen" surface on the TV cube mesh (surface index 1)
3. Automatically connects to any CameraSnapshotComponent in the scene
4. Receives and displays the captured texture with static overlay, scan lines, and emission

**Exports:**
- **screen_mesh_path** (NodePath): Path to screen mesh (empty = auto-detect)
  - Auto-detects meshes named "screen" or "screen.001"
  - Can also detect surface index 1 on multi-surface meshes
- **screen_surface_index** (int): Surface index to apply material to (default: 1 for TV cube)
  - -1 = use material_override (entire mesh)
  - 0+ = specific surface only
- **enable_static** (bool): Enable static/noise effect (default: true)
- **static_intensity** (float 0-1): Mapped to shader's static_density (default: 0.15)
  - Controls the overall static overlay amount
- **static_speed** (float): Animation speed of static (default: 10.0)
- **static_scale** (float): Not used (kept for compatibility)
- **auto_connect_camera** (bool): Auto-find camera in scene (default: true)
- **camera_snapshot_path** (NodePath): Specific camera to use (empty = auto)

**Methods:**
- `set_texture(texture: Texture2D)` - Manually set displayed texture
- `set_static_intensity(intensity: float)` - Update static strength at runtime

**How It Works:**
1. Finds the screen surface on the TV cube mesh (surface index 1)
2. Loads the existing `tv_static.gdshader` shader
3. Creates a ShaderMaterial with the shader and sets parameters:
   - `base_texture` - The camera snapshot
   - `static_density` - Amount of static (currently ~0.08% with 0.001 mix)
   - `static_speed` - Animation speed
   - `scan_line_speed` - Vertical scan line animation
   - `scan_line_intensity` - Visibility of scan lines (0.1 = subtle)
   - `emission_color` - Cyan glow (0.7, 0.8, 1.0)
   - `emission_strength` - Brightness of glow (2.0)
4. Applies material to surface 1 only using `set_surface_override_material()`
5. Searches scene for CameraSnapshotComponent
6. Connects to the camera's signal
7. When snapshot is received, sets the `base_texture` shader parameter
8. Shader continuously animates static and scan lines over the frozen image

**Shader Features:**
- **Camera Image Base:** Displays the captured photo (90%+ visible)
- **Animated Static:** Very subtle noise overlay (~10% with 0.001 density mix)
- **Scan Lines:** Thin horizontal lines (1000 lines, 0.1 intensity)
- **Color Variation:** Slight red/blue color shifts for realism
- **Cyan Emission:** Glow effect matching the TV light color
- **Performance:** Lightweight, runs on static texture (not re-rendering)

---

## Quick Setup Guide

### Step 1: Place the Camera

In your level (e.g., `test_level.tscn`):

1. Add a `camera_snapshot.tscn` instance
2. Position it at the end of the level (or wherever you want to capture)
3. Rotate it to face the desired scene
   - **Visual Indicator:** The scene includes a cyan arrow visible only in the editor
   - The arrow points in the direction the camera is looking (-Z axis)
   - Shows a 2-meter-long arrow to help you aim the camera
   - This indicator is automatically hidden during gameplay
4. Adjust exports in Inspector if needed:
   - Increase `capture_resolution` for better quality
   - Adjust `camera_fov` to change viewing angle
   - Change `capture_delay` if scene needs more load time

**Note:** If you want to see the indicator in-game for debugging, select the `VisualIndicator` node and set `show_in_game = true`.

### Step 2: Verify TV Setup

The `pickup_tv.tscn` already has `TVScreenComponent` attached and configured. No additional setup needed!

### Step 3: Test

1. Open your level scene
2. Run the game (F5)
3. **What happens:**
   - After 0.2 seconds, the camera captures a snapshot
   - The camera's light briefly illuminates the scene during capture
   - Camera and light immediately disappear after the photo
   - TV screen displays the frozen captured image with subtle static and scan lines
4. Pick up the TV with E key and carry it around
5. The TV shows the "photograph" of what was at the end of the level

---

## Technical Details

### SubViewport Rendering (One-Time Snapshot)

The system uses Godot 4's SubViewport to render a single frame to a texture:

```gdscript
var viewport = SubViewport.new()
viewport.size = Vector2i(512, 512)
viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS  # Initially enabled

var camera = Camera3D.new()
viewport.add_child(camera)

# Wait for scene to load and render
await get_tree().create_timer(0.2).timeout
await RenderingServer.frame_post_draw

# Get texture (frozen snapshot)
var texture = viewport.get_texture()

# Disable rendering to save performance
viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

# Hide camera and light
get_parent().visible = false
```

### TV Static Shader (`tv_static.gdshader`)

The shader uses the original `tv_static.gdshader` file with camera texture support:

**Key Features:**
1. **Base Texture:** Samples the camera snapshot
2. **Animated Static Noise:** Time-based random noise (very subtle at 0.001 mix)
3. **Scan Lines:** Vertical scan lines (1000 lines for thin effect)
4. **Color Variation:** Red/blue channel shifts for realism
5. **Emission Glow:** Cyan emission matching the TV light

**Shader Parameters:**
- `base_texture` - The captured photograph
- `static_density` - Overall static amount (0.0 to 1.0, default 0.8)
- `static_speed` - Noise animation speed (default 5.0)
- `scan_line_speed` - Scan line movement speed (default 1.0)
- `scan_line_intensity` - Scan line visibility (0.1 = subtle)
- `emission_color` - RGB color for glow (cyan: 0.7, 0.8, 1.0)
- `emission_strength` - Brightness of emission (2.0)

**Mix Formula:**
```glsl
// Static overlay is very subtle (0.001 = 0.1% mix)
vec3 final_color = mix(base_color.rgb, static_color, static_density * 0.001);
```

---

## Customization Examples

### Change Static Intensity at Runtime

```gdscript
# Get the TV screen component
var tv_screen = $PickupTV/TVScreenComponent

# Make static more intense (spooky!)
tv_screen.set_static_intensity(0.4)

# Disable static completely
tv_screen.set_static_intensity(0.0)
```

### Capture Multiple Snapshots

```gdscript
# Get camera component
var camera = $CameraSnapshot/CameraSnapshotComponent

# Move camera to new position
get_parent().position = new_position
camera.update_camera_transform()

# Capture new snapshot
camera.capture_snapshot()
# This automatically updates all connected TVs
```

### Multiple Cameras and TVs

```gdscript
# Disable auto-connect on TV
tv_screen.auto_connect_camera = false

# Manually connect to specific camera
var camera = $SpecificCamera/CameraSnapshotComponent
camera.snapshot_captured.connect(tv_screen._on_snapshot_captured)
```

### Change Capture Resolution

Higher resolution = sharper image on TV screen, but uses more memory:

```
128x128  = Very pixelated, retro look
512x512  = Default, balanced quality (recommended)
1024x1024 = High quality, smooth image
2048x2048 = Very high quality, memory intensive
```

---

## Performance Notes

- **SubViewport Cost:** Minimal - renders only ONE frame
  - Starts with `UPDATE_ALWAYS` for initial render
  - Automatically switches to `UPDATE_DISABLED` after snapshot
  - No ongoing rendering cost after the first 0.2 seconds
  - Keep viewport resolution reasonable (512x512 recommended)

- **Shader Cost:** Very lightweight
  - Simple noise function, minimal texture samples
  - Runs on a static texture (not re-rendering scene)
  - Negligible performance impact

- **Memory:** Captured texture stays in VRAM
  - 512x512 RGBA = ~1MB per texture
  - Multiple cameras = multiple textures in memory
  - Camera node disappears after capture (no ongoing cost)

- **Overall:** Extremely performance-friendly
  - One-time 0.2s cost at level start
  - Then just a static texture with animated shader
  - Camera and light completely removed from scene

---

## Troubleshooting

### TV Screen is Black

1. Check that `CameraSnapshotComponent` exists in scene
2. Verify camera is positioned correctly (not inside geometry)
3. Check console for "Snapshot captured" message
4. Ensure TV's `auto_connect_camera` is enabled

### Static is Too Strong/Weak

- Adjust `static_intensity` export on `TVScreenComponent`
- Values: 0.0 (no static) to 1.0 (full static)
- Recommended: 0.1 to 0.3 for subtle effect

### Screen Mesh Not Found

- TV model must have a mesh named "screen" or "screen.001"
- Or manually set `screen_mesh_path` to your mesh node
- Check console for "Could not find screen mesh" error

### Capture Happening Too Early

- Increase `capture_delay` on `CameraSnapshotComponent`
- Scene objects may not be fully loaded/positioned yet
- Try 0.5 or 1.0 seconds for complex scenes

---

## Future Enhancements

Possible additions to the system:

- **Multi-Camera Switching:** Cycle through multiple camera views
- **Recording Mode:** Capture multiple frames for animation
- **Color Processing:** Shader variants (night vision, thermal, etc.)
- **Glitch Effects:** Additional distortion and artifacts
- **Interactive Cameras:** Player-controlled pan/tilt/zoom
- **Security Camera UI:** HUD overlay with timestamp, recording indicator

---

## Integration with Existing Systems

### With Pickup System
- TV screen displays captured image while carried
- Static effect animates continuously
- Works perfectly with `flip_away_from_player` rotation

### With Lighting System
- TV light (cyan SpotLight3D) still functions normally on the TV itself
- Flicker effect still active via `FlickerLightComponent`
- Screen emission adds subtle cyan glow to the captured image
- Camera has its own temporary light that disappears after capture
- Creates atmospheric effect: captured area was lit, but now it's dark

### With Component Architecture
- Follows single responsibility principle
- Components communicate via signals
- No tight coupling between camera and TV
- Multiple TVs can display same camera feed
- Camera self-destructs (hides) after doing its job
