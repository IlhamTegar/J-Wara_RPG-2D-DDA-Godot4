extends CharacterBody2D

# --- CONFIG PERGERAKAN ---
@export var SPEED : float = 150.0
@export var DASH_SPEED : float = 350.0
@export var DASH_DURATION : float = 0.25
@export var JUMP_VELOCITY : float = -350.0

# --- STATUS UTAMA PLAYER ---
@export var max_health: float = 100.0
var current_health: float
var is_player_dead: bool = false
var is_taking_damage: bool = false 

# --- SISTEM STAMINA BARU ---
@export var max_stamina: float = 100.0
var current_stamina: float
@export var stamina_regen_rate: float = 25.0 
const BIAYA_DASH: float = 30.0
const BIAYA_PARRY: float = 20.0

# --- KNOCKBACK PLAYER ---
var knockback_velocity: Vector2 = Vector2.ZERO
@export var KNOCKBACK_STRENGTH: float = 250.0 # Sedikit dinaikkan agar pentalan terasa

# --- STATE MEKANIK COMBAT & DASH ---
var is_dashing : bool = false
var is_attacking : bool = false
var is_invincible : bool = false 
var is_parrying : bool = false 
var dash_direction : Vector2 = Vector2.ZERO

# --- SISTEM KOMBO & DASH ATTACK NEW ---
var combo_state: int = 1 
var can_dash_attack: bool = false 

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- REFRENSİ NODE ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape_1: CollisionShape2D = $Hitbox/HitboxShape1
@onready var hitbox_shape_2: CollisionShape2D = $Hitbox/HitboxShape2
@onready var hitbox_shape_3: CollisionShape2D = $Hitbox/HitboxShape3
@onready var hurtbox: Area2D = $Hurtbox

# --- REFERENSI HUD UI BARU ---
@onready var hp_bar: TextureProgressBar = get_node_or_null("../HUD_Layer/HUD_Panel/HP_Bar")
@onready var stamina_bar: TextureProgressBar = get_node_or_null("../HUD_Layer/HUD_Panel/Stamina_Bar")

func _ready() -> void:
	GlobalGameManager.reset_data_wave_baru()
	current_health = max_health
	current_stamina = max_stamina
	is_player_dead = false
	is_taking_damage = false
	is_parrying = false
	
	add_to_group("player_group")
	
	if is_instance_valid(hurtbox):
		hurtbox.add_to_group("player_hurtbox")
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	if not animated_sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		animated_sprite.frame_changed.connect(_on_sprite_frame_changed)
	
	_matikan_semua_hitbox()
	_update_hud_visual()

func _physics_process(delta: float) -> void:
	if is_player_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- REGENERASI STAMINA OTOMATIS (HANYA AKTIF JIKA HIDUP) ---
	if current_stamina < max_stamina:
		current_stamina = move_toward(current_stamina, max_stamina, stamina_regen_rate * delta)
		if is_instance_valid(stamina_bar):
			stamina_bar.value = current_stamina

	# --- 1. SEKAT UTAMA DASH ---
	if is_dashing:
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
		velocity = dash_direction * DASH_SPEED
		move_and_slide()
		return

	# --- 2. KALKULASI KNOCKBACK AGAR CHARACTER BISA MUNDUR ---
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return

	# --- 3. LOGIC SAFEZONE ---
	if GlobalGameManager.is_in_safezone:
		if not is_on_floor(): 
			velocity.y += gravity * delta
		
		var safe_dir_x = 0.0
		if Input.is_key_pressed(KEY_D): safe_dir_x += 1.0
		if Input.is_key_pressed(KEY_A): safe_dir_x -= 1.0
		
		if safe_dir_x != 0.0:
			velocity.x = safe_dir_x * SPEED
			animated_sprite.play("safe_walk")
			animated_sprite.flip_h = (safe_dir_x < 0)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animated_sprite.play("safe_idle")
		move_and_slide()
		return

	# --- 🛠️ FIX TOTAL LUPUH: KUNCI INPUT HANYA BERLAKU SEKEJAP (0.15 DETIK) ---
	if is_taking_damage:
		# Buat timer instan untuk membuka paksa status terkunci jika macet
		get_tree().create_timer(0.15).timeout.connect(func():
			is_taking_damage = false
		)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- 5. INPUT DETEKSI AKSI COMBAT (PARRY & SERANG) ---
	if Input.is_action_just_pressed("parry") and not is_attacking and not is_dashing:
		if current_stamina >= BIAYA_PARRY:
			current_stamina -= BIAYA_PARRY
			_update_hud_visual()
			_eksekusi_parry()
		else:
			print("[STAMINA] Gagal Parry! Stamina kosong.")
		return

	if Input.is_action_just_pressed("serang") and not is_attacking:
		_eksekusi_serangan()
		return

	if is_attacking or is_parrying:
		if animated_sprite.animation == "attack3":
			velocity = velocity.move_toward(Vector2.ZERO, 500 * delta)
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return

	# =================================================================
	# 🛠️ PERBAIKAN UTAMA: SISTEM INPUT VECTOR RESPONSIF & DINAMIS
	# =================================================================
	var direction_x := 0.0
	var direction_y := 0.0
	
	# Membaca pergerakan keyboard secara real-time
	if Input.is_key_pressed(KEY_D): direction_x += 1.0
	if Input.is_key_pressed(KEY_A): direction_x -= 1.0
	if Input.is_key_pressed(KEY_S): direction_y += 1.0
	if Input.is_key_pressed(KEY_W): direction_y -= 1.0
	
	var input_vector = Vector2(direction_x, direction_y)
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	# =================================================================

	# --- 6. PEMICU DASH / DODGE ---
	if Input.is_action_just_pressed("dodge") and input_vector != Vector2.ZERO:
		if current_stamina >= BIAYA_DASH:
			current_stamina -= BIAYA_DASH
			_update_hud_visual()
			_eksekusi_dash(input_vector)
		else:
			print("[STAMINA] Gagal Dash! Stamina habis.")
		return 

	# --- 7. KALKULASI KECEPATAN BERJALAN & SET ANIMASI ---
	if input_vector.length() > 0:
		velocity = input_vector * SPEED
		if not is_parrying and not is_dashing and not can_dash_attack and not is_attacking:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		if direction_x != 0:
			animated_sprite.flip_h = (direction_x < 0)
			if is_instance_valid(hitbox):
				hitbox.scale.x = -1.0 if direction_x < 0 else 1.0
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		if not is_parrying and not is_dashing and not can_dash_attack and not is_attacking:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

	move_and_slide()
	
