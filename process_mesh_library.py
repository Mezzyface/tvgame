#!/usr/bin/env python3
"""
Process mesh_library.tscn to:
1. Make all instances editable (local to the scene)
2. Space them out in a grid layout
"""

import re

def process_tscn(input_file, output_file):
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    output_lines = []
    node_index = 0  # Counter for positioning nodes (excluding root)
    items_per_row = 20
    spacing = 3.0  # Units between each mesh

    i = 0
    while i < len(lines):
        line = lines[i]

        # Check if this is a node with an instance
        if line.startswith('[node ') and 'instance=ExtResource(' in line:
            # Extract the node declaration
            # Make it editable by removing the closing bracket and adding editable=true
            if line.rstrip().endswith(']'):
                # Add editable=true to the node
                new_line = line.rstrip()[:-1] + ' editable=true]\n'
                output_lines.append(new_line)

                # Calculate grid position
                row = node_index // items_per_row
                col = node_index % items_per_row
                x = col * spacing
                z = row * spacing
                y = 0.0

                # Add transform on the next line
                transform_line = f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x}, {y}, {z})\n'
                output_lines.append(transform_line)

                node_index += 1
                i += 1
            else:
                # Line doesn't end with ], just copy it
                output_lines.append(line)
                i += 1
        else:
            # Not an instance node, just copy the line
            output_lines.append(line)
            i += 1

    # Write the output
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)

    print(f"Processed {node_index} nodes")
    print(f"Arranged in {items_per_row} columns with {spacing} unit spacing")
    print(f"Total grid size: {(items_per_row - 1) * spacing} x {((node_index - 1) // items_per_row) * spacing}")

if __name__ == '__main__':
    input_file = r'C:\game-dev\halloween\mesh_library.tscn'
    output_file = r'C:\game-dev\halloween\mesh_library.tscn'

    # Backup first
    import shutil
    backup_file = r'C:\game-dev\halloween\mesh_library.tscn.backup'
    shutil.copy(input_file, backup_file)
    print(f"Backup created: {backup_file}")

    process_tscn(input_file, output_file)
    print("Done!")
