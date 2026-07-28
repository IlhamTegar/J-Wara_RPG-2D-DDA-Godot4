extends Area2D

var player_di_area: bool = false

@onready var label_petunjuk: Label = $Label
@onready var buku_panel: Control = get_parent().get_node("UI_Layer/BukuSavePanel")

var tombol_slot: Array = []
var text_wave_slot: Array = []

func _ready() -> void:
	label_petunjuk.hide()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if is_instance_valid(buku_panel):
		buku_panel.hide()
		
		var h_kiri = buku_panel.get_node_or_null("HalamanKiri")
		var h_kanan = buku_panel.get_node_or_null("HalamanKanan")
		
		if h_kiri and h_kanan:
			tombol_slot = [
				h_kiri.get_node("Slot1_Button"), h_kiri.get_node("Slot2_Button"),
				h_kiri.get_node("Slot3_Button"), h_kiri.get_node("Slot4_Button"),
				h_kanan.get_node("Slot5_Button"), h_kanan.get_node("Slot6_Button"),
				h_kanan.get_node("Slot7_Button"), h_kanan.get_node("Slot8_Button")
			]
			
			text_wave_slot = [
				h_kiri.get_node("Slot1_Button/WaveLabel"), h_kiri.get_node("Slot2_Button/WaveLabel"),
				h_kiri.get_node("Slot3_Button/WaveLabel"), h_kiri.get_node("Slot4_Button/WaveLabel"),
				h_kanan.get_node("Slot5_Button/WaveLabel"), h_kanan.get_node("Slot6_Button/WaveLabel"),
				h_kanan.get_node("Slot7_Button/WaveLabel"), h_kanan.get_node("Slot8_Button/WaveLabel")
			]
			
			for i in range(8):
				var slot_num = i + 1
				tombol_slot[i].pressed.connect(func(): _on_slot_buku_diklik(slot_num))
				
			var tombol_tutup = h_kanan.get_node_or_null("TutupLoadButton")
			if tombol_tutup:
				tombol_tutup.pressed.connect(_tutup_buku_save)

func _process(_delta: float) -> void:
	if player_di_area and Input.is_action_just_pressed("interaksi"):
		if is_instance_valid(buku_panel):
			if buku_panel.visible:
				_tutup_buku_save()
			else:
				_buka_buku_save()

func _buka_buku_save() -> void:
	_refresh_visual_wave_buku()
	buku_panel.show()
	label_petunjuk.hide()
	tombol_slot[0].grab_focus()

func _tutup_buku_save() -> void:
	buku_panel.hide()
	if player_di_area:
		label_petunjuk.show()

func _refresh_visual_wave_buku() -> void:
	for i in range(8):
		var slot_num = i + 1
		
		# 🛠️ Ambil node TitleLabel yang ada di dalam masing-masing tombol slot secara otomatis
		var label_judul = tombol_slot[i].get_node_or_null("TitleLabel")
		
		if GlobalGameManager.has_method("dapatkan_info_slot"):
			var info = GlobalGameManager.dapatkan_info_slot(slot_num)
			
			if info["status"] == "Kosong":
				if label_judul: 
					label_judul.text = "Slot " + str(slot_num) + " (Kosong)"
				text_wave_slot[i].text = "- Kosong -"
			else:
				# 🛠️ FIX UTAMA: Ubah judul slot di dalam game menjadi nama pemain yang terdaftar!
				if label_judul: 
					label_judul.text = info["nama"]
				text_wave_slot[i].text = "Wave " + str(info["wave"])
		else:
			if label_judul: 
				label_judul.text = "Slot " + str(slot_num)
			text_wave_slot[i].text = "- Kosong -"

func _on_slot_buku_diklik(slot_number: int) -> void:
	if GlobalGameManager.has_method("save_ke_slot"):
		GlobalGameManager.save_ke_slot(slot_number)
		_refresh_visual_wave_buku()
		print("[RUMAH SAVE] Progress sukses dicatat pada Slot: ", slot_number)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		player_di_area = true
		label_petunjuk.text = "F"
		label_petunjuk.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_group"):
		player_di_area = false
		label_petunjuk.hide()
		_tutup_buku_save()
