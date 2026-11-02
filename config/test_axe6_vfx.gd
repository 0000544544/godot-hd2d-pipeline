extends SceneTree

func _init() -> void:
	print("--- TEST AXE 6 : EFFETS VISUELS & PARTICULES ENVIRONNEMENTALES (REFINED) ---")
	var packed_scene = load("res://scenes/main_hd2d_scene.tscn")
	if not packed_scene:
		printerr("ERREUR: Impossible de charger main_hd2d_scene.tscn")
		quit(1)
		return
	
	var scene = packed_scene.instantiate()
	root.add_child(scene)
	
	# 1. Vérification WorldEnvironment & Volumetric Fog
	var env_node = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	assert(env_node != null, "WorldEnvironment introuvable")
	assert(env_node.environment != null, "Environment ressource introuvable")
	assert(env_node.environment.volumetric_fog_enabled == true, "Volumetric fog doit être activé")
	assert(env_node.environment.volumetric_fog_density > 0.01, "Densité volumetric fog invalide")
	assert(env_node.environment.volumetric_fog_anisotropy > 0.2, "Anisotropie volumetric fog invalide")
	print("✔ 1. WorldEnvironment & Volumetric Fog validés : density=", env_node.environment.volumetric_fog_density, " anisotropy=", env_node.environment.volumetric_fog_anisotropy)

	# 2. Vérification SunDirectionalLight
	var sun = scene.get_node_or_null("SunDirectionalLight") as DirectionalLight3D
	assert(sun != null, "SunDirectionalLight introuvable")
	assert(sun.light_volumetric_fog_energy >= 2.0, "Sun volumetric_fog_energy doit être >= 2.0")
	print("✔ 2. SunDirectionalLight validé : volumetric_fog_energy=", sun.light_volumetric_fog_energy, " energy=", sun.light_energy)

	# 3. Vérification des 5 torches (Flicker, Sparks, Smoke, Cast Shadow Off)
	var torch_names = ["Torch_NW", "Torch_NE", "Torch_SW", "Torch_SE", "Torch_Eldrin"]
	for t_name in torch_names:
		var torch = scene.get_node_or_null("Courtyard/TorchesAndLighting/" + t_name)
		assert(torch != null, "Torche manquante: " + t_name)
		
		var light = null
		for c in torch.get_children():
			if c is OmniLight3D:
				light = c
				break
		assert(light != null, "Lumière manquante sur " + t_name)
		assert(light.get_script() != null, "Script TorchFlicker manquant sur " + t_name)
		assert(light.light_volumetric_fog_energy >= 1.5, "light_volumetric_fog_energy insuffisant sur " + t_name)
		
		var sparks = torch.find_child("TorchSparks", true, false) as CPUParticles3D
		assert(sparks != null, "TorchSparks manquant sur " + t_name)
		assert(sparks.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "TorchSparks cast_shadow doit être OFF")
		
		var smoke = torch.find_child("TorchSmoke", true, false) as CPUParticles3D
		assert(smoke != null, "TorchSmoke manquant sur " + t_name)
		assert(smoke.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "TorchSmoke cast_shadow doit être OFF")
		
		var flame = torch.find_child("FlameCore", true, false)
		assert(flame != null, "FlameCore manquant sur " + t_name)
		print("✔ 3. Torche validée: ", t_name, " (Flicker, Sparks, Smoke, Cast Shadow OFF OK)")

	# 4. Vérification WaterPond & Shader d'eau fluide DEPTH_TEXTURE
	var pond = scene.get_node_or_null("Courtyard/Props/WaterPond") as MeshInstance3D
	assert(pond != null, "WaterPond manquant dans Courtyard/Props")
	assert(pond.mesh != null and pond.mesh is PlaneMesh, "Mesh du WaterPond doit être un PlaneMesh")
	assert(pond.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "WaterPond cast_shadow doit être OFF")
	var mat = pond.mesh.material as ShaderMaterial
	assert(mat != null, "ShaderMaterial manquant sur WaterPond")
	assert(mat.shader != null, "Shader GDShader manquant sur WaterPond")
	assert(mat.get_shader_parameter("foam_amount") != null, "Uniform foam_amount manquant dans le shader")
	print("✔ 4. WaterPond & Shader d'eau fluide validés : foam_amount=", mat.get_shader_parameter("foam_amount"), " (Plan simple encastré, bords automatiques via DEPTH_TEXTURE)")

	# 5. Vérification des particules atmosphériques (AtmosphericParticles)
	var dust = scene.get_node_or_null("Courtyard/AtmosphericParticles") as CPUParticles3D
	assert(dust != null, "AtmosphericParticles manquant dans Courtyard")
	assert(dust.amount >= 30, "Quantité de particules atmosphériques insuffisante")
	assert(dust.mesh != null, "Mesh des particules atmosphériques manquant")
	assert(dust.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "AtmosphericParticles cast_shadow doit être OFF")
	print("✔ 5. Particules atmosphériques (poussière/motes) validées : amount=", dust.amount, " cast_shadow=OFF")

	print("=== TOUTES LES VALIDATIONS AXE 6 (CORRECTIFS PARTICULES & BASSINE) SONT 100% SUCCÈS ===")
	quit(0)
