extends SceneTree

func _init() -> void:
	var packed = load("res://scenes/main_hd2d_scene.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	
	print("\n=== INSPECTION VISUELLE SCENE ===")
	
	# 1. Floor mesh AABB
	var floor_inst = scene.get_node_or_null("Courtyard/Floors/Floor_19")
	if floor_inst:
		print("Floor_19 position: ", floor_inst.global_position)
		for c in floor_inst.get_children():
			if c is MeshInstance3D and c.mesh:
				var aabb = c.mesh.get_aabb()
				print("Floor mesh AABB: ", aabb, " Top Y world: ", floor_inst.global_position.y + aabb.position.y + aabb.size.y)
	
	# 2. WaterPond
	var pond = scene.get_node_or_null("Courtyard/Props/WaterPond") as MeshInstance3D
	if pond:
		print("WaterPond position: ", pond.global_position)
		if pond.mesh:
			var aabb = pond.mesh.get_aabb()
			print("WaterPond AABB: ", aabb, " Y range: [", pond.global_position.y + aabb.position.y, " , ", pond.global_position.y + aabb.position.y + aabb.size.y, "]")
			var mat = pond.mesh.material as ShaderMaterial
			print("WaterPond material: ", mat != null)
			if mat:
				print("WaterPond shader: ", mat.shader != null)
	
	# 3. Player
	var player = scene.get_node_or_null("Player") as Node3D
	if player:
		print("Player position: ", player.global_position)
	
	# 4. Camera
	var cam = scene.get_node_or_null("HD2D_Camera") as Camera3D
	if cam:
		print("Camera position: ", cam.global_position, " target: ", cam.target_node)
		print("Camera fov: ", cam.fov, " projection: ", cam.projection)
		# Check if waterpond is in camera frustum from player view
		print("Distance Player to WaterPond: ", player.global_position.distance_to(pond.global_position) if player and pond else -1)
	
	quit(0)
