$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$ProjDir = ""
if (Test-Path "$ScriptDir\project.godot") {
    $ProjDir = $ScriptDir
} elseif (Test-Path "$ScriptDir\godot-hd2d-pipeline\project.godot") {
    $ProjDir = "$ScriptDir\godot-hd2d-pipeline"
} else {
    Write-Error "Fichier project.godot introuvable."
    exit 1
}

$GodotExe = "$ProjDir\tools\Godot_v4.3-stable_win64.exe"
if (-not (Test-Path $GodotExe)) {
    Write-Error "Executable Godot introuvable : $GodotExe"
    exit 1
}

Start-Process -FilePath $GodotExe -ArgumentList @("--path", $ProjDir, "res://scenes/main_hd2d_scene.tscn") -WorkingDirectory $ProjDir
