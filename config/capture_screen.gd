extends SceneTree

func _initialize() -> void:
	var packed = load("res://scenes/main_hd2d_scene.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	
	# Attendre plusieurs frames pour le rendu complet avec shaders et HUD
	for i in range(15):
		await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("screenshot_full_system.png")
		print("Screenshot sauvegardé: screenshot_full_system.png, taille: ", img.get_size())
	quit(0)
