class_name TVScreenComponent
extends Node

## Component that displays a captured image on a TV screen with static effect
## Attach this to a TV (RigidBody3D or Node3D) that has a screen mesh
## Automatically finds and connects to CameraSnapshotComponent in the scene

@export_group("Screen Settings")
## Path to the MeshInstance3D node that represents the TV screen
## Leave empty to auto-detect a child mesh named "screen" or "screen.001"
@export var screen_mesh_path: NodePath = ""

## Surface index to apply material to (-1 = use material_override, >=0 = specific surface)
## Use this when the screen is a surface on a multi-surface mesh (e.g., Cube with surface 1 = screen)
@export var screen_surface_index: int = -1

## Enable static/noise effect overlay
@export var enable_static: bool = true

@export_group("Static Effect")
## Intensity of the static overlay (0.0 = none, 1.0 = full)
@export var static_intensity: float = 0.15

## Speed of static animation
@export var static_speed: float = 10.0

## Scale of the static noise pattern
@export var static_scale: float = 300.0

@export_group("Camera Connection")
## Automatically find and connect to a CameraSnapshotComponent in the scene
@export var auto_connect_camera: bool = true

## Specific camera to connect to (leave empty for auto-detection)
@export var camera_snapshot_path: NodePath = ""

var _screen_mesh: MeshInstance3D
var _material: StandardMaterial3D
var _shader_material: ShaderMaterial
var _base_texture: Texture2D


func _ready() -> void:
	# Find the screen mesh
	_find_screen_mesh()

	if not _screen_mesh:
		push_error("TVScreenComponent: Could not find screen mesh!")
		return

	# Set up the material with shader for static effect
	_setup_material()

	# Connect to camera snapshot component
	if auto_connect_camera:
		_connect_to_camera()


func _find_screen_mesh() -> void:
	if not screen_mesh_path.is_empty():
		_screen_mesh = get_node_or_null(screen_mesh_path)
		return

	# Auto-detect screen mesh
	var parent = get_parent()
	if parent:
		# First try to find mesh named "screen" or "screen.001"
		_screen_mesh = _find_mesh_by_name(parent, "screen")
		if not _screen_mesh:
			_screen_mesh = _find_mesh_by_name(parent, "screen.001")

		# If not found, search for mesh with surface named "screen"
		if not _screen_mesh:
			var result = _find_mesh_with_screen_surface(parent)
			if result:
				_screen_mesh = result.mesh
				screen_surface_index = result.surface_index
				print("TVScreenComponent: Found screen at surface index ", screen_surface_index)


func _find_mesh_by_name(node: Node, mesh_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name.to_lower() == mesh_name:
		return node

	for child in node.get_children():
		var result = _find_mesh_by_name(child, mesh_name)
		if result:
			return result

	return null


## Find a mesh that has a surface named "screen"
func _find_mesh_with_screen_surface(node: Node) -> Dictionary:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		if mesh_instance.mesh:
			var mesh = mesh_instance.mesh
			# Check each surface for "screen" in the name
			for i in range(mesh.get_surface_count()):
				var material = mesh.surface_get_material(i)
				# Check if surface has a name (in ArrayMesh) or if there's a material
				# Try to get the blend shape or surface name if available
				if mesh is ArrayMesh:
					var array_mesh = mesh as ArrayMesh
					# ArrayMesh surfaces can have names via blend shapes or we check the material
					# For now, we'll check if this is surface index 1 (common for screen on cube)
					if i == 1:
						return {"mesh": mesh_instance, "surface_index": i}

	for child in node.get_children():
		var result = _find_mesh_with_screen_surface(child)
		if result:
			return result

	return {}


func _setup_material() -> void:
	if not enable_static:
		# Simple material without static
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color.BLACK
		_apply_material_to_mesh(_material)
		return

	# Load the existing TV static shader
	var shader = load("res://shaders/tv_static.gdshader")
	if not shader:
		push_error("TVScreenComponent: Could not load tv_static.gdshader!")
		return

	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader

	# Set shader parameters (using the original shader's parameter names)
	_shader_material.set_shader_parameter("static_speed", static_speed * 0.5)  # Original uses 0-10 range
	_shader_material.set_shader_parameter("static_density", static_intensity)  # Map intensity to density
	_shader_material.set_shader_parameter("emission_color", Vector3(0.7, 0.8, 1.0))  # Cyan glow
	_shader_material.set_shader_parameter("emission_strength", 2.0)
	_shader_material.set_shader_parameter("scan_line_speed", 1.0)
	_shader_material.set_shader_parameter("scan_line_intensity", 0.3)

	_apply_material_to_mesh(_shader_material)


## Apply material to mesh (either via material_override or specific surface)
func _apply_material_to_mesh(material: Material) -> void:
	if screen_surface_index >= 0:
		# Apply to specific surface
		_screen_mesh.set_surface_override_material(screen_surface_index, material)
		print("TVScreenComponent: Applied material to surface ", screen_surface_index)
	else:
		# Apply to entire mesh
		_screen_mesh.material_override = material
		print("TVScreenComponent: Applied material_override")


func _connect_to_camera() -> void:
	var camera: CameraSnapshotComponent = null

	# Try specific path first
	if not camera_snapshot_path.is_empty():
		camera = get_node_or_null(camera_snapshot_path)
	else:
		# Search the scene for a CameraSnapshotComponent
		camera = _find_camera_snapshot_in_scene()

	if camera:
		camera.snapshot_captured.connect(_on_snapshot_captured)
		print("TVScreenComponent: Connected to camera snapshot component")

		# If camera already has a texture, use it
		var existing_texture = camera.get_captured_texture()
		if existing_texture:
			_on_snapshot_captured(existing_texture)
	else:
		push_warning("TVScreenComponent: No CameraSnapshotComponent found in scene")


func _find_camera_snapshot_in_scene() -> CameraSnapshotComponent:
	var root = get_tree().root
	return _search_for_camera_snapshot(root)


func _search_for_camera_snapshot(node: Node) -> CameraSnapshotComponent:
	if node is CameraSnapshotComponent:
		return node

	for child in node.get_children():
		var result = _search_for_camera_snapshot(child)
		if result:
			return result

	return null


func _on_snapshot_captured(texture: Texture2D) -> void:
	_base_texture = texture

	if enable_static and _shader_material:
		_shader_material.set_shader_parameter("base_texture", texture)
	elif _material:
		_material.albedo_texture = texture

	print("TVScreenComponent: Received snapshot texture")


## Manually set the displayed texture
func set_texture(texture: Texture2D) -> void:
	_on_snapshot_captured(texture)


## Update static effect parameters at runtime
func set_static_intensity(intensity: float) -> void:
	static_intensity = intensity
	if _shader_material:
		_shader_material.set_shader_parameter("static_intensity", intensity)
