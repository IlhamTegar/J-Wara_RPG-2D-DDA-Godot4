extends Control

@onready var cerita_label: Label = $CeritaLabel
@onready var loading_bar: TextureProgressBar = $LoadingBar
@onready var lanjutkan_btn: Button = $LanjutkanButton

var teks_prolog_dunia: String = "Disebuah zaman yang jauh dimana cerita mengenai kesatria, monster dan legenda bukanlah omongkosong, terdapat desa yang letaknya di pinggir sebuah kerajaan dan sangat terpencil yang bahkan pihak kerajaan tidak tahu bahwa desa itu dibawah yuridis kerajaan itu. Desa tersebut selalu melawan gelombang monster setiap harinya yang membuat beberapa warga memutuskan untuk pergi dari desa tersebut untuk mencari kehidupan yang lebih baik atau hanya sekedar menyelamatkan diri. Tetapi masih ada satu pemuda yang masih mau menjaga desa tersebut dan melawan gerombolan monster yang terus menyerang desa, dan berharap agar desanya bisa damai suatu hari....."

# 🛠️ NARRATIVE ADDITIONS: Teks KABUR & teks EPILOG (TAMAT)
var teks_kabur: String = "Si pemuda yang melawan monster setiap harinya sudah lelah dengan menghadapi monster dan memutuskan kabur. Tetapi harapan agar desanya suatu hari bisa damai bukanlah kebohongan hanya saja dia tidak bisa membuat harapan itu menjadi kenyataan."
var teks_epilog: String = "Setelah perjuangan panjang yang melelahkan melawan gelombang monster yang tak henti-hentinya menyerang, kedamaian yang diimpikan sang pemuda akhirnya tidak lagi sekadar menjadi angan-angan belaka. Gerombolan monster telah musnah sepenuhnya, desa terpencil itu kini terbebas dari cengkeraman ketakutan, dan masa depan yang damai serta tenang akhirnya berhasil dia wujudkan menjadi kenyataan..."

var target_scene: String = ""

func _ready() -> void:
	lanjutkan_btn.hide()
	loading_bar.value = 0
	
	target_scene = GlobalGameManager.next_scene_path
	
	# 🛠️ KONDISI A: Jika terdeteksi pindah ke Main Menu secara NORMAL (Bukan Kabur / Epilog)
	if "main_menu" in target_scene.to_lower() and not GlobalGameManager.is_player_escaping and not GlobalGameManager.is_game_cleared_epilog:
		cerita_label.text = "" # Hilangkan label teks murni agar visual bersih
		loading_bar.show()
		_simulasi_pemuetan_loading()
		return
		
	# 🛠️ KONDISI B: Jika player memicu tombol KABUR di Pause Menu (Bad/Escape Ending)
	if GlobalGameManager.is_player_escaping:
		cerita_label.text = teks_kabur
		loading_bar.hide()
		lanjutkan_btn.show()
		lanjutkan_btn.grab_focus()
		GlobalGameManager.is_player_escaping = false # Reset saklar kembali
		return
		
	# 🛠️ KONDISI C: Jika player berhasil menyelesaikan Wave Terakhir (True/Good Ending)
	if GlobalGameManager.is_game_cleared_epilog:
		cerita_label.text = teks_epilog
		loading_bar.hide()
		lanjutkan_btn.show()
		lanjutkan_btn.grab_focus()
		GlobalGameManager.is_game_cleared_epilog = false # Reset saklar kembali
		return

	# KONDISI D: Logika Bawaan Awal (Prolog New Game atau Loading Wilayah Biasa)
	if GlobalGameManager.butuh_cerita_awal:
		cerita_label.text = teks_prolog_dunia
		loading_bar.hide()
		lanjutkan_btn.show()
		lanjutkan_btn.grab_focus()
		GlobalGameManager.butuh_cerita_awal = false
	else:
		cerita_label.text = "Memuat wilayah baru... Bersiaplah!"
		loading_bar.show()
		_simulasi_pemuetan_loading()

func _simulasi_pemuetan_loading() -> void:
	var timer = get_tree().create_timer(0.05)
	for i in range(101):
		loading_bar.value = i
		await get_tree().create_timer(0.02).timeout
		
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)

func _on_lanjutkan_button_pressed() -> void:
	lanjutkan_btn.hide()
	loading_bar.show()
	_simulasi_pemuetan_loading()
