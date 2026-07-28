extends Area2D

@export var speed: float = 380.0
var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("projektil")
	
	# Matikan interaksi otomatis lewat editor agar tidak bentrok
	collision_layer = 0
	collision_mask = 0
	
	get_tree().create_timer(3.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# 1. Panah tetap meluncur maju
	position += direction * speed * delta
	
	# 2. Ambil seluruh objek di dalam arena untuk mencari Player secara presisi
	var player_nodes = get_tree().get_nodes_in_group("player_group")
	if player_nodes.size() > 0:
		var player_root = player_nodes[0]
		
		# Ambil node PlayerHurtbox dari root Player
		var hurtbox = player_root.get_node_or_null("PlayerHurtbox")
		if hurtbox and is_instance_valid(hurtbox):
			
			# Lacak semua anak node di dalam PlayerHurtbox (mencari CollisionShape2D)
			for child in hurtbox.get_children():
				if child is CollisionShape2D and not child.disabled:
					
					# Hitung apakah posisi global anak panah saat ini sudah masuk ke dalam radius Kapsul Dada Player
					var jarak_ke_kapsul_dada = global_position.distance_to(child.global_position)
					
					# Sesuaikan dengan ukuran radius kapsul dada di editor kamu (misal 20-25 pixel)
					if jarak_ke_kapsul_dada <= 25.0:
						if player_root.has_method("take_damage"):
							player_root.call_deferred("take_damage", 12.0)
							print("[🎯 ARROW DIRECT SUCCESS] Panah sukses menusuk Kapsul Collision di dalam PlayerHurtbox!")
							queue_free() # Hancurkan panah instan
							return

func set_direction(arah_baru: Vector2) -> void:
	direction = arah_baru
	rotation = direction.angle() 

# --- 🎯 GERBANG UTAMA: DETEKSI BODI UTAMA KAKI PLAYER & TEMBOK ---
func _on_body_entered(body: Node2D) -> void:
	if body == null: return 

	# 1. JIKA MENGENAI PLAYER (Mendeteksi CharacterBody2D / player_group)
	if body.is_in_group("player_group"): 
		if body.has_method("take_damage"):
			# Panggil fungsi damage milik player secara langsung
			body.take_damage(12.0) 
		print("[🎯 ARROW HIT] Anak panah mendarat di bodi fisik Player!") 
		queue_free() # Panah langsung hancur setelah memberikan damage 
		return

	# 2. JIKA MENGENAI DINAMIS TEMBOK / TILEMAP LINGKUNGAN
	if body is StaticBody2D or "tilemap" in body.name.to_lower() or "dinding" in body.name.to_lower():
		print("[🧱 ARROW WALL] Panah patah menabrak dinding lingkungan.") 
		queue_free() 
