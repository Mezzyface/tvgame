@tool
class_name MultiMeshCombinerComponent
extends Node

## Component that combines multiple mesh objects into optimized MultiMeshInstances.
##
## This component is useful for batch-processing many similar objects (rocks, trees, props)
## into MultiMesh instances for better rendering performance. It also merges collision shapes
## into a single StaticBody3D.
##
## Usage:
## 1. Create a Node3D and attach this component
## 2. Create a child node (e.g., "Objects") containing all objects to combine
## 3. Set the objects_parent_path to point to that child node
## 4. In the editor, the merge() function will run automatically on _ready()
## 5. For runtime use, call merge() manually or enable auto_merge_on_ready
##
## The component will:
## - Group objects by their mesh resource
## - Create one MultiMeshInstance3D per unique mesh
## - Combine all collision shapes into one StaticBody3D
## - Optionally save the MultiMesh resources to disk
## - Remove the original individual objects

@export_group("Object Selection")
## Path to the parent node containing all objects to combine
@export var objects_parent_path: NodePath = NodePath("Objects")

@export_group("Material Settings")
## Optional texture to apply to all combined multimeshes
@export var override_texture: Texture2D
## Optional material to apply to all combined multimeshes (overrides texture setting)
@export var override_material: Material

@export_group("Save Settings")
## Folder where generated MultiMesh .tres files will be saved (if save_multimeshes is true)
@export var multimesh_save_folder: String = "res://generated_multimeshes/"
## Whether to save the generated MultiMesh resources to disk
@export var save_multimeshes: bool = false

@export_group("Runtime Settings")
## Whether to automatically run merge() when _ready() is called at runtime (NOT in editor)
@export var auto_merge_on_ready: bool = false
## Whether to remove original objects after merging (disable for debugging)
@export var remove_original_objects: bool = true

@export_group("Editor Control")
## Click this button in the Inspector to manually trigger the merge (editor only)
@export var trigger_merge_button: bool = false:
	set(value):
		if Engine.is_editor_hint() and value:
			merge.call_deferred()
		trigger_merge_button = false  # Reset button

## Reference to the parent node
var parent_node: Node3D

func _ready():
	# Only auto-merge at runtime if enabled
	if not Engine.is_editor_hint() and auto_merge_on_ready:
		merge()

## Main function that combines objects into MultiMeshInstances
func merge():
	print("[MultiMeshCombinerComponent] Starting merge process...")

	# Get the parent Node3D
	if not get_parent() is Node3D:
		push_error("[MultiMeshCombinerComponent] Parent must be a Node3D!")
		return

	parent_node = get_parent()

	# --- 0) Cleanup any previous merge output ---
	cleanup_previous_merge()

	# --- 1) Gather all objects under the specified parent ---
	var objects_parent = parent_node.get_node_or_null(objects_parent_path)
	if objects_parent == null:
		push_error("[MultiMeshCombinerComponent] Invalid objects_parent_path: ", objects_parent_path)
		return

	var objects = objects_parent.get_children()
	if objects.is_empty():
		push_warning("[MultiMeshCombinerComponent] No child objects found to merge")
		return

	print("[MultiMeshCombinerComponent] Found ", objects.size(), " objects to process")

	# --- 2) Group each object's global_transform by its mesh resource ---
	var mesh_to_transforms = {}
	var mesh_to_materials = {}  # Track original materials per mesh

	for obj in objects:
		# Look for MeshInstance3D in the object or its children
		var mesh_instance = find_mesh_instance(obj)
		if mesh_instance and mesh_instance.mesh:
			var mesh = mesh_instance.mesh

			if not mesh_to_transforms.has(mesh):
				mesh_to_transforms[mesh] = []
				mesh_to_materials[mesh] = mesh_instance.material_override

			# Use the MeshInstance3D's global transform, not the parent object's
			mesh_to_transforms[mesh].append(mesh_instance.global_transform)

	if mesh_to_transforms.is_empty():
		push_error("[MultiMeshCombinerComponent] Couldn't find any MeshInstance3D children with a mesh")
		return

	print("[MultiMeshCombinerComponent] Found ", mesh_to_transforms.size(), " unique mesh types")

	# --- 3) Create a single StaticBody3D to hold all collisions ---
	var merged_collisions = await create_merged_collision_body(objects)

	# --- 4) Build & add one MultiMeshInstance3D per unique mesh ---
	var total_instances = 0
	var mesh_index = 0

	for mesh in mesh_to_transforms.keys():
		var transforms = mesh_to_transforms[mesh]
		var original_material = mesh_to_materials[mesh]

		# Create MultiMesh
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = transforms.size()

		# Set all instance transforms
		for i in range(transforms.size()):
			mm.set_instance_transform(i, transforms[i])

		# Create MultiMeshInstance3D
		var mmi = MultiMeshInstance3D.new()
		mmi.name = "MultiMesh_%d" % mesh_index
		mmi.multimesh = mm

		# Add child and set owner appropriately for editor/runtime
		if Engine.is_editor_hint():
			parent_node.add_child.call_deferred(mmi, true)
			await get_tree().process_frame
			if is_instance_valid(mmi):
				mmi.owner = get_tree().edited_scene_root
		else:
			parent_node.add_child(mmi)

		# --- Apply materials ---
		if override_material:
			mmi.material_override = override_material
		elif override_texture:
			var mat = StandardMaterial3D.new()
			mat.albedo_texture = override_texture
			mmi.material_override = mat
		elif original_material:
			mmi.material_override = original_material

		# --- Save the MultiMesh resource to disk ---
		if save_multimeshes:
			save_multimesh_to_disk(mm, mesh, mesh_index)

		total_instances += transforms.size()
		mesh_index += 1

	print("[MultiMeshCombinerComponent] Created ", mesh_index, " MultiMeshInstances with ", total_instances, " total instances")

	# --- 5) Remove original objects ---
	if remove_original_objects:
		for obj in objects:
			obj.queue_free()
		print("[MultiMeshCombinerComponent] Removed original objects")
	else:
		print("[MultiMeshCombinerComponent] Kept original objects (remove_original_objects = false)")

	print("[MultiMeshCombinerComponent] Merge complete! Save the scene to persist changes.")

