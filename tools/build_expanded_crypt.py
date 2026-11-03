import sys
from pathlib import Path

class Color:
    def __init__(self, r, g, b):
        self.r, self.g, self.b = r, g, b

def generate_scene():
    out = []
    
    # 1. Header & ExtResources
    out.append('[gd_scene load_steps=52 format=3 uid="uid://blu8jj26y2oyc"]')
    out.append('')
    
    ext_resources = [
        ('Script', '', 'res://scripts/main_hd2d_scene.gd', 'script_main_scene'),
        ('Environment', 'uid://bgqkfi1roieos', 'res://scenes/world_environment.tres', '1_env'),
        ('Script', '', 'res://scripts/camera/hd2d_camera.gd', '2_cam'),
        ('Script', '', 'res://scripts/player/player_hd2d.gd', '3_ply'),
        ('Script', '', 'res://scripts/ai/groq_npc_dialogue.gd', '4_ai'),
        ('Script', '', 'res://scripts/lighting/torch_flicker.gd', '6_flicker'),
        ('CameraAttributesPractical', '', 'res://scenes/camera_attributes.tres', 'cam_attr'),
        ('PackedScene', 'uid://ws5n7x3mse63', 'res://assets/models/barrel_large.glb', 'mod_barrel'),
        ('PackedScene', 'uid://cum3e72byvvhu', 'res://assets/models/barrel_small_stack.glb', 'mod_barrel_stack'),
        ('PackedScene', 'uid://dww57qpcuybta', 'res://assets/models/chest_gold.glb', 'mod_chest'),
        ('PackedScene', 'uid://c5vbo0o118sjh', 'res://assets/models/floor_tile_large.glb', 'mod_floor'),
        ('PackedScene', 'uid://qq3bvi5as7jy', 'res://assets/models/floor_tile_large_rocks.glb', 'mod_floor_rocks'),
        ('PackedScene', 'uid://c0d17pycmi14v', 'res://assets/models/pillar.glb', 'mod_pillar'),
        ('PackedScene', 'uid://colbltrpmd6v1', 'res://assets/models/pillar_decorated.glb', 'mod_pillar_dec'),
        ('PackedScene', '', 'res://assets/models/column.glb', 'mod_column'),
        ('PackedScene', '', 'res://assets/models/stairs_walled.glb', 'mod_stairs'),
        ('PackedScene', 'uid://bdtcstu8ambig', 'res://assets/models/torch_lit.glb', 'mod_torch'),
        ('PackedScene', 'uid://ba8e2ravuo8jw', 'res://assets/models/wall.glb', 'mod_wall'),
        ('PackedScene', 'uid://c3m3gfntuv2cx', 'res://assets/models/wall_arched.glb', 'mod_wall_arched'),
        ('PackedScene', 'uid://b3qqg7mhl0i8c', 'res://assets/models/wall_broken.glb', 'mod_wall_broken'),
        ('PackedScene', '', 'res://assets/models/characters/Knight.glb', 'char_knight'),
        ('PackedScene', '', 'res://assets/models/characters/Mage.glb', 'char_mage'),
        ('PackedScene', '', 'res://assets/models/characters/Skeleton_Warrior.glb', 'char_skeleton'),
        ('PackedScene', '', 'res://assets/models/characters/Skeleton_Rogue.glb', 'char_skeleton_rogue'),
        ('PackedScene', '', 'res://assets/models/characters/Skeleton_Mage.glb', 'char_skeleton_mage'),
        ('PackedScene', '', 'res://assets/models/characters/Skeleton_Minion.glb', 'char_skeleton_minion'),
        ('Script', '', 'res://scripts/npc/npc_eldrin.gd', 'script_eldrin'),
        ('Script', '', 'res://scripts/interaction/interactable.gd', 'script_interactable'),
        ('Script', '', 'res://scripts/props/gold_chest.gd', 'script_chest'),
        ('Script', '', 'res://scripts/props/destructible_barrel.gd', 'script_barrel'),
        ('Script', '', 'res://scripts/props/spike_trap.gd', 'script_spiketrap'),
        ('Script', '', 'res://scripts/ui/dialogue_box.gd', 'script_dialogue'),
        ('Script', '', 'res://scripts/ui/rpg_hud.gd', 'script_rpg_hud'),
        ('Script', '', 'res://scripts/enemy/enemy_skeleton.gd', 'script_skeleton')
    ]
    
    for rtype, uid, path, rid in ext_resources:
        if uid:
            out.append(f'[ext_resource type="{rtype}" uid="{uid}" path="{path}" id="{rid}"]')
        else:
            out.append(f'[ext_resource type="{rtype}" path="{path}" id="{rid}"]')
            
    out.append('')
    
    # 2. SubResources (Materials, Meshes, Collision Shapes)
    out.append('''[sub_resource type="StandardMaterial3D" id="Mat_FlameGlow"]
shading_mode = 0
albedo_color = Color(2.5, 1.4, 0.4, 1)

[sub_resource type="SphereMesh" id="Mesh_FlameGlow"]
material = SubResource("Mat_FlameGlow")
radius = 0.12
height = 0.24

[sub_resource type="StandardMaterial3D" id="Mat_TorchSparks"]
shading_mode = 0
albedo_color = Color(2.8, 1.8, 0.5, 1)

[sub_resource type="BoxMesh" id="Mesh_TorchSparks"]
material = SubResource("Mat_TorchSparks")
size = Vector3(0.04, 0.04, 0.04)

[sub_resource type="StandardMaterial3D" id="Mat_TorchSmoke"]
transparency = 1
shading_mode = 0
albedo_color = Color(0.2, 0.18, 0.16, 0.45)

[sub_resource type="SphereMesh" id="Mesh_TorchSmoke"]
material = SubResource("Mat_TorchSmoke")
radius = 0.15
height = 0.3

[sub_resource type="StandardMaterial3D" id="Mat_DustMotes"]
transparency = 1
shading_mode = 0
albedo_color = Color(1, 0.9, 0.75, 0.4)

[sub_resource type="SphereMesh" id="Mesh_DustMote"]
material = SubResource("Mat_DustMotes")
radius = 0.025
height = 0.05

[sub_resource type="BoxShape3D" id="BoxShape_floor"]
size = Vector3(56, 1, 44)

[sub_resource type="BoxShape3D" id="BoxShape_wall_thick"]
size = Vector3(4, 4, 1.5)

[sub_resource type="BoxShape3D" id="BoxShape_wall_unit"]
size = Vector3(4.0, 4.0, 1.0)

[sub_resource type="BoxShape3D" id="BoxShape_arch_pillar"]
size = Vector3(1.1, 4.0, 1.0)

[sub_resource type="CylinderShape3D" id="CylinderShape_pillar"]
height = 4.0
radius = 0.65

[sub_resource type="BoxShape3D" id="BoxShape_chest_solid"]
size = Vector3(1.4, 1.1, 1.1)

[sub_resource type="BoxShape3D" id="BoxShape_stairs"]
size = Vector3(4.0, 3.0, 4.0)

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_player"]
radius = 0.4
height = 1.6

[sub_resource type="BoxShape3D" id="BoxShape3D_npc"]
size = Vector3(1, 1.8, 1)

[sub_resource type="CylinderShape3D" id="CylinderShape_interact"]
height = 2.5
radius = 2.5

[sub_resource type="CylinderShape3D" id="CylinderShape3D_barrel_hurtbox"]
height = 1.6
radius = 0.75

[sub_resource type="CylinderShape3D" id="CylinderShape3D_barrel_solid"]
height = 1.3
radius = 0.55

[sub_resource type="BoxShape3D" id="BoxShape3D_hitbox"]
size = Vector3(1.6, 1.4, 1.6)

[sub_resource type="BoxShape3D" id="BoxShape_Zone_GrandHall"]
size = Vector3(22, 6, 16)

[sub_resource type="BoxShape3D" id="BoxShape_Zone_Treasure"]
size = Vector3(22, 6, 14)

[sub_resource type="BoxShape3D" id="BoxShape_Zone_WestRuins"]
size = Vector3(16, 6, 20)

[sub_resource type="BoxShape3D" id="BoxShape_Zone_Sanctuary"]
size = Vector3(16, 6, 16)
''')

    # Root Node with main scene script attached
    out.append('[node name="MainHD2DScene" type="Node3D"]')
    out.append('script = ExtResource("script_main_scene")')
    out.append('')
    out.append('[node name="WorldEnvironment" type="WorldEnvironment" parent="."]')
    out.append('environment = ExtResource("1_env")')
    out.append('')
    out.append('[node name="SunDirectionalLight" type="DirectionalLight3D" parent="."]')
    out.append('transform = Transform3D(0.866025, -0.286788, 0.409576, 0, 0.819152, 0.573576, -0.5, -0.496732, 0.709406, 0, 15, 0)')
    out.append('light_color = Color(1, 0.92, 0.82, 1)')
    out.append('light_energy = 0.55')
    out.append('light_volumetric_fog_energy = 0.65')
    out.append('shadow_enabled = true')
    out.append('shadow_bias = 0.04')
    out.append('directional_shadow_max_distance = 60.0')
    out.append('')

    # Courtyard Parent
    out.append('[node name="Courtyard" type="Node3D" parent="."]')
    out.append('')
    out.append('[node name="Floors" type="Node3D" parent="Courtyard"]')
    out.append('')

    # Build Floor Tiles
    floor_tiles = set()
    rocky_tiles = set()
    
    for x in range(-8, 9, 4):
        for z in range(-4, 9, 4):
            floor_tiles.add((x, z))
            
    for x in range(-8, 9, 4):
        for z in range(-16, -7, 4):
            floor_tiles.add((x, z))
            
    for x in range(-20, -11, 4):
        for z in range(-8, 9, 4):
            floor_tiles.add((x, z))
            if (x + z) % 8 == 0 or x == -20:
                rocky_tiles.add((x, z))
                
    for x in range(12, 21, 4):
        for z in range(-4, 9, 4):
            floor_tiles.add((x, z))

    idx = 1
    for (fx, fz) in sorted(floor_tiles):
        tile_name = f"Floor_{idx:02d}"
        res_type = "mod_floor_rocks" if (fx, fz) in rocky_tiles else "mod_floor"
        out.append(f'[node name="{tile_name}" parent="Courtyard/Floors" instance=ExtResource("{res_type}")]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {fx}, 0, {fz})')
        out.append('')
        idx += 1

    # Walls & Gateways
    out.append('[node name="Walls" type="Node3D" parent="Courtyard"]')
    out.append('')

    # Define Walls: list of (name, res, x, y, z, rot_y_deg)
    walls = [
        # North Wall of Treasure Room (Z = -18)
        ("Wall_Treas_N1", "mod_wall", -8, 0, -18, 0),
        ("Wall_Treas_N2", "mod_wall", -4, 0, -18, 0),
        # X=0 is the grand staircase
        ("Wall_Treas_N3", "mod_wall", 4, 0, -18, 0),
        ("Wall_Treas_N4", "mod_wall", 8, 0, -18, 0),
        # East & West Walls of Treasure Room
        ("Wall_Treas_W1", "mod_wall", -10, 0, -16, 90),
        ("Wall_Treas_W2", "mod_wall", -10, 0, -12, 90),
        ("Wall_Treas_W3", "mod_wall", -10, 0, -8, 90),
        ("Wall_Treas_E1", "mod_wall", 10, 0, -16, 90),
        ("Wall_Treas_E2", "mod_wall", 10, 0, -12, 90),
        ("Wall_Treas_E3", "mod_wall", 10, 0, -8, 90),

        # West Wing (Ruins & Traps)
        # North wall at Z = -10
        ("Wall_West_N1", "mod_wall_broken", -20, 0, -10, 0),
        ("Wall_West_N2", "mod_wall", -16, 0, -10, 0),
        ("Wall_West_N3", "mod_wall", -12, 0, -10, 0),
        # West boundary wall at X = -22
        ("Wall_West_W1", "mod_wall", -22, 0, -8, 90),
        ("Wall_West_W2", "mod_wall_broken", -22, 0, -4, 90),
        ("Wall_West_W3", "mod_wall", -22, 0, 0, 90),
        ("Wall_West_W4", "mod_wall_broken", -22, 0, 4, 90),
        ("Wall_West_W5", "mod_wall", -22, 0, 8, 90),
        # Arch divider into West Wing (at X = -10, Z = 0)
        ("Gate_West_Wing", "mod_wall_arched", -10, 0, 0, 90),

        # East Wing (Eldrin's Sanctuary)
        # North wall at Z = -6
        ("Wall_East_N1", "mod_wall", 12, 0, -6, 0),
        ("Wall_East_N2", "mod_wall", 16, 0, -6, 0),
        ("Wall_East_N3", "mod_wall", 20, 0, -6, 0),
        # East boundary wall at X = 22
        ("Wall_East_E1", "mod_wall", 22, 0, -4, 90),
        ("Wall_East_E2", "mod_wall", 22, 0, 0, 90),
        ("Wall_East_E3", "mod_wall", 22, 0, 4, 90),
        ("Wall_East_E4", "mod_wall", 22, 0, 8, 90),
        # Arch divider into East Wing (at X = 10, Z = 0)
        ("Gate_East_Wing", "mod_wall_arched", 10, 0, 0, 90),
    ]

    for wname, wres, wx, wy, wz, wrot in walls:
        out.append(f'[node name="{wname}" parent="Courtyard/Walls" instance=ExtResource("{wres}")]')
        if wrot == 90:
            out.append(f'transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, {wx}, {wy}, {wz})')
        elif wrot == -90:
            out.append(f'transform = Transform3D(0, 0, -1, 0, 1, 0, 1, 0, 0, {wx}, {wy}, {wz})')
        else:
            out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {wx}, {wy}, {wz})')
        out.append('')
        
        # StaticBody3D Collider pour chaque mur
        out.append(f'[node name="SolidCollider" type="StaticBody3D" parent="Courtyard/Walls/{wname}"]')
        out.append('collision_layer = 1')
        out.append('collision_mask = 1')
        out.append('')
        
        if wres == "mod_wall_arched":
            # Arche : 2 montants latéraux pour laisser le passage central libre (1.8m de passage)
            out.append(f'[node name="ColLeft" type="CollisionShape3D" parent="Courtyard/Walls/{wname}/SolidCollider"]')
            out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.45, 2.0, 0)')
            out.append('shape = SubResource("BoxShape_arch_pillar")')
            out.append('')
            out.append(f'[node name="ColRight" type="CollisionShape3D" parent="Courtyard/Walls/{wname}/SolidCollider"]')
            out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.45, 2.0, 0)')
            out.append('shape = SubResource("BoxShape_arch_pillar")')
            out.append('')
        else:
            # Mur plein standard 4x4x1
            out.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Walls/{wname}/SolidCollider"]')
            out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)')
            out.append('shape = SubResource("BoxShape_wall_unit")')
            out.append('')

    # Pillars
    out.append('[node name="Pillars" type="Node3D" parent="Courtyard"]')
    out.append('')
    pillars = [
        # Grand Colonnade in Central Hall
        ("Pillar_Center_NW", "mod_pillar", -4.0, 0, 0),
        ("Pillar_Center_NE", "mod_pillar", 4.0, 0, 0),
        ("Pillar_Center_SW", "mod_pillar", -4.0, 0, 4.5),
        ("Pillar_Center_SE", "mod_pillar", 4.0, 0, 4.5),
        # Entrance to Treasure Room
        ("Pillar_Entrance_Treas_L", "mod_pillar_dec", -4.0, 0, -6.0),
        ("Pillar_Entrance_Treas_R", "mod_pillar_dec", 4.0, 0, -6.0),
        # Royal Treasure Dais
        ("Pillar_Dais_L", "mod_pillar_dec", -2.8, 0, -12.0),
        ("Pillar_Dais_R", "mod_pillar_dec", 2.8, 0, -12.0),
        ("Pillar_Treas_NW", "mod_pillar", -8.0, 0, -16.0),
        ("Pillar_Treas_NE", "mod_pillar", 8.0, 0, -16.0),
        # Ruins & Traps Wing
        ("Pillar_Ruins_1", "mod_pillar", -16.0, 0, -4.0),
        ("Pillar_Ruins_2", "mod_pillar", -16.0, 0, 4.0),
        # Sanctuary Wing
        ("Column_Eldrin_1", "mod_column", 15.0, 0, -3.0),
        ("Column_Eldrin_2", "mod_column", 17.0, 0, 3.0),
    ]

    for pname, pres, px, py, pz in pillars:
        out.append(f'[node name="{pname}" parent="Courtyard/Pillars" instance=ExtResource("{pres}")]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {px}, {py}, {pz})')
        out.append('')
        # StaticBody3D Collider cylindrique pour chaque pilier
        out.append(f'[node name="SolidCollider" type="StaticBody3D" parent="Courtyard/Pillars/{pname}"]')
        out.append('collision_layer = 1')
        out.append('collision_mask = 1')
        out.append('')
        out.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Pillars/{pname}/SolidCollider"]')
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 0)')
        out.append('shape = SubResource("CylinderShape_pillar")')
        out.append('')

    # Torches & Lighting
    out.append('[node name="TorchesAndLighting" type="Node3D" parent="Courtyard"]')
    out.append('')
    
    torches = [
        ("Torch_Hall_NW", -3.6, 2.4, 0.4, Color(1, 0.72, 0.42), 2.8),
        ("Torch_Hall_NE", 3.6, 2.4, 0.4, Color(1, 0.72, 0.42), 2.8),
        ("Torch_Hall_SW", -3.6, 2.4, 4.1, Color(1, 0.75, 0.45), 2.6),
        ("Torch_Hall_SE", 3.6, 2.4, 4.1, Color(1, 0.75, 0.45), 2.6),
        ("Torch_Treasure_L", -2.0, 2.5, -12.0, Color(1.0, 0.85, 0.5), 3.2),
        ("Torch_Treasure_R", 2.0, 2.5, -12.0, Color(1.0, 0.85, 0.5), 3.2),
        ("Torch_Stairs", 0.0, 3.0, -15.5, Color(1.0, 0.7, 0.35), 3.0),
        ("Torch_Ruins_West", -16.0, 2.2, 0.0, Color(0.95, 0.65, 0.35), 2.8),
        ("Torch_Sanctuary_Eldrin", 16.0, 2.2, -0.8, Color(0.85, 0.65, 1.0), 3.0)
    ]

    for tname, tx, ty, tz, col, energy in torches:
        out.append(f'[node name="{tname}" parent="Courtyard/TorchesAndLighting" instance=ExtResource("mod_torch")]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {tx}, 0, {tz})')
        out.append('')
        # OmniLight3D
        out.append(f'[node name="TorchLight" type="OmniLight3D" parent="Courtyard/TorchesAndLighting/{tname}"]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {ty}, 0)')
        out.append(f'light_color = Color({col.r}, {col.g}, {col.b}, 1)')
        out.append(f'light_energy = {energy}')
        out.append('light_volumetric_fog_energy = 0.5')
        out.append('shadow_enabled = true')
        out.append('omni_range = 8.5')
        out.append('omni_attenuation = 1.3')
        out.append('script = ExtResource("6_flicker")')
        out.append(f'base_energy = {energy}')
        out.append('')
        # FlameGlow Mesh
        out.append(f'[node name="FlameGlow" type="MeshInstance3D" parent="Courtyard/TorchesAndLighting/{tname}"]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {ty - 0.2}, 0)')
        out.append('cast_shadow = 0')
        out.append('mesh = SubResource("Mesh_FlameGlow")')
        out.append('')
        # Sparks
        out.append(f'[node name="TorchSparks" type="CPUParticles3D" parent="Courtyard/TorchesAndLighting/{tname}"]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {ty - 0.15}, 0)')
        out.append('cast_shadow = 0')
        out.append('amount = 8')
        out.append('lifetime = 0.7')
        out.append('explosiveness = 0.1')
        out.append('randomness = 0.8')
        out.append('mesh = SubResource("Mesh_TorchSparks")')
        out.append('direction = Vector3(0, 1, 0)')
        out.append('spread = 40.0')
        out.append('gravity = Vector3(0, 1.5, 0)')
        out.append('initial_velocity_min = 0.6')
        out.append('initial_velocity_max = 1.4')
        out.append('')

    # Props & Interactive Dungeon Elements
    out.append('[node name="Props" type="Node3D" parent="Courtyard"]')
    out.append('')

    # 1. Grand Stairs in the Treasure Chamber (leading down)
    out.append('[node name="Stairs_Deep_Crypt" parent="Courtyard/Props" instance=ExtResource("mod_stairs")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -18)')
    out.append('')
    out.append('[node name="SolidCollider" type="StaticBody3D" parent="Courtyard/Props/Stairs_Deep_Crypt"]')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Props/Stairs_Deep_Crypt/SolidCollider"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)')
    out.append('shape = SubResource("BoxShape_stairs")')
    out.append('')

    # 2. Chest_Gold on the Royal Dais
    out.append('[node name="Chest_Gold" parent="Courtyard/Props" instance=ExtResource("mod_chest")]')
    out.append('transform = Transform3D(1.15, 0, 0, 0, 1.15, 0, 0, 0, 1.15, 0, 0, -12.5)')
    out.append('script = ExtResource("script_chest")')
    out.append('')
    out.append('[node name="SolidCollider" type="StaticBody3D" parent="Courtyard/Props/Chest_Gold"]')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Props/Chest_Gold/SolidCollider"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)')
    out.append('shape = SubResource("BoxShape_chest_solid")')
    out.append('')
    out.append('[node name="InteractableArea" type="Area3D" parent="Courtyard/Props/Chest_Gold"]')
    out.append('script = ExtResource("script_interactable")')
    out.append('prompt_text = "[E] Ouvrir le Coffre Royal"')
    out.append('prompt_offset = Vector3(0, 1.4, 0)')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Props/Chest_Gold/InteractableArea"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)')
    out.append('shape = SubResource("CylinderShape_interact")')
    out.append('')

    # 3. Spike Trap in West Wing (Crypt of the Sovereign hazard!)
    out.append('[node name="SpikeTrap_West" type="Node3D" parent="Courtyard/Props"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -16.0, 0, 0)')
    out.append('script = ExtResource("script_spiketrap")')
    out.append('')

    # 4. Destructible Barrels with Loot
    barrel_configs = [
        ("Barrel_Hall_Stack", "mod_barrel_stack", -4.2, 0, 1.5, 0), # Coin
        ("Barrel_Hall_Large", "mod_barrel", -4.2, 0, -0.8, 1), # Potion
        ("Barrel_Treas_L", "mod_barrel_stack", -5.5, 0, -13.0, 0),
        ("Barrel_Treas_R", "mod_barrel", 5.5, 0, -13.0, 1),
        ("Barrel_Ruins_Stack", "mod_barrel_stack", -19.0, 0, -6.0, 0),
        ("Barrel_Ruins_Large", "mod_barrel", -19.0, 0, 6.0, 1),
        ("Barrel_Sanctuary", "mod_barrel", 19.0, 0, 4.0, 1)
    ]

    for bname, bres, bx, by, bz, ltype in barrel_configs:
        out.append(f'[node name="{bname}" parent="Courtyard/Props" instance=ExtResource("{bres}")]')
        out.append(f'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {bx}, {by}, {bz})')
        out.append('script = ExtResource("script_barrel")')
        out.append(f'loot_type = {ltype}')
        out.append('')
        out.append(f'[node name="Hurtbox" type="Area3D" parent="Courtyard/Props/{bname}" groups=["destructible"]]')
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)')
        out.append('collision_layer = 1')
        out.append('collision_mask = 0')
        out.append('')
        out.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Props/{bname}/Hurtbox"]')
        out.append('shape = SubResource("CylinderShape3D_barrel_hurtbox")')
        out.append('')
        out.append(f'[node name="SolidCollider" type="StaticBody3D" parent="Courtyard/Props/{bname}"]')
        out.append('collision_layer = 1')
        out.append('collision_mask = 1')
        out.append('')
        out.append(f'[node name="CollisionShape3D" type="CollisionShape3D" parent="Courtyard/Props/{bname}/SolidCollider"]')
        out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.7, 0)')
        out.append('shape = SubResource("CylinderShape3D_barrel_solid")')
        out.append('')

    # Static Colliders for Floor and Outer Boundaries
    out.append('[node name="StaticColliders" type="StaticBody3D" parent="Courtyard"]')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('')
    # Ground floor collision
    out.append('[node name="CollisionFloor" type="CollisionShape3D" parent="Courtyard/StaticColliders"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.5, -2)')
    out.append('shape = SubResource("BoxShape_floor")')
    out.append('')
    # Boundary walls collisions
    # North Treasure Wall
    out.append('[node name="Collision_N_Treasure" type="CollisionShape3D" parent="Courtyard/StaticColliders"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, -18.8)')
    out.append('shape = SubResource("BoxShape_wall_thick")')
    out.append('')
    # West Boundary
    out.append('[node name="Collision_W_Boundary" type="CollisionShape3D" parent="Courtyard/StaticColliders"]')
    out.append('transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, -22.8, 2, 0)')
    out.append('shape = SubResource("BoxShape_wall_thick")')
    out.append('')
    # East Boundary
    out.append('[node name="Collision_E_Boundary" type="CollisionShape3D" parent="Courtyard/StaticColliders"]')
    out.append('transform = Transform3D(0, 0, 1, 0, 1, 0, -1, 0, 0, 22.8, 2, 2)')
    out.append('shape = SubResource("BoxShape_wall_thick")')
    out.append('')
    # South Boundary
    out.append('[node name="Collision_S_Boundary" type="CollisionShape3D" parent="Courtyard/StaticColliders"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2, 10.8)')
    out.append('shape = SubResource("BoxShape_wall_thick")')
    out.append('')

    # Atmospheric Particles
    out.append('[node name="AtmosphericParticles" type="CPUParticles3D" parent="Courtyard"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, -2)')
    out.append('cast_shadow = 0')
    out.append('amount = 35')
    out.append('lifetime = 6.0')
    out.append('mesh = SubResource("Mesh_DustMote")')
    out.append('emission_shape = 3')
    out.append('emission_box_extents = Vector3(20, 3.5, 16)')
    out.append('direction = Vector3(0.1, -0.2, 0.1)')
    out.append('spread = 40.0')
    out.append('gravity = Vector3(0, -0.05, 0)')
    out.append('initial_velocity_min = 0.1')
    out.append('initial_velocity_max = 0.4')
    out.append('')

    # Player
    out.append('[node name="Player" type="CharacterBody3D" parent="." node_paths=PackedStringArray("model_root", "sword_hitbox")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 5.0)')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('script = ExtResource("3_ply")')
    out.append('model_root = NodePath("Knight")')
    out.append('sword_hitbox = NodePath("Knight/SwordHitbox")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Player"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)')
    out.append('shape = SubResource("CapsuleShape3D_player")')
    out.append('')
    out.append('[node name="Knight" parent="Player" instance=ExtResource("char_knight")]')
    out.append('transform = Transform3D(1.25, 0, 0, 0, 1.25, 0, 0, 0, 1.25, 0, 0, 0)')
    out.append('')
    out.append('[node name="SwordHitbox" type="Area3D" parent="Player/Knight"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.7, 0.85)')
    out.append('monitoring = false')
    out.append('monitorable = false')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Player/Knight/SwordHitbox"]')
    out.append('shape = SubResource("BoxShape3D_hitbox")')
    out.append('')

    # HD2D Camera
    out.append('[node name="HD2DCamera" type="Camera3D" parent="." node_paths=PackedStringArray("target")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 0.848048, 0.529919, 0, -0.529919, 0.848048, 0, 9.5, 16)')
    out.append('attributes = ExtResource("cam_attr")')
    out.append('current = true')
    out.append('fov = 36.0')
    out.append('script = ExtResource("2_cam")')
    out.append('target = NodePath("../Player")')
    out.append('')

    # NPC Eldrin (In his mystical Sanctuary Wing)
    out.append('[node name="NPC_Eldrin" type="StaticBody3D" parent="." node_paths=PackedStringArray("model_root", "groq_client", "interactable")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 16.0, 0.05, 0.0)')
    out.append('script = ExtResource("script_eldrin")')
    out.append('model_root = NodePath("Mage")')
    out.append('groq_client = NodePath("GroqDialogueClient")')
    out.append('interactable = NodePath("InteractableArea")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="NPC_Eldrin"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)')
    out.append('shape = SubResource("BoxShape3D_npc")')
    out.append('')
    out.append('[node name="Mage" parent="NPC_Eldrin" instance=ExtResource("char_mage")]')
    out.append('transform = Transform3D(1.02394, 0, 0.71697, 0, 1.25, 0, -0.71697, 0, 1.02394, 0, 0, 0)')
    out.append('')
    out.append('[node name="InteractableArea" type="Area3D" parent="NPC_Eldrin"]')
    out.append('script = ExtResource("script_interactable")')
    out.append('prompt_text = "[E] Parler à Maître Eldrin"')
    out.append('prompt_offset = Vector3(0, 2.1, 0)')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="NPC_Eldrin/InteractableArea"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)')
    out.append('shape = SubResource("CylinderShape_interact")')
    out.append('')
    out.append('[node name="GroqDialogueClient" type="Node" parent="NPC_Eldrin"]')
    out.append('script = ExtResource("4_ai")')
    out.append('chest_node = NodePath("../../Courtyard/Props/Chest_Gold")')
    out.append('')

    # Dialogue Box
    out.append('[node name="DialogueBox" type="CanvasLayer" parent="."]')
    out.append('script = ExtResource("script_dialogue")')
    out.append('')

    # RPG HUD
    out.append('[node name="RPGHUD" type="CanvasLayer" parent="."]')
    out.append('script = ExtResource("script_rpg_hud")')
    out.append('')

    # =========================================================================
    # LES 4 ENNEMIS SQUELETTES DU DONJON
    # =========================================================================

    # Ennemi 1 : Skeleton_Warrior dans la Grande Nef Centrale
    out.append('[node name="Enemy_Skeleton_Warrior" type="CharacterBody3D" parent="." node_paths=PackedStringArray("model_root", "player_target")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.0, 0.05, 0.0)')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('script = ExtResource("script_skeleton")')
    out.append('skeleton_type = 0') # WARRIOR
    out.append('max_health = 3')
    out.append('patrol_distance = 4.0')
    out.append('model_root = NodePath("Skeleton_Warrior")')
    out.append('player_target = NodePath("../Player")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Enemy_Skeleton_Warrior"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)')
    out.append('shape = SubResource("CapsuleShape3D_player")')
    out.append('')
    out.append('[node name="Skeleton_Warrior" parent="Enemy_Skeleton_Warrior" instance=ExtResource("char_skeleton")]')
    out.append('transform = Transform3D(1.25, 0, 0, 0, 1.25, 0, 0, 0, 1.25, 0, 0, 0)')
    out.append('')

    # Ennemi 2 : Skeleton_Rogue véloce gardant l'entrée Nord de la Crypte Royale
    out.append('[node name="Enemy_Skeleton_Rogue" type="CharacterBody3D" parent="." node_paths=PackedStringArray("model_root", "player_target")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.0, 0.05, -6.0)')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('script = ExtResource("script_skeleton")')
    out.append('skeleton_type = 1') # ROGUE
    out.append('max_health = 2')
    out.append('walk_speed = 2.4')
    out.append('chase_speed = 4.2')
    out.append('patrol_distance = 3.5')
    out.append('model_root = NodePath("Skeleton_Rogue")')
    out.append('player_target = NodePath("../Player")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Enemy_Skeleton_Rogue"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)')
    out.append('shape = SubResource("CapsuleShape3D_player")')
    out.append('')
    out.append('[node name="Skeleton_Rogue" parent="Enemy_Skeleton_Rogue" instance=ExtResource("char_skeleton_rogue")]')
    out.append('transform = Transform3D(1.25, 0, 0, 0, 1.25, 0, 0, 0, 1.25, 0, 0, 0)')
    out.append('')

    # Ennemi 3 : Skeleton_Mage embusqué dans l'Aile Ouest (Ruines) attaquant à distance
    out.append('[node name="Enemy_Skeleton_Mage" type="CharacterBody3D" parent="." node_paths=PackedStringArray("model_root", "player_target")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -14.0, 0.05, -3.0)')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('script = ExtResource("script_skeleton")')
    out.append('skeleton_type = 2') # MAGE
    out.append('max_health = 3')
    out.append('walk_speed = 1.5')
    out.append('chase_speed = 2.4')
    out.append('attack_range = 6.5')
    out.append('detection_range = 9.0')
    out.append('model_root = NodePath("Skeleton_Mage")')
    out.append('player_target = NodePath("../Player")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Enemy_Skeleton_Mage"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)')
    out.append('shape = SubResource("CapsuleShape3D_player")')
    out.append('')
    out.append('[node name="Skeleton_Mage" parent="Enemy_Skeleton_Mage" instance=ExtResource("char_skeleton_mage")]')
    out.append('transform = Transform3D(1.2, 0, 0, 0, 1.2, 0, 0, 0, 1.2, 0, 0, 0)')
    out.append('')

    # Ennemi 4 : Skeleton_Minion rôdant près du piège dans les Ruines de l'Ouest
    out.append('[node name="Enemy_Skeleton_Minion" type="CharacterBody3D" parent="." node_paths=PackedStringArray("model_root", "player_target")]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -17.0, 0.05, 4.0)')
    out.append('collision_layer = 1')
    out.append('collision_mask = 1')
    out.append('script = ExtResource("script_skeleton")')
    out.append('skeleton_type = 3') # MINION
    out.append('max_health = 2')
    out.append('walk_speed = 2.2')
    out.append('chase_speed = 3.8')
    out.append('patrol_distance = 3.5')
    out.append('model_root = NodePath("Skeleton_Minion")')
    out.append('player_target = NodePath("../Player")')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Enemy_Skeleton_Minion"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.85, 0)')
    out.append('shape = SubResource("CapsuleShape3D_player")')
    out.append('')
    out.append('[node name="Skeleton_Minion" parent="Enemy_Skeleton_Minion" instance=ExtResource("char_skeleton_minion")]')
    out.append('transform = Transform3D(1.15, 0, 0, 0, 1.15, 0, 0, 0, 1.15, 0, 0, 0)')
    out.append('')

    # =========================================================================
    # ZONES DE DÉCOUVERTE ET BANDEAUX DE LIEUX
    # =========================================================================
    out.append('[node name="Zones" type="Node3D" parent="."]')
    out.append('')

    # 1. Grande Nef d'Armes
    out.append('[node name="Zone_GrandHall" type="Area3D" parent="Zones"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, 2)')
    out.append('collision_layer = 0')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Zones/Zone_GrandHall"]')
    out.append('shape = SubResource("BoxShape_Zone_GrandHall")')
    out.append('')

    # 2. Crypte Royale du Trésor
    out.append('[node name="Zone_Treasure" type="Area3D" parent="Zones"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, -13)')
    out.append('collision_layer = 0')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Zones/Zone_Treasure"]')
    out.append('shape = SubResource("BoxShape_Zone_Treasure")')
    out.append('')

    # 3. Aile des Ruines
    out.append('[node name="Zone_WestRuins" type="Area3D" parent="Zones"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -16, 3, 0)')
    out.append('collision_layer = 0')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Zones/Zone_WestRuins"]')
    out.append('shape = SubResource("BoxShape_Zone_WestRuins")')
    out.append('')

    # 4. Sanctuaire d'Eldrin
    out.append('[node name="Zone_Sanctuary" type="Area3D" parent="Zones"]')
    out.append('transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 16, 3, 1)')
    out.append('collision_layer = 0')
    out.append('collision_mask = 1')
    out.append('')
    out.append('[node name="CollisionShape3D" type="CollisionShape3D" parent="Zones/Zone_Sanctuary"]')
    out.append('shape = SubResource("BoxShape_Zone_Sanctuary")')
    out.append('')

    content = '\n'.join(out)
    with open('scenes/main_hd2d_scene.tscn', 'w', encoding='utf-8') as f:
        f.write(content)
        
    print(f"Generated expanded crypt with {len(floor_tiles)} floor tiles, {len(walls)} walls (all collidable), {len(pillars)} pillars (all collidable), chest & stairs collidable, 4 skeleton archetypes, and 4 zone triggers!")

if __name__ == '__main__':
    generate_scene()
