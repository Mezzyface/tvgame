# MultiMesh System

The MultiMesh system provides high-performance rendering for many similar objects by batching them into single draw calls. This is essential for rendering hundreds or thousands of objects like rocks, trees, grass, debris, or environmental props.

## Overview

The system consists of two main components:

1. **MultiMeshCollisionComponent** - Generates collision bodies for MultiMesh instances
2. **MultiMeshCombinerComponent** - Combines multiple objects into optimized MultiMesh instances

## Performance Benefits

**Without MultiMesh:**
- 10,000 objects = 10,000 draw calls
- Severe performance impact
- Low FPS with many objects

**With MultiMesh:**
- 10,000 objects = 1 draw call (per unique mesh)
- Massive performance improvement
- Smooth FPS even with 100,000+ objects

## MultiMeshCollisionComponent

### Purpose
Automatically generates collision bodies for each instance in a MultiMeshInstance3D, allowing multimesh objects to have physics collision.

### Setup

```gdscript
# Scene structure:
MultiMeshInstance3D (e.g., "Rocks")
├── MultiMeshCollisionComponent
```

1. Create or select a MultiMeshInstance3D node
2. Add MultiMeshCollisionComponent as a child
3. Configure the component exports:
   - `collision_layer` - Which physics layers these bodies are on (bitmask)
   - `collision_mask` - Which layers these bodies detect (bitmask)
   - `use_convex_shapes` - false = trimesh (accurate), true = convex (faster)
   - `auto_generate_on_ready` - Auto-generate on scene load
   - `yield_every_n_instances` - Process N instances before yielding (prevents freezing)

### Usage Example

```gdscript
# Automatically generates on _ready() if auto_generate_on_ready = true
# Or call manually:
$MultiMeshInstance3D/MultiMeshCollisionComponent.generate_collision_bodies()

# Regenerate collisions (if multimesh changes at runtime):
$MultiMeshInstance3D/MultiMeshCollisionComponent.regenerate_collisions()

# Remove all collision bodies:
$MultiMeshInstance3D/MultiMeshCollisionComponent.remove_collision_bodies()
```

### Collision Shape Types

**Trimesh (Concave) - `use_convex_shapes = false`**
- Accurate collision for complex meshes
- Slower performance
- Use for: Complex rocks, buildings, detailed props

**Convex - `use_convex_shapes = true`**
- Simplified collision hull
- Faster performance
- Use for: Simple objects, rounded rocks, boxes

### Performance Considerations

- Generating thousands of collision bodies can be expensive (one-time cost)
- Each instance gets its own StaticBody3D with collision shape
- For purely visual props (non-interactive), don't use collision
- Use convex shapes when possible for better physics performance

## MultiMeshCombinerComponent

### Purpose
Combines many individual objects into optimized MultiMesh instances. Groups objects by mesh type and merges collision shapes.

### Setup

```gdscript
# Scene structure:
Node3D (e.g., "Level")
├── MultiMeshCombinerComponent
├── Objects (child node containing all objects to merge)
    ├── Rock1 (StaticBody3D with MeshInstance3D and CollisionShape3D)
    ├── Rock2
    ├── Rock3
    └── ...
```

1. Create a Node3D (this will be the parent)
2. Add MultiMeshCombinerComponent as a child
3. Create a child node to hold all objects (e.g., "Objects", "Rocks", "Trees")
4. Add all your individual objects as children of that node
5. Configure the component exports:
   - `objects_parent_path` - Path to the node containing objects (e.g., "Objects")
   - `override_texture` - Optional texture to apply to all multimeshes
   - `override_material` - Optional material to apply to all multimeshes
   - `multimesh_save_folder` - Where to save .tres files (if enabled)
   - `save_multimeshes` - Whether to save MultiMesh resources to disk
   - `auto_merge_on_ready` - Auto-merge on scene load
   - `remove_original_objects` - Remove originals after merging

### What It Does

1. **Groups by Mesh** - Objects with the same mesh are batched together
2. **Creates MultiMeshInstances** - One per unique mesh type
3. **Merges Collisions** - All CollisionShape3Ds combined into one StaticBody3D
4. **Applies Materials** - Uses override material/texture or original materials
5. **Saves Resources** - Optionally saves MultiMesh .tres files
6. **Cleans Up** - Removes original objects (optional)

### Usage Example

#### In the Editor (@tool mode)

