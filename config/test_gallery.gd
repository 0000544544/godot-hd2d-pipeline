extends SceneTree

func _init() -> void:
	print("==================================================")
	print("TEST UNITAIRE & FONCTIONNEL : GALLERY LEVEL HD-2D")
	print("==================================================")

	var scene_res = ResourceLoader.load("res://scenes/test_gallery.tscn")
	if not scene_res:
		printerr("[FAIL] Impossible de charger res://scenes/test_gallery.tscn")
		quit(1)
		return
	
	var scene = scene_res.instantiate()
	if not scene:
		printerr("[FAIL] Échec de l'instanciation de la scène")
		quit(1)
		return
	
	root.add_child(scene)
	print("[PASS] Scène instanciée et ajoutée au SceneTree avec succès.")

	# 1. Vérification Pièce 1 : Approche Hybride
	var demo_hybrid = scene.get_node_or_null("Room1_Hybrid/Demo_Hybrid") as CharacterBody3D
	if not demo_hybrid:
		printerr("[FAIL] Demo_Hybrid introuvable dans Room1_Hybrid")
		quit(1)
		return
	if not demo_hybrid.get_script() or "npc_patrol.gd" not in demo_hybrid.get_script().resource_path:
		printerr("[FAIL] Demo_Hybrid n'utilise pas le script npc_patrol.gd")
		quit(1)
		return
	if demo_hybrid.distance_patrouille != 4.0 or demo_hybrid.vitesse != 2.0:
		printerr("[FAIL] Paramètres de patrouille incorrects sur Demo_Hybrid")
		quit(1)
		return
	var vp = demo_hybrid.get_node_or_null("SubViewport")
	var spr_hybrid = demo_hybrid.get_node_or_null("Sprite3D") as Sprite3D
	if not vp or not spr_hybrid:
		printerr("[FAIL] SubViewport ou Sprite3D manquant dans Demo_Hybrid")
		quit(1)
		return
	if spr_hybrid.billboard != BaseMaterial3D.BILLBOARD_FIXED_Y:
		printerr("[FAIL] Sprite3D de Demo_Hybrid n'est pas en Billboard Y")
		quit(1)
		return
	if spr_hybrid.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
		printerr("[FAIL] Sprite3D de Demo_Hybrid n'est pas en filtrage Nearest")
		quit(1)
		return
	print("[PASS] Pièce 1 (Hybride 3D-2D) : Demo_Hybrid avec SubViewport et Sprite3D Y-Billboard Nearest validé.")

	# 2. Vérification Pièce 2 : Pixel-Art pur
	var demo_pixel = scene.get_node_or_null("Room2_PixelArt/Demo_PixelArt") as CharacterBody3D
	if not demo_pixel:
		printerr("[FAIL] Demo_PixelArt introuvable dans Room2_PixelArt")
		quit(1)
		return
	if not demo_pixel.get_script() or "npc_patrol.gd" not in demo_pixel.get_script().resource_path:
		printerr("[FAIL] Demo_PixelArt n'utilise pas le script npc_patrol.gd")
		quit(1)
		return
	if demo_pixel.distance_patrouille != 4.0 or demo_pixel.vitesse != 2.0:
		printerr("[FAIL] Paramètres de patrouille incorrects sur Demo_PixelArt")
		quit(1)
		return
	var spr_anim = demo_pixel.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if not spr_anim or not spr_anim.sprite_frames:
		printerr("[FAIL] AnimatedSprite3D ou SpriteFrames manquant dans Demo_PixelArt")
		quit(1)
		return
	if spr_anim.billboard != BaseMaterial3D.BILLBOARD_FIXED_Y:
		printerr("[FAIL] AnimatedSprite3D de Demo_PixelArt n'est pas en Billboard Y")
		quit(1)
		return
	if spr_anim.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
		printerr("[FAIL] AnimatedSprite3D de Demo_PixelArt n'est pas en filtrage Nearest")
		quit(1)
		return
	print("[PASS] Pièce 2 (Vrai Pixel-Art) : Demo_PixelArt avec AnimatedSprite3D et frames de marche validé.")

	# 3. Vérification Pièce 3 : Rendu 3D direct
	var demo_3d = scene.get_node_or_null("Room3_Direct3D/Demo_Direct3D") as CharacterBody3D
	if not demo_3d:
		printerr("[FAIL] Demo_Direct3D introuvable dans Room3_Direct3D")
		quit(1)
		return
	if not demo_3d.get_script() or "npc_patrol.gd" not in demo_3d.get_script().resource_path:
		printerr("[FAIL] Demo_Direct3D n'utilise pas le script npc_patrol.gd")
		quit(1)
		return
	if demo_3d.distance_patrouille != 4.0 or demo_3d.vitesse != 2.0:
		printerr("[FAIL] Paramètres de patrouille incorrects sur Demo_Direct3D")
		quit(1)
		return
	var model_root = demo_3d.get_node_or_null("ModelRoot")
	if not model_root or model_root.get_child_count() == 0:
		printerr("[FAIL] ModelRoot ou maillage 3D manquant dans Demo_Direct3D")
		quit(1)
		return
	print("[PASS] Pièce 3 (3D Direct Low-Poly) : Demo_Direct3D avec ModelRoot et maillage 3D natif validé.")

	# 4. Vérification Joueur & Caméra HD-2D
	var player = scene.get_node_or_null("Player") as CharacterBody3D
	var cam = scene.get_node_or_null("HD2DCamera") as Camera3D
	if not player or not cam:
		printerr("[FAIL] Joueur ou caméra HD2DCamera manquant dans la galerie")
		quit(1)
		return
	if cam.target != player:
		printerr("[FAIL] HD2DCamera ne cible pas le joueur")
		quit(1)
		return
	print("[PASS] Joueur interactif et Caméra HD-2D connectés.")

	# 5. Vérification Labels 3D
	var lbl1 = scene.get_node_or_null("Labels/Label_Room1") as Label3D
	var lbl2 = scene.get_node_or_null("Labels/Label_Room2") as Label3D
	var lbl3 = scene.get_node_or_null("Labels/Label_Room3") as Label3D
	if not lbl1 or not lbl2 or not lbl3:
		printerr("[FAIL] Labels 3D des pièces manquants")
		quit(1)
		return
	print("[PASS] Panneaux indicateurs 3D (Label3D) validés dans les 3 pièces.")

	# 6. Vérification Éclairage, Torches & Particules sans ombres (Axe 6)
	var dust = scene.get_node_or_null("AtmosphericParticles") as CPUParticles3D
	if not dust or dust.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		printerr("[FAIL] AtmosphericParticles manquant ou cast_shadow != OFF")
		quit(1)
		return
	for t_name in ["Torch_R1", "Torch_R2", "Torch_R3"]:
		var torch = scene.get_node_or_null("Torches/" + t_name)
		if not torch:
			printerr("[FAIL] Torche manquante: " + t_name)
			quit(1)
			return
		var sparks = torch.find_child("TorchSparks", true, false) as CPUParticles3D
		var smoke = torch.find_child("TorchSmoke", true, false) as CPUParticles3D
		if not sparks or sparks.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			printerr("[FAIL] TorchSparks cast_shadow != OFF sur " + t_name)
			quit(1)
			return
		if not smoke or smoke.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			printerr("[FAIL] TorchSmoke cast_shadow != OFF sur " + t_name)
			quit(1)
			return
	print("[PASS] Torches et particules conformes Axe 6 (Flicker, Sparks, Smoke, Cast Shadow OFF).")

	# 7. Vérification des passages communicants (Arches)
	var arch1 = scene.get_node_or_null("Architecture/Arch_R1_R2")
	var arch2 = scene.get_node_or_null("Architecture/Arch_R2_R3")
	if not arch1 or not arch2:
		printerr("[FAIL] Passages en arche entre les pièces manquants")
		quit(1)
		return
	print("[PASS] Portes et passages communicants entre les pièces validés.")

	print("==================================================")
	print("TOUS LES TESTS DU GALLERY LEVEL SONT VALIDÉS (100%)")
	print("==================================================")
	quit(0)
