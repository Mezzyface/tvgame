# MultiMesh Usage Guide - Step by Step

## Problem with @tool Mode

The MultiMeshCombinerComponent has `@tool` mode enabled, which means it runs automatically in the editor. This caused the meshes to disappear because:
1. The component ran on scene load
2. It removed the original meshes
3. It created new MultiMeshInstance3D nodes
4. But those new nodes weren't properly saved to the scene

## Solution: Two Approaches

### Approach 1: Use the Component at Runtime Only (Recommended for Testing)

**Steps:**
1. Open `test_level.tscn` in Godot
2. Don't add MultiMeshCombinerComponent to the scene
3. Instead, the saved MultiMesh resources already exist:
   - `generated_multimeshes/multimesh_floor_dirt.tres`
   - `generated_multimeshes/multimesh_fence.tres`
4. Manually add MultiMeshInstance3D nodes to the scene
5. Load the saved .tres files into them

**Manual Setup:**

```
test_level (Node3D)
├── Floor (Node3D) - DELETE all the individual floor instances
└── FloorMultiMesh (MultiMeshInstance3D) - NEW
    └── Set multimesh property to: res://generated_multimeshes/multimesh_floor_dirt.tres

test_level (Node3D)
├── Fence (Node3D) - DELETE all the individual fence instances
└── FenceMultiMesh (MultiMeshInstance3D) - NEW
    └── Set multimesh property to: res://generated_multimeshes/multimesh_fence.tres
```

### Approach 2: Use the Component Correctly in Editor

The component has been updated with a `merge_completed` flag to prevent re-running.

**Steps:**
1. Open `test_level.tscn` in Godot
2. Make sure all Floor and Fence instances are present
3. Add MultiMeshCombinerComponent as shown below
4. **IMMEDIATELY** save the scene after it merges
5. The `merge_completed` flag will prevent it from running again

**Scene Structure for Floor:**

```
StaticBody3D
├── MultiMeshCombinerComponent
│   └── Export Settings:
│       - objects_parent_path: "Floor"
│       - save_multimeshes: true
│       - merge_completed: false (will auto-set to true after merge)
├── CollisionShape3D (keep existing collision)
└── Floor (Node3D)
    ├── 1 (floor_dirt.fbx instance)
    ├── 2 (floor_dirt.fbx instance)
    └── ... (all floor instances)
```

**What Happens:**
1. When you add the component, it will merge on next scene reload
2. Original Floor instances will be removed
3. New MultiMesh_0 node will be created with all instances
4. merge_completed will be set to true
5. **You MUST save the scene immediately!**
6. Next time you open the scene, it won't re-run because merge_completed=true

**Scene Structure for Fence:**

```
StaticBody3D2
├── MultiMeshCombinerComponent
│   └── Export Settings:
│       - objects_parent_path: "Fence"
│       - save_multimeshes: true
│       - merge_completed: false
├── CollisionShape3D (keep existing collision)
└── Fence (Node3D)
    ├── 1 (fence.fbx instance)
    ├── 2 (fence.fbx instance)
    └── ... (all fence instances)
```

### Approach 3: Disable @tool Mode (Safest for Manual Control)

**Steps:**
1. Open `components/MultiMeshCombinerComponent.gd`
2. Comment out the first line: `# @tool`
3. Now the component won't run in the editor at all
4. You can trigger it manually via script or at runtime

**Usage at Runtime:**

```gdscript
# In a script somewhere (like level loader)
func _ready():
    # Get the combiner and trigger merge
    var floor_combiner = $StaticBody3D/MultiMeshCombinerComponent
    floor_combiner.merge()

    var fence_combiner = $StaticBody3D2/MultiMeshCombinerComponent
    fence_combiner.merge()
```

## Current State

The MultiMesh resources have been successfully generated and saved:
- `✅ generated_multimeshes/multimesh_floor_dirt.tres` (48 floor instances)
- `✅ generated_multimeshes/multimesh_fence.tres` (16 fence instances)

You can use these saved resources directly without needing to run the combiner component again!

## Recommended Next Steps

1. **Quick Fix (Use Saved Resources):**
   - In Godot, delete the Floor and Fence nodes from test_level.tscn
   - Create new MultiMeshInstance3D nodes
   - Drag the saved .tres files into their `multimesh` property
   - Done! Instant performance boost.

2. **Learn the System:**
   - Try Approach 1 to understand how MultiMesh works
   - Experiment with adding more props and merging them
   - Use the component for future levels with many objects

3. **Future Workflow:**
   - Design level with individual objects (easy to place)
   - When ready to optimize, add MultiMeshCombinerComponent
   - Set merge_completed = false, save_multimeshes = true
   - Let it run once
   - Save the scene immediately
   - The .tres files can be reused in other scenes!

## Troubleshooting

**Q: Meshes disappeared and aren't coming back**
A: The scene was saved after merge but before the MultiMeshInstance3D nodes were properly saved. Solution: Use `git checkout scenes/test_level.tscn` to restore, or manually readd the floor/fence instances.

**Q: Component keeps running every time I open the scene**
A: Check that `merge_completed` is set to `true` in the Inspector. If not, the component will re-run.

**Q: I want to reset and start over**
A: Set `merge_completed = false` and `remove_original_objects = false`. This will let you see what's being created without losing originals.

**Q: Can I use this at runtime for procedural generation?**
A: Yes! Disable @tool mode, create objects programmatically, then call `merge()` to batch them into MultiMesh.

## Performance Gains

**Before MultiMesh:**
- 48 floor draw calls
- 16 fence draw calls
- **64 total draw calls**

**After MultiMesh:**
- 1 floor draw call
- 1 fence draw call
- **2 total draw calls** (32x improvement!)

This becomes even more dramatic with hundreds of objects!