The component runs automatically when the scene loads in the editor:

```gdscript
# Just attach the component and set objects_parent_path
# It will auto-merge when you open the scene
```

#### At Runtime

```gdscript
# Auto-merge on _ready() if auto_merge_on_ready = true
# Or call manually:
$Level/MultiMeshCombinerComponent.merge()

# Trigger merge manually at any time:
$Level/MultiMeshCombinerComponent.trigger_merge()
```

#### Example Scene Setup

```
Level (Node3D)
├── MultiMeshCombinerComponent
│   └── objects_parent_path = "Rocks"
│   └── save_multimeshes = true
│   └── override_texture = preload("res://textures/rock.png")
└── Rocks (Node3D)
    ├── Rock1 (StaticBody3D)
    │   ├── MeshInstance3D (mesh = rock_mesh_a)
    │   └── CollisionShape3D
    ├── Rock2 (StaticBody3D)
    │   ├── MeshInstance3D (mesh = rock_mesh_a)
    │   └── CollisionShape3D
    ├── Rock3 (StaticBody3D)
    │   ├── MeshInstance3D (mesh = rock_mesh_b)
    │   └── CollisionShape3D
    └── Rock4 (StaticBody3D)
        ├── MeshInstance3D (mesh = rock_mesh_b)
        └── CollisionShape3D
```

**After merge:**

```
Level (Node3D)
├── MultiMeshCombinerComponent
├── MultiMesh_0 (MultiMeshInstance3D)  # rock_mesh_a (2 instances)
├── MultiMesh_1 (MultiMeshInstance3D)  # rock_mesh_b (2 instances)
└── MergedCollisions (StaticBody3D)
    ├── CollisionShape3D (from Rock1)
    ├── CollisionShape3D (from Rock2)
    ├── CollisionShape3D (from Rock3)
    └── CollisionShape3D (from Rock4)
```

### Material Handling

The component prioritizes materials in this order:

1. **override_material** (if set) - Applied to all MultiMeshInstances
2. **override_texture** (if set) - Creates StandardMaterial3D with this texture
3. **Original material** - Uses the material from the source MeshInstance3D

### Saving MultiMesh Resources

When `save_multimeshes = true`:

```gdscript
# Resources are saved to multimesh_save_folder
# res://generated_multimeshes/multimesh_rock_mesh_a.tres
# res://generated_multimeshes/multimesh_rock_mesh_b.tres

# You can then load these in other scenes:
var mm = preload("res://generated_multimeshes/multimesh_rocks.tres")
var mmi = MultiMeshInstance3D.new()
mmi.multimesh = mm
add_child(mmi)
```

## Common Use Cases

### 1. Rock Field (Many Similar Objects)

**Goal:** Scatter 500 rocks across a field with collision

```gdscript
# Setup:
# - Create 500 rock StaticBody3D nodes with random positions/rotations
# - Add MultiMeshCombinerComponent
# - Point it at the rocks parent
# - Enable save_multimeshes
# - Run merge()

# Result:
# - All rocks become 1-3 MultiMeshInstances (depending on mesh variety)
# - All collisions merged into one StaticBody3D
# - Saved .tres file can be reused in other levels
```

### 2. Grass/Foliage (Visual Only, No Collision)

**Goal:** Render 10,000 grass blades without collision

```gdscript
# Setup:
# - Create MultiMeshInstance3D manually or via script
# - Set instance_count = 10000
# - Set instance transforms programmatically
# - NO MultiMeshCollisionComponent needed (visual only)

# Code:
var mm = MultiMesh.new()
mm.transform_format = MultiMesh.TRANSFORM_3D
mm.mesh = grass_mesh
mm.instance_count = 10000

for i in range(10000):
    var t = Transform3D()
    t.origin = Vector3(randf() * 100, 0, randf() * 100)
    mm.set_instance_transform(i, t)

var mmi = MultiMeshInstance3D.new()
mmi.multimesh = mm
add_child(mmi)
```

### 3. Debris Spawning (Runtime MultiMesh)

**Goal:** Spawn 1000 pieces of debris when something explodes

