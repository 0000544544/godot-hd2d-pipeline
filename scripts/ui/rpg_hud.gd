class_name RPGHUD
extends CanvasLayer

## Interface Utilisateur RPG HD-2D
## - Jauge de vie (PV : 5 / 5 avec barre rouge)
## - Compteur d'or (Or : 0)
## - Objectif / Quête active (Vaincre les squelettes et ouvrir le Coffre Royal)
## - Bandeau de découverte de zone en haut au centre

@export var max_player_hp: int = 5

var current_hp: int = 5
var total_gold: int = 0
var skeletons_defeated: int = 0
var total_skeletons: int = 4
var is_chest_opened: bool = false

var _hp_label: Label
var _hp_bar: ProgressBar
var _gold_label: Label
var _quest_label: Label

var _banner_panel: PanelContainer
var _banner_label: Label
var _banner_tween: Tween
var _current_zone_name: String = ""

func _ready() -> void:
	layer = 5
	_build_hud_ui()
	_build_zone_banner_ui()
	update_hp(max_player_hp, max_player_hp)
	update_gold(0)
	update_quest_objective()

func _build_hud_ui() -> void:
	# Conteneur principal en haut à gauche
	var hud_panel = PanelContainer.new()
	hud_panel.name = "HUDPanel"
	
	# Style élégant sombre / bronze
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.82)
	style.border_color = Color(0.42, 0.38, 0.32, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	hud_panel.add_theme_stylebox_override("panel", style)
	
	hud_panel.position = Vector2(24, 20)
	add_child(hud_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	hud_panel.add_child(vbox)
	
	# 1. Section Points de Vie (PV)
	var hp_box = VBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 2)
	vbox.add_child(hp_box)
	
	_hp_label = Label.new()
	_hp_label.name = "HPLabel"
	_hp_label.text = "PV : 5 / 5"
	_hp_label.add_theme_font_size_override("font_size", 14)
	_hp_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	hp_box.add_child(_hp_label)
	
	_hp_bar = ProgressBar.new()
	_hp_bar.name = "HPBar"
	_hp_bar.min_value = 0
	_hp_bar.max_value = max_player_hp
	_hp_bar.value = max_player_hp
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(210, 14)
	
	# Styles de la barre rouge
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.18, 0.08, 0.08, 0.9)
	bar_bg.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.88, 0.16, 0.16, 1.0)
	bar_fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", bar_fill)
	hp_box.add_child(_hp_bar)
	
	# 2. Section Or
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.text = "✦ Or : 0"
	_gold_label.add_theme_font_size_override("font_size", 14)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.22))
	_gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_gold_label.add_theme_constant_override("shadow_offset_x", 1)
	_gold_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(_gold_label)
	
	# Séparateur subtil
	var hsep = HSeparator.new()
	vbox.add_child(hsep)
	
	# 3. Section Objectif / Quête
	_quest_label = Label.new()
	_quest_label.name = "QuestLabel"
	_quest_label.text = "Objectif : Vaincre les Squelettes (0/4) et ouvrir le Coffre Royal"
	_quest_label.add_theme_font_size_override("font_size", 12)
	_quest_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84))
	_quest_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_quest_label.add_theme_constant_override("shadow_offset_x", 1)
	_quest_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(_quest_label)

func _build_zone_banner_ui() -> void:
	_banner_panel = PanelContainer.new()
	_banner_panel.name = "ZoneBanner"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.06, 0.09, 0.88)
	style.border_color = Color(0.85, 0.72, 0.35, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_banner_panel.add_theme_stylebox_override("panel", style)
	
	_banner_label = Label.new()
	_banner_label.text = "Grande Nef d'Armes"
	_banner_label.add_theme_font_size_override("font_size", 18)
	_banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_banner_label.add_theme_constant_override("shadow_offset_x", 1)
	_banner_label.add_theme_constant_override("shadow_offset_y", 1)
	_banner_panel.add_child(_banner_label)
	
	add_child(_banner_panel)
	
	# Centrage horizontal en haut
	_banner_panel.anchor_left = 0.5
	_banner_panel.anchor_right = 0.5
	_banner_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner_panel.position = Vector2(0, 24)
	_banner_panel.modulate.a = 0.0 # Masqué au départ

func update_hp(new_hp: int, new_max: int = -1) -> void:
	current_hp = new_hp
	if new_max > 0:
		max_player_hp = new_max
	if _hp_label:
		_hp_label.text = "PV : %d / %d" % [current_hp, max_player_hp]
	if _hp_bar:
		_hp_bar.max_value = max_player_hp
		_hp_bar.value = current_hp

func update_gold(new_gold: int) -> void:
	total_gold = new_gold
	if _gold_label:
		_gold_label.text = "✦ Or : %d" % total_gold

func on_skeleton_defeated(_skeleton: Node = null) -> void:
	skeletons_defeated = min(skeletons_defeated + 1, total_skeletons)
	update_quest_objective()

func on_chest_opened() -> void:
	is_chest_opened = true
	update_quest_objective()

func update_quest_objective() -> void:
	if not _quest_label:
		return
	
	if skeletons_defeated >= total_skeletons and is_chest_opened:
		_quest_label.text = "✦ Donjon Purifié ! Tous les squelettes sont vaincus et le trésor est vôtre !"
		_quest_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	elif is_chest_opened:
		_quest_label.text = "Objectif : Vaincre les Squelettes (%d/%d) [Coffre Royal ouvert !]" % [skeletons_defeated, total_skeletons]
		_quest_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	else:
		_quest_label.text = "Objectif : Vaincre les Squelettes (%d/%d) et ouvrir le Coffre Royal" % [skeletons_defeated, total_skeletons]
		_quest_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.84))

func show_zone_banner(zone_name: String) -> void:
	if zone_name == _current_zone_name and _banner_panel.modulate.a > 0.1:
		return
	_current_zone_name = zone_name
	
	if not _banner_label or not _banner_panel:
		return
	
	_banner_label.text = "⚔  %s  ⚔" % zone_name
	
	# Repositionnement centré
	var vp_size = get_viewport().get_visible_rect().size
	_banner_panel.reset_size()
	_banner_panel.position = Vector2((vp_size.x - _banner_panel.size.x) * 0.5, 24)
	
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	
	_banner_tween = create_tween()
	# Apparition douce en 0.25s
	_banner_tween.tween_property(_banner_panel, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	# Maintien pendant 2.0s
	_banner_tween.tween_interval(2.0)
	# Disparition progressive en 0.45s
	_banner_tween.tween_property(_banner_panel, "modulate:a", 0.0, 0.45)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
