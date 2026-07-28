extends Control

# Tempat memasukkan file scene gameplay kamu (Safezone) lewat Inspector nanti
@export_file("*.tscn") var gameplay_scene: String

# --- DEKLARASI NODE TOMBOL MENU UTAMA & ANIMASI ---
@onready var new_game_btn: Button = $NewGame_Button
@onready var new_game_anim: AnimatedSprite2D = $NewGame_Button/AnimatedSprite2D

@onready var load_game_btn: Button = $LoadGame_Button
@onready var load_game_anim: AnimatedSprite2D = $LoadGame_Button/AnimatedSprite2D

@onready var setting_btn: Button = $Setting_Button
@onready var setting_anim: AnimatedSprite2D = $Setting_Button/AnimatedSprite2D

@onready var exit_btn: Button = $Exit_Button
@onready var exit_anim: AnimatedSprite2D = $Exit_Button/AnimatedSprite2D

# --- DEKLARASI PENGUNCI INPUT GLOBAL (COLORRECT) ---
@onready var black_overlay: ColorRect = $UI_Layer/BlackOverlay

# --- DEKLARASI NODE INPUT NAMA (DIAPERTANKAN) ---
@onready var name_input_panel: Panel = $UI_Layer/NameInputPanel
@onready var name_line_edit: LineEdit = $UI_Layer/NameInputPanel/NameLineEdit
@onready var confirm_name_btn: Button = $UI_Layer/NameInputPanel/ConfirmNameButton
@onready var close_name_btn: Button = $UI_Layer/NameInputPanel/TutupButton

# --- DEKLARASI BUKU LOAD GAME (MANUAL 8 SLOT) ---
@onready var load_game_panel: Panel = $UI_Layer/LoadGamePanel
@onready var close_load_btn: Button = $UI_Layer/LoadGamePanel/HalamanKanan/TutupLoadButton

# Slot Halaman Kiri (1 - 4)
@onready var slot1_btn: Button = $UI_Layer/LoadGamePanel/HalamanKiri/Slot1_Button
@onready var slot1_title: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot1_Button/TitleLabel
@onready var slot1_wave: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot1_Button/WaveLabel

@onready var slot2_btn: Button = $UI_Layer/LoadGamePanel/HalamanKiri/Slot2_Button
@onready var slot2_title: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot2_Button/TitleLabel
@onready var slot2_wave: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot2_Button/WaveLabel

@onready var slot3_btn: Button = $UI_Layer/LoadGamePanel/HalamanKiri/Slot3_Button
@onready var slot3_title: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot3_Button/TitleLabel
@onready var slot3_wave: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot3_Button/WaveLabel

@onready var slot4_btn: Button = $UI_Layer/LoadGamePanel/HalamanKiri/Slot4_Button
@onready var slot4_title: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot4_Button/TitleLabel
@onready var slot4_wave: Label = $UI_Layer/LoadGamePanel/HalamanKiri/Slot4_Button/WaveLabel

# Slot Halaman Kanan (5 - 8)
@onready var slot5_btn: Button = $UI_Layer/LoadGamePanel/HalamanKanan/Slot5_Button
@onready var slot5_title: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot5_Button/TitleLabel
@onready var slot5_wave: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot5_Button/WaveLabel

@onready var slot6_btn: Button = $UI_Layer/LoadGamePanel/HalamanKanan/Slot6_Button
@onready var slot6_title: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot6_Button/TitleLabel
@onready var slot6_wave: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot6_Button/WaveLabel

@onready var slot7_btn: Button = $UI_Layer/LoadGamePanel/HalamanKanan/Slot7_Button
@onready var slot7_title: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot7_Button/TitleLabel
@onready var slot7_wave: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot7_Button/WaveLabel

@onready var slot8_btn: Button = $UI_Layer/LoadGamePanel/HalamanKanan/Slot8_Button
@onready var slot8_title: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot8_Button/TitleLabel
@onready var slot8_wave: Label = $UI_Layer/LoadGamePanel/HalamanKanan/Slot8_Button/WaveLabel

# --- REFERENSI KE NODE SETTINGS MENU ---
@onready var settings_menu: Control = $UI_Layer/SettingsMenu

var player_name: String = ""

func _ready() -> void:
	# 1. Mainkan animasi awal
	new_game_anim.play("stand")
	load_game_anim.play("stand")
	setting_anim.play("stand")
	exit_anim.play("stand")
	
	# Bersihkan tampilan awal, sembunyikan semua panel dan overlay pengunci klik
	black_overlay.visible = false
	name_input_panel.visible = false
	load_game_panel.visible = false
	
	new_game_btn.grab_focus()
	
	# 2. Hubungkan Sinyal Menu Utama
	new_game_btn.mouse_entered.connect(func(): new_game_anim.play("hover"))
	new_game_btn.mouse_exited.connect(func(): new_game_anim.play("stand"))
	new_game_btn.pressed.connect(_on_new_game_pressed)
	
	load_game_btn.mouse_entered.connect(func(): load_game_anim.play("hover"))
	load_game_btn.mouse_exited.connect(func(): load_game_anim.play("stand"))
	load_game_btn.pressed.connect(_on_load_game_pressed)
	
	setting_btn.mouse_entered.connect(func(): setting_anim.play("hover"))
	setting_btn.mouse_exited.connect(func(): setting_anim.play("stand"))
	setting_btn.pressed.connect(_on_setting_pressed)
	
	exit_btn.mouse_entered.connect(func(): exit_anim.play("hover"))
	exit_btn.mouse_exited.connect(func(): exit_anim.play("stand"))
	exit_btn.pressed.connect(_on_exit_pressed)

	# 3. Hubungkan Sinyal Sub-Panel (Sinyal kesulitan dihapus secara permanen)
	confirm_name_btn.pressed.connect(_on_confirm_name_pressed)
	close_name_btn.pressed.connect(_on_close_name_pressed)

	# 4. Hubungkan Sinyal Slot Buku Load Game
	close_load_btn.pressed.connect(_on_close_load_pressed)
	slot1_btn.pressed.connect(func(): _on_slot_pressed(1))
	slot2_btn.pressed.connect(func(): _on_slot_pressed(2))
	slot3_btn.pressed.connect(func(): _on_slot_pressed(3))
	slot4_btn.pressed.connect(func(): _on_slot_pressed(4))
	slot5_btn.pressed.connect(func(): _on_slot_pressed(5))
	slot6_btn.pressed.connect(func(): _on_slot_pressed(6))
	slot7_btn.pressed.connect(func(): _on_slot_pressed(7))
	slot8_btn.pressed.connect(func(): _on_slot_pressed(8))
	
	if is_instance_valid(settings_menu):
		settings_menu.visibility_changed.connect(func():
			if not settings_menu.visible:
				black_overlay.visible = false
				setting_btn.grab_focus()
		)
	
	_update_slot_visuals()

