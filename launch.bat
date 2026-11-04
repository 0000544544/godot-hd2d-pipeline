@echo off
cd /d "%~dp0"
echo ========================================================
echo Lancement du Jeu 3D HD-2D (Godot 4.3 - Octopath Style)
echo ========================================================
echo Controles :
echo   - ZQSD / Fleches : Deplacement
echo   - Espace / Clic Gauche : Attaque a l'epee
echo   - Echap : Quitter
echo ========================================================
tools\Godot_v4.3-stable_win64.exe --path . "res://demo_hd2d/demo_hd2d.tscn"
