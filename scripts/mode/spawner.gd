extends Node2D

# --- REFERENSI SCENE ENEMY (Silakan sesuaikan path-nya) ---
@export var enemy_melee_scene: PackedScene
@export var enemy_ranged_scene: PackedScene
@export var boss_general_scene: PackedScene
@export var boss_shaman_scene: PackedScene
@export var boss_king_scene: PackedScene

# --- REFERENSI NODE INTERNAL ---
var spawner_nodes: Array = []

# --- STATUS UTAMA WAVE ---
var current_wave: int = 1
var enemies_killed_in_wave: int = 0
var total_enemies_in_arena: int = 0
var is_wave_active: bool = false
var boss_spawned: bool = false
var boss_defeated: bool = false

# --- TIMER & COUNTER CONFIG ---
var wave_timer: float = 0.0
var spawn_cooldown: float = 3.0
var time_since_last_spawn: float = 0.0

func _ready() -> void:
	# Pastikan status game tahu kita sedang bertarung (bukan di safezone)
	GlobalGameManager.is_in_safezone = false
	# Mencari node spawner secara aman berdasarkan hierarki root arena
	if has_node("spawner"): spawner_nodes.append(get_node("spawner"))
	if has_node("spawner2"): spawner_nodes.append(get_node("spawner2"))
	
	# Jika skrip ini ternyata MENEMPEL LANGSUNG di node 'spawner' itu sendiri,
	# kita daftarkan dirinya sendiri (self) dan spawner saudaranya secara aman:
	if spawner_nodes.size() == 0:
		spawner_nodes.append(self)
		var saudara_spawner = get_parent().get_node_or_null("spawner2")
		if saudara_spawner:
			spawner_nodes.append(saudara_spawner)

	# Load wave awal dari GlobalGameManager atau progress save data
	if "current_wave" in GlobalGameManager:
		current_wave = GlobalGameManager.current_wave
		
	_mulai_wave(current_wave)

func _process(delta: float) -> void:
	if not is_wave_active: return
	
	# --- RUNTIME DATA DDA MIKRO ---
	# Di sini tempat algoritma Fuzzy DDA Mikro kamu membaca data setiap detiknya
	# Contoh: _jalankan_fuzzy_dda_mikro(delta)
	
	# 1. KELOLA TIMING DAN SPONDING MUSUH
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_cooldown:
		time_since_last_spawn = 0.0
		_kontrol_pembatasan_spawn()

	# 2. KELOLA ATURAN BERDASARKAN TIPE WAVE
	if current_wave == 1 or current_wave == 2:
		wave_timer -= delta
		# Cek Kondisi Menang Wave 1 & 2 (Waktu Habis ATAU Target Kill Terpenuhi)
		var target_kill = 50 if current_wave == 1 else 100
		if wave_timer <= 0.0 or enemies_killed_in_wave >= target_kill:
			_selesaikan_wave()
			
	elif current_wave >= 3 and current_wave <= 5:
		# Fase Memunculkan Bos setelah 30 Kroco Mati
		if enemies_killed_in_wave >= 30 and not boss_spawned:
			_spawn_boss_sesuai_wave(current_wave)

# --- FUNGSI MEMULAI WAVE ---
func _mulai_wave(wave_num: int) -> void:
	is_wave_active = true
	boss_spawned = false
	boss_defeated = false
	enemies_killed_in_wave = 0
	total_enemies_in_arena = 0
	time_since_last_spawn = 0.0
	
	print("[SYSTEM] Memulai Pertempuran Wave: ", wave_num)
	
	# Atur Kondisi Awal Berdasarkan Wave
	if wave_num == 1:
		wave_timer = 90.0 # 1 Menit 30 Detik
		spawn_cooldown = 4.0 # Tempo spawn awal agak lambat
	elif wave_num == 2:
		wave_timer = 120.0 # 2 Menit
		spawn_cooldown = 3.0 # Lebih cepat
	else:
		wave_timer = 9999.0 # Wave 3-5 murni berbasis kill boss
		spawn_cooldown = 3.5

