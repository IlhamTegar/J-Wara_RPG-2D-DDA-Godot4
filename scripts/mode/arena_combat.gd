extends Node2D

@export var enemy_melee_scene: PackedScene
@export var enemy_ranged_scene: PackedScene
@export var boss_general_scene: PackedScene
@export var boss_shaman_scene: PackedScene
@export var boss_king_scene: PackedScene

# UI Layer Controls
@onready var victory_layer: Control = $UI_Layer/Victory_Layer
@onready var death_layer: Control = $UI_Layer/Death_Layer
@onready var reward_label: Label = $UI_Layer/Victory_Layer/Victory_Panel/Reward_Label

@onready var back_safezone_btn: Button = $UI_Layer/Victory_Layer/Victory_Panel/BackSafeZone_Button
@onready var main_menu_btn: Button = $UI_Layer/Death_Layer/Death_Panel/MainMenu_Button

@onready var tutorial_panel_combat: Panel = $UI_Layer/TutorialPanelCombat
@onready var judul_label: Label = $UI_Layer/TutorialPanelCombat/JudulLabel
@onready var tutorial_texture: TextureRect = $UI_Layer/TutorialPanelCombat/TutorialTexture
@onready var deskripsi_label: Label = $UI_Layer/TutorialPanelCombat/DeskripsiLabel
@onready var selanjutnya_btn: Button = $UI_Layer/TutorialPanelCombat/SelanjutnyaButton
@onready var tutuptuto_btn: Button = $UI_Layer/TutorialPanelCombat/TutupTutoButton

# --- DATA MATERI TUTORIAL COMBAT STEP-BY-STEP ---
var combat_steps: Array = [
	{
		"judul": "Move atau Bergerak",
		"deskripsi": "Tekan tombol W/A/S/D untuk menggerakkan karakter.",
		"gambar": "res://assets/images/tutorial/combat/tuto-walk.png"
	},
	{
		"judul": "MEKANIK KOMBO PEDANG",
		"deskripsi": "Tekan Klik Kiri Mouse (atau tombol serang) secara beruntun untuk memicu kombinasi serangan Attack 1 -> Attack 2. Perhatikan timing agar kombo tidak putus!",
		"gambar": "res://assets/images/tutorial/combat/tuto-attack.png"
	},
	{
		"judul": "TAKTIK PARRY (TANGKISAN)",
		"deskripsi": "Tekan tombol spasi (atau tombol parry) tepat sebelum gada musuh mengenai tubuhmu. Parry yang sukses akan mementalkan musuh dan membuatnya pusing (stun) selama 1.5 detik!",
		"gambar": "res://assets/images/tutorial/combat/tuto-parry.png"
	},
	{
		"judul": "DASH EVASI & CANCEL ATTACK",
		"deskripsi": "Gunakan Klik Kanan Mouse (atau tombol dodge) + WASD untuk dash kedepan dan menghindari serangan atau proyektil panah. Kamu juga bisa menekan Dash dan tombol serang untuk mengeluarkan dash-attack atau kamu bisa saat menekan serang lalu dash untuk membatalkan animasi tebasan!",
		"gambar": "res://assets/images/tutorial/combat/tuto-dash.png"
	},
	{
		"judul": "BUKA TAS",
		"deskripsi": "Tekan B untuk memunculkan inventory, lalu pilih item yang ingin kamu gunakan antara potion untuk memulihkan hp atau menggunakan scroll buff untuk menambahkan stats kamu sementara.",
		"gambar": "res://assets/images/tutorial/combat/tuto-bag.png"
	}
]

var current_combat_step: int = 0

@onready var pause_menu = $PauseMenu
var spawner_nodes: Array = []

var micro_dda_timer : float = 0.0
var micro_dda_interval : float = 15.0

var current_wave: int = 1
var enemies_killed_in_wave: int = 0
var total_enemies_in_arena: int = 0
var is_wave_active: bool = false
var boss_spawned: bool = false
var boss_defeated: bool = false
var is_spawn_stopped: bool = false

var melee_killed_count: int = 0
var ranged_killed_count: int = 0

var wave_timer: float = 0.0
var spawn_cooldown: float = 3.0
var base_spawn_cooldown: float = 3.0
var time_since_last_spawn: float = 0.0