# --- FUNGSI AKSI KETIKA TOMBOL DI MENU UTAMA DITEKAN ---
func _on_new_game_pressed() -> void:
	print("Tombol New Game Berhasil Ditekan!")
	black_overlay.visible = true
	name_input_panel.visible = true
	name_line_edit.text = "" # Reset kolom nama lama saat membuat game baru
	name_line_edit.grab_focus()

func _on_load_game_pressed() -> void:
	print("Tombol Load Game Berhasil Ditekan!")
	_update_slot_visuals()
	black_overlay.visible = true
	load_game_panel.visible = true
	slot1_btn.grab_focus()

func _on_setting_pressed() -> void:
	print("Tombol Setting Berhasil Ditekan!")
	if is_instance_valid(settings_menu) and settings_menu.has_method("open_menu"):
		black_overlay.visible = true 
		settings_menu.open_menu()

func _on_exit_pressed() -> void:
	get_tree().quit()

# --- FUNGSI ALUR DATA PLAYER & START GAME ---
func _on_confirm_name_pressed() -> void:
	player_name = name_line_edit.text.strip_edges()
	if player_name == "":
		print("Peringatan: Nama karakter tidak boleh kosong!")
		return
	print("Nama disimpan: ", player_name)
	name_input_panel.visible = false
	black_overlay.visible = false
	
	# 🛠️ BYPASS UTAMA SKRIPSI: Langsung eksekusi mulai permainan tanpa membuka panel kesulitan
	_start_game()

func _start_game() -> void:
		print("=== MEMULAI GAME BARU (DDA CORE BASELINE INITIALIZED) ===")

		if "player_name" in GlobalGameManager: GlobalGameManager.player_name = player_name
		if "current_wave" in GlobalGameManager: GlobalGameManager.current_wave = 1
		if "player_points" in GlobalGameManager: GlobalGameManager.player_points = 0

		# Pemicu Logika Loading Cerita
		GlobalGameManager.butuh_cerita_awal = true
		GlobalGameManager.belum_tutorial_safezone = true
		GlobalGameManager.belum_tutorial_combat = true
		GlobalGameManager.is_in_safezone = true

		# Set jalur tujuan ke loading screen terlebih dahulu
		GlobalGameManager.next_scene_path = gameplay_scene # Biasanya diisi path safezone.tscn
		get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _on_close_name_pressed() -> void:
	name_input_panel.visible = false
	black_overlay.visible = false
	name_line_edit.text = "" 
	new_game_btn.grab_focus() 

# --- FUNGSI MANAJEMEN BUKU LOAD GAME DARI STORAGE LOKAL (8 SLOT) ---
# --- FUNGSI MANAJEMEN BUKU LOAD GAME DARI STORAGE LOKAL (8 SLOT) ---
func _update_slot_visuals() -> void:
	var all_titles = [slot1_title, slot2_title, slot3_title, slot4_title, slot5_title, slot6_title, slot7_title, slot8_title]
	var all_waves = [slot1_wave, slot2_wave, slot3_wave, slot4_wave, slot5_wave, slot6_wave, slot7_wave, slot8_wave]
	
	for i in range(8):
		var slot_num = i + 1
		
		if GlobalGameManager.has_method("dapatkan_info_slot"):
			var info = GlobalGameManager.dapatkan_info_slot(slot_num)
			
			if info["status"] == "Kosong":
				all_titles[i].text = "Slot " + str(slot_num) + " (Kosong)" # Teks jika slot belum diisi
				all_waves[i].text = "- Kosong -"
			else:
				# 🛠️ FIX UTAMA: Ubah title menjadi Nama Pemain yang didaftarkan saat New Game!
				all_titles[i].text = info["nama"] 
				all_waves[i].text = "Wave " + str(info["wave"])
		else:
			all_titles[i].text = "Save Data " + str(slot_num)
			all_waves[i].text = "- Kosong -"

func _on_slot_pressed(slot_number: int) -> void:
	if GlobalGameManager.has_method("load_dari_slot"):
		var sukses_load = GlobalGameManager.load_dari_slot(slot_number)
		if sukses_load:
			# 🛠️ REKAM SLOT YANG SEDANG DIMAINKAN
			GlobalGameManager.slot_aktif_sekarang = slot_number 
			
			print("Load berhasil dari Slot: ", slot_number)
			GlobalGameManager.is_in_safezone = true
			GlobalGameManager.next_scene_path = gameplay_scene
			get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _on_close_load_pressed() -> void:
	load_game_panel.visible = false
	black_overlay.visible = false
	load_game_btn.grab_focus()
