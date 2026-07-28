extends Area2D

@export var speed: float = 300.0
var direction: Vector2 = Vector2.ZERO
var penyerang: Node = null

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	get_tree().create_timer(4.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func set_direction(arah_baru: Vector2) -> void:
	direction = arah_baru
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Jika objek yang tertabrak secara fisik adalah penembaknya sendiri, abaikan total dan biarkan panah meluncur lewat
	if body == penyerang:
		return
		
	# Jika mengenai Player utama secara fisik, berikan damage lalu hancur
	if body.is_in_group("player_group") or body.name.to_lower().contains("player"):
		if body.has_method("take_damage"):
			body.take_damage(12.0, self)
		queue_free()
		return
		
	# Panah hanya hancur menabrak lingkungan jika objek tersebut adalah StaticBody2D (Tembok/Gate)
	if body is StaticBody2D or body.name.to_lower().contains("wall") or body.name.to_lower().contains("gate"):
		queue_free()
