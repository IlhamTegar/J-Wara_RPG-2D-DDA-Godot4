extends Node2D

@onready var pause_menu = $PauseMenu
@onready var tutorial_panel_safezone: Panel = $UI_Layer/TutorialPanelSafezone
@onready var judul_label: Label = $UI_Layer/TutorialPanelSafezone/JudulLabel
@onready var tutorial_texture: TextureRect = $UI_Layer/TutorialPanelSafezone/TutorialTexture
@onready var deskripsi_label: Label = $UI_Layer/TutorialPanelSafezone/DeskripsiLabel
@onready var selanjutnya_btn: Button = $UI_Layer/TutorialPanelSafezone/SelanjutnyaButton
@onready var tutuptuto_btn: Button = $UI_Layer/TutorialPanelSafezone/TutupTutoButton

# --- DATA MATERI TUTORIAL SAFEZONE STEP-BY-STEP ---
var safezone_steps: Array = [
	{
		"judul": "WALK / PERGERAKAN KARAKTER",
		"deskripsi": "Tekan tombol A/D pada keyboard untuk menggerakkan karakter.",
		"gambar": "res://assets/images/tutorial/safezone/tuto-safe-walk.png"
	},
	{
		"judul": "INTERAKSI LINGKUNGAN",
		"deskripsi": "Dekati objek interaktif seperti pintu rumah atau NPC, lalu tekan tombol F pada keyboard untuk interaksi.",
		"gambar": "res://assets/images/tutorial/safezone/tuto-safe-interact.png"
	},
	{
		"judul": "SISTEM PENYIMPANAN (SAVE DATA)",
		"deskripsi": "Kamu bisa berinteraksi dengan rumah untuk menyimpan progres permainanmu secara permanen ke dalam slot penyimpanan lokal.",
		"gambar": "res://assets/images/tutorial/safezone/tuto-safe-save.png"
	},
	{
		"judul": "MANAJEMEN TOKO & MERCHANT",
		"deskripsi": "Gunakan reward poin hasil pertempuranmu di Toko Merchant untuk membeli ramuan obat (Potion) atau membeli scroll buff sebelum kembali bertarung.",
		"gambar": "res://assets/images/tutorial/safezone/tuto-safe-shop.png"
	}
]

var current_safezone_step: int = 0

func _ready() -> void:
	GlobalGameManager.is_in_safezone = true 
	
	# 🛠️ FIX UTAMA DETEKSI STARTING REWARD:
	# Jika player baru pertama kali main (belum pernah tutorial) DAN data masih kosong,
	# suntikkan bonus 50 koin dan 2 potion secara otomatis di sini!
	if GlobalGameManager.belum_tutorial_safezone:
		if GlobalGameManager.total_koin == 0 and GlobalGameManager.potion_count == 0:
			GlobalGameManager.total_koin = 50
			GlobalGameManager.potion_count = 2
			GlobalGameManager.scroll_count = 0
			print("[🎁 REWARD SECURITY] Sukses menyuntikkan modal awal: 50 Koin & 2 Potion!")

	# Pengecekan panel tutorial bawaan kamu
	var panel_tuto = get_node_or_null("UI_Layer/TutorialPanel")
	if panel_tuto and GlobalGameManager.belum_tutorial_safezone:
		panel_tuto.show()
		get_tree().paused = true 
		
	print("[SAFEZONE] Selamat datang kembali di zona aman. Wave saat ini: ", GlobalGameManager.current_wave)
	$PortalCombat.body_entered.connect(_on_portal_combat_entered) 
	
	_ready_tutorial_safezone_check() 
	
	# Hubungkan sinyal klik tombol secara aman di awal permainan
	if not selanjutnya_btn.pressed.is_connected(_on_selanjutnya_safezone_pressed): 
		selanjutnya_btn.pressed.connect(_on_selanjutnya_safezone_pressed) 
	if not tutuptuto_btn.pressed.is_connected(_on_tutup_safezone_pressed): 
		tutuptuto_btn.pressed.connect(_on_tutup_safezone_pressed) 

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if is_instance_valid(pause_menu):
			if get_tree().paused:
				pause_menu.close_pause()
			else:
				pause_menu.open_pause()

func _on_portal_combat_entered(body: Node) -> void:
	if body.is_in_group("player_group") or body is CharacterBody2D: 
		print("Player memasuki portal! Bersiap menuju Arena Combat...") 
		
		GlobalGameManager.next_scene_path = "res://scenes/mode/arena_combat.tscn" 
		
		# 🛠️ FIX UTAMA: Tutorial hanya disetel TRUE jika ini adalah Wave 1!
		if GlobalGameManager.current_wave == 1:
			GlobalGameManager.belum_tutorial_combat = true 
		else:
			GlobalGameManager.belum_tutorial_combat = false # Wave 2-5 aman tanpa tutorial
		
		get_tree().call_deferred("change_scene_to_file", "res://scenes/ui/loading_screen.tscn")

func _ready_tutorial_safezone_check() -> void:
	# Periksa status biner global apakah player belum pernah melewati tutorial safezone
	if tutorial_panel_safezone and GlobalGameManager.belum_tutorial_safezone:
		_mulai_tutorial_safezone()
	else:
		if tutorial_panel_safezone:
			tutorial_panel_safezone.hide()

func _mulai_tutorial_safezone() -> void:
	current_safezone_step = 0
	get_tree().paused = true # Bekukan jalannya waktu objek di safezone
	tutorial_panel_safezone.show()
	_tampilkan_halaman_safezone(current_safezone_step)

func _tampilkan_halaman_safezone(index: int) -> void:
	var data = safezone_steps[index]
	
	judul_label.text = data["judul"]
	deskripsi_label.text = data["deskripsi"]
	
	# Load aset gambar demonstrasi tutorial secara dinamis
	if ResourceLoader.exists(data["gambar"]):
		tutorial_texture.texture = load(data["gambar"])
	else:
		tutorial_texture.texture = null
		
	# --- 🧠 SAKLAR VISIBILITAS DUA TOMBOL BERGANTIAN ---
	if index == safezone_steps.size() - 1:
		# Jika sudah mencapai halaman terakhir (Langkah ke-4: Toko)
		selanjutnya_btn.hide()      # Sembunyikan tombol selanjutnya
		tutuptuto_btn.show()        # Munculkan tombol tutup tutorial
		tutuptuto_btn.grab_focus()   # Alihkan fokus klik/input ke tombol tutup
	else:
		# Jika halaman tutorial masih ada di tengah jalan
		selanjutnya_btn.show()      # Munculkan tombol selanjutnya
		tutuptuto_btn.hide()        # Sembunyikan tombol tutup tutorial
		selanjutnya_btn.grab_focus() # Alihkan fokus klik/input ke tombol selanjutnya

func _on_selanjutnya_safezone_pressed() -> void:
	current_safezone_step += 1
	if current_safezone_step < safezone_steps.size():
		_tampilkan_halaman_safezone(current_safezone_step)

func _on_tutup_safezone_pressed() -> void:
	tutorial_panel_safezone.hide()
	get_tree().paused = false # Lepas status pause, player bebas bergerak normal!
	GlobalGameManager.belum_tutorial_safezone = false # Kunci flag biner agar tutorial tidak bocor lagi
	print("[📘 TUTORIAL SAFEZONE] Selesai! Wilayah Safezone aman dieksplorasi.")
