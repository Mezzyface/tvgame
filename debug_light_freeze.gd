extends Node

## Debug script to verify light freeze system setup
## Attach to your level's root node temporarily for debugging

func _ready() -> void:
	print("\n=== DEBUG: Light Freeze System ===")

	# Find Death enemy
	var deaths = get_tree().get_nodes_in_group("enemy")
	print("Found ", deaths.size(), " enemies in 'enemy' group")
	for death in deaths:
		print("  Enemy: ", death.name)
		if death.has_node("LightFreezeComponent"):
			print("    ✓ Has LightFreezeComponent")
		else:
			print("    ✗ Missing LightFreezeComponent")

		if death.has_node("LightDetectionArea"):
			var area = death.get_node("LightDetectionArea")
			print("    ✓ Has LightDetectionArea")
			print("      Layer: ", area.collision_layer, " Mask: ", area.collision_mask)
		else:
			print("    ✗ Missing LightDetectionArea (will be auto-created)")

	# Find freeze lights
	var lights = get_tree().get_nodes_in_group("freeze_light")
	print("\nFound ", lights.size(), " objects in 'freeze_light' group")
	for light in lights:
		print("  Light: ", light.name, " (", light.get_parent().name, ")")
		if light is Area3D:
			print("    ✓ Is Area3D")
			print("      Layer: ", light.collision_layer, " Mask: ", light.collision_mask)
			var shape_count = light.get_child_count()
			print("      Collision shapes: ", shape_count)
		else:
			print("    ✗ Not an Area3D!")

	# Find TV
	var tvs = get_tree().get_nodes_in_group("pickup")
	print("\nFound ", tvs.size(), " pickupable objects")
	for tv in tvs:
		if "TV" in tv.name:
			print("  TV: ", tv.name)
			if tv.has_node("SpotLight3D"):
				print("    ✓ Has SpotLight3D")
				if tv.has_node("SpotLight3D/FreezeLightArea"):
					print("    ✓ Has FreezeLightArea")
				else:
					print("    ✗ Missing FreezeLightArea")

	print("=== End Debug ===\n")
