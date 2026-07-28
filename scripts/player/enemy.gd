extends CharacterBody2D

# --- CONFIG DATA DASAR ENEMY MELEE ---
@export var speed: float = 60.0 
@export var ATTACK_RANGE: float = 40.0 
@export var max_health: float = 50.0 
@export var ATTACK_COOLDOWN: float = 1.5

var current_health: float 
var is_dead: bool = false 
var is_taking_damage: bool = false 
var is_attacking: bool = false 
var can_attack: bool = true

# --- 🛠️ VARIABEL PENGAMAN BARU (ANTI-DAMAGE BERANTAI) ---
var has_damaged_player: bool = false # Mencatat apakah pukulan sudah masuk dalam 1 siklus animasi

var knockback_velocity: Vector2 = Vector2.ZERO 
var player: CharacterBody2D = null 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 
@onready var enemy_hitbox: Area2D = $EnemyHitbox 
@onready var enemy_hitbox_shape: CollisionShape2D = $EnemyHitbox/CollisionShape2D 

func _ready() -> void:
	add_to_group("enemy_group") 
	current_health = max_health 
	is_dead = false 
	is_taking_damage = false 
	is_attacking = false 
	can_attack = true
	has_damaged_player = false
	
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished) 
	
	var player_nodes = get_tree().get_nodes_in_group("player_group") 
	if player_nodes.size() > 0:
		player = player_nodes[0] 
	else:
		player = get_tree().current_scene.find_child("Player", true, false) 
		
	if is_instance_valid(enemy_hitbox_shape):
		enemy_hitbox_shape.disabled = true 

func _physics_process(delta: float) -> void:
	if is_dead: 
		velocity = Vector2.ZERO 
		move_and_slide() 
		return 

	var push_back_vector = Vector2.ZERO
	if player and not is_dead:
		var jarak_ke_player = global_position.distance_to(player.global_position)
		if jarak_ke_player < 35.0:
			var arah_menjauh = (global_position - player.global_position).normalized()
			if arah_menjauh.y < 0:
				arah_menjauh.y *= 1.8
			push_back_vector = arah_menjauh * 180.0

	if is_taking_damage or is_attacking or not player or GlobalGameManager.is_in_safezone: 
		velocity = push_back_vector
		move_and_slide() 
		return 

	if knockback_velocity.length() > 0: 
		velocity = knockback_velocity 
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 800 * delta) 
		move_and_slide() 
		return 

	var distance_to_player = global_position.distance_to(player.global_position)
	var direction = (player.global_position - global_position).normalized()

	if distance_to_player <= ATTACK_RANGE and can_attack:
		_eksekusi_serangan_musuh()
		return

	var target_velocity = direction * speed
	velocity = target_velocity + _hitung_push_vector() + push_back_vector

	if velocity.length() > 10:
		if animated_sprite.animation != "walk": 
			animated_sprite.play("walk") 
		animated_sprite.flip_h = (direction.x < 0) 
		if direction.x != 0:
			enemy_hitbox.scale.x = -1.0 if direction.x < 0 else 1.0 
	else:
		animated_sprite.play("idle")
		
	move_and_slide()

func _hitung_push_vector() -> Vector2:
	var push_vector = Vector2.ZERO
	var all_enemies = get_tree().get_nodes_in_group("enemy_group")
	for other_enemy in all_enemies:
		if other_enemy != self and is_instance_valid(other_enemy) and not other_enemy.is_dead:
			var dist = global_position.distance_to(other_enemy.global_position)
			if dist < 32.0:
				var push_dir = (global_position - other_enemy.global_position).normalized()
				push_vector += push_dir * (32.0 - dist) * 2.0
	return push_vector

func _eksekusi_serangan_musuh() -> void:
	if is_attacking or is_taking_damage or not can_attack: return
	is_attacking = true
	has_damaged_player = false # Reset status serangan saat mulai mengayunkan senjata baru
	velocity = Vector2.ZERO
	animated_sprite.play("attack")

# --- 🛠️ PERBAIKAN UTAMA: DISIPLIN FRAME ANIMASI SERANGAN ---
func _on_enemy_frame_changed() -> void:
	# --- 🛠️ FIX MUTLAK CRASH NIL ON SPAWN ---
	if not is_instance_valid(animated_sprite) or animated_sprite == null:
		return
		
	if is_dead: return
	
	# Jalankan pengecekan serangan melee jika sprite sudah valid
	if animated_sprite.animation == "attack" and (animated_sprite.frame == 5 or animated_sprite.frame == 6):
		if not has_damaged_player and player and is_instance_valid(player):
			var distance_to_player = global_position.distance_to(player.global_position)
			if distance_to_player <= (ATTACK_RANGE + 35.0):
				if player.has_method("take_damage"):
					has_damaged_player = true
					player.take_damage(10.0, self)
					print("[⚔️ MELEE] Pukulan masuk tunggal! Jarak: ", distance_to_player)

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false
		has_damaged_player = false # Lepas kunci saat animasi benar-benar selesai
		animated_sprite.play("idle")
		
		can_attack = false
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout
		can_attack = true
		
	elif animated_sprite.animation == "hurt": 
		is_taking_damage = false 
		animated_sprite.play("idle") 
	elif animated_sprite.animation == "die" or animated_sprite.animation == "dead": 
		var arena = get_tree().current_scene 
		if arena and arena.has_method("_on_enemy_died"): 
			arena._on_enemy_died() 
		queue_free() 

func take_damage(amount: float, player_position: Vector2) -> void:
	if is_dead: return
	current_health -= amount 
	print(name, " Terluka! Sisa Darah: ", current_health) 
	
	if "mikro_damage_diberikan" in GlobalGameManager:
		GlobalGameManager.mikro_damage_diberikan += amount

	var arah_pentalan = (global_position - player_position).normalized()
	knockback_velocity = arah_pentalan * 150.0

	if current_health > 0:
		is_taking_damage = true
		is_attacking = false 
		animated_sprite.play("hurt")
	else:
		_eksekusi_mati()

func _eksekusi_mati() -> void:
	is_dead = true
	collision_layer = 0
	collision_mask = 0
	animated_sprite.play("die")

func terkena_stun_parry() -> void:
	if is_dead: return
	is_attacking = false
	is_taking_damage = true
	knockback_velocity = Vector2.ZERO
	animated_sprite.play("hurt")
	animated_sprite.modulate = Color(2.0, 1.5, 0.2, 1)
	await get_tree().create_timer(1.2).timeout
	animated_sprite.modulate = Color(1, 1, 1, 1)
	is_taking_damage = false
