extends CharacterBody2D

@export var speed: float = 40.0
@export var ATTACK_RANGE: float = 200.0
@export var max_health: float = 150.0
@export var spell_aoe_scene: PackedScene

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

	# 🛠️ FIX UTAMA DETEKSI HIT: Sambungkan sinyal hurtbox secara otomatis lewat kode
	var hurtbox_node = get_node_or_null("EnemyHurtbox")
	if hurtbox_node:
		if not hurtbox_node.area_entered.is_connected(_on_enemy_hurtbox_area_entered):
			hurtbox_node.area_entered.connect(_on_enemy_hurtbox_area_entered)
			print("[⚡ BOSS SHAMAN] Sinyal EnemyHurtbox sukses diikat otomatis!")

func _physics_process(_delta: float) -> void:
	if is_dead or is_taking_damage or is_attacking or not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	if distance_to_player <= ATTACK_RANGE and can_attack:
		_eksekusi_sihir_petir()
		return

	velocity = direction * speed
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
		
	# Tiru Sistem Balik Skala Total Milik Enemy_Bow
	if direction.x != 0:
		var arah_skala = -1.0 if direction.x < 0 else 1.0
		animated_sprite.scale.x = abs(animated_sprite.scale.x) * arah_skala
		$EnemyHitbox.scale.x = arah_skala
		$EnemyHurtbox.scale.x = arah_skala

	move_and_slide()

func _eksekusi_sihir_petir() -> void:
	is_attacking = true
	can_attack = false
	velocity = Vector2.ZERO
	animated_sprite.play("attack")

func _on_boss_frame_changed() -> void:
	var nama_anim_kecil = animated_sprite.animation.to_lower()
	if "attack" in nama_anim_kecil and animated_sprite.frame == 3:
		if spell_aoe_scene == null or player == null: return
		
		# Amankan arah hadap wajah sebelum melahirkan petir
		var arah_ke_player = (player.global_position - global_position).normalized()
		if arah_ke_player.x != 0:
			var arah_skala = -1.0 if arah_ke_player.x < 0 else 1.0
			animated_sprite.scale.x = abs(animated_sprite.scale.x) * arah_skala
			$EnemyHitbox.scale.x = arah_skala
			$EnemyHurtbox.scale.x = arah_skala

		var posisi_target_player = player.global_position
		var petir_instansi = spell_aoe_scene.instantiate()
		petir_instansi.global_position = posisi_target_player
		
		get_tree().current_scene.add_child(petir_instansi)
		print("[⚡ BOSS SHAMAN] Mantra Petir sukses meledak di koordinat Player!")

func _on_animation_finished() -> void:
	var nama_animasi_sekarang = animated_sprite.animation.to_lower()
	if "attack" in nama_animasi_sekarang:
		is_attacking = false
		animated_sprite.play("idle")
		await get_tree().create_timer(2.5).timeout
		can_attack = true
	elif "hurt" in nama_animasi_sekarang:
		is_taking_damage = false
	elif "die" in nama_animasi_sekarang:
		queue_free()

func _on_enemy_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead: return
	if area.name == "PlayerHitbox" or area.is_in_group("player_hitbox"):
		_terkena_luka(25.0)

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
