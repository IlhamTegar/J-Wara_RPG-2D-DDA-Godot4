extends Control
signal menu_closed

# --- DEKLARASI NODE PANEL PENGATURAN INDUK ---
@onready var settings_menu_panel: Panel = $SettingsMenuPanel
@onready var audio_btn: Button = $SettingsMenuPanel/AudioButton
@onready var display_btn: Button = $SettingsMenuPanel/DisplayButton
@onready var controls_btn: Button = $SettingsMenuPanel/ControlsButton
@onready var close_settings_btn: Button = $SettingsMenuPanel/TutupSettingsButton

# --- PANEL SUB-MENU: AUDIO ---
@onready var audio_settings_panel: Panel = $AudioSettingsPanel
@onready var close_audio_btn: Button = $AudioSettingsPanel/TutupAudioButton
@onready var master_slider: TextureProgressBar = $AudioSettingsPanel/MasterSlider
@onready var music_slider: TextureProgressBar = $AudioSettingsPanel/MusicSlider
@onready var sfx_slider: TextureProgressBar = $AudioSettingsPanel/SFXSlider
@onready var master_slider_input: HSlider = $AudioSettingsPanel/MasterSliderInput
@onready var music_slider_input: HSlider = $AudioSettingsPanel/MusicSliderInput
@onready var sfx_slider_input: HSlider = $AudioSettingsPanel/SFXSliderInput

# --- PANEL SUB-MENU: DISPLAY ---
@onready var display_settings_panel: Panel = $DisplaySettingsPanel
@onready var display_mode_btn: Button = $DisplaySettingsPanel/DisplayModeButton
@onready var vsync_btn: Button = $DisplaySettingsPanel/VsyncButton
@onready var close_display_btn: Button = $DisplaySettingsPanel/TutupDisplayButton

# --- PANEL SUB-MENU: CONTROLS (REMAP) ---
@onready var controls_panel: Panel = $ControlsPanel
@onready var close_controls_btn: Button = $ControlsPanel/TutupControlsButton
@onready var serang_btn: Button = $ControlsPanel/Serang_Btn
@onready var parry_btn: Button = $ControlsPanel/Parry_Btn
@onready var dodge_btn: Button = $ControlsPanel/Dodge_Btn
@onready var interaksi_btn: Button = $ControlsPanel/Interaksi_Btn
@onready var heal_btn: Button = $ControlsPanel/Heal_Btn

# --- VARIABEL STATE ---
var is_fullscreen: bool = false
var is_vsync_on: bool = true
var aksi_yang_diedit: String = ""
var sedang_menunggu_input: bool = false