# --- LOGIKA KONTROL SPAWNING MUSUH (ANTI-OVERFLOW) ---
func _kontrol_pembatasan_spawn() -> void:
	# Batasi jumlah musuh maksimal yang ada di layar sekaligus agar game tidak lag
	# Nilai max_on_screen ini nantinya bisa dipengaruhi secara dinamis oleh DDA Mikro kamu!
	var max_on_screen = 6 
	
	if current_wave == 1 or current_wave == 2:
		if total_enemies_in_arena < max_on_screen:
			_spawn_kroco_biasa()
			
	elif current_wave >= 3:
		# Sebelum bos muncul, batasi spawn kroco biasa
		if not boss_spawned and total_enemies_in_arena < 5:
			_spawn_kroco_biasa()
		# Setelah bos muncul, kroco tetap spawn terus sebagai gangguan (misal dijaga selalu ada 3 ekor)
		elif boss_spawned and not boss_defeated and total_enemies_in_arena < 4:
			_spawn_kroco_biasa()

# --- FUNGSI SPAWN MUSUH BIASA ---
func _spawn_kroco_biasa() -> void:
	if spawner_nodes.size() == 0: return
	
	# Pilih titik spawn secara acak antara spawner 1 atau spawner 2
	var titik_acak = spawner_nodes[randi() % spawner_nodes.size()]
	
	# Variasi tipe musuh (Melee atau Ranged)
	var scene_dipilih = enemy_melee_scene if randf() > 0.3 else enemy_ranged_scene
	if scene_dipilih == null: return
	
	var enemy_instansi = scene_dipilih.instantiate()
	enemy_instansi.global_position = titik_acak.global_position
	
	# Hubungkan sinyal atau override data jika diperlukan sebelum add_child
	add_child(enemy_instansi)
	total_enemies_in_arena += 1

# --- FUNGSI SPAWN BOS SPESIFIK ---
func _spawn_boss_sesuai_wave(wave_num: int) -> void:
	boss_spawned = true
	var titik_spawn = spawner_nodes[0] # Taruh bos di spawner utama
	var boss_scene: PackedScene = null
	
	if wave_num == 3: boss_scene = boss_general_scene
	elif wave_num == 4: boss_scene = boss_shaman_scene
	elif wave_num == 5: boss_scene = boss_king_scene
	
	if boss_scene == null:
		print("[WARNING] Scene Bos belum dimasukkan di Inspector!")
		return
		
	var boss_instansi = boss_scene.instantiate()
	boss_instansi.global_position = titik_spawn.global_position
	
	# Beri penanda pada nama atau variabel bos agar skrip tahu saat dia mati
	boss_instansi.name = "BOS_UTAMA"
	
	add_child(boss_instansi)
	total_enemies_in_arena += 1
	print("[BOSS] Peringatan! Bos Wave ", wave_num, " telah memasuki arena!")

# --- HOOK UNTUK DIPANGGIL SAAT MUSUH MATI (`enemy.gd`) ---
func _on_enemy_died() -> void:
	total_enemies_in_arena -= 1
	enemies_killed_in_wave += 1
	
	# Cek apakah musuh yang mati itu adalah Bos Utama (Khusus Wave 3-5)
	if current_wave >= 3 and not boss_defeated:
		# Kita cek apakah node bos masih ada di dalam scene tree
		var bos_node = find_child("BOS_UTAMA", true, false)
		if not bos_node or bos_node.is_queued_for_deletion():
			boss_defeated = true
			print("[BOSS] Bos berhasil dikalahkan!")
			_selesaikan_wave()

# --- FUNGSI SELESAI & EVALUASI BALIK KE SAFEZONE ---
func _selesaikan_wave() -> void:
	is_wave_active = false
	print("[SYSTEM] Wave ", current_wave, " SELESAI Sempurna!")
	
	# --- EKSEKUSI DATA DDA MAKRO ---
	# Di sini tempat Fungsi Fuzzy DDA Makro kamu membaca performa total Player 
	# setelah 1 wave selesai untuk menentukan blueprint tingkat kesulitan wave berikutnya.
	# Contoh: _hitung_fuzzy_dda_makro()
	
	# Naikkan indeks wave untuk petualangan berikutnya
	current_wave += 1
	if "current_wave" in GlobalGameManager:
		GlobalGameManager.current_wave = current_wave
		
	# Bersihkan sisa musuh yang masih hidup di arena (jika ada)
	_bersihkan_sisa_kroco()
	
	# Kirim kembali Player ke Safezone untuk memulihkan diri & Save kemajuan game
	await get_tree().create_timer(2.0).timeout
	GlobalGameManager.is_in_safezone = true
	get_tree().change_scene_to_file("res://safezone.tscn")

func _bersihkan_sisa_kroco() -> void:
	var sisa_musuh = get_tree().get_nodes_in_group("enemy_group")
	for enemy in sisa_musuh:
		if is_instance_valid(enemy) and not enemy.is_dead:
			enemy.queue_free()
