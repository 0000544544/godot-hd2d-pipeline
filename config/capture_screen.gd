extends SceneTree

func _init() -> void:
	var packed = load("res://scenes/main_hd2d_scene.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	
	# Attendre 2 frames pour le rendu
	await process_frame
	await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshot_test.png")
		print("Screenshot sauvegardé avec succès: res://screenshot_test.png (taille: ", img.get_size(), ")")
	else:
		print("Impossible de capturer l'image")
	quit(0)
