extends Control

# 🛠️ SEKARANG LANGSUNG MENEMBAK KE NODE LABEL UTAMA
@onready var credits_label: Label = $Label

# Durasi kecepatan scroll (makin besar angkanya, makin pelan jalannya)
@export var durasi_scroll: float = 25.0 

func _ready() -> void:
	# 1. Posisikan awal teks tepat di bawah batas layar monitor
	var tinggi_layar = get_viewport_rect().size.y
	credits_label.global_position.y = tinggi_layar
	
	# Berikan jeda ketenangan 1 detik sebelum teks mulai berjalan
	await get_tree().create_timer(1.0).timeout
	
	# 2. Hebatnya Godot: 'get_combined_minimum_size().y' akan otomatis menghitung
	# tinggi total teks kamu sepanjang apa pun ke bawah meskipun tidak terlihat di layar monitor!
	var tinggi_konten_teks = credits_label.get_combined_minimum_size().y
	var target_posisi_y = -tinggi_konten_teks
	
	# 3. Jalankan efek rolling text merayap naik ke atas secara konstan
	var tween = create_tween()
	tween.tween_property(credits_label, "global_position:y", target_posisi_y, durasi_scroll).set_trans(Tween.TRANS_LINEAR)
	
	# Sinyal otomatis jika baris paling terakhir sudah hilang di atas layar
	tween.finished.connect(_kembali_ke_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	# 🛠️ FIX UTAMA: Memastikan objek event adalah tombol keyboard, mendeteksi KEY_SPACE, dan hanya saat ditekan (pressed)
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.keycode == KEY_SPACE and event.pressed):
		_kembali_ke_main_menu()

func _kembali_ke_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