func _ready() -> void:
	# 🛠️ FIX UTAMA DETEKSI RESOLUSI LOKAL AWAL:
	# Sinkronkan isi boolean state langsung membaca kondisi real-time dari OS / Project Settings kamu
	var mode_real = DisplayServer.window_get_mode()
	if mode_real == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or mode_real == DisplayServer.WINDOW_MODE_FULLSCREEN:
		is_fullscreen = true
	else:
		is_fullscreen = false
		
	# Sinkronkan pendeteksian VSync awal bawaan hardware laptop
	var vsync_real = DisplayServer.window_get_vsync_mode()
	if vsync_real == DisplayServer.VSYNC_DISABLED:
		is_vsync_on = false
	else:
		is_vsync_on = true

	# --- KODE BARU: INISIALISASI PEMBACAAN DATA CONFIG AUDIO PERSISTEN ---
	var config = ConfigFile.new()
	var file_exist = config.load(GlobalGameManager.AUDIO_SAVE_PATH) == OK

	# 1. SETEL VALUE AWAL & SINYAL SLIDER AUDIO (MASTER)
	master_slider_input.min_value = 0
	master_slider_input.max_value = 100
	master_slider_input.step = 5
	master_slider_input.value_changed.connect(func(value):
		master_slider.value = value
		_on_master_slider_changed(value)
	)
	# 🛠️ FIX PERSISTENSI: Ambil data dari file config, jika belum pernah disetel otomatis 100
	master_slider_input.value = config.get_value("audio", "Master", 100.0) if file_exist else 100.0

	# SETEL VALUE AWAL & SINYAL SLIDER AUDIO (MUSIC)
	music_slider_input.min_value = 0
	music_slider_input.max_value = 100
	music_slider_input.step = 5
	music_slider_input.value_changed.connect(func(value):
		music_slider.value = value
		_on_music_slider_changed(value)
	)
	# 🛠️ FIX PERSISTENSI: Ambil data dari file config, jika belum pernah disetel otomatis 100
	music_slider_input.value = config.get_value("audio", "Music", 100.0) if file_exist else 100.0

	# SETEL VALUE AWAL & SINYAL SLIDER AUDIO (SFX)
	sfx_slider_input.min_value = 0
	sfx_slider_input.max_value = 100
	sfx_slider_input.step = 5
	sfx_slider_input.value_changed.connect(func(value):
		sfx_slider.value = value
		_on_sfx_slider_changed(value)
	)
	# 🛠️ FIX PERSISTENSI: Ambil data dari file config, jika belum pernah disetel otomatis 100
	sfx_slider_input.value = config.get_value("audio", "SFX", 100.0) if file_exist else 100.0

	# --- TRIK MENGHILANGKAN BULATAN PUTIH UNTUK SEMUA SLIDER INPUT ---
	var blank_texture = ImageTexture.create_from_image(Image.create_empty(1, 1, false, Image.FORMAT_RGBA8))
	master_slider_input.add_theme_icon_override("grabber", blank_texture)
	master_slider_input.add_theme_icon_override("grabber_highlight", blank_texture)
	music_slider_input.add_theme_icon_override("grabber", blank_texture)
	music_slider_input.add_theme_icon_override("grabber_highlight", blank_texture)
	sfx_slider_input.add_theme_icon_override("grabber", blank_texture)
	sfx_slider_input.add_theme_icon_override("grabber_highlight", blank_texture)

	# 2. SAMBUNGKAN SINYAL HUBUNG INDUK PENGATURAN & KATEGORI SUB-MENU
	close_settings_btn.pressed.connect(_on_close_settings_pressed)
	audio_btn.pressed.connect(_on_audio_category_pressed)
	close_audio_btn.pressed.connect(_on_close_audio_pressed)

	display_btn.pressed.connect(_on_display_category_pressed)
	close_display_btn.pressed.connect(_on_close_display_pressed)
	display_mode_btn.pressed.connect(_on_display_mode_toggled)
	vsync_btn.pressed.connect(_on_vsync_toggled)

	controls_btn.pressed.connect(_on_controls_category_pressed)
	close_controls_btn.pressed.connect(_on_close_controls_pressed)

	# Sambungkan tombol aksi kustom ke fungsi penangkap input generic
	serang_btn.pressed.connect(func(): _mulai_remap_tombol("serang", serang_btn))
	parry_btn.pressed.connect(func(): _mulai_remap_tombol("parry", parry_btn))
	dodge_btn.pressed.connect(func(): _mulai_remap_tombol("dodge", dodge_btn))
	interaksi_btn.pressed.connect(func(): _mulai_remap_tombol("interaksi", interaksi_btn))
	heal_btn.pressed.connect(func(): _mulai_remap_tombol("buka_tas", heal_btn))

	# Inisialisasi teks tampilan grafis bawaan di awal game dibuka
	_update_display_ui_text()

# Dipanggil dari MainMenu.gd lewat: settings_menu.open_menu()
func open_menu() -> void:
	print("OPEN MENU DIPANGGIL")
	visible = true

	settings_menu_panel.visible = true
	audio_settings_panel.visible = false
	display_settings_panel.visible = false
	controls_panel.visible = false

	audio_btn.grab_focus()

func close_menu() -> void:
	visible = false
	menu_closed.emit()

# --- PROSES DETEKSI KUSTOM REMAP INPUT SECARA REALTIME ---
func _input(event: InputEvent) -> void:
	if not sedang_menunggu_input:
		return

	# Izinkan Keyboard (Key) atau Klik Mouse (MouseButton)
	if event is InputEventKey or event is InputEventMouseButton:
		# Batalkan remap jika menekan tombol ESC karena dipakai untuk Pause Game
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			sedang_menunggu_input = false
			aksi_yang_diedit = ""
			_update_all_control_labels()
			return

		if event.is_pressed():
			_eksekusi_remap(aksi_yang_diedit, event)
			get_viewport().set_input_as_handled() # Konsumsi event agar tidak bocor ke UI

