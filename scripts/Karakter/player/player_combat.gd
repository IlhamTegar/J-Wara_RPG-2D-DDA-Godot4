extends CharacterBody2D

# --- CONFIG PERGERAKAN & COMBAT ---
@export var SPEED : float = 150.0
@export var DASH_SPEED : float = 350.0
@export var DASH_DURATION : float = 0.25

# --- STATUS UTAMA PLAYER ---
@export var max_health: float = 100.0
var current_health: float
var is_player_dead: bool = false
var is_taking_damage: bool = false 
var is_invincible: bool = false
var long_buff_invincible_count: int = 0  # 🛠️ AMAN: Registrasi variabel counter pelindung durasi panjang
var attack_multiplier: float = 1.0  # Pengali damage tebasan pedang player
var can_use_potion: bool = true     # Status cek pencekalan minum ramuan darah
var has_revive_buff: bool = false   # Nyawa cadangan (Revive Buff)

# --- STATE MEKANIK COMBAT & DASH ---
var is_dashing : bool = false
var is_attacking : bool = false
var is_parrying : bool = false 
var dash_direction : Vector2 = Vector2.ZERO

# --- SISTEM KOMBO & DASH ATTACK ---
var combo_state: int = 1
var waktu_klik_terakhir: float = 0.0
@export var COMBO_WINDOW: float = 1.5 
var can_continue_combo: bool = false 
var combo_timer: SceneTreeTimer = null
var can_dash_attack: bool = false 

# --- SISTEM STAMINA & HUD CONFIG ---
@export var max_stamina: float = 100.0
var current_stamina: float
@export var STAMINA_REGEN_RATE: float = 15.0 
@export var DASH_STAMINA_COST: float = 25.0  

var hud_layer: CanvasLayer = null
var knockback_velocity: Vector2 = Vector2.ZERO
@export var KNOCKBACK_DECAY: float = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_shape_1: CollisionShape2D = $PlayerHitbox/CollisionShape2D1
@onready var hitbox_shape_2: CollisionShape2D = $PlayerHitbox/CollisionShape2D2
@onready var hitbox_shape_3: CollisionShape2D = $PlayerHitbox/CollisionShape2D3

func _ready() -> void:
	add_to_group("player_group")
	current_health = max_health
	current_stamina = max_stamina
	is_player_dead = false
	is_taking_damage = false
	is_parrying = false
	is_invincible = false
	long_buff_invincible_count = 0
	
	hud_layer = get_parent().get_node_or_null("HUD_Layer")
	_update_tampilan_hud()

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

	if is_instance_valid(hitbox_shape_1): hitbox_shape_1.disabled = true
	if is_instance_valid(hitbox_shape_2): hitbox_shape_2.disabled = true
	if is_instance_valid(hitbox_shape_3): hitbox_shape_3.disabled = true

func _physics_process(delta: float) -> void:
	if is_player_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback_velocity.length() > 0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * 100 * delta)
		
	var tas_lagi_buka = GlobalGameManager.is_inventory_open if "is_inventory_open" in GlobalGameManager else false

	# Hanya jalankan serangan jika tombol serang ditekan DAN tas sedang tertutup
	if Input.is_action_just_pressed("serang") and not tas_lagi_buka:
		_eksekusi_serangan_kombo_baru()
		return

	if not is_dashing and current_stamina < max_stamina:
		current_stamina = min(max_stamina, current_stamina + (STAMINA_REGEN_RATE * delta))
		_update_tampilan_hud()

	if is_dashing or is_taking_damage:
		velocity = (dash_direction * DASH_SPEED if is_dashing else Vector2.ZERO) + knockback_velocity
		move_and_slide()
		return

	var direction_x := 0.0
	var direction_y := 0.0
	if Input.is_key_pressed(KEY_D): direction_x += 1.0
	if Input.is_key_pressed(KEY_A): direction_x -= 1.0
	if Input.is_key_pressed(KEY_S): direction_y += 1.0
	if Input.is_key_pressed(KEY_W): direction_y -= 1.0
	var input_vector = Vector2(direction_x, direction_y)

	if Input.is_action_just_pressed("dodge") and input_vector != Vector2.ZERO and not is_dashing:
		if current_stamina >= DASH_STAMINA_COST:
			current_stamina -= DASH_STAMINA_COST
			_update_tampilan_hud()
			_eksekusi_dash(input_vector)
			return
		else:
			print("[⚠️ SYSTEM] Stamina tidak cukup untuk melakukan Dash!")

	#if Input.is_action_just_pressed("serang"):
		#_eksekusi_serangan_kombo_baru()
		#return

	if Input.is_action_just_pressed("parry") and not is_attacking and not is_dashing:
		_eksekusi_parry()
		return

	if is_attacking or is_parrying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		velocity = input_vector * SPEED
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		if direction_x != 0:
			animated_sprite.flip_h = (direction_x < 0)
			$PlayerHitbox.scale.x = -1.0 if direction_x < 0 else 1.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

	velocity += knockback_velocity
	move_and_slide()

