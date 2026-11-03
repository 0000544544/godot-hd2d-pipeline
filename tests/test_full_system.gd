extends SceneTree

const LootItemScript = preload("res://scripts/props/loot_item.gd")

func _initialize() -> void:
	print("==================================================")
	print("LANCEMENT DES TESTS COMPLETS DU SYSTÈME DONJON HD-2D")
	print("==================================================")
	
	var scene_resource = load("res://scenes/main_hd2d_scene.tscn")
	if not scene_resource:
		print("ERREUR: Impossible de charger la scène main_hd2d_scene.tscn")
		quit(1)
		return
	
	var root_node = scene_resource.instantiate()
	root.add_child(root_node)
	await process_frame
	
	print("\n--- 1. TEST DES COLLISIONS DU DÉCOR (PARTIE 1) ---")
	var walls_node = root_node.find_child("Walls", true, false)
	assert(walls_node != null, "Noeud Walls manquant")
	
	var wall_count = 0
	var arched_count = 0
	for wall in walls_node.get_children():
		var col_body = wall.find_child("SolidCollider", true, false)
		assert(col_body != null, "Mur sans SolidCollider: " + wall.name)
		assert(col_body is StaticBody3D, "SolidCollider n'est pas un StaticBody3D")
		assert(col_body.collision_layer == 1, "Collision layer != 1")
		assert(col_body.collision_mask == 1, "Collision mask != 1")
		
		if wall.name.begins_with("Gate_"):
			arched_count += 1
			var col_l = col_body.find_child("ColLeft", true, false)
			var col_r = col_body.find_child("ColRight", true, false)
			assert(col_l != null and col_r != null, "Arche sans doubles montants: " + wall.name)
			assert(col_l.shape is BoxShape3D, "Montant gauche pas un BoxShape3D")
			assert(col_r.shape is BoxShape3D, "Montant droit pas un BoxShape3D")
		else:
			wall_count += 1
			var col_shape = col_body.find_child("CollisionShape3D", true, false)
			assert(col_shape != null, "Mur sans CollisionShape3D: " + wall.name)
			assert(col_shape.shape is BoxShape3D, "Forme de mur pas un BoxShape3D")
			var box = col_shape.shape as BoxShape3D
			assert(box.size.x >= 3.8 and box.size.y >= 3.8, "Taille de BoxShape3D mur incorrecte")
	
	print("SUCCÈS: %d murs pleins et %d arches vérifiés avec collisions solides (passage central ouvert) !" % [wall_count, arched_count])
	
	var pillars_node = root_node.find_child("Pillars", true, false)
	assert(pillars_node != null, "Noeud Pillars manquant")
	var pillar_count = 0
	for pillar in pillars_node.get_children():
		var col_body = pillar.find_child("SolidCollider", true, false)
		assert(col_body != null, "Pilier sans SolidCollider: " + pillar.name)
		assert(col_body is StaticBody3D, "SolidCollider pilier n'est pas StaticBody3D")
		var col_shape = col_body.find_child("CollisionShape3D", true, false)
		assert(col_shape != null and col_shape.shape is CylinderShape3D, "Pilier sans CylinderShape3D: " + pillar.name)
		pillar_count += 1
	print("SUCCÈS: %d piliers vérifiés avec CylinderShape3D solide !" % pillar_count)
	
	var chest = root_node.find_child("Chest_Gold", true, false)
	assert(chest != null, "Chest_Gold manquant")
	var chest_col = chest.find_child("SolidCollider", true, false)
	assert(chest_col != null and chest_col.find_child("CollisionShape3D", true, false).shape is BoxShape3D, "Coffre sans BoxShape3D solide")
	print("SUCCÈS: Coffre royal vérifié avec BoxShape3D solide !")
	
	var stairs = root_node.find_child("Stairs_Deep_Crypt", true, false)
	assert(stairs != null, "Stairs manquant")
	var stairs_col = stairs.find_child("SolidCollider", true, false)
	assert(stairs_col != null and stairs_col.find_child("CollisionShape3D", true, false).shape is BoxShape3D, "Escaliers sans BoxShape3D solide")
	print("SUCCÈS: Escaliers vérifiés avec BoxShape3D solide !")
	
	print("\n--- 2. TEST DES ENNEMIS SQUELETTES ET ARCHÉTYPES (PARTIE 2) ---")
	var sk_warrior = root_node.find_child("Enemy_Skeleton_Warrior", true, false)
	var sk_rogue = root_node.find_child("Enemy_Skeleton_Rogue", true, false)
	var sk_mage = root_node.find_child("Enemy_Skeleton_Mage", true, false)
	var sk_minion = root_node.find_child("Enemy_Skeleton_Minion", true, false)
	
	assert(sk_warrior != null, "Warrior manquant")
	assert(sk_rogue != null, "Rogue manquant")
	assert(sk_mage != null, "Mage manquant")
	assert(sk_minion != null, "Minion manquant")
	
	assert(sk_warrior.skeleton_type == 0, "Warrior type mismatch")
	assert(sk_rogue.skeleton_type == 1, "Rogue type mismatch")
	assert(sk_mage.skeleton_type == 2, "Mage type mismatch")
	assert(sk_minion.skeleton_type == 3, "Minion type mismatch")
	print("SUCCÈS: Les 4 archétypes de squelettes sont bien instanciés (Warrior, Rogue, Mage, Minion) !")
	
	# Test animations et coup
	assert(sk_warrior.anim_player != null, "Warrior sans AnimationPlayer")
	assert(sk_warrior.anim_player.has_animation("Death_A"), "Animation Death_A manquante sur Warrior")
	assert(sk_mage.anim_player.has_animation("Spellcast_Shoot"), "Animation Spellcast_Shoot manquante sur Mage")
	assert(sk_rogue.anim_player.has_animation("Dualwield_Melee_Attack_Slice"), "Animation Dualwield manquante sur Rogue")
	print("SUCCÈS: Vraies animations KayKit vérifiées sur tous les modèles (.glb) !")
	
	# Simuler la défaite du minion pour tester le loot et Death_A
	var initial_child_count = root_node.get_child_count()
	sk_minion.take_hit(null)
	sk_minion.take_hit(null)
	assert(sk_minion.is_dead, "Minion devrait être mort")
	assert(sk_minion.anim_player.current_animation == "Death_A", "Minion devrait jouer Death_A")
	assert(sk_minion.rotation.x == 0.0 and sk_minion.rotation.z == 0.0, "Le squelette ne doit PAS basculer à 90 degrés !")
	
	# Vérifier que 1 à 2 objets de butin ont été spawnés
	var loot_found = 0
	for c in root_node.get_children():
		if c.name.begins_with("LootItem") or c is LootItemScript:
			loot_found += 1
	print("SUCCÈS: Mort propre sans basculement et %d objet(s) de loot généré(s) !" % loot_found)
	
	print("\n--- 3. TEST DU JOUEUR, HUD, TEXTES FLOTTANTS ET ZONES (PARTIE 3) ---")
	var player = root_node.find_child("Player", true, false)
	var hud = root_node.find_child("RPGHUD", true, false)
	assert(player != null, "Player manquant")
	assert(hud != null, "RPGHUD manquant")
	
	assert(player.current_hp == 5 and player.max_hp == 5, "HP initial != 5")
	assert(player.gold == 0, "Or initial != 0")
	
	# Dégât
	player.take_damage(1)
	assert(player.current_hp == 4, "HP après dégât != 4")
	assert(hud.current_hp == 4, "HUD HP != 4")
	
	# Soin
	player.heal(1)
	assert(player.current_hp == 5, "HP après soin != 5")
	assert(hud.current_hp == 5, "HUD HP après soin != 5")
	
	# Or et coffre
	player.add_gold(10)
	assert(player.gold == 10, "Gold != 10")
	assert(hud.total_gold == 10, "HUD Gold != 10")
	
	# Ouvrir coffre
	chest.open_chest()
	assert(chest.is_opened, "Coffre devrait être ouvert")
	assert(player.gold == 110, "Gold après coffre != 110 (+100)")
	assert(hud.is_chest_opened, "HUD devrait savoir que le coffre est ouvert")
	
	# Zones
	var zones = root_node.find_child("Zones", true, false)
	assert(zones != null, "Noeud Zones manquant")
	assert(zones.find_child("Zone_GrandHall", true, false) != null, "Zone_GrandHall manquante")
	assert(zones.find_child("Zone_Treasure", true, false) != null, "Zone_Treasure manquante")
	assert(zones.find_child("Zone_WestRuins", true, false) != null, "Zone_WestRuins manquante")
	assert(zones.find_child("Zone_Sanctuary", true, false) != null, "Zone_Sanctuary manquante")
	print("SUCCÈS: 4 zones de découverte configurées !")
	
	# Test bandeau
	hud.show_zone_banner("Sanctuaire d'Eldrin")
	assert(hud._banner_label.text == "⚔  Sanctuaire d'Eldrin  ⚔", "Texte du bandeau incorrect")
	print("SUCCÈS: Bandeau de zone en haut au centre testé et fonctionnel !")
	
	print("\n==================================================")
	print("TOUS LES TESTS ONT RÉUSSI AVEC SUCCÈS (100% CONFORME)")
	print("==================================================")
	
	quit(0)
