extends CharacterBody2D

# --- STATS BOSS KING (FINAL BOSS: AGILITY CEPAT, COOLDOWN SINGKAT) ---
@export var speed: float = 55.0
@export var max_health: float = 400.0
@export var ATTACK_COOLDOWN: float = 0.8 # Sangat agresif menyerang beruntun

# 🛠️ FIX EROR MERAH IDENTIFIER: Deklarasi variabel knockback & stun yang kurang!
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

	if has_node("EnemyHitbox/CollisionShape2D"):
		$EnemyHitbox/CollisionShape2D.disabled = true

	# 🛠️ FIX BISA DI-HIT: Ikat sinyal hurtbox secara otomatis lewat kode
	var hurtbox_node = get_node_or_null("EnemyHurtbox")
	if hurtbox_node:
		if not hurtbox_node.area_entered.is_connected(_on_enemy_hurtbox_area_entered):
			hurtbox_node.area_entered.connect(_on_enemy_hurtbox_area_entered)
			print("[👑 BOSS KING] Sinyal EnemyHurtbox sukses diikat otomatis!")

func _physics_process(_delta: float) -> void:
	if knockback_velocity.length() > 0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * 100 * _delta)

	if is_dead or is_taking_damage or is_attacking or is_stunned or not player:
		velocity = knockback_velocity
		move_and_slide()
		return

	# Logika area serang kotak responsif
	var jarak_x = abs(player.global_position.x - global_position.x)
	var jarak_y = abs(player.global_position.y - global_position.y)
	var direction = (player.global_position - global_position).normalized()

	var jangkauan_horizontal: float = 65.0 
	var jangkauan_vertikal: float = 30.0
	
	if jarak_x <= jangkauan_horizontal and jarak_y <= jangkauan_vertikal and can_attack:
		animated_sprite.flip_h = (direction.x < 0)
		$EnemyHitbox.scale.x = -1.0 if direction.x < 0 else 1.0
		_eksekusi_serangan_raja()
		return

	velocity = direction * speed
	
	# 🛠️ FIX ANIMASI: Pengaman agar animasi jalan tidak stuck/membeku akibat FPS tinggi
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
		
	animated_sprite.flip_h = (direction.x < 0)
	$EnemyHitbox.scale.x = -1.0 if direction.x < 0 else 1.0
	
	velocity = (direction * speed) + knockback_velocity
	move_and_slide()

func _eksekusi_serangan_raja() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	animated_sprite.play("attack")

func _on_enemy_frame_changed() -> void:
	var nama_anim_kecil = animated_sprite.animation.to_lower()
	
	# 🛠️ FIX BISA MENDAMAGE: Mengaktifkan Hitbox & Mengubah target deteksi ke AREA (Hurtbox Player)
	if "attack" in nama_anim_kecil and (animated_sprite.frame == 7 or animated_sprite.frame == 8):
		if has_node("EnemyHitbox/CollisionShape2D"):
			$EnemyHitbox/CollisionShape2D.set_deferred("disabled", false)
			
		var areas = $EnemyHitbox.get_overlapping_areas()
		for area in areas:
			if area.name == "PlayerHurtbox" or area.is_in_group("player_hurtbox"):
				var player_root = area.get_parent()
				
				if player_root.is_parrying:
					dipicu_parry(player_root.global_position)
					return
				elif player_root.has_method("take_damage_with_knockback"):
					player_root.take_damage_with_knockback(15.0, global_position)
					print("[👑 BOSS KING] Menebas PlayerHurtbox! Damage + Knockback terkirim.")
	else:
		if has_node("EnemyHitbox/CollisionShape2D"):
			$EnemyHitbox/CollisionShape2D.set_deferred("disabled", true)

func _on_animation_finished() -> void:
	var nama_animasi_sekarang = animated_sprite.animation.to_lower()
	if "attack" in nama_animasi_sekarang:
		is_attacking = false
		animated_sprite.play("idle")
		if has_node("EnemyHitbox/CollisionShape2D"):
			$EnemyHitbox/CollisionShape2D.set_deferred("disabled", true)
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout
		can_attack = true
	elif "hurt" in nama_animasi_sekarang:
		is_taking_damage = false
		animated_sprite.play("idle")
	elif "die" in nama_animasi_sekarang:
		queue_free()

func _on_enemy_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "PlayerHitbox" or area.is_in_group("player_hitbox"):
		_terkena_luka(20.0)

# DI DALAM SKRIP BOSS (CONTOH: boss_king.gd / boss_general.gd)
func _terkena_luka(amount: float) -> void:
	current_health -= amount
	is_attacking = false
	print("HP Boss Berkurang: ", current_health)
	
	# 🛠️ UPDATE BAR HP BOSS DI ATAS LAYAR SECARA REAL-TIME
	var arena = get_tree().get_first_node_in_group("arena_combat")
	if arena and arena.has_method("perbarui_hp_bar_boss"):
		# Kirim data HP saat ini, HP maksimal, dan nama boss ke UI
		arena.perbarui_hp_bar_boss(current_health, max_health, "Boss General")
		
	if current_health > 0:
		is_taking_damage = true
		animated_sprite.play("hurt")
	else:
		is_dead = true
		collision_layer = 0
		collision_mask = 0
		animated_sprite.play("die")
		if arena and arena.has_method("_on_enemy_died"):
			arena._on_enemy_died(3)

# --- FUNGSI MEKANIK PARRY PLAYER ---
func dipicu_parry(posisi_player: Vector2) -> void:
	if is_dead: return
	is_attacking = false
	is_stunned = true
	
	var arah_pental = (global_position - posisi_player).normalized()
	knockback_velocity = arah_pental * 400.0 
	animated_sprite.play("idle") 
	
	var timer_kedip = get_tree().create_timer(1.5)
	while timer_kedip.get_time_left() > 0:
		if is_dead: break
		animated_sprite.modulate = Color(2, 2, 0) 
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = Color(1, 1, 1) 
		await get_tree().create_timer(0.1).timeout
		
	is_stunned = false
