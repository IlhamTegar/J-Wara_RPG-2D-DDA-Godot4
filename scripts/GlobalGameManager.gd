extends Node

const AUDIO_SAVE_PATH = "user://audio_settings.cfg"

# --- DATA PLAYER DASAR & PROGRES ---
var player_name: String = ""
var player_points: int = 0
var current_wave: int = 1
var is_in_safezone: bool = true
var total_koin: int = 0
var item_dibeli: Array = []
var potion_count: int = 0 
var scroll_count: int = 0
var high_scroll_count: int = 0
var ancient_scroll_count: int = 0

# --- 1. VARIABEL REKAM DATA UNTUK DDA MIKRO (REAL-TIME COMBAT) ---
var mikro_damage_diterima: float = 0.0
var mikro_potion_digunakan: bool = false
var mikro_sukses_parry: int = 0
var mikro_sukses_dodge: int = 0
var mikro_total_serangan_masuk: int = 0 

# --- 2. VARIABEL REKAM DATA UNTUK DDA MAKRO (AKHIR WAVE) ---
var makro_total_hp_berkurang: float = 0.0
var makro_total_potion_wave: int = 0
var makro_usaha_defensif: int = 0
var makro_sukses_defensif: int = 0
var macro_dda_modifier: float = 1.0 

# --- 3. VARIABEL OUTPUT DDA MIKRO (UNTUK MUSUH & SPAWNER) ---
var enemy_hp_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var spawner_jumlah_musuh: int = 7 
var mikro_spawn_cooldown_modifier: float = 1.0
var mikro_crisp_kesulitan: float = 0.5 

# --- 4. CONFIG CONFIG OUTPUT DDA MAKRO (UNTUK BOSS) ---
var wave_total_spawn_target: int = 15
var wave_duration: float = 60.0
var boss_hp_multiplier: float = 1.0
var boss_damage_multiplier: float = 1.0

var enemies_alive : int = 0
var next_scene_path: String = ""
var butuh_cerita_awal: bool = false
var is_player_escaping: bool = false   # Menandai jika player menekan tombol KABUR
var is_game_cleared_epilog: bool = false # Menandai jika player menamatkan wave terakhir
var belum_tutorial_safezone: bool = true
var belum_tutorial_combat: bool = true
var slot_aktif_sekarang: int = 1
var is_inventory_open: bool = false

var kategori_rata_hp_terakhir: String = "Normal"
var kategori_defensif_terakhir: String = "Sedang"
var persentase_defensif_terakhir: float = 0.0

func _ready() -> void:
	muat_setelan_audio_lokal()

func siapkan_game_baru(nama_baru: String) -> void:
	player_name = nama_baru
	current_wave = 1
	macro_dda_modifier = 1.0
	belum_tutorial_safezone = true
	belum_tutorial_combat = true
	total_koin = 50       
	potion_count = 2     
	scroll_count = 0
	high_scroll_count = 0
	ancient_scroll_count = 0
	print("[NEW GAME] Karakter Baru Dibuat!")

# FIX UTAMA: Pemisahan fungsi reset agar data makro tidak terhapus di tengah pertempuran
func reset_data_mikro_saja() -> void:
	mikro_damage_diterima = 0.0
	mikro_potion_digunakan = false
	mikro_sukses_parry = 0
	mikro_sukses_dodge = 0
	mikro_total_serangan_masuk = 0

func reset_data_makro_saja() -> void:
	makro_total_hp_berkurang = 0.0
	makro_total_potion_wave = 0
	makro_usaha_defensif = 0
	makro_sukses_defensif = 0

