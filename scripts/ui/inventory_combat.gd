extends CanvasLayer

@onready var bag_panel: Panel = $BagPanel
@onready var slots_grid: GridContainer = $BagPanel/SlotsGrid
@onready var gunakan_btn: Button = $BagPanel/GunakanButton

var item_terpilih: String = "" 

func _ready() -> void:
	visible = false
	bag_panel.visible = false
	
	gunakan_btn.visible = false
	gunakan_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 🛠️ FIX SAFETY MOUSE: Pastikan panel utama menghentikan klik mouse agar tidak tembus ke background
	bag_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	for slot_node in slots_grid.get_children():
		if slot_node is Button:
			slot_node.pressed.connect(func(): _on_slot_diklik(slot_node.name))
			
	if not gunakan_btn.pressed.is_connected(_on_gunakan_item_pressed):
		gunakan_btn.pressed.connect(_on_gunakan_item_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("buka_tas"):
		if not GlobalGameManager.is_in_safezone:
			visible = !visible
			bag_panel.visible = visible
			
			# 🛠️ Update status global
			GlobalGameManager.is_inventory_open = visible
			
			if visible:
				item_terpilih = ""
				gunakan_btn.visible = false
				_render_isi_slot_tas()
			else:
				gunakan_btn.visible = false

func _render_isi_slot_tas() -> void:
	var path_potion = "res://assets/sprites/ui/logo potion-toko.png"
	var path_scroll = "res://assets/sprites/ui/logo buff-toko.png"
	var path_high_scroll = "res://assets/sprites/ui/high scroll.png"
	var path_ancient_scroll = "res://assets/sprites/ui/ancient scroll.png"
	
	var texture_potion = load(path_potion) if ResourceLoader.exists(path_potion) else null
	var texture_scroll = load(path_scroll) if ResourceLoader.exists(path_scroll) else null
	var texture_high_scroll = load(path_high_scroll) if ResourceLoader.exists(path_high_scroll) else null
	var texture_ancient_scroll = load(path_ancient_scroll) if ResourceLoader.exists(path_ancient_scroll) else null
	
	var total_potion = GlobalGameManager.potion_count
	var total_scroll = GlobalGameManager.scroll_count
	var total_high_scroll = GlobalGameManager.high_scroll_count if "high_scroll_count" in GlobalGameManager else 0
	var total_ancient_scroll = GlobalGameManager.ancient_scroll_count if "ancient_scroll_count" in GlobalGameManager else 0
	
	var list_slot = slots_grid.get_children()
	
	for slot in list_slot:
		if slot is Button:
			slot.text = ""
			slot.icon = null
			slot.set_meta("tipe_item", "")

	var current_slot_idx = 0
	
	for p in range(total_potion):
		if current_slot_idx < 12:
			var btn_slot = list_slot[current_slot_idx] as Button
			btn_slot.icon = texture_potion
			btn_slot.set_meta("tipe_item", "potion")
			btn_slot.expand_icon = true
			btn_slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			current_slot_idx += 1
			
	for s in range(total_scroll):
		if current_slot_idx < 12:
			var btn_slot = list_slot[current_slot_idx] as Button
			btn_slot.icon = texture_scroll
			btn_slot.set_meta("tipe_item", "scroll")
			btn_slot.expand_icon = true
			btn_slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			current_slot_idx += 1

	for hs in range(total_high_scroll):
		if current_slot_idx < 12:
			var btn_slot = list_slot[current_slot_idx] as Button
			btn_slot.icon = texture_high_scroll
			btn_slot.set_meta("tipe_item", "high_scroll")
			btn_slot.expand_icon = true
			btn_slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			current_slot_idx += 1

	for ac in range(total_ancient_scroll):
		if current_slot_idx < 12:
			var btn_slot = list_slot[current_slot_idx] as Button
			btn_slot.icon = texture_ancient_scroll
			btn_slot.set_meta("tipe_item", "ancient_scroll")
			btn_slot.expand_icon = true
			btn_slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			current_slot_idx += 1

func _on_slot_diklik(slot_name: String) -> void:
	var target_slot = slots_grid.get_node(slot_name) as Button
	var tipe = target_slot.get_meta("tipe_item")
	
	if tipe != "":
		item_terpilih = tipe
		gunakan_btn.visible = true
		
		gunakan_btn.global_position = Vector2(
			target_slot.global_position.x + (target_slot.size.x / 2) - (gunakan_btn.size.x / 2),
			target_slot.global_position.y - gunakan_btn.size.y - 5
		)
		
		gunakan_btn.move_to_front()
		print("[TAS] Item terpilih: ", tipe, ".")
	else:
		item_terpilih = ""
		gunakan_btn.visible = false

func _on_gunakan_item_pressed() -> void:
	print("[CLICK ACTION] Tombol gunakan mendeteksi klik fisik!")
	var player = get_tree().get_first_node_in_group("player_group")
	
	if item_terpilih == "potion":
		if GlobalGameManager.potion_count > 0:
			GlobalGameManager.potion_count -= 1
			GlobalGameManager.mikro_potion_digunakan = true
			
			if player and player.has_method("take_damage"):
				if "current_health" in player:
					player.current_health = min(player.max_health, player.current_health + 25.0)
					if player.has_method("_update_tampilan_hud"):
						player._update_tampilan_hud()
			print("[TAS] 🧪 1 Potion berhasil digunakan!")
			
	elif item_terpilih == "scroll":
		if GlobalGameManager.scroll_count > 0:
			GlobalGameManager.scroll_count -= 1
			print("[TAS] 📜 1 Scroll Buff berhasil diaktifkan!")

	elif item_terpilih == "high_scroll":
		if GlobalGameManager.high_scroll_count > 0:
			GlobalGameManager.high_scroll_count -= 1
			if player and player.has_method("gunakan_high_scroll"):
				player.gunakan_high_scroll()
			print("[TAS] 🎰 1 High Scroll sukses dikonsumsi!")

	elif item_terpilih == "ancient_scroll":
		if GlobalGameManager.ancient_scroll_count > 0:
			GlobalGameManager.ancient_scroll_count -= 1
			if player and player.has_method("gunakan_ancient_scroll"):
				player.gunakan_ancient_scroll()
			print("[TAS] 🔮 1 Ancient Scroll sukses dikonsumsi!")

	item_terpilih = ""
	gunakan_btn.visible = false
	_render_isi_slot_tas()