func _eksekusi_serangan() -> void:
	is_attacking = true
	if is_parrying:
		is_parrying = false
		animated_sprite.modulate = Color(1, 1, 1, 1)
		animated_sprite.speed_scale = 1.0
	if can_dash_attack:
		animated_sprite.speed_scale = 1.0 
		animated_sprite.play("attack3")
		var arah_hadap = -1.0 if animated_sprite.flip_h else 1.0
		velocity = Vector2(arah_hadap * (DASH_SPEED * 0.8), 0.0)
		can_dash_attack = false 
		return
	if combo_state == 1:
		animated_sprite.play("attack1")
		combo_state = 2 
	else:
		animated_sprite.play("attack2")
		combo_state = 1

func _eksekusi_parry() -> void:
	is_parrying = true
	if animated_sprite.sprite_frames.has_animation("parry"):
		animated_sprite.speed_scale = 2.5 
		animated_sprite.play("parry")
	else:
		animated_sprite.play("idle")
		animated_sprite.modulate = Color(0.5, 0.8, 1.0, 1) 
	await get_tree().create_timer(0.2).timeout
	if is_parrying:
		is_parrying = false
		animated_sprite.speed_scale = 1.0
		if not animated_sprite.sprite_frames.has_animation("parry"):
			animated_sprite.modulate = Color(1, 1, 1, 1)

func _on_sprite_frame_changed() -> void:
	if is_dashing: return
	if animated_sprite.animation == "attack1" and (animated_sprite.frame == 2 or animated_sprite.frame == 3):
		if is_instance_valid(hitbox_shape_1): hitbox_shape_1.disabled = false
		_proses_pemberian_damage(25.0)
	elif animated_sprite.animation == "attack2" and (animated_sprite.frame >= 2 and animated_sprite.frame <= 4):
		if is_instance_valid(hitbox_shape_2): hitbox_shape_2.disabled = false
		_proses_pemberian_damage(30.0) 
	elif animated_sprite.animation == "attack3" and (animated_sprite.frame >= 2 and animated_sprite.frame <= 4):
		if is_instance_valid(hitbox_shape_3): hitbox_shape_3.disabled = false
		_proses_pemberian_damage(40.0) 
	else:
		_matikan_semua_hitbox()

func _proses_pemberian_damage(damage_value: float) -> void:
	if is_instance_valid(hitbox):
		var target_terkena_hit = hitbox.get_overlapping_areas()
		for area in target_terkena_hit:
			if area.has_method("take_damage"):
				area.take_damage(damage_value, global_position)
			elif area.get_parent() and area.get_parent().has_method("take_damage"):
				area.get_parent().take_damage(damage_value, global_position)

func _matikan_semua_hitbox() -> void:
	if is_instance_valid(hitbox_shape_1): hitbox_shape_1.disabled = true
	if is_instance_valid(hitbox_shape_2): hitbox_shape_2.disabled = true
	if is_instance_valid(hitbox_shape_3): hitbox_shape_3.disabled = true

