class_name CameraSnapshotComponent
extends Node

## Component that captures a snapshot from a camera view using SubViewport
## Attach this to a Node3D at the location where you want to capture the scene
## Broadcasts the captured texture via signal so TVs can receive it

signal snapshot_captured(texture: Texture2D)

@export_group("Capture Settings")
## Resolution of the captured image
@export var capture_resolution: Vector2i = Vector2i(512, 512)

## Automatically capture on ready (on level start)
@export var auto_capture: bool = true

## Delay before capturing (useful for ensuring scene is fully loaded)
@export var capture_delay: float = 0.1

@export_group("Camera Settings")
## Field of view for the camera
@export var camera_fov: float = 75.0

## Near clipping plane
@export var camera_near: float = 0.05

## Far clipping plane
@export var camera_far: float = 4000.0

var _viewport: SubViewport
var _camera: Camera3D
var _captured_texture: Texture2D = null


func _ready() -> void:
	# Create the SubViewport
	_viewport = SubViewport.new()
	_viewport.size = capture_resolution
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	add_child(_viewport)

	# Create the camera inside the viewport
	_camera = Camera3D.new()
	_camera.fov = camera_fov
	_camera.near = camera_near
	_camera.far = camera_far
	_viewport.add_child(_camera)

	# Position camera at parent's global position and rotation
	if get_parent() is Node3D:
		_camera.global_transform = get_parent().global_transform

	if auto_capture:
		await get_tree().create_timer(capture_delay).timeout
		capture_snapshot()


## Manually trigger a snapshot capture
func capture_snapshot() -> void:
	# Wait for the next frame to ensure viewport has rendered
	await RenderingServer.frame_post_draw

	# Get the texture from the viewport
	_captured_texture = _viewport.get_texture()

	# Disable continuous rendering after snapshot (save performance)
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	# Emit signal so TVs can receive it
	snapshot_captured.emit(_captured_texture)

	print("CameraSnapshotComponent: Snapshot captured at resolution ", capture_resolution)
	print("CameraSnapshotComponent: Viewport rendering disabled (static snapshot)")

	# Hide the camera and all its children (including lights)
	var parent = get_parent()
	if parent is Node3D:
		parent.visible = false
		print("CameraSnapshotComponent: Camera and light hidden")


## Get the captured texture (useful for late-joiners or manual access)
func get_captured_texture() -> Texture2D:
	return _captured_texture


## Update camera position/rotation to match parent
func update_camera_transform() -> void:
	if get_parent() is Node3D and _camera:
		_camera.global_transform = get_parent().global_transform
