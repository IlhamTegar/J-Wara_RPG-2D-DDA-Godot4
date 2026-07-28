
extends CanvasLayer

@onready var pause_panel = $PausePanel
@onready var settings_menu = $SettingsMenu

@onready var continue_button = $PausePanel/ContinueButton
@onready var settings_button = $PausePanel/SettingsButton
@onready var escape_button = $PausePanel/EscapeButton

func _ready():
	visible = false
	settings_menu.menu_closed.connect(_on_settings_closed)

func open_pause():
	visible = true
	pause_panel.visible = true
	settings_menu.visible = false
	get_tree().paused = true

	continue_button.grab_focus()

func close_pause():
	get_tree().paused = false
	visible = false

func _on_continue_button_pressed():
	close_pause()

func _on_settings_button_pressed():
	pause_panel.visible = false
	settings_menu.open_menu()

func _on_escape_button_pressed():
	get_tree().paused = false
	GlobalGameManager.is_player_escaping = true
	GlobalGameManager.next_scene_path = "res://scenes/main_menu/main_menu.tscn"
	get_tree().change_scene_to_file("res://scenes/ui/loading_screen.tscn")

func _on_settings_closed():
	pause_panel.visible = true
