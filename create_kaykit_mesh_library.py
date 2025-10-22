#!/usr/bin/env python3
"""
Create a mesh library scene from Kaykit GLTF assets.
This script generates a .tscn file with all GLTF models as child nodes,
which can then be used to create a MeshLibrary resource in Godot.
"""

import os
import glob

def create_mesh_library_scene():
    # Find all GLTF files
    gltf_files = glob.glob('assets/Kaykit/gltf/*.gltf')
    gltf_files.sort()

    print(f"Found {len(gltf_files)} GLTF files")

    # Start building the scene file
    scene_content = '[gd_scene load_steps={} format=3]\n\n'.format(len(gltf_files) + 1)

    # Add external resources
    for idx, gltf_path in enumerate(gltf_files, start=1):
        # Convert Windows path to Godot res:// path
        godot_path = gltf_path.replace('\\', '/')
        scene_content += f'[ext_resource type="PackedScene" uid="uid://generated_{idx}" path="res://{godot_path}" id="{idx}"]\n'

    scene_content += '\n'

    # Add root node
    scene_content += '[node name="KaykitMeshLibrary" type="Node3D"]\n\n'

    # Add child nodes for each GLTF, arranged in a grid
    items_per_row = 20
    spacing = 3.0

    for idx, gltf_path in enumerate(gltf_files):
        # Get the filename without extension for node name
        filename = os.path.basename(gltf_path).replace('.gltf', '')

        # Calculate grid position
        row = idx // items_per_row
        col = idx % items_per_row
        x = col * spacing
        z = row * spacing
        y = 0.0

        # Add node
        scene_content += f'[node name="{filename}" parent="." instance=ExtResource("{idx + 1}")]\n'
        scene_content += f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})\n\n'

    # Write the scene file
    output_file = 'kaykit_mesh_library.tscn'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(scene_content)

    print(f"Created {output_file}")
    print(f"Total meshes: {len(gltf_files)}")
    print(f"Grid layout: {items_per_row} columns x {(len(gltf_files) - 1) // items_per_row + 1} rows")
    print(f"Spacing: {spacing} units")
    print(f"\nNext steps:")
    print("1. Open kaykit_mesh_library.tscn in Godot")
    print("2. Select Scene > Convert To... > MeshLibrary")
    print("3. Save the MeshLibrary resource (e.g., kaykit_mesh_library.tres)")
    print("4. Use the MeshLibrary in a GridMap node")

if __name__ == '__main__':
    create_mesh_library_scene()
