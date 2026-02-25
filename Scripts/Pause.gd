extends Control

signal resume_pressed
signal leave_game_pressed
signal quit_menu_pressed

func _ready():
	$VBoxContainer/ResumeButton.pressed.connect(func(): emit_signal("resume_pressed"))
	$VBoxContainer/LeaveButton.pressed.connect(func(): emit_signal("leave_game_pressed"))
	$VBoxContainer/QuitButton.pressed.connect(func(): emit_signal("quit_menu_pressed"))
