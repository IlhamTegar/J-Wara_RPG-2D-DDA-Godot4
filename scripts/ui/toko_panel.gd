extends Control

# --- DEKLARASI TOMBOL MENU ATAS ---
@onready var buy_btn: Button = $MenuBar/Buy_Button
@onready var cancel_btn: Button = $MenuBar/Cancel_Button
@onready var poin_label: Label = $Poin_Label

# --- DEKLARASI DAFTAR ITEM (KIRI) ---
@onready var daftar_item_panel: Control = $DaftarItem_Panel
@onready var potion_btn: Button = $DaftarItem_Panel/Potion_Button
@onready var scroll_btn: Button = $DaftarItem_Panel/Scroll_Button
@onready var high_scroll_btn: Button = $DaftarItem_Panel/High_Scroll_Button
@onready var ancient_scroll_btn: Button = $DaftarItem_Panel/Ancient_Scroll_Button

# --- DEKLARASI INFO KANAN ---
@onready var possession_label: Label = $Info_Panel/Possession_Label
@onready var deskripsi_label: Label = $Info_Panel/Deskripsi_Label

# --- KONSTANTA HARGA ITEM ---
const HARGA_POTION: int = 50
const HARGA_SCROLL: int = 80
const HARGA_HIGH_SCROLL: int = 250    
const HARGA_ANCIENT_SCROLL: int = 1000 

func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	
	potion_btn.pressed.connect(_beli_potion)
	scroll_btn.pressed.connect(_beli_scroll)
	high_scroll_btn.pressed.connect(_beli_high_scroll)
	ancient_scroll_btn.pressed.connect(_beli_ancient_scroll)
	
	potion_btn.mouse_entered.connect(func(): _update_info_kanan("potion"))
	scroll_btn.mouse_entered.connect(func(): _update_info_kanan("scroll"))
	high_scroll_btn.mouse_entered.connect(func(): _update_info_kanan("high_scroll"))
	ancient_scroll_btn.mouse_entered.connect(func(): _update_info_kanan("ancient_scroll"))
	
	potion_btn.focus_entered.connect(func(): _update_info_kanan("potion"))
	scroll_btn.focus_entered.connect(func(): _update_info_kanan("scroll"))
	high_scroll_btn.focus_entered.connect(func(): _update_info_kanan("high_scroll"))
	ancient_scroll_btn.focus_entered.connect(func(): _update_info_kanan("ancient_scroll"))
	
	daftar_item_panel.modulate = Color(0.5, 0.5, 0.5, 1.0) 
	potion_btn.disabled = true
	scroll_btn.disabled = true
	high_scroll_btn.disabled = true
	ancient_scroll_btn.disabled = true
	
	_refresh_tampilan_toko()

func _refresh_tampilan_toko() -> void:
	if "total_koin" in GlobalGameManager:
		poin_label.text = str(GlobalGameManager.total_koin) + " Koin"
	else:
		poin_label.text = "0 Koin"

func _on_buy_pressed() -> void:
	print("[TOKO] Mode Beli Aktif!")
	daftar_item_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	potion_btn.disabled = false
	scroll_btn.disabled = false
	high_scroll_btn.disabled = false
	ancient_scroll_btn.disabled = false
	potion_btn.grab_focus()

func _update_info_kanan(tipe_item: String) -> void:
	match tipe_item:
		"potion":
			var jumlah_owned = GlobalGameManager.potion_count if "potion_count" in GlobalGameManager else 0
			possession_label.text = "Possession: " + str(jumlah_owned)
			deskripsi_label.text = "Memulihkan HP Player secara instan saat bertarung."
		"scroll":
			var jumlah_owned = GlobalGameManager.scroll_count if "scroll_count" in GlobalGameManager else 0
			possession_label.text = "Possession: " + str(jumlah_owned)
			deskripsi_label.text = "Meningkatkan status ATK / DEF Player selama beberapa saat."
		"high_scroll":
			var jumlah_owned = GlobalGameManager.high_scroll_count if "high_scroll_count" in GlobalGameManager else 0
			possession_label.text = "Possession: " + str(jumlah_owned)
			deskripsi_label.text = "Scroll Premium. Gacha acak: Rage Mode x2 (50%), Stamina Surge (25%), Kebal 15s (20%), atau Revive Pasif 50% HP (5%)."
		"ancient_scroll":
			var jumlah_owned = GlobalGameManager.ancient_scroll_count if "ancient_scroll_count" in GlobalGameManager else 0
			possession_label.text = "Possession: " + str(jumlah_owned)
			deskripsi_label.text = "Gacha Gulungan Terlarang Ekstrem (Tier 1-3). Efek puncak: Instan Win Wipeout Arena (1%) ATAU Mati Konyol Seketika (1%)."

