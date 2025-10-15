class_name MultiMeshCollisionComponent
extends Node

## Component that generates collision bodies for each instance in a MultiMeshInstance3D.
##
## This component creates individual StaticBody3D nodes with collision shapes for each
## instance in a MultiMesh, allowing the multimesh instances to have physics collision.
##
## Usage:
## 1. Attach this component as a child of a MultiMeshInstance3D node
## 2. Configure collision_layer, collision_mask, and shape type
## 3. Collision bodies will be generated automatically on _ready()
##
## Performance Notes:
## - Generating thousands of collision bodies can be expensive
## - For purely visual instances, consider not using collisions
## - Use convex shapes for simpler/faster collision detection
## - Use trimesh (concave) shapes for complex meshes that need accurate collision

@export_group("Collision Settings")
## The collision layer these bodies will be on (bitmask)
@export_flags_3d_physics var collision_layer: int = 1
## The collision mask these bodies will detect (bitmask)
@export_flags_3d_physics var collision_mask: int = 1
## Whether to use convex shapes (simpler, faster) or trimesh shapes (accurate, slower)
@export var use_convex_shapes: bool = false

@export_group("Generation Settings")
## Whether to automatically generate collision bodies on _ready()
@export var auto_generate_on_ready: bool = true
## How many instances to process before yielding (prevents freezing with large counts)
@export var yield_every_n_instances: int = 100

## Reference to the parent MultiMeshInstance3D
var multimesh_instance: MultiMeshInstance3D

func _ready():
	# Validate parent is a MultiMeshInstance3D
	if not get_parent() is MultiMeshInstance3D:
		push_error("MultiMeshCollisionComponent must be a child of MultiMeshInstance3D!")
		return

	multimesh_instance = get_parent()

	if auto_generate_on_ready:
		generate_collision_bodies()

## Generates collision bodies for all instances in the MultiMesh
func generate_collision_bodies():
	if not multimesh_instance:
		push_error("No valid MultiMeshInstance3D parent found!")
		return

	print("[MultiMeshCollisionComponent] Generating collision bodies...")

	# Validate MultiMesh exists
	if not multimesh_instance.multimesh:
		push_error("No MultiMesh resource found on parent!")
		return

	var multimesh = multimesh_instance.multimesh

	if not multimesh.mesh:
		push_error("MultiMesh has no base mesh!")
		return

	if multimesh.instance_count <= 0:
		push_warning("MultiMesh has no instances to generate collisions for")
		return

	var base_mesh = multimesh.mesh
	var mesh_shape: Shape3D

	# Generate appropriate collision shape
	if use_convex_shapes:
		mesh_shape = base_mesh.create_convex_shape()
		if not mesh_shape:
			push_error("Failed to create convex shape from mesh")
			return
	else:
		mesh_shape = base_mesh.create_trimesh_shape()
		if not mesh_shape:
			push_error("Failed to create trimesh shape from mesh")
			return

	print("[MultiMeshCollisionComponent] Created collision shape: ", mesh_shape.get_class())

	# Clear any existing collision bodies
	clear_existing_collision_bodies()

	# Create collision bodies for each instance
	var created_count = 0
	for i in range(multimesh.instance_count):
		var instance_transform = multimesh.get_instance_transform(i)

		# Create StaticBody3D
		var body = StaticBody3D.new()
		body.name = "CollisionBody_" + str(i)
		body.transform = instance_transform

		# Set collision layers and mask
		body.collision_layer = collision_layer
		body.collision_mask = collision_mask

		# Create CollisionShape3D
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = mesh_shape

		# Add collision shape to body, body to parent (not this component)
		body.add_child(collision_shape)
		multimesh_instance.add_child(body)

		created_count += 1

		# Yield periodically for large numbers of instances
		if i % yield_every_n_instances == 0 and i > 0:
			await get_tree().process_frame

	print("[MultiMeshCollisionComponent] Generated ", created_count, " collision bodies")

## Removes all existing collision body children from the parent MultiMeshInstance3D
func clear_existing_collision_bodies():
	if not multimesh_instance:
		return

	# Remove any existing StaticBody3D children
	for child in multimesh_instance.get_children():
		if child is StaticBody3D:
			child.queue_free()

## Manually regenerate all collision bodies (useful if multimesh changes at runtime)
func regenerate_collisions():
	generate_collision_bodies()

## Remove all collision bodies without regenerating
func remove_collision_bodies():
	clear_existing_collision_bodies()
	print("[MultiMeshCollisionComponent] Removed all collision bodies")