func _ready() -> void:
	GlobalGameManager.is_in_safezone = false
	
	# 🛠️ FIX UTAMA: Ganti fungsi lama dengan dua fungsi reset baru yang sudah dipisah
	GlobalGameManager.reset_data_mikro_saja()
	GlobalGameManager.reset_data_makro_saja()
	
	add_to_group("arena_combat")
	
	# Amankan mode proses agar UI mengabaikan pembekuan pause game
	if has_node("UI_Layer"): $UI_Layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if victory_layer: victory_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if death_layer: death_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if tutorial_panel_combat: tutorial_panel_combat.process_mode = Node.PROCESS_MODE_ALWAYS
	if selanjutnya_btn: selanjutnya_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	if tutuptuto_btn: tutuptuto_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var s1 = get_node_or_null("spawner")
	var s2 = get_node_or_null("spawner2")
	if s1: spawner_nodes.append(s1)
	if s2: spawner_nodes.append(s2)
	
	if spawner_nodes.size() == 0:
		spawner_nodes.append(self)
		print("[WARNING] Node spawner tidak ditemukan! Musuh spawn di koordinat root.")
		
	if "current_wave" in GlobalGameManager:
		current_wave = GlobalGameManager.current_wave
		
	print("Arena Combat Dimulai - Wave: ", current_wave)
	_mulai_wave(current_wave)
	
	if victory_layer: victory_layer.visible = false
	if death_layer: death_layer.visible = false
	
	# 🛠️ FIX BUG 3: Dipanggil via call_deferred agar siklus render frame pertama selesai 
	# dan tidak menyebabkan freeze saat tree dipause langsung di fungsi _ready.
	call_deferred("_ready_tutorial_check")
	
	if not back_safezone_btn.pressed.is_connected(_on_back_safezone_pressed):
		back_safezone_btn.pressed.connect(_on_back_safezone_pressed)
		
	if not main_menu_btn.pressed.is_connected(_on_main_menu_pressed):
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _process(delta: float) -> void:
	# 🛠️ FIX BUG 2: Secara aktif mendeteksi status HP Player. Jika mati (HP <= 0), picu death_layer.
	var player_node = get_tree().get_first_node_in_group("player_group")
	if player_node and player_node.current_health <= 0:
		if death_layer and not death_layer.visible:
			memicu_defeated()
		return

	if not is_wave_active: return
	
	micro_dda_timer += delta
	if micro_dda_timer >= micro_dda_interval:
		_pemicu_dda_mikro()
		micro_dda_timer = 0.0

	if not is_spawn_stopped:
		time_since_last_spawn += delta
		if time_since_last_spawn >= spawn_cooldown:
			time_since_last_spawn = 0.0
			_kontrol_pembatasan_spawn()

	if current_wave == 1 or current_wave == 2:
		wave_timer -= delta
		var target_kill = 50 if current_wave == 1 else 100
		
		if wave_timer <= 0.0 or enemies_killed_in_wave >= target_kill:
			if not is_spawn_stopped:
				is_spawn_stopped = true
				print("[SYSTEM] Batasan waktu/kill tercapai! Spawner dikunci mati. Bersihkan sisa musuh!")
		
		if is_spawn_stopped and total_enemies_in_arena <= 0:
			_selesaikan_wave()
			
	elif current_wave >= 3 and current_wave <= 5:
		if wave_timer > 0.0 and not boss_spawned:
			wave_timer -= delta
			if wave_timer <= 0.0:
				_spawn_boss_sesuai_wave(current_wave)
		# 🛠️ FIX BUG 1 (Safety Net): Jika boss sudah muncul, cek keberadaannya secara real-time.
		# Ini mencegah stuck apabila signal kematian boss tidak terkirim/terlewat.
		elif boss_spawned and not boss_defeated:
			var bos_node = find_child("BOS_UTAMA", true, false)
			if not bos_node or bos_node.is_queued_for_deletion() or ("current_health" in bos_node and bos_node.current_health <= 0):
				_proses_kematian_boss()

func _pemicu_dda_mikro() -> void:
	var player_node = get_tree().get_first_node_in_group("player_group")
	if player_node and GlobalGameManager.has_method("hitung_fuzzy_mikro"):
		var hp_percent = float(player_node.current_health) / float(player_node.max_health)
		GlobalGameManager.hitung_fuzzy_mikro(hp_percent)
		spawn_cooldown = base_spawn_cooldown * GlobalGameManager.mikro_spawn_cooldown_modifier
	print("[SYSTEM] DDA Mikro melakukan penyesuaian intensitas pertempuran...")