func _on_animation_finished() -> void:
	if animated_sprite.animation in ["attack1", "attack2", "attack3"]:
		is_attacking = false
		_matikan_semua_hitbox()
	elif animated_sprite.animation == "parry":
		is_parrying = false
		animated_sprite.speed_scale = 1.0
		animated_sprite.modulate = Color(1, 1, 1, 1)

# --- 🛠️ PERBAIKAN 3: DETEKSI SUMBER DAMAGE JELAS (MELEE VS ARROW DETECTOR) ---
func take_damage(amount: float, enemy_node: Node = null) -> void:
	# --- 🛠️ BYPASS LOCK: JIKA SEDANG KEBAL ATAU SEDANG TERLUKA, TOLAK HIT BERIKUTNYA ---
	if is_player_dead or is_invincible or is_taking_damage: return
		
	if is_parrying and enemy_node != null:
		print("[💥 PARRY SUKSES! 💥]") 
		is_parrying = false 
		animated_sprite.speed_scale = 1.0 
		animated_sprite.modulate = Color(1,1,1,1)
		if "makro_usaha_defensif" in GlobalGameManager:
			GlobalGameManager.makro_usaha_defensif += 2
		if enemy_node.has_method("terkena_stun_parry"):
			enemy_node.terkena_stun_parry()
		return
		
	current_health -= amount
	_update_hud_visual()

	if "mikro_damage_diterima" in GlobalGameManager:
		GlobalGameManager.mikro_damage_diterima += amount

	if enemy_node != null and "global_position" in enemy_node:
		var arah_pentalan = (global_position - enemy_node.global_position).normalized()
		knockback_velocity = arah_pentalan * KNOCKBACK_STRENGTH 

	if current_health > 0:
		if not is_taking_damage:
			is_taking_damage = true
			is_attacking = false # Batalkan status menyerang jika sedang memukul
			
			# Matikan semua hitbox serangan agar tidak ada sisa damage yang aktif saat pusing
			_matikan_semua_hitbox() 
			
			# Mainkan animasi hit secara tegas
			animated_sprite.play("hit")
			_efek_berkedip_merah()
			
			# --- 🛠️ PENGAMAN UTAMA (Sistem Timer Absolut) ---
			# Berapa pun musuh yang memukul, setelah 0.15 detik, kunci bodi WAJIB dibuka kembali
			var durasi_kaku = get_tree().create_timer(0.15)
			durasi_kaku.timeout.connect(func():
				is_taking_damage = false
				if animated_sprite.animation == "hit":
					animated_sprite.play("idle")
				print("[SYSTEM] Pengaman Waktu: Freeze animasi hit dipaksa lepas!")
			)
	else:
		is_player_dead = true 
		animated_sprite.play("dead") 
		var root_arena = get_parent() 
		if is_instance_valid(root_arena) and root_arena.has_method("memicu_defeated"):
			root_arena.memicu_defeated() 
			
func _on_hit_timeout() -> void:
	is_taking_damage = false
	# Paksa velocity diisi ulang sedikit agar bodi bergeser keluar dari jebakan musuh
	velocity = Vector2.ZERO 
	print("[SYSTEM] Kendali Player resmi dibuka kembali secara responsif!")

func _efek_berkedip_merah() -> void:
	animated_sprite.modulate = Color(2, 0.3, 0.3, 1) 
	await get_tree().create_timer(0.15).timeout
	animated_sprite.modulate = Color(1, 1, 1, 1)

func _eksekusi_dash(arah_input: Vector2) -> void:
	if is_dashing: return
	is_dashing = true
	is_invincible = true
	can_dash_attack = false
	dash_direction = arah_input.normalized()
	animated_sprite.speed_scale = 1.0
	animated_sprite.stop()
	animated_sprite.play("dash")
	animated_sprite.frame = 0
	velocity = dash_direction * DASH_SPEED
	var mask_sebelumnya = collision_mask
	set_collision_mask_value(3, false)
	set_collision_mask_value(2, true)
	if "makro_usaha_defensif" in GlobalGameManager:
		GlobalGameManager.makro_usaha_defensif += 1
	await get_tree().create_timer(DASH_DURATION).timeout
	collision_mask = mask_sebelumnya
	is_dashing = false
	is_invincible = false
	can_dash_attack = true
	await get_tree().create_timer(0.3).timeout
	if not is_attacking:
		can_dash_attack = false
		if velocity.length() > 10:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")

func _update_hud_visual() -> void:
	if is_instance_valid(hp_bar):hp_bar.value = current_health
	if is_instance_valid(stamina_bar):stamina_bar.value = current_stamina