# --- JEMBATAN INTERUPSI KE MERCHANT SCENE ---
func _pemicu_dialog_merchant(pesan_teks: String) -> void:
	var merchant = get_tree().current_scene.find_child("Merchant", true, false)
	if merchant and merchant.has_method("tampilkan_peringatan_kuota"):
		merchant.tampilkan_peringatan_kuota(pesan_teks)

# --- LOGIKA TRANSAKSI ITEM ---
func _beli_potion() -> void:
	if GlobalGameManager.potion_count >= 10:
		print("[🛒 TOKO] Gagal! Kantong Potion kamu sudah penuh (Maks 10)!")
		_pemicu_dialog_merchant("Saya hanya menjual potion 10") # 🛠️ Picu omelan interupsi
		return
		
	if _apakah_inventory_penuh(): return

	if GlobalGameManager.total_koin >= HARGA_POTION:
		GlobalGameManager.total_koin -= HARGA_POTION
		GlobalGameManager.potion_count += 1
		print("[🛒 TOKO] Sukses membeli 1 Potion!")
		_refresh_tampilan_toko()
		_update_info_kanan("potion")
	else:
		print("[🛒 TOKO] Koin tidak mencukupi!")

func _beli_scroll() -> void:
	if GlobalGameManager.scroll_count >= 5:
		print("[🛒 TOKO] Gagal! Kantong Scroll Buff sudah penuh (Maks 5)!")
		_pemicu_dialog_merchant("Saya hanya menjual scroll buff 5") # 🛠️ Picu omelan interupsi
		return
		
	if _apakah_inventory_penuh(): return

	if GlobalGameManager.total_koin >= HARGA_SCROLL:
		GlobalGameManager.total_koin -= HARGA_SCROLL
		GlobalGameManager.scroll_count += 1
		print("[🛒 TOKO] Sukses membeli 1 Scroll Buff!")
		_refresh_tampilan_toko()
		_update_info_kanan("scroll")
	else:
		print("[🛒 TOKO] Koin tidak mencukupi!")

func _beli_high_scroll() -> void:
	if GlobalGameManager.high_scroll_count >= 2:
		print("[🛒 TOKO] Gagal! Kantong High Scroll sudah penuh (Maks 2)!")
		_pemicu_dialog_merchant("Saya hanya menjual scroll unggulan 2") # 🛠️ Picu omelan interupsi
		return
		
	if _apakah_inventory_penuh(): return

	if GlobalGameManager.total_koin >= HARGA_HIGH_SCROLL:
		GlobalGameManager.total_koin -= HARGA_HIGH_SCROLL
		GlobalGameManager.high_scroll_count += 1
		print("[🛒 TOKO] Sukses membeli 1 High Scroll Buff!")
		_refresh_tampilan_toko()
		_update_info_kanan("high_scroll")
	else:
		print("[🛒 TOKO] Koin tidak mencukupi!")

func _beli_ancient_scroll() -> void:
	if GlobalGameManager.ancient_scroll_count >= 1:
		print("[🛒 TOKO] Gagal! Kantong Ancient Scroll sudah penuh (Maks 1)!")
		_pemicu_dialog_merchant("Scroll ini hanya ada 1") # 🛠️ Picu omelan interupsi
		return
		
	if _apakah_inventory_penuh(): return

	if GlobalGameManager.total_koin >= HARGA_ANCIENT_SCROLL:
		GlobalGameManager.total_koin -= HARGA_ANCIENT_SCROLL
		GlobalGameManager.ancient_scroll_count += 1
		print("[🛒 TOKO] Sukses membeli 1 Ancient Scroll!")
		_refresh_tampilan_toko()
		_update_info_kanan("ancient_scroll")
	else:
		print("[🛒 TOKO] Koin tidak mencukupi!")

func _apakah_inventory_penuh() -> bool:
	var total_slot = GlobalGameManager.potion_count + GlobalGameManager.scroll_count + GlobalGameManager.high_scroll_count + GlobalGameManager.ancient_scroll_count
	if total_slot >= 12:
		print("[🛒 TOKO] Gagal! Slot Inventory penuh (Maks 12 tempat)!")
		return true
	return false

func _on_cancel_pressed() -> void:
	potion_btn.disabled = true
	scroll_btn.disabled = true
	high_scroll_btn.disabled = true
	ancient_scroll_btn.disabled = true
	daftar_item_panel.modulate = Color(0.5, 0.5, 0.5, 1.0)
	self.hide()
