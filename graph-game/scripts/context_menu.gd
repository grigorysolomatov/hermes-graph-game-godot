class_name ContextMenuView
extends Control

signal delete_pressed(node_id: int)
signal connect_pressed(node_id: int)

var node_id: int = -1

func _on_delete_pressed() -> void:
	delete_pressed.emit(node_id)
	hide()

func _on_connect_pressed() -> void:
	connect_pressed.emit(node_id)
	hide()