func _mulai_wave(wave_num: int) -> void:
	is_wave_active = true
	boss_spawned = false
	boss_defeated = false
	is_spawn_stopped = false
	enemies_killed_in_wave = 0
	total_enemies_in_arena = 0
	time_since_last_spawn = 0.0
	micro_dda_timer = 0.0
	
	melee_killed_count = 0
	ranged_killed_count = 0
	
	print("[SYSTEM] Memulai Pertempuran Wave: ", wave_num)
	
	if wave_num == 1:
		wave_timer = 90.0
		base_spawn_cooldown = 4.0
	elif wave_num == 2:
		wave_timer = 120.0
		base_spawn_cooldown = 3.0
	else:
		wave_timer = 30.0
		base_spawn_cooldown = 3.5
	spawn_cooldown = base_spawn_cooldown

func _kontrol_pembatasan_spawn() -> void:
	var max_on_screen = GlobalGameManager.spawner_jumlah_musuh
	
	if current_wave == 1 or current_wave == 2:
		if total_enemies_in_arena < max_on_screen:
			_spawn_kroco_biasa()
			
	elif current_wave >= 3:
		if not boss_spawned and total_enemies_in_arena < 5:
			_spawn_kroco_biasa()
		elif boss_spawned and not boss_defeated and total_enemies_in_arena < max_on_screen:
			_spawn_kroco_biasa()

func _spawn_kroco_biasa() -> void:
	if spawner_nodes.size() == 0: return
	var titik_acak = spawner_nodes[randi() % spawner_nodes.size()]
	if titik_acak == null: return
	
	var scene_dipilih = enemy_melee_scene if randf() > 0.3 else enemy_ranged_scene
	if scene_dipilih == null: return
	
	var enemy_instansi = scene_dipilih.instantiate()
	var final_hp_mod = GlobalGameManager.enemy_hp_multiplier * GlobalGameManager.macro_dda_modifier
	enemy_instansi.max_health = enemy_instansi.max_health * final_hp_mod
	
	enemy_instansi.global_position = titik_acak.global_position
	add_child(enemy_instansi)
	total_enemies_in_arena += 1

func _spawn_boss_sesuai_wave(wave_num: int) -> void:
	boss_spawned = true
	var titik_spawn = spawner_nodes[0]
	var boss_scene: PackedScene = null
	
	if wave_num == 3: boss_scene = boss_general_scene
	elif wave_num == 4: boss_scene = boss_shaman_scene
	elif wave_num == 5: boss_scene = boss_king_scene
	
	if boss_scene == null: return
		
	var boss_instansi = boss_scene.instantiate()
	boss_instansi.max_health = boss_instansi.max_health * GlobalGameManager.boss_hp_multiplier
	boss_instansi.global_position = titik_spawn.global_position
	boss_instansi.name = "BOS_UTAMA"
	
	add_child(boss_instansi)
	total_enemies_in_arena += 1
	print("[BOSS] Peringatan! Bos Wave ", wave_num, " telah memasuki arena!")

func _on_enemy_died(tipe_musuh: int) -> void:
	total_enemies_in_arena -= 1
	enemies_killed_in_wave += 1
	
	if tipe_musuh == 1: melee_killed_count += 1
	elif tipe_musuh == 2: ranged_killed_count += 1
	
	if current_wave >= 3 and boss_spawned and not boss_defeated:
		var bos_node = find_child("BOS_UTAMA", true, false)
		# 🛠️ FIX BUG 1: Deteksi tipe_musuh boss (di luar 1 & 2) atau kondisi instansi node
		if tipe_musuh > 2 or not bos_node or bos_node.is_queued_for_deletion() or ("current_health" in bos_node and bos_node.current_health <= 0): 
			_proses_kematian_boss()
	SoundManager.play_sfx("enemy_hurt")

# 🛠️ Fungsi pembantu baru untuk merestrukturisasi penyelesaian wave boss agar bersih
func _proses_kematian_boss() -> void:
	boss_defeated = true
	is_spawn_stopped = true
	print("[BOSS] Bos berhasil dikalahkan! Bersihkan arena!")
	_bersihkan_sisa_kroco()
	_selesaikan_wave()

func _selesaikan_wave() -> void:
	is_wave_active = false
	print("[SYSTEM] Wave ", current_wave, " SELESAI Sempurna!")
	if GlobalGameManager.has_method("hitung_fuzzy_makro"):
		GlobalGameManager.hitung_fuzzy_makro()
	memicu_victory()

func _bersihkan_sisa_kroco() -> void:
	var sisa_musuh = get_tree().get_nodes_in_group("enemy_group")
	for enemy in sisa_musuh:
		if is_instance_valid(enemy) and enemy.name != "BOS_UTAMA":
			enemy.queue_free()
	total_enemies_in_arena = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_instance_valid(pause_menu):
			if get_tree().paused:
				pause_menu.close_pause()
			else:
				pause_menu.open_pause()