func minum_potion_darah(heal_amount: float) -> void:
	if not can_use_potion:
		print("[⚠️ DEBUFF ACTIVATED] Kamu tidak bisa meminum Potion saat ini!")
		return
	if is_player_dead: return
	current_health = min(max_health, current_health + heal_amount)
	_update_tampilan_hud()
	
	GlobalGameManager.mikro_potion_digunakan = true
	GlobalGameManager.makro_total_potion_wave += 1
	print("[🧪 FUZZY TRACK] Player meminum potion tambahan.")

func _matikan_semua_hitbox() -> void:
	if is_instance_valid(hitbox_shape_1): hitbox_shape_1.set_deferred("disabled", true)
	if is_instance_valid(hitbox_shape_2): hitbox_shape_2.set_deferred("disabled", true)
	if is_instance_valid(hitbox_shape_3): hitbox_shape_3.set_deferred("disabled", true)

func _eksekusi_serangan_kombo_baru() -> void:
	if can_dash_attack:
		is_attacking = true
		can_dash_attack = false
		combo_state = 1
		animated_sprite.play("attack3")
		print("[⚔️ DASH ATTACK] Sukses memicu Attack 3!")
		var arah_hadap = -1.0 if animated_sprite.flip_h else 1.0
		velocity = Vector2(arah_hadap * (DASH_SPEED * 0.4), 0.0)
		SoundManager.play_sfx("dash_attack")
		return

	if is_attacking: return
	
	is_attacking = true
	var waktu_sekarang = Time.get_ticks_msec() / 1000.0
	var selisih_waktu = waktu_sekarang - waktu_klik_terakhir
	waktu_klik_terakhir = waktu_sekarang

	if selisih_waktu <= COMBO_WINDOW:
		if combo_state == 1:
			animated_sprite.play("attack1")
			combo_state = 2
		elif combo_state == 2:
			animated_sprite.play("attack2")
			combo_state = 1
	else:
		combo_state = 1
		animated_sprite.play("attack1")
		combo_state = 2
	SoundManager.play_sfx("sword_swing")

func _eksekusi_parry() -> void:
	is_parrying = true
	animated_sprite.play("parry")
	
	GlobalGameManager.makro_usaha_defensif += 1
	GlobalGameManager.mikro_total_serangan_masuk += 1
	
	await get_tree().create_timer(0.3).timeout
	is_parrying = false
	SoundManager.play_sfx("parry")

func _eksekusi_dash(arah: Vector2) -> void:
	if is_attacking:
		is_attacking = false
		_matikan_semua_hitbox()
		print("[⚡ DASH CANCEL] Sukses membatalkan serangan dengan melakukan Dash!")

	is_dashing = true
	is_invincible = true
	can_dash_attack = false
	_reset_combo_state()
	
	set_collision_mask_value(3, false)
	
	GlobalGameManager.mikro_sukses_dodge += 1
	GlobalGameManager.makro_sukses_defensif += 1
	
	dash_direction = arah.normalized()
	animated_sprite.play("dash")
	SoundManager.play_sfx("dash")
	
	await get_tree().create_timer(DASH_DURATION).timeout
	is_dashing = false
	is_invincible = false
	set_collision_mask_value(3, true)
	
	can_dash_attack = true
	await get_tree().create_timer(0.25).timeout
	can_dash_attack = false

func _on_sprite_frame_changed() -> void:
	if is_dashing: return
	var sedang_di_frame_serang: bool = false

	if animated_sprite.animation == "attack1" and (animated_sprite.frame == 4 or animated_sprite.frame == 5):
		if is_instance_valid(hitbox_shape_1):
			hitbox_shape_1.set_deferred("disabled", false)
			sedang_di_frame_serang = true
	elif animated_sprite.animation == "attack2" and (animated_sprite.frame == 3 or animated_sprite.frame == 4):
		if is_instance_valid(hitbox_shape_2):
			hitbox_shape_2.set_deferred("disabled", false)
			sedang_di_frame_serang = true
	elif animated_sprite.animation == "attack3" and (animated_sprite.frame == 6 or animated_sprite.frame == 7):
		if is_instance_valid(hitbox_shape_3):
			hitbox_shape_3.set_deferred("disabled", false)
			sedang_di_frame_serang = true

	if not sedang_di_frame_serang:
		_matikan_semua_hitbox()

