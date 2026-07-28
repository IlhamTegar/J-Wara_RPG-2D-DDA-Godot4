extends CharacterBody2D

@export var speed: float = 50.0
@export var ATTACK_RANGE: float = 180.0 # Jarak tembak jauh
@export var max_health: float = 40.0
@export var projectile_scene: PackedScene # Masukkan arrow.tscn di Inspector

var current_health: float
var is_dead: bool = false
var is_taking_damage: bool = false
var is_attacking: bool = false
var can_attack: bool = true

var knockback_velocity: Vector2 = Vector2.ZERO
var player: CharacterBody2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy_group")
	current_health = max_health
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Cari player utama
	var player_nodes = get_tree().get_nodes_in_group("player_group")
	if player_nodes.size() > 0:
		player = player_nodes[0]

func _physics_process(delta: float) -> void:
	if is_dead or is_taking_damage or is_attacking or not player or GlobalGameManager.is_in_safezone:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta)
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	# AI KITING (Menjauh jika Player terlalu dekat agar tidak menempel)
	var MIN_SAFE_DISTANCE : float = 100.0
	if distance_to_player < MIN_SAFE_DISTANCE:
		var flee_direction = -direction 
		velocity = flee_direction * speed
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		animated_sprite.flip_h = (direction.x < 0)
		move_and_slide()
		return 

	# MEMICU TEMBAKAN PANAH
	if distance_to_player <= ATTACK_RANGE and can_attack:
		_eksekusi_serangan()
		return

	# BERJALAN MENDEKATI PLAYER JIKA TERLALU JAUH
	velocity = direction * speed
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	animated_sprite.flip_h = (direction.x < 0)
	move_and_slide()

func _eksekusi_serangan() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	animated_sprite.play("attack")

# --- DIPICU VIA TEMPO ANIMASI FRAME 3 ---
func _lepas_tembakan_proyektil() -> void:
	if projectile_scene == null: 
		print("[WARNING] Projectile Scene di Enemy_Bow masih KOSONG!")
		return
		
	var muzzle_node = get_node_or_null("Muzzle")
	var posisi_spawn = global_position
	
	if is_instance_valid(muzzle_node):
		posisi_spawn = muzzle_node.global_position
	else:
		var arah_hadap = -1.0 if animated_sprite.flip_h else 1.0
		posisi_spawn.x += arah_hadap * 25.0

	var panah_instansi = projectile_scene.instantiate()
	panah_instansi.global_position = posisi_spawn
	
	# --- 🛠️ PERBAIKAN: Kirim referensi penyerang (BARIS EXCEPTION YANG ERROR SUDAH DIHAPUS) ---
	if "penyerang" in panah_instansi:
		panah_instansi.penyerang = self
		
	var arah_tembakan = (player.global_position - posisi_spawn).normalized()
	if panah_instansi.has_method("set_direction"):
		panah_instansi.set_direction(arah_tembakan)
		
	get_tree().current_scene.add_child(panah_instansi)
	print("[🏹 ARCHER] Anak panah berhasil lepas dari busur!")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		animated_sprite.play("idle")
		# Cooldown menembak selama 2 detik
		await get_tree().create_timer(2.0).timeout
		can_attack = true
	elif animated_sprite.animation == "hurt":
		is_taking_damage = false
		animated_sprite.play("idle")
	elif animated_sprite.animation == "die":
		var arena = get_tree().current_scene
		if arena and arena.has_method("_on_enemy_died"):
			arena._on_enemy_died()
		queue_free()

func take_damage(amount: float, player_position: Vector2) -> void:
	if is_dead: return
	current_health -= amount
	
	var arah_pentalan = (global_position - player_position).normalized()
	knockback_velocity = arah_pentalan * 180.0

	if current_health > 0:
		is_taking_damage = true
		is_attacking = false 
		animated_sprite.play("hurt")
	else:
		is_dead = true
		collision_layer = 0
		collision_mask = 0
		animated_sprite.play("die")
		
func _on_enemy_frame_changed() -> void:
	# --- 🛠️ FIX MUTLAK CRASH NIL ON SPAWN ---
	# Jika animated_sprite belum dimuat atau bernilai null, keluar dari fungsi!
	if not is_instance_valid(animated_sprite) or animated_sprite == null:
		return
		
	if is_dead: return
	
	# Jalankan pengecekan animasi memanah jika sprite sudah valid
	if animated_sprite.animation == "attack" and animated_sprite.frame == 3:
		_lepas_tembakan_proyektil()
