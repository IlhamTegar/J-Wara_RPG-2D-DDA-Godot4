extends Control

@onready var logo: TextureRect = $Logo

func _ready() -> void:
	# 1. Kondisi Awal: Paksa logo menjadi transparan total (Layar Hitam Murni)
	logo.modulate.a = 0.0
	
	# Berikan jeda ketenangan 0.5 detik di layar hitam sebelum logo muncul
	await get_tree().create_timer(0.5).timeout
	
	# 2. FADE IN EFFECT: Memunculkan logo perlahan selama 1.5 detik
	var tween_in = create_tween()
	tween_in.tween_property(logo, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_in.finished
	
	# 3. HOLD STATE: Tahan logo menyala di layar selama 2.0 detik agar sempat dibaca
	await get_tree().create_timer(2.0).timeout
	
	# 4. FADE OUT EFFECT: Pudarkan kembali logo ke hitam selama 1.0 detik
	var tween_out = create_tween()
	tween_out.tween_property(logo, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween_out.finished
	
	# Jeda dramatis singkat di layar hitam sebelum lompat ke menu utama
	await get_tree().create_timer(0.4).timeout
	
	# 5. TRANSISI: Pindahkan scene langsung ke Main Menu kamu
	# (Pastikan path file di bawah ini sudah sesuai dengan letak scene Main Menu aslimu)
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
