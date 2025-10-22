@tool
extends EditorScript

## Creates a mesh library scene from all Kaykit OBJ assets
## Run this script from Script Editor > File > Run

const OBJ_PATH = "res://assets/Kaykit/obj/"
const OUTPUT_SCENE = "res://kaykit_mesh_library.tscn"
const ITEMS_PER_ROW = 20
const SPACING = 3.0

func _run():
	print("Creating Kaykit Mesh Library...")

	# Get all OBJ files
	var obj_files = []
	var dir = DirAccess.open(OBJ_PATH)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".obj"):
				obj_files.append(file_name)
			file_name = dir.get_next()

		dir.list_dir_end()
	else:
		push_error("Could not open directory: " + OBJ_PATH)
		return

	obj_files.sort()
	print("Found %d OBJ files" % obj_files.size())

	# Create root node
	var root = Node3D.new()
	root.name = "KaykitMeshLibrary"

	# Load and add each OBJ as a MeshInstance3D
	for idx in range(obj_files.size()):
		var file_name = obj_files[idx]
		var obj_path = OBJ_PATH + file_name

		# Load the mesh
		var mesh = load(obj_path)
		if not mesh:
			push_warning("Could not load: " + obj_path)
			continue

		# Create MeshInstance3D
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.name = file_name.replace(".obj", "")

		# Calculate grid position
		var row = idx / ITEMS_PER_ROW
		var col = idx % ITEMS_PER_ROW
		var x = col * SPACING
		var z = row * SPACING
		var y = 0.0

		# Set position
		mesh_instance.position = Vector3(x, y, z)

		# Add to root
		root.add_child(mesh_instance)
		mesh_instance.owner = root

	# Save the scene
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(root)

	if result == OK:
		result = ResourceSaver.save(packed_scene, OUTPUT_SCENE)
		if result == OK:
			print("Successfully created: " + OUTPUT_SCENE)
			print("Total meshes: %d" % obj_files.size())
			print("Grid layout: %d columns x %d rows" % [ITEMS_PER_ROW, (obj_files.size() - 1) / ITEMS_PER_ROW + 1])
			print("Spacing: %.1f units" % SPACING)
			print("\nNext steps:")
			print("1. Open kaykit_mesh_library.tscn in Godot editor")
			print("2. Select Scene > Convert To... > MeshLibrary")
			print("3. Save as kaykit_mesh_library.tres")
			print("4. Use the MeshLibrary in a GridMap node")
		else:
			push_error("Failed to save scene: " + str(result))
	else:
		push_error("Failed to pack scene: " + str(result))

	# Clean up
	root.queue_free()
