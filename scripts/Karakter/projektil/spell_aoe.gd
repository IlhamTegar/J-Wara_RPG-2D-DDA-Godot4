extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var sudah_memberi_damage: bool = false

func _ready() -> void:
	# 1. Keluar dari grup projektil bawaan player agar animasi tidak terhapus paksa
	add_to_group("spell_shaman")
	
	# 🛠️ FIX MUTLAK DARI DATA LOG: Paksa Mask bernilai 16 agar matanya bisa melihat Layer 5 (Player)
	collision_layer = 16 
	collision_mask = 16  
	
	# Mulai dalam keadaan MATI pada frame awal (0-6) sesuai konsepmu
	if has_node("CollisionShape2D"):
		$CollisionShape2D.disabled = true
	
	if not animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.connect(_on_frame_changed)
	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
		
	animated_sprite.play("default")

# MANAJEMEN SIKLUS HIDUP COLLISION (0-6 MATI -> 7-10 NYALA -> 11+ MATI)
func _on_frame_changed() -> void:
	var f = animated_sprite.frame
	
	if f >= 0 and f <= 6:
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true
			
	elif f >= 7 and f <= 10:
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = false
			
	elif f >= 11:
		if has_node("CollisionShape2D"):
			$CollisionShape2D.disabled = true

# EKSEKUSI PENGURANGAN DARAH SAAT TERJADI TABRAKAN FISIK
func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerHurtbox" or area.is_in_group("player_hurtbox"):
		var player_root = area.get_parent()
		while player_root != null and not player_root.has_method("take_damage"):
			player_root = player_root.get_parent()
			
		if player_root and not sudah_memberi_damage:
			sudah_memberi_damage = true
			player_root.take_damage(20.0)
			print("[💥 DAMAGE SUCCESS] Darah player berhasil dipotong via sinyal fisik!")

# ANIMASI MEMUDAR SELESAI -> BARU DIHAPUS DARI RAM SAVING
func _on_animation_finished() -> void:
	if animated_sprite.animation == "default":
		queue_free()
