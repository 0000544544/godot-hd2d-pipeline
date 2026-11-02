"""
Godot 4 Automation Bridge Script
Permet aux agents d'exécuter des vérifications syntaxiques GDScript, 
de compiler/lancer des tests headless et d'inspecter l'arbre des nœuds.
"""

import sys
import os
import subprocess
import json
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent.parent

def find_godot_executable():
    """Recherche l'exécutable Godot 4 sur la machine locale."""
    candidates = [
        os.environ.get("GODOT_PATH", ""),
        str(PROJECT_DIR / "tools" / "Godot_v4.3-stable_win64_console.exe"),
        str(PROJECT_DIR / "tools" / "Godot_v4.3-stable_win64.exe"),
        str(PROJECT_DIR / "tools" / "godot.exe"),
        "godot",
        "godot4",
        str(Path.home() / "scoop/apps/godot/current/godot.exe"),
        "C:/Program Files/Godot/Godot_v4.3-stable_win64_console.exe",
        "C:/Program Files/Godot/Godot_v4.3-stable_win64.exe",
        "C:/Program Files/Godot/godot.exe",
        "C:/Users/AymaneELHOMAIDI/Downloads/Godot_v4.3-stable_win64.exe",
    ]
    for c in candidates:
        if c and (Path(c).exists() or shutil_which(c)):
            return c
    return None

def shutil_which(name):
    from shutil import which
    return which(name)

def check_project_validity():
    """Vérifie la structure du projet Godot."""
    godot_file = PROJECT_DIR / "project.godot"
    if not godot_file.exists():
        return {"status": "error", "message": "project.godot manquant."}
    
    scenes = list(PROJECT_DIR.glob("scenes/**/*.tscn"))
    scripts = list(PROJECT_DIR.glob("scripts/**/*.gd"))
    shaders = list(PROJECT_DIR.glob("shaders/**/*.gdshader"))

    return {
        "status": "success",
        "project_name": "Godot HD-2D Zero Euro",
        "project_path": str(PROJECT_DIR),
        "scenes_count": len(scenes),
        "scripts_count": len(scripts),
        "shaders_count": len(shaders),
        "scenes": [s.name for s in scenes],
        "scripts": [sc.name for sc in scripts],
        "shaders": [sh.name for sh in shaders],
    }

def run_headless_check(scene_path="res://scenes/main_hd2d_scene.tscn"):
    """Lance Godot en mode headless pour valider qu'aucune erreur ne bloque."""
    godot = find_godot_executable()
    if not godot:
        return {
            "status": "warning", 
            "message": "Godot 4 n'est pas encore détecté sur le PATH. Vous pouvez télécharger l'exécutable standalone (Godot 4.3 stable win64) et définir GODOT_PATH."
        }
    
    cmd = [godot, "--headless", "--path", str(PROJECT_DIR), "--quit-after", "10", scene_path]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        return {
            "status": "ok" if res.returncode == 0 else "error",
            "returncode": res.returncode,
            "stdout": res.stdout.strip(),
            "stderr": res.stderr.strip()
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

if __name__ == "__main__":
    action = sys.argv[1] if len(sys.argv) > 1 else "status"
    if action == "status":
        print(json.dumps(check_project_validity(), indent=2))
    elif action == "find":
        exe = find_godot_executable()
        print(f"Godot executable: {exe if exe else 'Non trouvé'}")
    elif action == "check":
        scene = sys.argv[2] if len(sys.argv) > 2 else "res://scenes/main_hd2d_scene.tscn"
        print(json.dumps(run_headless_check(scene), indent=2))