## Finds a MeshInstance3D in a node or its descendants (recursive search)
func find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node

	# Search all descendants recursively (needed for FBX scene instances)
	for child in node.get_children():
		var result = find_mesh_instance(child)
		if result:
			return result

	return null

## Creates a merged collision body from all objects with collision shapes
func create_merged_collision_body(objects: Array) -> StaticBody3D:
	var collision_body = StaticBody3D.new()
	collision_body.name = "MergedCollisions"

	# Add child and set owner appropriately for editor/runtime
	if Engine.is_editor_hint():
		parent_node.add_child.call_deferred(collision_body, true)
		await get_tree().process_frame
		if is_instance_valid(collision_body):
			collision_body.owner = get_tree().edited_scene_root
	else:
		parent_node.add_child(collision_body)

	var collision_count = 0

	# Duplicate each object's CollisionShape3D into the merged body
	for obj in objects:
		if obj is StaticBody3D:
			for shape_node in obj.get_children():
				if shape_node is CollisionShape3D and shape_node.shape:
					var new_shape = CollisionShape3D.new()
					new_shape.shape = shape_node.shape.duplicate()

					# Add child and set owner appropriately for editor/runtime
					if Engine.is_editor_hint():
						collision_body.add_child.call_deferred(new_shape, true)
						await get_tree().process_frame
						if is_instance_valid(new_shape):
							new_shape.owner = get_tree().edited_scene_root
					else:
						collision_body.add_child(new_shape)

					new_shape.global_transform = shape_node.global_transform
					collision_count += 1

	if collision_count > 0:
		print("[MultiMeshCombinerComponent] Merged ", collision_count, " collision shapes")
	else:
		# Remove the collision body if no collisions were found
		collision_body.queue_free()
		collision_body = null

	return collision_body

## Saves a MultiMesh resource to disk
func save_multimesh_to_disk(mm: MultiMesh, mesh: Mesh, index: int):
	# Create directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(multimesh_save_folder):
		DirAccess.make_dir_recursive_absolute(multimesh_save_folder)

	# Generate filename
	var mesh_id = "mesh_%d" % index
	if mesh.resource_path != "":
		mesh_id = mesh.resource_path.get_file().get_basename()

	var save_path = multimesh_save_folder.path_join("multimesh_%s.tres" % mesh_id)

	# Save the resource
	var result = ResourceSaver.save(mm, save_path)
	if result != OK:
		push_error("[MultiMeshCombinerComponent] Failed to save MultiMesh to ", save_path)
	else:
		print("[MultiMeshCombinerComponent] Saved MultiMesh to ", save_path)

## Cleans up previous merge output
func cleanup_previous_merge():
	if not parent_node:
		return

	# Remove previous MergedCollisions
	if parent_node.has_node("MergedCollisions"):
		parent_node.get_node("MergedCollisions").queue_free()

	# Remove previous MultiMeshInstance3D children
	for child in parent_node.get_children():
		if child is MultiMeshInstance3D:
			child.queue_free()

## Manual merge trigger (useful for runtime)
func trigger_merge():
	merge()