# ===================================================================
# 🧠 LILIN AKADEMIK: IMPLEMENTASI FUZZY MAMDANI (MIKRO DDA)
# ===================================================================
func hitung_fuzzy_mikro(player_hp_percent: float) -> void:
	print("\n--- [🧠 FUZZY MAMDANI MIKRO START] ---")
	
	# 1. FUZZIFIKASI INPUT 1: HP Player (Kritis, Normal, Aman)
	var mu_hp_kritis = max(0.0, min(1.0, (0.4 - player_hp_percent) / 0.4)) if player_hp_percent <= 0.4 else 0.0
	var mu_hp_normal = 0.0
	if player_hp_percent > 0.2 and player_hp_percent <= 0.5:
		mu_hp_normal = (player_hp_percent - 0.2) / 0.3
	elif player_hp_percent > 0.5 and player_hp_percent < 0.8:
		mu_hp_normal = (0.8 - player_hp_percent) / 0.3
	var mu_hp_aman = max(0.0, min(1.0, (player_hp_percent - 0.6) / 0.4)) if player_hp_percent >= 0.6 else 0.0
	
	# FUZZIFIKASI INPUT 2: Rasio Evasi (Rendah, Tinggi)
	var total_evasi = mikro_sukses_parry + mikro_sukses_dodge
	var rasio_evasi = float(total_evasi) / float(mikro_total_serangan_masuk) if mikro_total_serangan_masuk > 0 else 0.0
	var mu_eva_rendah = max(0.0, min(1.0, (0.6 - rasio_evasi) / 0.6)) if rasio_evasi <= 0.6 else 0.0
	var mu_eva_tinggi = max(0.0, min(1.0, (rasio_evasi - 0.4) / 0.6)) if rasio_evasi >= 0.4 else 0.0
	
	print("Fuzzifikasi -> HP[Kritis:", mu_hp_kritis, ", Normal:", mu_hp_normal, ", Aman:", mu_hp_aman, "]")
	print("Fuzzifikasi -> Evasi[Rendah:", mu_eva_rendah, ", Tinggi:", mu_eva_tinggi, "]")
	
	# 2. INFERENSI RULE (MIN OPERATOR)
	var alpha_r1 = min(mu_hp_kritis, mu_eva_rendah)
	var alpha_r2 = mu_hp_normal
	var alpha_r3 = min(mu_hp_aman, mu_eva_tinggi)
	
	# 3. AGREGASI OUTPUT MAMDANI (MAX OPERATOR)
	var mu_mudah = alpha_r1
	var mu_sedang = alpha_r2
	var mu_sulit = alpha_r3
	
	# 4. DEFUZZIFIKASI MAMDANI (Metode COA / Center of Area Pendekatan Diskrit)
	var pembilang = 0.0
	var penyebut = 0.0
	
	for i in range(1, 11):
		var x = float(i) / 10.0
		var mf_mudah = max(0.0, min(mu_mudah, (0.4 - x) / 0.4)) if x <= 0.4 else 0.0
		var mf_sedang = max(0.0, min(mu_sedang, (x - 0.2)/0.3 if x <= 0.5 else (0.8 - x)/0.3)) if x > 0.2 and x < 0.8 else 0.0
		var mf_sulit = max(0.0, min(mu_sulit, (x - 0.6) / 0.4)) if x >= 0.6 else 0.0
		
		var mu_agregasi = max(mf_mudah, max(mf_sedang, mf_sulit))
		
		pembilang += x * mu_agregasi
		penyebut += mu_agregasi
		
	mikro_crisp_kesulitan = 0.5
	if penyebut > 0:
		mikro_crisp_kesulitan = pembilang / penyebut
		
	print("Defuzzifikasi COA -> Titik Crisp Kesulitan: ", mikro_crisp_kesulitan)
	
	# 5. TRANSFORMASI NILAI CRISP KE MEKANIK GAMEPLAY ENGINE
	if mikro_crisp_kesulitan < 0.4: 
		spawner_jumlah_musuh = 4
		enemy_hp_multiplier = 0.80
		enemy_damage_multiplier = 0.80
		mikro_spawn_cooldown_modifier = 1.5
		print("[DDA Mikro - Mamdani] Hasil: MUDAH (Aman untuk Player)")
	elif mikro_crisp_kesulitan > 0.6: 
		spawner_jumlah_musuh = 8
		enemy_hp_multiplier = 1.25
		enemy_damage_multiplier = 1.20
		mikro_spawn_cooldown_modifier = 0.75
		print("[DDA Mikro - Mamdani] Hasil: SULIT (Intensitas Dinaikkan)")
	else:
		spawner_jumlah_musuh = 6
		enemy_hp_multiplier = 1.0
		enemy_damage_multiplier = 1.0
		mikro_spawn_cooldown_modifier = 1.0
		print("[DDA Mikro - Mamdani] Hasil: SEDANG (Kondisi Stabil)")
		
	# 🛠️ FIX UTAMA: Bersihkan data mikro saja agar data HP berkurang makro tetap utuh
	reset_data_mikro_saja()

