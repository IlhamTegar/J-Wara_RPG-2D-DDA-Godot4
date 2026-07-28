extends Area2D

var player_di_area: bool = false

# --- REFERENSI KE UI TOKO DI CANVAS LAYER SAFEZONE ---
@onready var label_petunjuk: Label = $Label
@onready var toko_panel: Control = get_parent().get_node("UI_Layer/TokoPanel")
@onready var buy_button: Button = get_parent().get_node("UI_Layer/TokoPanel/MenuBar/Buy_Button")

# --- REFERENSI ANIMASI NPC MERCHANT NEW ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	label_petunjuk.hide() 
	
	body_entered.connect(_on_body_entered) 
	body_exited.connect(_on_body_exited) 
	
	if is_instance_valid(animated_sprite):
		animated_sprite.play("idle")

func _process(_delta: float) -> void:
	# Detektor auto-reset jika toko ditutup dari tombol Cancel luar UI
	if is_instance_valid(toko_panel) and not toko_panel.visible and animated_sprite.animation == "talk":
		_tutup_toko_merchant()

	if player_di_area and Input.is_action_just_pressed("interaksi"): 
		if is_instance_valid(toko_panel): 
			if toko_panel.visible: 
				_tutup_toko_merchant()
			else:
				_buka_toko_merchant()

func _buka_toko_merchant() -> void:
	if is_instance_valid(toko_panel) and toko_panel.has_method("_refresh_tampilan_toko"):
		toko_panel._refresh_tampilan_toko()
		
	toko_panel.show() 
	label_petunjuk.hide() # Sembunyikan huruf F saat masuk toko
	
	if is_instance_valid(animated_sprite):
		animated_sprite.play("talk")
	
	if is_instance_valid(buy_button):
		buy_button.grab_focus()

func _tutup_toko_merchant() -> void:
	if is_instance_valid(toko_panel) and toko_panel.visible:
		toko_panel.hide() 
	
	if is_instance_valid(animated_sprite):
		animated_sprite.play("idle")
		
	if player_di_area: 
		label_petunjuk.text = "F"
		label_petunjuk.show() 

# 🛠️ FUNGSI INTERUPSI: Muncul HANYA saat dipaksa beli melebihi kuota, lalu hilang otomatis setelah 2 detik
func tampilkan_peringatan_kuota(teks_peringatan: String) -> void:
	label_petunjuk.text = teks_peringatan
	label_petunjuk.show()
	
	# Amankan visual: Memainkan animasi bicara sebentar saat menegur player
	if is_instance_valid(animated_sprite):
		animated_sprite.play("talk")
		
	await get_tree().create_timer(2.0).timeout
	
	# Jika setelah 2 detik toko masih terbuka, sembunyikan omelan merchant
	if is_instance_valid(toko_panel) and toko_panel.visible:
		label_petunjuk.hide()
		if is_instance_valid(animated_sprite):
			animated_sprite.play("idle") # Kembalikan animasi diam

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_group"): 
		player_di_area = true 
		label_petunjuk.text = "F" 
		label_petunjuk.show() 

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_group"): 
		player_di_area = false 
		label_petunjuk.hide() 
		_tutup_toko_merchant()
