# Fichier : config/test_gallery.gd
extends Node3D

const KNIGHT_SCENE := preload("res://assets/models/characters/Knight.glb")
const MAGE_SCENE := preload("res://assets/models/characters/Mage.glb")

var player_node: CharacterBody3D = null
var player_mesh_root: Node3D = null
var player_viewport: SubViewport = null
var player_vp_model: Node3D = null
var player_sprite_3d: Sprite3D = null
var current_player_style: int = 1
var hud_label: Label = null

func _ready() -> void:
	_clean_broken_gallery_nodes()
	_fix_hd2d_lighting()
	_build_open_showcase_stands()
	_setup_live_player_style_switcher()
	_create_hud_instructions()

func _clean_broken_gallery_nodes() -> void:
	# Supprime les cloisons, anciens stands, lumières parasites et labels cassés
	for child in get_children():
		if child.name in ["Player", "HD2DCamera", "Floor", "Walls", "NavigationRegion3D"]:
			continue
		if child is DirectionalLight3D or child is WorldEnvironment:
			child.queue_free()
		elif child.name.begins_with("Room") or child.name.begins_with("Piece") or child.name.begins_with("Partition") or child.name.begins_with("Stand") or child.name.begins_with("Showcase") or child.name.begins_with("Divider"):
			child.queue_free()

func _fix_hd2d_lighting() -> void:
	# 1. Environnement HD-2D sombre, contrasté et non brûlé
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.03, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.20, 0.30)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.85
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	var world_env := WorldEnvironment.new()
	world_env.name = "HD2DWorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	# 2. Lumière directionnelle douce (évite le blanc cramé sur l'armure)
	var dir_light := DirectionalLight3D.new()
	dir_light.name = "KeyLight"
	dir_light.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	dir_light.light_color = Color(1.0, 0.92, 0.82)
	dir_light.light_energy = 0.55
	dir_light.shadow_enabled = true
	add_child(dir_light)

func _build_open_showcase_stands() -> void:
	var root := Node3D.new()
	root.name = "ShowcaseStands"
	add_child(root)

	# Stand 1 (Gauche) : 3D Low-Poly + Contour Noir (Toon Outline)
	_create_stand(
		root,
		Vector3(-6.0, 0.0, -3.5),
		"[ STAND 1 : 3D TOON + CONTOUR NOIR ]\nModèles 3D KayKit + Outline Shader",
		Color(0.35, 0.85, 1.0),
		0 # 0 = 3D avec Outline
	)

	# Stand 2 (Centre) : Pixel-Art Rétro 16-Bit (SubViewport 48x48)
	_create_stand(
		root,
		Vector3(0.0, 0.0, -3.5),
		"[ STAND 2 : PIXEL-ART RÉTRO 48x48 ]\nRendu 3D -> Sprite 2D gros pixels + Contour 1px",
		Color(1.0, 0.85, 0.3),
		48 # 48x48 pixels
	)

	# Stand 3 (Droite) : Pixel-Art HD-2D Fin (SubViewport 96x96)
	_create_stand(
		root,
		Vector3(6.0, 0.0, -3.5),
		"[ STAND 3 : PIXEL-ART HD-2D FIN 96x96 ]\nRendu 3D -> Sprite 2D haute densité + Ombres 3D",
		Color(0.45, 1.0, 0.55),
		96 # 96x96 pixels
	)

