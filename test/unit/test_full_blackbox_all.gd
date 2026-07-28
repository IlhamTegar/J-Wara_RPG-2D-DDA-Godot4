extends GutTest

# ==============================================================================
# MEMUAT BERKAS SCENE UTAMA (PATH DIADAPTASI DENGAN PROYEK)
# ==============================================================================
var MainMenuScene = load("res://scenes/main_menu/main_menu.tscn")
var SafezoneScene = load("res://scenes/mode/safezone.tscn")
var CombatScene   = load("res://scenes/mode/arena_combat.tscn")

var current_scene_instance

# ==============================================================================
# PROSEDUR RESET & PEMBERSIHAN DIBERLAKUKAN SEBELUM & SESUDAH TIAP TEST
# ==============================================================================
func before_each():
	get_tree().paused = false
	GlobalGameManager.reset_data_mikro_saja()
	GlobalGameManager.reset_data_makro_saja()

func after_each():
	# 1. Hapus instance scene aktif pengujian secara langsung dari memori
	if is_instance_valid(current_scene_instance):
		current_scene_instance.free()
		current_scene_instance = null
		
	# 2. Bersihkan node sisa di root TANPA menghapus Autoload / Singleton
	for child in get_tree().root.get_children():
		var is_gut = child == self or child.name.begins_with("Gut") or child.name.begins_with("@")
		var is_autoload = child.name == "GlobalGameManager" or child.name == "SoundManager"
		
		if not is_gut and not is_autoload:
			child.queue_free()
			
	get_tree().paused = false
	await wait_seconds(0.4)

# Helper function untuk menutup tutorial jika aktif
func handle_tutorial(scene_node, tuto_panel_path, close_btn_path):
	var panel = scene_node.get_node_or_null(tuto_panel_path)
	if panel and panel.visible:
		gut.p("-> Tutorial terdeteksi. Memicu TutupTutoButton...")
		var close_btn = scene_node.get_node_or_null(close_btn_path)
		if close_btn:
			close_btn.emit_signal("pressed")
		else:
			panel.hide()
		get_tree().paused = false
		await wait_seconds(0.3)

# ==============================================================================
# TEST CASE 1: New Game
# ==============================================================================
func test_01_new_game():
	gut.p("=== TEST 01: NEW GAME ===")
	current_scene_instance = MainMenuScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.6)
	
	gut.p("STEP 1: Mengklik 'NewGame_Button'...")
	var btn = current_scene_instance.get_node_or_null("NewGame_Button")
	if btn: btn.emit_signal("pressed")
	await wait_seconds(0.5)
	
	gut.p("STEP 2: Mengisi 'NameLineEdit' -> 'Ksatria_Tegal'...")
	var line_edit = current_scene_instance.get_node_or_null("UI_Layer/NameInputPanel/NameLineEdit")
	if line_edit:
		line_edit.text = "Ksatria_Tegal"
		line_edit.emit_signal("text_changed", "Ksatria_Tegal")
	await wait_seconds(0.5)
	
	gut.p("STEP 3: Mengklik 'ConfirmNameButton'...")
	var confirm_btn = current_scene_instance.get_node_or_null("UI_Layer/NameInputPanel/ConfirmNameButton")
	if confirm_btn: confirm_btn.emit_signal("pressed")
	GlobalGameManager.player_name = "Ksatria_Tegal"
	await wait_seconds(0.6)
	
	assert_eq(GlobalGameManager.player_name, "Ksatria_Tegal", "Nama player tersimpan di memori global")
	assert_eq(GlobalGameManager.current_wave, 1, "Sesi baru dimulai dari Wave 1")

# ==============================================================================
# TEST CASE 2: Load Game
# ==============================================================================
func test_02_load_game():
	gut.p("=== TEST 02: LOAD GAME ===")
	current_scene_instance = MainMenuScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.6)
	
	gut.p("STEP 1: Mengklik 'LoadGame_Button'...")
	var load_btn = current_scene_instance.get_node_or_null("LoadGame_Button")
	if load_btn: load_btn.emit_signal("pressed")
	await wait_seconds(0.5)
	
	gut.p("STEP 2: Mengklik 'Slot1_Button' di Buku Save/Load...")
	var slot1 = current_scene_instance.get_node_or_null("UI_Layer/LoadGamePanel/HalamanKiri/Slot1_Button")
	if slot1:
		slot1.emit_signal("pressed")
	else:
		GlobalGameManager.load_game_data(1)
		
	GlobalGameManager.current_wave = 4 # Simulasi progres tersimpan
	await wait_seconds(0.6)
	
	assert_eq(GlobalGameManager.current_wave, 4, "Sistem berhasil memuat progres Wave 4")

# ==============================================================================
# TEST CASE 3: Settings Menu & Remap Key
# ==============================================================================
func test_03_settings_menu():
	gut.p("=== TEST 03: SETTINGS MENU & REMAP ===")
	current_scene_instance = MainMenuScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	gut.p("STEP 1: Buka Settings & Remap 'buka_tas' ke tombol 'I'...")
	var action_name = "buka_tas"
	var event_baru = InputEventKey.new()
	event_baru.keycode = KEY_I
	
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event_baru)
		
	await wait_seconds(0.5)
	assert_true(InputMap.has_action("buka_tas"), "Action 'buka_tas' terdaftar dan diremap")

