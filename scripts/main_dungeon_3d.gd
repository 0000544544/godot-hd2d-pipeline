class_name MainDungeon3D
extends Node3D

## Scène Principale du Donjon 3D Action-RPG Dark Fantasy
## Coordonne l'ambiance sonore, l'initialisation Sentry, et les événements de quête/combat.

@onready var player: Player3D = $Player3D
@onready var chest: GoldChest = $Props/GoldChest
@onready var hud: RPGHUD3D = $RPGHUD3D
@onready var supabase: SupabaseManager = $SupabaseManager
@onready var sentry: SentryLogger = $SentryLogger

func _ready() -> void:
	# Initialisation Sentry
	if sentry:
		sentry.capture_message("Donjon 3D lancé avec succès - Moteur Godot 4.3 Stylisé", "info")

	# Événement Coffre Royal
	if chest:
		chest.chest_opened.connect(_on_chest_opened)

	# Initialisation sauvegarde Supabase
	if supabase:
		supabase.save_state(5, 0, 0, "Entrée dans la Crypte Royale")

	# Capture de vérification automatique si demandée via arguments
	var cmd_args = OS.get_cmdline_args()
	for arg in cmd_args:
		if arg == "--screenshot" or arg == "--capture-screenshot":
			get_tree().create_timer(1.8).timeout.connect(_take_screenshot)
			break

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var vp = get_viewport()
	if vp:
		var img = vp.get_texture().get_image()
		if img:
			img.save_png("res://screenshot_dungeon_3d.png")
			print("[Screenshot] Capture 3D sauvegardée : res://screenshot_dungeon_3d.png")
	get_tree().quit()

func _on_chest_opened() -> void:
	if sentry:
		sentry.capture_message("Coffre Doré ouvert par le joueur", "info")
	if supabase and player:
		supabase.save_state(player.hp, player.gold, player.enemies_killed, "Coffre Doré ouvert")
