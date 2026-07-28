extends CharacterBody2D

# --- STATS ENEMY BOW (KROCO JARAK JAUH) ---
@export var speed: float = 50.0 
@export var ATTACK_RANGE: float = 180.0 
@export var max_health: float = 35.0 
@export var ATTACK_COOLDOWN: float = 2.0 
@export var projectile_scene: PackedScene 

var knockback_velocity: Vector2 = Vector2.ZERO
var is_stunned: bool = false
@export var KNOCKBACK_DECAY: float = 8.0

var current_health: float 
var is_dead: bool = false 
var is_taking_damage: bool = false 
var is_attacking: bool = false 
var can_attack: bool = true 

var player: CharacterBody2D = null 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready() -> void:
	add_to_group("enemy_group") 
	current_health = max_health 
	var player_nodes = get_tree().get_nodes_in_group("player_group") 
	if player_nodes.size() > 0: 
		player = player_nodes[0] 

func _physics_process(_delta: float) -> void:
	# Reduksi knockback musuh secara berkala
	if knockback_velocity.length() > 0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * 100 * _delta)

	if is_dead or is_taking_damage or is_attacking or is_stunned or not player:
		velocity = knockback_velocity
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	if distance_to_player <= ATTACK_RANGE and can_attack:
		_eksekusi_menembak()
		return

	# AI Berjalan mendekat jika player terlalu jauh dari jangkauan busur
	velocity = direction * speed
	if animated_sprite.animation.to_lower() != "walk":
		animated_sprite.play("walk")
		
	# --- 🛠️ FIX UTAMA: FLIP SEMUA KOMPONEN (MUZZLE, HITBOX, HURTBOX) SEKALIGUS ---
	if direction.x != 0:
		# Jika bergerak ke kiri (direction.x < 0), set scale.x menjadi -1
		# Jika bergerak ke kanan (direction.x > 0), set scale.x menjadi 1
		var arah_skala = -1.0 if direction.x < 0 else 1.0
		
		# Balik seluruh komponen visual dan collision area berbasis scale horizontal
		animated_sprite.scale.x = abs(animated_sprite.scale.x) * arah_skala
		$EnemyHitbox.scale.x = arah_skala
		$EnemyHurtbox.scale.x = arah_skala
		if has_node("Muzzle"):
			$Muzzle.position.x = abs($Muzzle.position.x) * arah_skala
	
	velocity = (direction * speed) + knockback_velocity
	move_and_slide()

func _eksekusi_menembak() -> void: 
	is_attacking = true 
	can_attack = false 
	velocity = Vector2.ZERO 
	animated_sprite.play("attack") 

# --- Hubungkan ke Sinyal frame_changed milik AnimatedSprite2D di Editor ---
func _on_enemy_frame_changed() -> void:
	var nama_anim_kecil = animated_sprite.animation.to_lower()
	
	if "attack" in nama_anim_kecil and animated_sprite.frame == 5:
		if projectile_scene == null or player == null: return
		
		# 🛠️ AMANKAN ARAH HADAP SEBELUM SPAWN
		var arah_ke_player = (player.global_position - global_position).normalized()
		if arah_ke_player.x != 0:
			var arah_skala = -1.0 if arah_ke_player.x < 0 else 1.0
			animated_sprite.scale.x = abs(animated_sprite.scale.x) * arah_skala
			$EnemyHitbox.scale.x = arah_skala
			$EnemyHurtbox.scale.x = arah_skala
			if has_node("Muzzle"):
				$Muzzle.position.x = abs($Muzzle.position.x) * arah_skala

		var posisi_spawn = global_position
		if has_node("Muzzle"):
			posisi_spawn = $Muzzle.global_position
			
		var panah = projectile_scene.instantiate()
		panah.global_position = posisi_spawn
		
		var arah_panah = (player.global_position - posisi_spawn).normalized()
		if panah.has_method("set_direction"):
			panah.set_direction(arah_panah)
			
		get_tree().current_scene.add_child(panah)
		print("[🏹 BOW] Anak panah BERHASIL dilahirkan di arena!")

func _on_animation_finished() -> void: 
	var nama_animasi_sekarang = animated_sprite.animation.to_lower() 
	
	if "attack" in nama_animasi_sekarang or "serang" in nama_animasi_sekarang: 
		is_attacking = false 
		animated_sprite.play("idle") 
		
		can_attack = false 
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout 
		can_attack = true 
		
	elif "hurt" in nama_animasi_sekarang: 
		is_taking_damage = false 
		animated_sprite.play("idle") 
		
	elif "die" in nama_animasi_sekarang or "dead" in nama_animasi_sekarang: 
		queue_free() 

func _on_enemy_hurtbox_area_entered(area: Area2D) -> void: 
	if is_dead: return 
	if area.name == "PlayerHitbox" or area.is_in_group("player_hitbox"): 
		_terkena_luka(25.0) 

func _terkena_luka(amount: float) -> void: 
	current_health -= amount 
	is_attacking = false 
	if current_health > 0: 
		is_taking_damage = true 
		animated_sprite.play("hurt") 
	else: 
		is_dead = true 
		collision_layer = 0 
		collision_mask = 0 
		animated_sprite.play("die")
		
		var arena = get_tree().get_first_node_in_group("arena_combat")
		if arena and arena.has_method("_on_enemy_died"):
			arena._on_enemy_died(2)

# --- MODIFIKASI FUNGSI LUCA BAWAAN MUSUH ---
func _terkena_luka_with_knockback(amount: float, posisi_player: Vector2) -> void:
	if is_dead: return
	
	# Hitung arah knockback dari tebasan pedang player
	var arah_dorong = (global_position - posisi_player).normalized()
	knockback_velocity = arah_dorong * 250.0
	
	_terkena_luka(amount)

# --- FUNGSI BARU JIKA MUSUH TERKENA PARRY PLAYER ---
func dipicu_parry(posisi_player: Vector2) -> void:
	if is_dead: return
	
	is_attacking = false
	is_stunned = true
	
	# Pental musuh ke belakang menjauh dari player
	var arah_pental = (global_position - posisi_player).normalized()
	knockback_velocity = arah_pental * 400.0 # Pentalan parry lebih kuat
	
	animated_sprite.play("idle") # Atau mainkan animasi khusus jika ada
	
	# Efek Berkedip Kuning (Modulate Warna R:2, G:2, B:0 untuk efek glow kuning stabil)
	var timer_kedip = get_tree().create_timer(1.5)
	while timer_kedip.get_time_left() > 0:
		if is_dead: break
		animated_sprite.modulate = Color(2, 2, 0) # Kuning terang
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1) # Normal kembali
		await get_tree().create_timer(0.1).timeout
		
	is_stunned = false
