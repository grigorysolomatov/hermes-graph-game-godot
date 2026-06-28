class_name ContextMenuView
extends Control

signal delete_pressed(node_id: int)
signal connect_pressed(node_id: int)
signal close_requested

var node_id: int = -1

@onready var _delete_btn: Button = $HBox/DeleteBtn
@onready var _connect_btn: Button = $HBox/ConnectBtn

func show_for(id: int, world_pos: Vector2, camera: Camera2D) -> void:
	node_id = id
	# Convert world position to screen position
	var screen_pos: Vector2 = camera.unproject_position(Vector3(world_pos.x, world_pos.y, 0))
	# For Camera2D in 2D, use get_canvas_transform
	var vp: Viewport = get_viewport()
	var transform: Transform2D = vp.get_canvas_transform()
	var sp: Vector2 = transform * world_pos
	# Offset above the node
	sp.y -= 100.0
	sp.x -= size.x * 0.5
	position = sp
	show()

func show_above(world_pos: Vector2, canvas_transform: Transform2D) -> void:
	var sp: Vector2 = canvas_transform * world_pos
	sp.y -= 100.0
	sp.x -= size.x * 0.5
	position = sp
	show()

func _on_delete_pressed() -> void:
	delete_pressed.emit(node_id)
	hide()

func _on_connect_pressed() -> void:
	connect_pressed.emit(node_id)
	hide()
