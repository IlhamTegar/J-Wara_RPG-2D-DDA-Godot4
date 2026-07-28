extends CharacterBody2D

@export var SPEED : float = 120.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction := 0.0
	if Input.is_key_pressed(KEY_D): direction += 1.0
	if Input.is_key_pressed(KEY_A): direction -= 1.0
	
	if direction != 0.0:
		velocity.x = direction * SPEED
		animated_sprite.play("walk")
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animated_sprite.play("idle")
		
	move_and_slide()