func _on_player_hitbox_area_entered(area: Area2D) -> void:
	if area.name == "EnemyHurtbox" or area.is_in_group("enemy_hurtbox"):
		var enemy_root = area.get_parent()
		if enemy_root and enemy_root.has_method("_terkena_luka_with_knockback"):
			var final_damage = 25.0 * attack_multiplier
			enemy_root._terkena_luka_with_knockback(final_damage, global_position)
			print("[⚔️ ATTACK] Damage keluar: ", final_damage)

func _on_animation_finished() -> void:
	if animated_sprite.animation in ["attack1", "attack2", "attack3"]:
		is_attacking = false
		_matikan_semua_hitbox()
		if animated_sprite.animation == "attack3":
			combo_state = 1
	elif animated_sprite.animation == "parry":
		is_parrying = false
	elif animated_sprite.animation == "hurt":
		is_taking_damage = false
		is_invincible = false
		animated_sprite.play("idle")

func take_damage(amount: float) -> void:
	# 🛠️ AMAN: Proteksi gerbang utama mengecek status kebal normal dan counter lapisan panjang
	if is_player_dead or is_invincible or long_buff_invincible_count > 0 or is_taking_damage: return
	
	if is_parrying:
		print("[🛡️ PARRY SUCCESS] Player berhasil menangkal damage masuk via fungsi utama!")
		GlobalGameManager.mikro_sukses_parry += 1
		GlobalGameManager.makro_sukses_defensif += 1
		return

	if is_attacking:
		is_attacking = false
		_matikan_semua_hitbox()
		print("[💥 HIT INTERRUPT] Animasi serang Player dibatalkan karena terkena hit!")
	
	GlobalGameManager.mikro_damage_diterima += amount
	GlobalGameManager.makro_total_hp_berkurang += amount
	
	current_health = max(0.0, current_health - amount)
	_update_tampilan_hud()
	
	if is_instance_valid(animated_sprite):
		animated_sprite.modulate = Color(1.0, 0.0, 0.0, 1.0)
		get_tree().create_timer(0.15).timeout.connect(func():
			if is_instance_valid(animated_sprite):
				animated_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		)
	
	if current_health > 0:
		is_taking_damage = true
		is_invincible = true
		animated_sprite.play("hurt")
		
		get_tree().create_timer(0.2).timeout.connect(func():
			if is_taking_damage:
				is_taking_damage = false
				is_invincible = false
				if animated_sprite.animation == "hurt":
					animated_sprite.play("idle")
		)
	else:
		if has_revive_buff:
			has_revive_buff = false 
			current_health = max_health * 0.5 
			_update_tampilan_hud()
			
			long_buff_invincible_count += 1 # 🛠️ Lapisan kebal diaktifkan
			animated_sprite.play("idle")
			_set_teks_buff_hud("BUFF EFFECT: Kebal Pasif Bangkit (5s)")
			print("[😇 REVIVE SUCCESS] Player bangkit dari kematian dengan 50% HP + Kebal 5 detik!")
			
			await get_tree().create_timer(5.0).timeout
			long_buff_invincible_count -= 1 # 🛠️ Lapisan kebal dikurangi secara independen
			_set_teks_buff_hud("")
			return 
			
		# Logika kematian asli jika player tidak memiliki/gagal gacha revive buff
		is_player_dead = true
		animated_sprite.play("die")
		
		var arena = get_tree().get_first_node_in_group("arena_combat")
		if arena and arena.has_method("memicu_defeated"):
			# 🛠️ SUNTIKAN KATUP PENGAMAN: Cek kevalidan instansi node setelah timer 1.2 detik selesai
			get_tree().create_timer(1.2).timeout.connect(func():
				if is_instance_valid(arena) and arena.has_method("memicu_defeated"):
					arena.memicu_defeated()
				else:
					print("[⚠️ SYSTEM SAFETY] Gagal memicu defeated karena arena sudah tidak valid (Nil).")
			)

func take_damage_with_knockback(amount: float, posisi_sumber_serangan: Vector2) -> void:
	if is_player_dead or is_invincible or long_buff_invincible_count > 0 or is_taking_damage: return
	
	if is_parrying:
		print("[🛡️ PARRY SUCCESS] Player berhasil menangkis serangan!")
		GlobalGameManager.mikro_sukses_parry += 1
		GlobalGameManager.makro_sukses_defensif += 1
		return
		
	var arah_dorong = (global_position - posisi_sumber_serangan).normalized()
	knockback_velocity = arah_dorong * 300.0
	take_damage(amount)