# --- FUNGSI SUB-MENU: MANAGEMENT INDUK & AUDIO ---
func _on_close_settings_pressed():
	close_menu()

func _on_audio_category_pressed() -> void:
	settings_menu_panel.visible = false
	audio_settings_panel.visible = true
	master_slider_input.grab_focus()

func _on_close_audio_pressed() -> void:
	audio_settings_panel.visible = false
	settings_menu_panel.visible = true
	audio_btn.grab_focus()

func _on_master_slider_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	if bus_index != -1:
		var volume_linear = value / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))
		# Simpan permanen ke lokal laptop
		GlobalGameManager.simpan_setelan_action_audio("Master", value)

func _on_music_slider_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index != -1:
		var volume_linear = value / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))
		GlobalGameManager.simpan_setelan_action_audio("Music", value)

func _on_sfx_slider_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		var volume_linear = value / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_linear))
		GlobalGameManager.simpan_setelan_action_audio("SFX", value)

func linear_to_volume_db(value: float) -> float:
	if value == 0:
		return -80.0
	return remap(value, 0, 100, -30, 10)


# --- FUNGSI SUB-MENU: DISPLAY LOGIC ---
func _on_display_category_pressed() -> void:
	settings_menu_panel.visible = false
	display_settings_panel.visible = true
	display_mode_btn.grab_focus()

func _on_close_display_pressed() -> void:
	display_settings_panel.visible = false
	settings_menu_panel.visible = true
	display_btn.grab_focus()

func _on_display_mode_toggled() -> void:
	is_fullscreen = !is_fullscreen
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		# Solusi Godot 4.x Terbaru: Ambil ukuran layar monitor dan taruh posisi window di tengah
		var screen_id = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen_id)
		var window_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position((screen_size / 2.0) - (window_size / 2.0))

	_update_display_ui_text()

func _on_vsync_toggled() -> void:
	is_vsync_on = !is_vsync_on
	if is_vsync_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_update_display_ui_text()

func _update_display_ui_text() -> void:
	display_mode_btn.text = "Fullscreen" if is_fullscreen else "Windowed"
	vsync_btn.text = "VSync: On" if is_vsync_on else "VSync: Off"

# --- FUNGSI SUB-MENU: CONTROLS REMAP LOGIC ---
func _on_controls_category_pressed() -> void:
	settings_menu_panel.visible = false
	controls_panel.visible = true
	_update_all_control_labels()
	serang_btn.grab_focus()

func _on_close_controls_pressed() -> void:
	controls_panel.visible = false
	settings_menu_panel.visible = true
	controls_btn.grab_focus()

func _mulai_remap_tombol(nama_aksi: String, tombol_node: Button) -> void:
	if sedang_menunggu_input:
		return
	sedang_menunggu_input = true
	aksi_yang_diedit = nama_aksi
	tombol_node.text = "[ Tekan Tombol Baru... ]"

func _eksekusi_remap(nama_aksi: String, event_baru: InputEvent) -> void:
	InputMap.action_erase_events(nama_aksi)
	InputMap.action_add_event(nama_aksi, event_baru)
	sedang_menunggu_input = false
	aksi_yang_diedit = ""
	_update_all_control_labels()

func _dapatkan_nama_tombol(nama_aksi: String) -> String:
	var list_event = InputMap.action_get_events(nama_aksi)
	if list_event.size() > 0:
		# Mengubah format class mentah menjadi teks ringkas (misal: "J" atau "Left Mouse Button")
		return list_event[0].as_text().replace(" (Physical)", "")
	return "Unbound"

func _update_all_control_labels() -> void:
	serang_btn.text = "Serang: " + _dapatkan_nama_tombol("serang")
	parry_btn.text = "Parry: " + _dapatkan_nama_tombol("parry")
	dodge_btn.text = "Dodge: " + _dapatkan_nama_tombol("dodge")
	interaksi_btn.text = "Interaksi: " + _dapatkan_nama_tombol("interaksi")
	heal_btn.text = "Buka Tas: " + _dapatkan_nama_tombol("buka_tas")
