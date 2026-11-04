"""
Génération d'icônes RPG 64x64 haute qualité :
- sword_icon.png : Épée de chevalier en acier avec garde dorée et pommeau
- potion_icon.png : Fiole de potion de soin en verre avec liquide rouge rubis et bouchon de liège
"""
from PIL import Image, ImageDraw
import os

ICONS_DIR = r"c:\Users\AymaneELHOMAIDI\Desktop\Projects\WadWAd\godot-hd2d-pipeline\assets\ui\icons"
os.makedirs(ICONS_DIR, exist_ok=True)

# 1. SWORD ICON (64x64)
sword = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(sword)

# Lame diagonale argentée
blade_points = [
    (14, 14), (17, 11), (20, 14), (43, 37), (40, 40)
]
# Bordure sombre de la lame
draw.polygon([(13, 14), (17, 10), (21, 14), (45, 38), (39, 42)], fill=(25, 30, 40, 240))
# Corps de lame argenté
draw.polygon([(14, 14), (17, 11), (20, 14), (43, 37), (40, 40)], fill=(190, 205, 220, 255))
# Fil de la lame éclatant
draw.line([(17, 11), (41, 35)], fill=(245, 250, 255, 255), width=2)
# Reflet d'acier
draw.line([(15, 15), (38, 38)], fill=(140, 155, 175, 255), width=1)

# Garde dorée
guard_points = [(35, 45), (45, 35), (48, 38), (38, 48)]
draw.polygon([(34, 46), (46, 34), (50, 38), (38, 50)], fill=(80, 55, 15, 255))
draw.polygon([(35, 45), (45, 35), (48, 38), (38, 48)], fill=(235, 180, 45, 255))
draw.line([(37, 44), (45, 36)], fill=(255, 225, 120, 255), width=1)

# Poignée cuir sombre
draw.line([(43, 43), (51, 51)], fill=(90, 50, 30, 255), width=3)
draw.line([(44, 44), (50, 50)], fill=(140, 80, 40, 255), width=1)

# Pommeau doré
draw.ellipse([50, 50, 56, 56], fill=(80, 55, 15, 255))
draw.ellipse([51, 51, 55, 55], fill=(235, 180, 45, 255))
draw.point((52, 52), fill=(255, 240, 160, 255))

sword_path = os.path.join(ICONS_DIR, "sword_icon.png")
sword.save(sword_path)
print(f"Épée sauvegardée : {sword_path}")

# 2. POTION ICON (64x64)
potion = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw = ImageDraw.Draw(potion)

# Bouchon de liège
draw.rounded_rectangle([27, 8, 37, 15], radius=2, fill=(160, 105, 55, 255), outline=(70, 40, 20, 255))
draw.line([(29, 10), (35, 10)], fill=(205, 145, 85, 255))

# Col de la bouteille
draw.rounded_rectangle([25, 15, 39, 23], radius=2, fill=(180, 220, 245, 160), outline=(60, 90, 120, 220))

# Corps de la fiole ronde
draw.ellipse([12, 21, 52, 59], fill=(30, 50, 75, 180), outline=(50, 85, 120, 240), width=2)

# Liquide rouge potion magique
draw.pieslice([14, 23, 50, 57], 15, 165, fill=(215, 25, 45, 245), outline=(130, 10, 25, 255))
# Dégradé interne / cœur brillant
draw.ellipse([20, 38, 44, 53], fill=(245, 75, 95, 255))

# Bulles d'effervescence magiques
draw.ellipse([24, 33, 28, 37], fill=(255, 180, 190, 255))
draw.ellipse([36, 42, 39, 45], fill=(255, 180, 190, 255))
draw.point((30, 46), fill=(255, 220, 220, 255))

# Reflet spéculaire sur le verre (Arc blanc en haut à gauche)
draw.arc([16, 25, 48, 55], 195, 260, fill=(245, 250, 255, 230), width=2)
draw.point((20, 30), fill=(255, 255, 255, 255))

potion_path = os.path.join(ICONS_DIR, "potion_icon.png")
potion.save(potion_path)
print(f"Potion sauvegardée : {potion_path}")