func _update_tampilan_hud() -> void:
	if hud_layer != null:
		var hp_bar = hud_layer.get_node_or_null("HUD_Panel/HP_Bar")
		var stamina_bar = hud_layer.get_node_or_null("HUD_Panel/Stamina_Bar")
		if hp_bar is TextureProgressBar: hp_bar.value = current_health
		if stamina_bar is TextureProgressBar: stamina_bar.value = current_stamina

func _set_teks_buff_hud(teks: String) -> void:
	print("\n--- [🔍 RADAR BUFF HUD] Pemicu Aktif ---")
	print("[DEBUG BUFF] Target teks baru: '", teks, "'")
	
	if hud_layer == null:
		print("[❌ ERROR HUD] 'hud_layer' bernilai NULL! Player gagal mendeteksi HUD_Layer di arena.")
		return
		
	var label_buff = hud_layer.get_node_or_null("HUD_Panel/BuffLabel")
	if label_buff == null:
		print("[⚠️ PATH MISS] Lintasan 'HUD_Panel/BuffLabel' salah. Mencari otomatis ke seluruh anak node...")
		label_buff = hud_layer.find_child("BuffLabel", true, false)
		
	if label_buff is Label:
		label_buff.text = teks
		print("[✅ SUCCESS BUFF] Teks berhasil disuntikkan ke layar UI!")
	else:
		if label_buff == null:
			print("[❌ CRITICAL ERROR] Node bernama 'BuffLabel' LITERALLY TIDAK ADA di dalam HUD_Layer kamu!")
		else:
			print("[❌ TYPE ERROR] Node ketemu, tapi tipenya BUKAN Label! Melainkan: ", label_buff.get_class())
	print("-----------------------------------------\n")

func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	# 🛠️ AMAN: Pengunci gerbang sinyal fisik dari musuh, membaca sistem lapisan kebal durasi panjang
	if is_player_dead or is_invincible or long_buff_invincible_count > 0 or is_taking_damage:
		print("[🛡️ SYSTEM BLOCK] Sinyal fisik musuh dibatalkan karena Player dalam mode kebal!")
		return
	
	if is_parrying:
		print("[🛡️ PARRY SUCCESS] Player berhasil menangkis serangan fisik gada!")
		GlobalGameManager.mikro_sukses_parry += 1
		GlobalGameManager.makro_sukses_defensif += 1
		return

	GlobalGameManager.mikro_total_serangan_masuk += 1
	
	if area.name == "EnemyHitbox" or area.is_in_group("enemy_heartbox"):
		print("[💥 DAMAGE] Player terkena hantaman gada musuh!")
		take_damage(10.0)
		return

	if area.is_in_group("projektil") or "arrow" in area.name.to_lower():
		print("[🎯 ARROW HURTBOX SUCCESS] Anak panah sukses menembus dada Player!")
		take_damage(12.0)
		if is_instance_valid(area):
			area.call_deferred("queue_free")
		return

func _reset_combo_state() -> void:
	combo_state = 1
	can_continue_combo = false

# ===================================================================
# 🎰 MEKANIK GACHA: HIGH SCROLL BUFF
# ===================================================================
func gunakan_high_scroll() -> void:
	if is_player_dead: return
	var acak = randf() * 100.0
	print("[🎲 HIGH SCROLL] Memutar gacha item...")
	
	if acak <= 5.0:
		has_revive_buff = true
		_set_teks_buff_hud("BUFF: Nyawa Cadangan Aktif (Pasif)")
		print("[BUFF] Sukses mendapatkan Nyawa Cadangan!")
		
	elif acak <= 25.0:
		long_buff_invincible_count += 1 # 🛠️ Menggunakan penambah lapisan counter
		_set_teks_buff_hud("BUFF: Kebal Semua Serangan (15s)")
		print("[BUFF] Player menjadi KEBAL selama 15 detik!")
		
		await get_tree().create_timer(15.0).timeout
		long_buff_invincible_count -= 1 # 🛠️ Pengurang lapisan counter aman tanpa bentrok
		_set_teks_buff_hud("")
		print("[BUFF] Efek kebal 15 detik telah habis.")
		
	elif acak <= 50.0:
		var sisa_regen = STAMINA_REGEN_RATE
		STAMINA_REGEN_RATE = 50.0
		_set_teks_buff_hud("BUFF: Stamina Surge (Regen Kilat 20s)")
		print("[BUFF] Stamina Surge Aktif selama 20 detik!")
		
		await get_tree().create_timer(20.0).timeout
		STAMINA_REGEN_RATE = sisa_regen
		_set_teks_buff_hud("")
		print("[BUFF] Efek Stamina Surge berakhir.")
		
	else:
		attack_multiplier = 2.0
		SPEED = 200.0
		_set_teks_buff_hud("BUFF: Rage Mode! Damage x2 & Speed Naik (15s)")
		print("[BUFF] Rage Mode Aktif selama 15 detik!")
		
		await get_tree().create_timer(15.0).timeout
		attack_multiplier = 1.0
		SPEED = 150.0
		_set_teks_buff_hud("")
		print("[BUFF] Efek Rage Mode normal kembali.")

