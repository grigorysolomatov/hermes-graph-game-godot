class_name ResourcePickerView
extends Control

signal resource_selected(edge_id: int, resource_type: GameState.ResourceType)

var _edge_id: int = -1
var _labor_tex: Texture2D = null
var _fish_tex: Texture2D = null

@onready var _labor_btn: Button = $Panel/VBox/LaborBtn
@onready var _fish_btn: Button = $Panel/VBox/FishBtn
@onready var _cancel_btn: Button = $Panel/VBox/CancelBtn

func set_textures(labor: Texture2D, fish: Texture2D) -> void:
	_labor_tex = labor
	_fish_tex = fish
	_labor_btn.icon = labor
	_fish_btn.icon = fish

func show_for(edge_id: int) -> void:
	_edge_id = edge_id
	show()

func _on_labor_pressed() -> void:
	resource_selected.emit(_edge_id, GameState.ResourceType.LABOR)
	hide()

func _on_fish_pressed() -> void:
	resource_selected.emit(_edge_id, GameState.ResourceType.FISH)
	hide()

func _on_cancel_pressed() -> void:
	hide()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch and event.pressed:
		if not get_rect().has_point(event.position):
			hide()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if not get_rect().has_point(event.position):
			hide()
			get_viewport().set_input_as_handled()
