class_name MainHD2DScene
extends Node3D

## Contrôleur de Scène Principale HD-2D
## - Garantit la génération et vérification intégrale des collisions de décor (Murs, Arches, Piliers, Coffre, Escaliers)
## - Connecte le HUD RPG, les statistiques du joueur, le butin et les objectifs de quête
## - Gère les zones de découverte et l'affichage des bandeaux de zone

const RPGHUDScript = preload("res://scripts/ui/rpg_hud.gd")

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $RPGHUD
@onready var chest: Node3D = $Courtyard/Props/Chest_Gold

func _ready() -> void:
	_setup_decor_collisions()
	_connect_hud_and_systems()
	_setup_zone_triggers()
	
	# Affichage initial du lieu au lancement
	if hud:
		hud.show_zone_banner("Grande Nef d'Armes")

## =============================================================================
## PARTIE 1 : GARANTIE ABSOLUE DES COLLISIONS DE DÉCOR
## =============================================================================

func _setup_decor_collisions() -> void:
	var courtyard = find_child("Courtyard", true, false)
	if not courtyard:
		return
	
	# Parcourir les conteneurs de décor principaux (Walls, Pillars, Props)
	for container_name in ["Walls", "Pillars", "Props"]:
		var container = courtyard.find_child(container_name, true, false)
		if not container:
			continue
		for item in container.get_children():
			_ensure_item_collider(item)

func _ensure_item_collider(item: Node) -> void:
	if not (item is Node3D):
		return
	
	# Si l'élément possède déjà un StaticBody3D solide, ne rien ajouter
	for sub in item.get_children():
		if sub is StaticBody3D:
			return
	
	var item_name = item.name.to_lower()
	var scene_path = ""
	if item.scene_file_path:
		scene_path = item.scene_file_path.get_file().to_lower()
	
	# 1. Arches (2 montants latéraux pour passage central libre)
	if item_name.begins_with("gate_") or scene_path == "wall_arched.glb":
		_add_arch_collider(item)
	# 2. Murs normaux ou brisés
	elif item_name.begins_with("wall_") or scene_path in ["wall.glb", "wall_broken.glb", "wall_corner.glb"]:
		_add_wall_collider(item)
	# 3. Piliers et Colonnes
	elif item_name.begins_with("pillar_") or item_name.begins_with("column_") or scene_path in ["pillar.glb", "pillar_decorated.glb", "column.glb"]:
		_add_pillar_collider(item)
	# 4. Coffre doré
	elif item_name.begins_with("chest_") or scene_path == "chest_gold.glb":
		_add_chest_collider(item)
	# 5. Escaliers
	elif item_name.begins_with("stairs_") or scene_path == "stairs_walled.glb":
		_add_stairs_collider(item)

func _add_wall_collider(target: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "SolidCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box = BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 1.0)
	col.shape = box
	col.position = Vector3(0, 2.0, 0)
	
	body.add_child(col)
	target.add_child(body)

func _add_arch_collider(target: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "SolidCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	
	# Montant gauche (1.1m de large)
	var col_left = CollisionShape3D.new()
	col_left.name = "ColLeft"
	var box_left = BoxShape3D.new()
	box_left.size = Vector3(1.1, 4.0, 1.0)
	col_left.shape = box_left
	col_left.position = Vector3(-1.45, 2.0, 0)
	body.add_child(col_left)
	
	# Montant droit (1.1m de large)
	var col_right = CollisionShape3D.new()
	col_right.name = "ColRight"
	var box_right = BoxShape3D.new()
	box_right.size = Vector3(1.1, 4.0, 1.0)
	col_right.shape = box_right
	col_right.position = Vector3(1.45, 2.0, 0)
	body.add_child(col_right)
	
	target.add_child(body)

func _add_pillar_collider(target: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "SolidCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl = CylinderShape3D.new()
	cyl.radius = 0.65
	cyl.height = 4.0
	col.shape = cyl
	col.position = Vector3(0, 2.0, 0)
	
	body.add_child(col)
	target.add_child(body)

func _add_chest_collider(target: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "SolidCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box = BoxShape3D.new()
	box.size = Vector3(1.4, 1.1, 1.1)
	col.shape = box
	col.position = Vector3(0, 0.55, 0)
	
	body.add_child(col)
	target.add_child(body)

func _add_stairs_collider(target: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "SolidCollider"
	body.collision_layer = 1
	body.collision_mask = 1
	
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box = BoxShape3D.new()
	box.size = Vector3(4.0, 3.0, 4.0)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	
	body.add_child(col)
	target.add_child(body)

## =============================================================================
## PARTIE 3 : LIAISON HUD, SIGNAUX ET BANDEAUX DE ZONE
## =============================================================================

func _connect_hud_and_systems() -> void:
	if not hud:
		return
	
	# Connexion des jauges du joueur
	if player:
		player.hp_changed.connect(hud.update_hp)
		player.gold_changed.connect(hud.update_gold)
		hud.update_hp(player.current_hp, player.max_hp)
		hud.update_gold(player.gold)
	
	# Connexion du coffre royal
	if chest and chest.has_signal("chest_opened"):
		chest.chest_opened.connect(hud.on_chest_opened)
	
	# Connexion de tous les ennemis squelettes
	var enemies = get_tree().get_nodes_in_group("enemy")
	var count = 0
	for enemy in enemies:
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(hud.on_skeleton_defeated)
			count += 1
	if count > 0:
		hud.total_skeletons = count
		hud.update_quest_objective()

func _setup_zone_triggers() -> void:
	var zones = [
		{"name": "Zone_GrandHall", "title": "Grande Nef d'Armes"},
		{"name": "Zone_Treasure", "title": "Crypte Royale du Trésor"},
		{"name": "Zone_WestRuins", "title": "Aile des Ruines"},
		{"name": "Zone_Sanctuary", "title": "Sanctuaire d'Eldrin"}
	]
	
	for z in zones:
		var area = find_child(z["name"], true, false) as Area3D
		if area:
			var zone_title = z["title"]
			area.body_entered.connect(func(body: Node3D):
				if body.is_in_group("player") and hud:
					hud.show_zone_banner(zone_title)
			)
