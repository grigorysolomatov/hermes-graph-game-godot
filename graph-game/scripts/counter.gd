extends Control

var count: int = 0

func _on_button_pressed() -> void:
	count += 1
	$VBoxContainer/CountLabel.text = str(count)