# ===================================================================
# 💀 EXTREME MEKANIK: ANCIENT SCROLL BUFF & DEBUFF (HIGH RISK)
# ===================================================================
func gunakan_ancient_scroll() -> void:
	if is_player_dead: return
	var dadu = randf() * 100.0
	print("[🔮 ANCIENT SCROLL] Membuka gulungan terlarang...")
	
	if dadu <= 1.0:
		_set_teks_buff_hud("TIER 3 BUFF: ANCIENT WIDEOUT ARENA!")
		print("[👑 BUFF TIER 3] DEWA KEBERUNTUNGAN! Menghancurkan seluruh isi arena!")
		var enemies = get_tree().get_nodes_in_group("enemy_group")
		for enemy in enemies:
			if is_instance_valid(enemy):
				if enemy.has_node("CollisionShape2D"):
					enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
				if enemy.has_node("AnimatedSprite2D"):
					enemy.get_node("AnimatedSprite2D").play("die")
					
		await get_tree().create_timer(1.5).timeout
		for enemy in enemies:
			if is_instance_valid(enemy): enemy.queue_free()
			
		var arena = get_tree().get_first_node_in_group("arena_combat")
		if arena and arena.has_method("memicu_victory"):
			arena.memicu_victory()
			
	elif dadu <= 2.0:
		_set_teks_buff_hud("TIER 3 DEBUFF: KUTUKAN MATI INSTAN!")
		print("[💀 DEBUFF TIER 3] KUTUKAN ANCIENT! Kamu tewas seketika!")
		current_health = 0.0
		_update_tampilan_hud()
		is_player_dead = true
		animated_sprite.play("die")
		
	elif dadu <= 16.0:
		print("[🔷 BUFF TIER 2] Mendapatkan berkah tingkat tinggi!")
		if randf() > 0.5:
			long_buff_invincible_count += 1 # 🛠️ Lapisan kebal gacha premium
			_set_teks_buff_hud("TIER 2 BUFF: Kebal Serangan (15s)")
			await get_tree().create_timer(15.0).timeout
			long_buff_invincible_count -= 1
			_set_teks_buff_hud("")
		else:
			has_revive_buff = true
			_set_teks_buff_hud("TIER 2 BUFF: Nyawa Cadangan Aktif")
			
	elif dadu <= 30.0:
		print("[❌ DEBUFF TIER 2] Terkena Kutukan Pembusukan Darah!")
		can_use_potion = false
		SPEED = 75.0
		_set_teks_buff_hud("DEBUFF TIER 2: Pembusukan Darah (-5HP/s) & Cekal Potion (10s)")
		
		for i in range(10):
			if is_player_dead: break
			await get_tree().create_timer(1.0).timeout
			current_health = max(1.0, current_health - 5.0)
			_update_tampilan_hud()
			
		can_use_potion = true
		SPEED = 150.0
		_set_teks_buff_hud("")
		print("[❌ DEBUFF TIER 2] Kutukan selesai.")
		
	elif dadu <= 65.0:
		print("[⚪ BUFF TIER 1] Statistik meningkat ringan.")
		attack_multiplier = 1.35
		SPEED = 180.0
		_set_teks_buff_hud("TIER 1 BUFF: ATK +35% & Kecepatan Naik (15s)")
		
		await get_tree().create_timer(15.0).timeout
		attack_multiplier = 1.0
		SPEED = 150.0
		_set_teks_buff_hud("")
		
	else:
		print("[🔸 DEBUFF TIER 1] Tubuh lemas!")
		SPEED = 75.0
		attack_multiplier = 0.75
		_set_teks_buff_hud("DEBUFF TIER 1: Slowness 50% & Damage Lemas -25% (10s)")
		
		await get_tree().create_timer(10.0).timeout
		SPEED = 150.0
		attack_multiplier = 1.0
		_set_teks_buff_hud("")
