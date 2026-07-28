extends Area2D

@export var DAMAGE: float = 15.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Di awal lahir, matikan dulu collision-nya sampai frame ledakan muncul
	collision_shape.disabled = true
	
	# Hubungkan sinyal internal animasi
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Mainkan animasi ledakan sihir
	animated_sprite.play("explode")

func _on_frame_changed() -> void:
	# Sesuaikan indeks frame di bawah dengan sprite milikmu!
	# Misal: Frame 0-2 baru muncul lingkaran sihir di tanah (tanda peringatan/warning)
	# Frame 3 adalah saat sihir meletup/meledak ke atas
	if animated_sprite.animation == "explode" and animated_sprite.frame == 3:
		collision_shape.disabled = false
		_cek_apakah_mengenai_player()
	else:
		collision_shape.disabled = true

func _cek_apakah_mengenai_player() -> void:
	var areas = get_overlapping_areas()
	for area in areas:
		if area.name == "PlayerHurtbox":
			var player_obj = area.get_parent()
			if player_obj and player_obj.has_method("take_damage"):
				# Berikan damage dan efek pentalan berdasarkan posisi ledakan ini
				player_obj.take_damage(DAMAGE, self)

func _on_animation_finished() -> void:
	# Begitu animasi ledakan selesai, langsung hapus objek ini dari map
	queue_free()
