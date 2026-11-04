@echo off
cd /d "%~dp0"
echo ========================================================
echo Lancement Action-RPG 3D Dark Fantasy (Godot 4.3 Stylise)
echo ========================================================
echo Controles :
echo   - ZQSD / Fleches : Deplacement 3D fluide
echo   - Espace / Clic Gauche : Coup d'epee avec hitbox et recul
echo   - E : Parler a Maitre Eldrin (Groq AI) / Ouvrir le Coffre Royal
echo   - Echap : Fermer le dialogue
echo ========================================================
tools\Godot_v4.3-stable_win64.exe --path . "res://scenes/dungeon_3d.tscn"