func _create_stand(parent: Node3D, pos: Vector3, title: String, color: Color, pixel_res: int) -> void:
	var stand := Node3D.new()
	stand.position = pos
	parent.add_child(stand)

	# Tapis lumineux au sol pour délimiter le stand sans mur bloquant
	var pad := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.5
	cyl.height = 0.06
	var pad_mat := StandardMaterial3D.new()
	pad_mat.albedo_color = color.darkened(0.65)
	pad_mat.emission_enabled = true
	pad_mat.emission = color
	pad_mat.emission_energy_multiplier = 0.25
	cyl.material = pad_mat
	pad.mesh = cyl
	pad.position = Vector3(0.0, 0.03, 0.0)
	stand.add_child(pad)

	# Lumière chaude locale par stand
	var omni := OmniLight3D.new()
	omni.position = Vector3(0.0, 2.8, 1.5)
	omni.light_color = Color(1.0, 0.78, 0.55)
	omni.light_energy = 1.2
	omni.omni_range = 6.5
	omni.shadow_enabled = true
	stand.add_child(omni)

	# Pancarte lisible au-dessus du stand
	var label := Label3D.new()
	label.text = title
	label.font_size = 28
	label.outline_size = 10
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0.0, 3.1, 0.0)
	stand.add_child(label)

	if pixel_res == 0:
		# Stand 1 : Vrais modèles 3D avec contour noir et attaque en boucle
		var knight := KNIGHT_SCENE.instantiate()
		knight.position = Vector3(-0.9, 0.0, 0.0)
		stand.add_child(knight)
		_apply_toon_outline_to_tree(knight, 0.018)
		_play_looping_anim(knight, ["1H_Melee_Attack_Slice_Diagonal", "Walk_A", "Walking_A", "Idle"])

		var mage := MAGE_SCENE.instantiate()
		mage.position = Vector3(0.9, 0.0, 0.0)
		stand.add_child(mage)
		_apply_toon_outline_to_tree(mage, 0.018)
		_play_looping_anim(mage, ["Idle", "Walk_A", "Walking_A"])
	else:
		# Stands 2 & 3 : Conversion Temps Réel 3D -> Sprite3D Pixel-Art via SubViewport isolé
		var knight_sp := _create_pixel_art_character(KNIGHT_SCENE, pixel_res, ["1H_Melee_Attack_Slice_Diagonal", "Walk_A", "Walking_A", "Idle"])
		knight_sp.position = Vector3(-0.9, 1.25, 0.0)
		stand.add_child(knight_sp)

		var mage_sp := _create_pixel_art_character(MAGE_SCENE, pixel_res, ["Idle", "Walk_A", "Walking_A"])
		mage_sp.position = Vector3(0.9, 1.25, 0.0)
		stand.add_child(mage_sp)

func _create_pixel_art_character(scene_res: PackedScene, res_px: int, anim_candidates: Array) -> Node3D:
	var holder := Node3D.new()

	var vp := SubViewport.new()
	vp.size = Vector2i(res_px, res_px)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	holder.add_child(vp)

	var vp_root := Node3D.new()
	vp.add_child(vp_root)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(0.0, 1.15, 3.0)
	cam.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	vp_root.add_child(cam)

	var v_light := DirectionalLight3D.new()
	v_light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	v_light.light_energy = 0.85
	v_light.light_color = Color(1.0, 0.95, 0.88)
	vp_root.add_child(v_light)

	var v_env := WorldEnvironment.new()
	var env_res := Environment.new()
	env_res.background_mode = Environment.BG_CLEAR_COLOR
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.55, 0.52, 0.65)
	env_res.ambient_light_energy = 0.75
	v_env.environment = env_res
	vp_root.add_child(v_env)

	var model := scene_res.instantiate()
	vp_root.add_child(model)
	# Contour plus épais en 48x48 pour garantir 1px noir autour du sprite
	var outline_thickness := 0.032 if res_px <= 48 else 0.020
	_apply_toon_outline_to_tree(model, outline_thickness)
	_play_looping_anim(model, anim_candidates)

	var sprite := Sprite3D.new()
	sprite.texture = vp.get_texture()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 2.5 / float(res_px)
	sprite.shaded = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.alpha_scissor_threshold = 0.25
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	holder.add_child(sprite)

	return holder

