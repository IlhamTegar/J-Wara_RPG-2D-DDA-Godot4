extends CanvasLayer

@onready var panel_dashboard: Panel = $DashboardPanel
@onready var status_wilayah_label: Label = $DashboardPanel/StatusWilayahLabel
@onready var wave_label: Label = $DashboardPanel/WaveLabel

# --- NODE TAMPILAN MAKRO (FIX JALUR PATH) ---
@onready var fuzzy_macro_label: Label = $DashboardPanel/KelompokMakro/FuzzyMacroLabel
@onready var enemy_hp_label: Label = $DashboardPanel/KelompokMakro/EnemyHPLabel
@onready var boss_hp_label: Label = $DashboardPanel/KelompokMakro/BossHPLabel
@onready var max_enemy_label: Label = $DashboardPanel/KelompokMakro/MaxEnemyLabel

# --- NODE TAMPILAN MIKRO (FIX JALUR PATH + LABEL BARU) ---
@onready var fuzzy_micro_label: Label = $DashboardPanel/KelompokMikro/FuzzyMicroLabel
@onready var spawn_cooldown_label: Label = $DashboardPanel/KelompokMikro/SpawnCooldownLabel
@onready var tempo_spawn_label: Label = $DashboardPanel/KelompokMikro/TempoSpawnLabel
@onready var estimasi_hp_label: Label = $DashboardPanel/KelompokMikro/EstimasiHPLabel
@onready var kapasitas_arena_label: Label = $DashboardPanel/KelompokMikro/KapasitasArenaLabel


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		visible = !visible
		panel_dashboard.visible = visible
		print("[RESEARCH] Visibilitas panel debug: ", visible)


func _process(_delta: float) -> void:
	if visible:
		_perbarui_data_dashboard()


func _perbarui_data_dashboard() -> void:
	wave_label.text = "Wave Saat Ini: " + str(GlobalGameManager.current_wave)
	
	if GlobalGameManager.is_in_safezone:
		status_wilayah_label.text = "Wilayah: SAFEZONE (Zona Aman)"
		
		$DashboardPanel/KelompokMakro.show()
		$DashboardPanel/KelompokMikro.hide()
		
		# 🧠 UPDATE MAKRO (SUGENO CORNER):
		fuzzy_macro_label.text = "Fuzzy Makro (Sugeno WA): " + str(snapped(GlobalGameManager.macro_dda_modifier, 0.01)) + "x"
		enemy_hp_label.text = "Pengali HP Kroco Global: " + str(snapped(GlobalGameManager.enemy_hp_multiplier * GlobalGameManager.macro_dda_modifier, 0.01)) + "x"
		boss_hp_label.text = "Pengali HP Boss: " + str(snapped(GlobalGameManager.boss_hp_multiplier, 0.01)) + "x"
		
		# 🛠️ FIX SINKRONISASI: Mengubah target 15 menjadi batas asli DDA (7 musuh) agar sama dengan arena
		max_enemy_label.text = "Batas Musuh di Layar: " + str(GlobalGameManager.spawner_jumlah_musuh) + " Musuh"
		
	else:
		status_wilayah_label.text = "Wilayah: ARENA COMBAT (Pertempuran)"
		
		$DashboardPanel/KelompokMakro.hide()
		$DashboardPanel/KelompokMikro.show()
		
		# Ambil basis data runtime dari arena combat
		var arena = get_tree().get_first_node_in_group("arena_combat")
		var cooldown_detik: float = 0.0
		if arena:
			cooldown_detik = arena.spawn_cooldown

		var basis_hp_kroco_melee: float = 40.0
		var hp_real_kroco = basis_hp_kroco_melee * GlobalGameManager.enemy_hp_multiplier * GlobalGameManager.macro_dda_modifier
		
		# 🧠 UPDATE MIKRO (MAMDANI COA CORNER):
		var status_realtime = "SEDANG"
		if GlobalGameManager.mikro_crisp_kesulitan < 0.4:
			status_realtime = "MUDAH"
		elif GlobalGameManager.mikro_crisp_kesulitan > 0.6:
			status_realtime = "SULIT"
			
		fuzzy_micro_label.text = "Fuzzy Mikro (Mamdani COA): " + str(snapped(GlobalGameManager.mikro_crisp_kesulitan, 0.01)) + " (" + status_realtime + ")"
		
		# Komponen Informasi Realtime Lapangan
		spawn_cooldown_label.text = "Pengali Cooldown: " + str(snapped(GlobalGameManager.mikro_spawn_cooldown_modifier, 0.01)) + "x"
		tempo_spawn_label.text = "Tempo Spawn Nyata: " + str(snapped(cooldown_detik, 0.1)) + " detik/musuh"
		estimasi_hp_label.text = "Estimasi HP Kroco Baru: " + str(snapped(hp_real_kroco, 1.0)) + " HP"
		kapasitas_arena_label.text = "Kapasitas Maks Arena: " + str(GlobalGameManager.spawner_jumlah_musuh) + " Musuh"
