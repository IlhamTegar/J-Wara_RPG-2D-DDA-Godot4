extends Node

# --- LOAD ASET SFX SECARA PRE-LOAD AGAR TIDAK DELAY ---
var sfx_list: Dictionary = {
	"sword_swing": preload("res://assets/audio/sfx/sword-swing.wav"),
	"dash": preload("res://assets/audio/sfx/dash.wav"),
	"dash_attack": preload("res://assets/audio/sfx/dash-attack.wav"),
	"parry": preload("res://assets/audio/sfx/parry.wav"),
	"enemy_hurt": preload("res://assets/audio/sfx/enemy-hurt.wav"),
	"lightning": preload("res://assets/audio/sfx/lightning.wav")
}

func play_sfx(sfx_name: String) -> void:
	if not sfx_list.has(sfx_name):
		print("[SoundManager] Warning: SFX ", sfx_name, " tidak ditemukan!")
		return
		
	# Buat player audio instan secara dinamis agar suara tidak saling memotong saat spam aksi
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = sfx_list[sfx_name]
	audio_player.bus = "SFX" # Hubungkan otomatis ke AudioBus SFX di settings menu!
	
	add_child(audio_player)
	audio_player.play()
	
	# Hancurkan node audio secara otomatis jika durasi suara sudah selesai berputar
	audio_player.finished.connect(func(): audio_player.queue_free())
