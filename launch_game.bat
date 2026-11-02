@echo off
title Godot HD-2D Game Launcher
cd /d "%~dp0"
start "" "%~dp0tools\Godot_v4.3-stable_win64.exe" --path "%~dp0" "res://scenes/main_hd2d_scene.tscn"
exit