func _apply_toon_outline_to_tree(node: Node, outline_width: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		var outline_mat := StandardMaterial3D.new()
		outline_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		outline_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		outline_mat.albedo_color = Color(0.04, 0.03, 0.06, 1.0)
		outline_mat.grow = true
		outline_mat.grow_amount = outline_width

		var mesh_res := mi.mesh
		if mesh_res:
			for s in range(mesh_res.get_surface_count()):
				var base_mat := mi.get_active_material(s)
				if base_mat is StandardMaterial3D:
					var dup := base_mat.duplicate() as StandardMaterial3D
					dup.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
					dup.specular_mode = BaseMaterial3D.SPECULAR_TOON
					dup.roughness = 0.85
					dup.next_pass = outline_mat
					mi.set_surface_override_material(s, dup)
	for child in node.get_children():
		_apply_toon_outline_to_tree(child, outline_width)

func _play_looping_anim(model: Node, candidates: Array) -> void:
	var ap := _find_anim_player(model)
	if not ap:
		return
	for anim_name in candidates:
		if ap.has_animation(anim_name):
			var anim := ap.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR
			ap.play(anim_name)
			return

func _find_anim_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for c in node.get_children():
		var found := _find_anim_player(c)
		if found:
			return found
	return null

func _setup_live_player_style_switcher() -> void:
	player_node = get_node_or_null("Player") as CharacterBody3D
	if not player_node:
		return
	player_node.position = Vector3(0.0, 0.1, 2.5)
	for c in player_node.get_children():
		if c is Node3D and not (c is CollisionShape3D) and not (c is Area3D):
			player_mesh_root = c
			break
	if player_mesh_root:
		_apply_toon_outline_to_tree(player_mesh_root, 0.018)

	# Création d'un SubViewport attaché au joueur pour tester les modes Pixel-Art [2] et [3] en jouant
	player_viewport = SubViewport.new()
	player_viewport.size = Vector2i(64, 64)
	player_viewport.transparent_bg = true
	player_viewport.own_world_3d = true
	player_viewport.msaa_3d = Viewport.MSAA_DISABLED
	player_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	player_node.add_child(player_viewport)

	var vp_root := Node3D.new()
	player_viewport.add_child(vp_root)

	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.6
	cam.position = Vector3(0.0, 1.15, 3.0)
	cam.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	vp_root.add_child(cam)

	var v_light := DirectionalLight3D.new()
	v_light.rotation_degrees = Vector3(-45.0, 35.0, 0.0)
	v_light.light_energy = 0.85
	vp_root.add_child(v_light)

	var v_env := WorldEnvironment.new()
	var env_res := Environment.new()
	env_res.background_mode = Environment.BG_CLEAR_COLOR
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.55, 0.52, 0.65)
	env_res.ambient_light_energy = 0.75
	v_env.environment = env_res
	vp_root.add_child(v_env)

	player_vp_model = KNIGHT_SCENE.instantiate()
	vp_root.add_child(player_vp_model)
	_apply_toon_outline_to_tree(player_vp_model, 0.028)

	player_sprite_3d = Sprite3D.new()
	player_sprite_3d.texture = player_viewport.get_texture()
	player_sprite_3d.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	player_sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	player_sprite_3d.pixel_size = 2.5 / 64.0
	player_sprite_3d.position = Vector3(0.0, 1.25, 0.0)
	player_sprite_3d.shaded = true
	player_sprite_3d.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	player_sprite_3d.alpha_scissor_threshold = 0.25
	player_sprite_3d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	player_sprite_3d.visible = false
	player_node.add_child(player_sprite_3d)

func _process(_delta: float) -> void:
	# Synchronise la rotation et l'animation du modèle 3D du joueur avec son clone Pixel-Art
	if player_mesh_root and player_vp_model and current_player_style > 1:
		player_vp_model.rotation = player_mesh_root.rotation
		var src_ap := _find_anim_player(player_mesh_root)
		var dst_ap := _find_anim_player(player_vp_model)
		if src_ap and dst_ap and src_ap.current_animation != "":
			if dst_ap.current_animation != src_ap.current_animation:
				dst_ap.play(src_ap.current_animation)
			dst_ap.seek(src_ap.current_animation_position, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1 or event.physical_keycode == KEY_1:
			_set_player_style(1)
		elif event.keycode == KEY_2 or event.physical_keycode == KEY_2:
			_set_player_style(2)
		elif event.keycode == KEY_3 or event.physical_keycode == KEY_3:
			_set_player_style(3)

func _set_player_style(style_id: int) -> void:
	current_player_style = style_id
	if not player_mesh_root or not player_sprite_3d or not player_viewport:
		return
	if style_id == 1:
		player_mesh_root.visible = true
		player_sprite_3d.visible = false
		if hud_label:
			hud_label.text = "Style actif du Joueur : [1] 3D Toon + Contour  |  Appuyez sur [1] [2] [3] pour changer"
	elif style_id == 2:
		player_mesh_root.visible = false
		player_sprite_3d.visible = true
		player_viewport.size = Vector2i(48, 48)
		player_sprite_3d.pixel_size = 2.5 / 48.0
		if hud_label:
			hud_label.text = "Style actif du Joueur : [2] Pixel-Art Rétro 48x48  |  Appuyez sur [1] [2] [3] pour changer"
	elif style_id == 3:
		player_mesh_root.visible = false
		player_sprite_3d.visible = true
		player_viewport.size = Vector2i(96, 96)
		player_sprite_3d.pixel_size = 2.5 / 96.0
		if hud_label:
			hud_label.text = "Style actif du Joueur : [3] Pixel-Art HD-2D Fin 96x96  |  Appuyez sur [1] [2] [3] pour changer"

func _create_hud_instructions() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud_label = Label.new()
	hud_label.text = "Style actif du Joueur : [1] 3D Toon + Contour  |  Appuyez sur [1] [2] [3] pour changer en direct"
	hud_label.position = Vector2(24, 20)
	hud_label.add_theme_font_size_override("font_size", 20)
	hud_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	hud_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hud_label.add_theme_constant_override("outline_size", 6)
	canvas.add_child(hud_label)
