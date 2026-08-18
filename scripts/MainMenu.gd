extends Control

func _ready():
	var start_button = get_node("StartButton")
	var title_label = get_node("Label")
	
	if start_button and title_label:
		start_button.connect("pressed", _on_start_pressed)
		title_label.add_theme_font_size_override("font_size", 48)
		start_button.add_theme_font_size_override("font_size", 24)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scripts/GameScene.tscn")