func memicu_victory() -> void:
	get_tree().paused = true
	if victory_layer: victory_layer.visible = true
	if back_safezone_btn: back_safezone_btn.grab_focus()
	
	var wave_label_node = get_node_or_null("UI_Layer/Victory_Layer/Victory_Panel/Wave_Label")
	if wave_label_node:
		wave_label_node.text = "Wave " + str(GlobalGameManager.current_wave) + " Selesai!"
	
	var total_reward = (melee_killed_count * 10) + (ranged_killed_count * 15)
	if current_wave >= 3: total_reward += 50
	
	# 🛠️ FIX OPSI A: Hapus atau beri tanda pagar (#) pada baris di bawah ini agar koin tidak double!
	# GlobalGameManager.total_koin += total_reward
		
	if reward_label != null:
		reward_label.text = "Hadiah Koin: +" + str(total_reward)

func memicu_defeated() -> void:
	get_tree().paused = true
	if death_layer: death_layer.visible = true
	if main_menu_btn: main_menu_btn.grab_focus()

func _on_back_safezone_pressed() -> void:
	get_tree().paused = false
	
	# Di dalam arena_combat.gd bagian check wave 5 kemarin, ubah jalurnya ke credits:
	if current_wave >= 5:
		GlobalGameManager.is_game_cleared_epilog = true
		# 🛠️ GANTI DI SINI: Alihkan jalan ke credits_screen terlebih dahulu, bukan langsung ke main menu
		GlobalGameManager.next_scene_path = "res://scenes/ui/credits_screen.tscn"
		get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")
		return
		
	GlobalGameManager.save_ke_slot(GlobalGameManager.slot_aktif_sekarang) 
	
	GlobalGameManager.current_wave += 1
	GlobalGameManager.is_in_safezone = true
	GlobalGameManager.next_scene_path = "res://scenes/mode/safezone.tscn"
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	GlobalGameManager.next_scene_path = "res://scenes/main_menu/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _ready_tutorial_check() -> void:
	if tutorial_panel_combat and GlobalGameManager.belum_tutorial_combat and current_wave == 1:
		_mulai_tutorial_combat()
	else:
		if tutorial_panel_combat: tutorial_panel_combat.hide()

func _mulai_tutorial_combat() -> void:
	current_combat_step = 0
	get_tree().paused = true
	if tutorial_panel_combat: tutorial_panel_combat.show()
	
	if not selanjutnya_btn.pressed.is_connected(_on_selanjutnya_combat_pressed):
		selanjutnya_btn.pressed.connect(_on_selanjutnya_combat_pressed)
	if not tutuptuto_btn.pressed.is_connected(_on_tutup_combat_pressed):
		tutuptuto_btn.pressed.connect(_on_tutup_combat_pressed)
		
	_tampilkan_halaman_combat(current_combat_step)

func _tampilkan_halaman_combat(index: int) -> void:
	var data = combat_steps[index]
	judul_label.text = data["judul"]
	deskripsi_label.text = data["deskripsi"]
	
	if ResourceLoader.exists(data["gambar"]):
		tutorial_texture.texture = load(data["gambar"])
	else:
		tutorial_texture.texture = null
		
	if index == combat_steps.size() - 1:
		selanjutnya_btn.hide()     
		tutuptuto_btn.show()       
		tutuptuto_btn.call_deferred("grab_focus")  
	else:
		selanjutnya_btn.show()     
		tutuptuto_btn.hide()       
		selanjutnya_btn.call_deferred("grab_focus")

func _on_selanjutnya_combat_pressed() -> void:
	current_combat_step += 1
	if current_combat_step < combat_steps.size():
		_tampilkan_halaman_combat(current_combat_step)

func _on_tutup_combat_pressed() -> void:
	if tutorial_panel_combat: tutorial_panel_combat.hide()
	get_tree().paused = false
	GlobalGameManager.belum_tutorial_combat = false
	print("[📘 TUTORIAL COMBAT] Selesai! Wave 1 resmi dilepas.")

func perbarui_hp_bar_boss(hp_sekarang: float, hp_maksimal: float, _nama_boss: String) -> void:
	var hud = get_node_or_null("HUD_Layer")
	if hud:
		var boss_bar = hud.get_node_or_null("Boss_HP_Bar")
		if boss_bar is TextureProgressBar:
			if not boss_bar.visible: boss_bar.visible = true
			boss_bar.max_value = hp_maksimal
			boss_bar.value = hp_sekarang
			if hp_sekarang <= 0: boss_bar.visible = false
