class_name NodeView
extends Node2D

signal node_tapped(node_id: int, global_pos: Vector2)

const NODE_RADIUS: float = 36.0
const WORKER_COLOR: Color = Color(0.961, 0.620, 0.043)
const SEA_COLOR: Color = Color(0.078, 0.722, 0.651)
const DRAG_THRESHOLD: float = 10.0

var node_id: int = -1
var node_type: GameState.NodeType = GameState.NodeType.WORKER
var is_ghost: bool = false

@onready var _icon: TextureRect = $Circle/Icon
@onready var _inventory_box: VBoxContainer = $InventoryBox

var _labor_tex: Texture2D
var _fish_tex: Texture2D
var _color: Color = WORKER_COLOR

var _tracking: bool = false
var _touch_start_screen: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
static var _drag_owner: int = -1

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
	for child in _inventory_box.get_children():
		child.queue_free()
	var show_resources: Array = []
	if node_type == GameState.NodeType.WORKER:
		show_resources = [GameState.ResourceType.LABOR]
	else:
		if GameState.get_node_inventory_count(node_id, GameState.ResourceType.LABOR) > 0:
			show_resources.append(GameState.ResourceType.LABOR)
		show_resources.append(GameState.ResourceType.FISH)
	for res: GameState.ResourceType in show_resources:
		var count: int = GameState.get_node_inventory_count(node_id, res)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _labor_tex if res == GameState.ResourceType.LABOR else _fish_tex
		var lbl := Label.new()
		lbl.text = str(count)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		row.add_child(icon)
		row.add_child(lbl)
		_inventory_box.add_child(row)

func _on_tick() -> void:
	_update_inventory()

func _input(event: InputEvent) -> void:
	if is_ghost:
		return

	# Press: start tracking if on this node and no other node owns the drag
	if (event is InputEventScreenTouch and event.pressed) or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if _drag_owner >= 0 and _drag_owner != node_id:
			return
		var screen_pos: Vector2 = event.position
		var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
		var local: Vector2 = to_local(world_pos)
		if local.length() <= NODE_RADIUS + 10.0:
			_tracking = true
			_is_dragging = false
			_touch_start_screen = screen_pos
			_drag_owner = node_id
			get_viewport().set_input_as_handled()
		return

	if not _tracking or _drag_owner != node_id:
		return

	# Motion: update drag
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		var screen_pos: Vector2 = event.position
		if not _is_dragging:
			if screen_pos.distance_to(_touch_start_screen) > DRAG_THRESHOLD:
				_is_dragging = true
		if _is_dragging:
			var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
			global_position = world_pos
			if node_id >= 0 and GameState.nodes.has(node_id):
				GameState.nodes[node_id]["position"] = world_pos
			get_viewport().set_input_as_handled()
		return

	# Release
	if (event is InputEventScreenTouch and not event.pressed) or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed):
		if _is_dragging:
			var screen_pos: Vector2 = event.position
			var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_pos
			global_position = world_pos
			if node_id >= 0 and GameState.nodes.has(node_id):
				GameState.nodes[node_id]["position"] = world_pos
		else:
			node_tapped.emit(node_id, global_position)
		_tracking = false
		_is_dragging = false
		_drag_owner = -1
		get_viewport().set_input_as_handled()
