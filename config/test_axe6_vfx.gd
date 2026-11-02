extends SceneTree

func _init() -> void:
	print("--- TEST AXE 6 : EFFETS VISUELS & PARTICULES ENVIRONNEMENTALES ---")
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

	# 3. Vérification des 5 torches (Flicker, Sparks, Smoke)
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
		
		var sparks = torch.find_child("TorchSparks", true, false)
		assert(sparks != null and sparks is CPUParticles3D, "TorchSparks manquant sur " + t_name)
		
		var smoke = torch.find_child("TorchSmoke", true, false)
		assert(smoke != null and smoke is CPUParticles3D, "TorchSmoke manquant sur " + t_name)
		
		var flame = torch.find_child("FlameCore", true, false)
		assert(flame != null, "FlameCore manquant sur " + t_name)
		print("✔ 3. Torche validée: ", t_name, " (Flicker, Sparks, Smoke, FlameCore OK)")

	# 4. Vérification du WaterPond & Shader stylisé
	var pond = scene.get_node_or_null("Courtyard/Props/WaterPond") as MeshInstance3D
	assert(pond != null, "WaterPond manquant dans Courtyard/Props")
	assert(pond.mesh != null, "Mesh du WaterPond manquant")
	var mat = pond.mesh.material as ShaderMaterial
	assert(mat != null, "ShaderMaterial manquant sur WaterPond")
	assert(mat.shader != null, "Shader GDShader manquant sur WaterPond")
	print("✔ 4. WaterPond & Shader d'eau validés : shader=", mat.shader.resource_path)

	# 5. Vérification des particules atmosphériques (AtmosphericParticles)
	var dust = scene.get_node_or_null("Courtyard/AtmosphericParticles") as CPUParticles3D
	assert(dust != null, "AtmosphericParticles manquant dans Courtyard")
	assert(dust.amount >= 30, "Quantité de particules atmosphériques insuffisante")
	assert(dust.mesh != null, "Mesh des particules atmosphériques manquant")
	print("✔ 5. Particules atmosphériques (poussière/motes) validées : amount=", dust.amount)

	print("=== TOUTES LES VALIDATIONS AXE 6 SONT 100% SUCCÈS ===")
	quit(0)