```gdscript
func spawn_debris(position: Vector3, count: int):
    var mm = MultiMesh.new()
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.mesh = debris_mesh
    mm.instance_count = count

    for i in range(count):
        var t = Transform3D()
        t.origin = position + Vector3.ONE * randf_range(-5, 5)
        t.basis = Basis(Vector3.UP, randf() * TAU)
        mm.set_instance_transform(i, t)

    var mmi = MultiMeshInstance3D.new()
    mmi.multimesh = mm
    add_child(mmi)

    # Add collision if needed:
    var collision_component = MultiMeshCollisionComponent.new()
    collision_component.use_convex_shapes = true
    mmi.add_child(collision_component)
    collision_component.generate_collision_bodies()
```

### 4. Converting Existing Level to MultiMesh

**Goal:** You have 200 hand-placed rocks and want to optimize them

```gdscript
# Before optimization:
Level
└── Rocks
    ├── Rock1 (placed by hand)
    ├── Rock2
    └── ... (200 total)

# Add MultiMeshCombinerComponent to Level:
# - objects_parent_path = "Rocks"
# - save_multimeshes = true
# - auto_merge_on_ready = true

# Open the scene in editor -> automatic merge!

# After optimization:
Level
├── MultiMeshCombinerComponent
├── MultiMesh_0 (all 200 rocks in 1-3 instances)
└── MergedCollisions (all collision shapes)
```

## Best Practices

### When to Use MultiMesh

✅ **Use MultiMesh for:**
- Many similar objects (rocks, trees, grass, debris)
- Static or infrequently updated objects
- Background props and decorations
- Environmental details (flowers, mushrooms, stones)
- Particle-like effects (snow, leaves, sparks)

❌ **Don't Use MultiMesh for:**
- Unique objects (player, NPCs, important items)
- Objects that need individual scripts/behavior
- Objects with frequently changing transforms
- Objects with different materials per instance (without per-instance color)

### Performance Tips

1. **Minimize Unique Meshes** - More unique meshes = more MultiMeshInstances = more draw calls
2. **Use Instance Color** - Vary appearance without multiple materials:
   ```gdscript
   multimesh.set_instance_color(i, Color.RED)
   ```
3. **Batch by Material** - Objects with same mesh AND material batch best
4. **LOD MultiMeshes** - Create separate MultiMeshes for near/far instances
5. **Culling** - MultiMesh supports frustum culling automatically

### Workflow Recommendations

**Level Design Workflow:**
1. Design level with individual objects (easy to edit)
2. Add MultiMeshCombinerComponent when ready to optimize
3. Save the generated MultiMesh .tres files
4. Use saved resources in final level (no need to keep originals)

**Runtime Spawning:**
1. Create MultiMesh programmatically
2. Set all instance transforms
3. Add MultiMeshCollisionComponent only if collision needed
4. Destroy when no longer needed

## Troubleshooting

### "No MultiMesh resource found!"
- Make sure MultiMeshCollisionComponent is a child of MultiMeshInstance3D
- Check that the MultiMeshInstance3D has a MultiMesh resource assigned

### "Couldn't find any MeshInstance3D children"
- Ensure objects have MeshInstance3D nodes (not just Node3D)
- Check that objects_parent_path points to the correct node

### Collision Not Working
- Verify collision_layer and collision_mask are set correctly
- Check that original objects had CollisionShape3D nodes
- Try switching between convex/trimesh shapes

### Poor Performance After Merge
- Too many unique meshes (each creates a draw call)
- Try consolidating meshes in your 3D modeling software
- Consider removing collision for purely visual objects

### Editor Freeze
- Reduce yield_every_n_instances to yield more frequently
- Disable auto_merge_on_ready for very large merges
- Process in batches instead of all at once

## Component Architecture Notes

Both components follow the project's component-based architecture:

- Extend `Node` (not the parent type)
- Use `class_name` for easy access
- Provide `@export` variables for configuration
- Work standalone without dependencies on other components
- Provide manual trigger functions for runtime control

## Integration with Halloween Game

MultiMesh is perfect for this Halloween game for:

- **Candles/Lights** - Place 100 flickering candles around the level
- **Debris** - Scattered papers, bones, broken objects
- **Foliage** - Dead grass, weeds, cobwebs
- **Props** - Bottles, crates, rocks, gravestones
- **Particles** - Dust motes, fireflies, floating embers

Example: Combine with FlickerLightComponent for atmospheric candle fields!

## Additional Resources

- [Godot MultiMesh Documentation](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- [Godot MultiMeshInstance3D Documentation](https://docs.godotengine.org/en/stable/classes/class_multimeshinstance3d.html)
- Original implementation: https://github.com/CodingQuests/Multimesh