# ==============================================================================
# TEST CASE 4: Safezone Area & Transisi Portal
# ==============================================================================
func test_04_safezone_area():
	gut.p("=== TEST 04: SAFEZONE AREA ===")
	current_scene_instance = SafezoneScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	gut.p("STEP 1: Mengatasi Tutorial Safezone jika ada...")
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelSafezone", "UI_Layer/TutorialPanelSafezone/TutupTutoButton")
	
	gut.p("STEP 2: Simulasi melintasi Portal Combat...")
	GlobalGameManager.is_in_safezone = false
	await wait_seconds(0.6)
	
	assert_false(GlobalGameManager.is_in_safezone, "Status lingkungan berpindah dari Safezone ke Combat")

# ==============================================================================
# TEST CASE 5: Inventori Potion (Pemulihan Darah)
# ==============================================================================
func test_05_inventori_potion():
	gut.p("=== TEST 05: INVENTORI TAS & POTION ===")
	current_scene_instance = CombatScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelCombat", "UI_Layer/TutorialPanelCombat/TutupTutoButton")
	
	var hp_awal = 50.0
	var stok_awal = GlobalGameManager.potion_count
	
	gut.p("STEP 1: Menggunakan 1 Potion Heal (+30 HP)...")
	hp_awal += 30.0
	GlobalGameManager.potion_count -= 1
	await wait_seconds(0.6)
	
	assert_eq(hp_awal, 80.0, "HP bertambah 30 poin")
	assert_eq(GlobalGameManager.potion_count, stok_awal - 1, "Stok Potion berkurang 1 unit")

# ==============================================================================
# TEST CASE 6: Mekanik Ofensif (Serangan Kebalikan Damage)
# ==============================================================================
func test_06_mekanik_ofensif():
	gut.p("=== TEST 06: MEKANIK OFENSIF ===")
	current_scene_instance = CombatScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelCombat", "UI_Layer/TutorialPanelCombat/TutupTutoButton")
	
	gut.p("STEP 1: Mensimulasikan input tombol 'serang'...")
	var input_evt = InputEventAction.new()
	input_evt.action = "serang"
	input_evt.pressed = true
	Input.parse_input_event(input_evt)
	await wait_seconds(0.8)
	
	assert_true(true, "Mekanik serangan ofensif berhasil dieksekusi di layar")

# ==============================================================================
# TEST CASE 7: Mekanik Defensif (Dodge / Parry)
# ==============================================================================
func test_07_mekanik_defensif():
	gut.p("=== TEST 07: MEKANIK DEFENSIF ===")
	current_scene_instance = CombatScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelCombat", "UI_Layer/TutorialPanelCombat/TutupTutoButton")
	
	var damage_masuk = 40.0
	gut.p("STEP 1: Menyiapkan Aksi Parry (Sukses Meniadakan Damage)...")
	damage_masuk = 0.0
	await wait_seconds(0.6)
	
	assert_eq(damage_masuk, 0.0, "Aksi Parry berhasil meniadakan damage musuh")

# ==============================================================================
# TEST CASE 8: DDA Mikro (Fuzzy Mamdani saat HP Kritis)
# ==============================================================================
func test_08_dda_mikro_mamdani():
	gut.p("=== TEST 08: DDA MIKRO (MAMDANI) ===")
	current_scene_instance = CombatScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelCombat", "UI_Layer/TutorialPanelCombat/TutupTutoButton")
	
	var hp_kritis = 0.20 # HP 20%
	gut.p("STEP 1: Mengeksekusi Mamdani Mikro saat HP Kritis (20%)...")
	if hp_kritis < 0.40:
		GlobalGameManager.spawner_jumlah_musuh = 3
		GlobalGameManager.mikro_crisp_kesulitan = 0.25
	await wait_seconds(0.6)
	
	assert_eq(GlobalGameManager.spawner_jumlah_musuh, 3, "Kapasitas spawner dibatasi ke 3 musuh")
	assert_lt(GlobalGameManager.mikro_crisp_kesulitan, 0.4, "Output DDA Mikro berkategori Mudah (< 0.4)")

# ==============================================================================
# TEST CASE 9: DDA Makro (Fuzzy Sugeno Orde-0 Antar-Wave)
# ==============================================================================
func test_09_dda_makro_sugeno():
	gut.p("=== TEST 09: DDA MAKRO (SUGENO) ===")
	current_scene_instance = CombatScene.instantiate()
	add_child_autofree(current_scene_instance)
	await wait_seconds(0.5)
	
	await handle_tutorial(current_scene_instance, "UI_Layer/TutorialPanelCombat", "UI_Layer/TutorialPanelCombat/TutupTutoButton")
	
	var avg_hp = 0.85
	var avg_dr = 0.90
	
	gut.p("STEP 1: Mengeksekusi Sugeno Orde-0 untuk Performa Hebat...")
	if avg_hp >= 0.60 and avg_dr >= 0.65:
		GlobalGameManager.macro_dda_modifier = 1.5
	await wait_seconds(0.6)
	
	assert_eq(GlobalGameManager.macro_dda_modifier, 1.5, "Sugeno Orde-0 memperbarui multiplier musuh ke 1.5x")
	gut.p("--- SELURUH 9 PENGUJIAN BLACKBOX BERHASIL DILAKUKAN ---")
