class_name NodeView
extends Node2D

signal node_tapped(node_id: int, global_pos: Vector2)

const NODE_RADIUS: float = 36.0
const WORKER_COLOR: Color = Color(0.961, 0.620, 0.043)
const SEA_COLOR: Color = Color(0.078, 0.722, 0.651)

var node_id: int = -1
var node_type: GameState.NodeType = GameState.NodeType.WORKER
var is_ghost: bool = false

@onready var _icon: TextureRect = $Circle/Icon
@onready var _inventory_box: HBoxContainer = $InventoryBox
@onready var _inv_icon: TextureRect = $InventoryBox/InvIcon
@onready var _inv_label: Label = $InventoryBox/InvLabel

var _labor_tex: Texture2D
var _fish_tex: Texture2D
var _color: Color = WORKER_COLOR

func setup(id: int, type: GameState.NodeType, labor_texture: Texture2D, fish_texture: Texture2D) -> void:
	node_id = id
	node_type = type
	_labor_tex = labor_texture
	_fish_tex = fish_texture
	_color = WORKER_COLOR if type == GameState.NodeType.WORKER else SEA_COLOR
	queue_redraw()
	_update_icon()
	_update_inventory()

func setup_ghost(type: GameState.NodeType, labor_texture: Texture2D, fish_texture: Texture2D) -> void:
	is_ghost = true
	node_type = type
	_labor_tex = labor_texture
	_fish_tex = fish_texture
	_color = WORKER_COLOR if type == GameState.NodeType.WORKER else SEA_COLOR
	modulate.a = 0.6
	queue_redraw()
	_update_icon()
	_inventory_box.hide()

func _draw() -> void:
	draw_circle(Vector2.ZERO, NODE_RADIUS, _color)
	draw_arc(Vector2.ZERO, NODE_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.2), 2.0)

func _update_icon() -> void:
	if not is_instance_valid(_icon):
		return
	if node_type == GameState.NodeType.WORKER:
		_icon.texture = _labor_tex
	else:
		_icon.texture = _fish_tex

func _update_inventory() -> void:
	if is_ghost or not is_instance_valid(_inventory_box):
		return
	var res: GameState.ResourceType
	var tex: Texture2D
	if node_type == GameState.NodeType.WORKER:
		res = GameState.ResourceType.LABOR
		tex = _labor_tex
	else:
		res = GameState.ResourceType.FISH
		tex = _fish_tex
	var count: int = GameState.get_node_inventory_count(node_id, res)
	_inv_icon.texture = tex
	_inv_label.text = str(count)

func _on_tick() -> void:
	_update_inventory()

func _input(event: InputEvent) -> void:
	if is_ghost:
		return
	var screen_pos: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventScreenTouch:
		pressed = event.pressed
		screen_pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		screen_pos = event.position
	if not pressed:
		return
	var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
	var local: Vector2 = to_local(world_pos)
	if local.length() <= NODE_RADIUS + 10.0:
		node_tapped.emit(node_id, global_position)
		get_viewport().set_input_as_handled()