# ===================================================================
# 🧠 LILIN AKADEMIK: IMPLEMENTASI FUZZY SUGENO ORDE-0 (MAKRO DDA)
# ===================================================================
func hitung_fuzzy_makro() -> void:
	print("\n=== [🧠 FUZZY SUGENO MAKRO START] ===")
	
	# Batasi maksimal persen_defensif di angka 100.0%
	var persen_defensif = 0.0
	if makro_usaha_defensif > 0:
		persen_defensif = minf(100.0, (float(makro_sukses_defensif) / float(makro_usaha_defensif)) * 100.0)
		
	print("Review Akhir Wave -> HP Berkurang: ", makro_total_hp_berkurang, " | Sukses Defensif: ", persen_defensif, "%")
	
	# 1. FUZZIFIKASI INPUT 1 & 2
	var mu_hp_rendah = max(0.0, min(1.0, (60.0 - makro_total_hp_berkurang) / 60.0)) if makro_total_hp_berkurang <= 60.0 else 0.0
	var mu_hp_tinggi = max(0.0, min(1.0, (makro_total_hp_berkurang - 30.0) / 50.0)) if makro_total_hp_berkurang >= 30.0 else 0.0
	
	var mu_def_buruk = max(0.0, min(1.0, (50.0 - persen_defensif) / 50.0)) if persen_defensif <= 50.0 else 0.0
	var mu_def_bagus = max(0.0, min(1.0, (persen_defensif - 40.0) / 50.0)) if persen_defensif >= 40.0 else 0.0
	
	# 2. INFERENSI RULE SUGENO ORDE-0
	var w1 = min(mu_hp_tinggi, mu_def_buruk)
	var z1 = 0.80
	
	var w2 = min(mu_hp_rendah, mu_def_bagus)
	var z2 = 1.35 # (Atau 1.5 jika menggunakan bobot sulit penuh)
	
	var w3 = min(mu_hp_rendah, mu_def_buruk)
	var z3 = 1.05
	
	# 3. DEFUZZIFIKASI SUGENO (Weighted Average)
	var total_w = w1 + w2 + w3
	var hasil_sugeno = 1.0
	if total_w > 0:
		hasil_sugeno = ((w1 * z1) + (w2 * z2) + (w3 * z3)) / total_w
		
	macro_dda_modifier = hasil_sugeno
	print("Defuzzifikasi Sugeno -> Multiplier Base: ", macro_dda_modifier)
	
	# 4. 🛠️ PENYESUAIAN POIN 4: PERKALIAN SUGENO + PENAMBAHAN MANUAL WAVE
	# Tentukan nilai penambahan manual per wave (misal +2 musuh setiap naik wave)
	var penambahan_manual_wave = (current_wave - 1) * 2 
	
	if macro_dda_modifier < 0.95:
		spawner_jumlah_musuh = int(5 * macro_dda_modifier) + penambahan_manual_wave
		
		# Khusus Wave 3-5 (Boss Challenge), atur target spawn tantangan kroco lebih ringan
		if current_wave >= 3:
			wave_total_spawn_target = int(10 * macro_dda_modifier) + penambahan_manual_wave
			boss_hp_multiplier = 0.80
			boss_damage_multiplier = 0.85
		else:
			wave_total_spawn_target = 10 # Default untuk survival awal
			
		total_koin += 75
		print("[DDA Makro] Dipermudah | Spawner: ", spawner_jumlah_musuh, " | Target Boss Challenge: ", wave_total_spawn_target)
		
	elif macro_dda_modifier > 1.15:
		spawner_jumlah_musuh = int(7 * macro_dda_modifier) + penambahan_manual_wave
		
		# Khusus Wave 3-5 (Boss Challenge), atur target spawn tantangan kroco menjadi sangat agresif
		if current_wave >= 3:
			wave_total_spawn_target = int(22 * macro_dda_modifier) + penambahan_manual_wave
			boss_hp_multiplier = 1.35 * macro_dda_modifier
			boss_damage_multiplier = 1.25 * macro_dda_modifier
		else:
			wave_total_spawn_target = 18
			
		total_koin += 250
		print("[DDA Makro] Diperketat | Spawner: ", spawner_jumlah_musuh, " | Target Boss Challenge: ", wave_total_spawn_target)
		
	else:
		spawner_jumlah_musuh = int(6 * macro_dda_modifier) + penambahan_manual_wave
		
		# Khusus Wave 3-5 (Boss Challenge), atur target spawn tantangan kroco dalam kondisi normal/stabil
		if current_wave >= 3:
			wave_total_spawn_target = int(15 * macro_dda_modifier) + penambahan_manual_wave
			boss_hp_multiplier = 1.05
			boss_damage_multiplier = 1.05
		else:
			wave_total_spawn_target = 15
			
		total_koin += 150
		print("[DDA Makro] Normal | Spawner: ", spawner_jumlah_musuh, " | Target Boss Challenge: ", wave_total_spawn_target)

	if makro_total_hp_berkurang < 25.0:
		kategori_rata_hp_terakhir = "Sehat"
	elif makro_total_hp_berkurang <= 55.0:
		kategori_rata_hp_terakhir = "Sedang"
	else:
		kategori_rata_hp_terakhir = "Kritis"
		
	persentase_defensif_terakhir = persen_defensif
	if persen_defensif >= 70.0:
		kategori_defensif_terakhir = "Baik"
	elif persen_defensif >= 40.0:
		kategori_defensif_terakhir = "Sedang"
	else:
		kategori_defensif_terakhir = "Buruk"

	# Bersihkan data pencatatan makro setelah dihitung
	reset_data_makro_saja()

# ===================================================================
# SISTEM MULTI-SLOT SAVE & LOAD PROGRESS (JSON METHOD)
# ===================================================================
func save_ke_slot(slot_number: int) -> void:
	var path_file = "user://save_slot_" + str(slot_number) + ".save"
	var data_save = {
		"player_name": player_name,                  
		"current_wave": current_wave, 
		"total_koin": total_koin, 
		"player_points": player_points,
		"potion_count": potion_count,         # 🛠️ Disimpan
		"scroll_count": scroll_count,         # 🛠️ Disimpan
		"high_scroll_count": high_scroll_count,      
		"ancient_scroll_count": ancient_scroll_count,  
		"item_dibeli": item_dibeli,
		"macro_dda_modifier": macro_dda_modifier, 
		"belum_tutorial_safezone": belum_tutorial_safezone,
		"belum_tutorial_combat": belum_tutorial_combat
	}
	var file = FileAccess.open(path_file, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(data_save))
		file.close()
		print("[SAVE] Data berhasil disimpan di Slot ", slot_number)

func load_dari_slot(slot_number: int) -> bool:
	var path_file = "user://save_slot_" + str(slot_number) + ".save"
	if not FileAccess.file_exists(path_file): return false
	var file = FileAccess.open(path_file, FileAccess.READ)
	if file:
		var baris_data = file.get_line()
		file.close()
		var json = JSON.new()
		if json.parse(baris_data) == OK:
			var data_termuat = json.get_data()
			player_name = data_termuat.get("player_name", "Tanpa Nama") # 🛠️ SUNTIKKAN INI: Muat nama pemain
			current_wave = int(data_termuat.get("current_wave", 1))
			total_koin = int(data_termuat.get("total_koin", 0))
			player_points = int(data_termuat.get("player_points", 0))
			potion_count = int(data_termuat.get("potion_count", 0))
			scroll_count = int(data_termuat.get("scroll_count", 0))
			high_scroll_count = int(data_termuat.get("high_scroll_count", 0))       
			ancient_scroll_count = int(data_termuat.get("ancient_scroll_count", 0))   
			item_dibeli = data_termuat.get("item_dibeli", [])
			macro_dda_modifier = float(data_termuat.get("macro_dda_modifier", 1.0))
			belum_tutorial_safezone = data_termuat.get("belum_tutorial_safezone", false)
			belum_tutorial_combat = data_termuat.get("belum_tutorial_combat", false)
			return true
	return false

func dapatkan_info_slot(slot_number: int) -> Dictionary:
	var path_file = "user://save_slot_" + str(slot_number) + ".save"
	if not FileAccess.file_exists(path_file): 
		return {"status": "Kosong", "wave": 0, "koin": 0, "nama": "Kosong", "potion": 0, "scroll": 0, "high_scroll": 0, "ancient_scroll": 0}
		
	var file = FileAccess.open(path_file, FileAccess.READ)
	if file:
		var baris_data = file.get_line()
		file.close()
		var json = JSON.new()
		if json.parse(baris_data) == OK:
			var data = json.get_data()
			# 🛠️ Kembalikan seluruh rincian inventori tas beserta data dasarnya
			return {
				"status": "Ada Data", 
				"wave": data.get("current_wave", 1), 
				"koin": data.get("total_koin", 0),
				"nama": data.get("player_name", "Tanpa Nama"),
				"potion": data.get("potion_count", 0),
				"scroll": data.get("scroll_count", 0),
				"high_scroll": data.get("high_scroll_count", 0),
				"ancient_scroll": data.get("ancient_scroll_count", 0)
			}
	return {"status": "Kosong", "wave": 0, "koin": 0, "nama": "Kosong", "potion": 0, "scroll": 0, "high_scroll": 0, "ancient_scroll": 0}

func simpan_setelan_action_audio(bus_name: String, value: float) -> void:
	var config = ConfigFile.new()
	if config.load(AUDIO_SAVE_PATH) == OK: pass
	config.set_value("audio", bus_name, value)
	config.save(AUDIO_SAVE_PATH)
	print("[AUDIO SAVE] Berhasil menyimpan setelan Bus ", bus_name, " = ", value, "%")

func muat_setelan_audio_lokal() -> void:
	var config = ConfigFile.new()
	var err = config.load(AUDIO_SAVE_PATH)
	var list_bus = ["Master", "Music", "SFX"]
	if err == OK:
		for bus in list_bus:
			var bus_idx = AudioServer.get_bus_index(bus)
			if bus_idx != -1:
				var saved_value = config.get_value("audio", bus, 100.0)
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(saved_value / 100.0))
		print("[AUDIO LOAD] Sukses memuat setelan audio.")
	else:
		for bus in list_bus:
			var bus_idx = AudioServer.get_bus_index(bus)
			if bus_idx != -1:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(1.0))
