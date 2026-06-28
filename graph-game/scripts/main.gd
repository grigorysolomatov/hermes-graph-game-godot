extends Control

var _labor_tex: Texture2D
var _fish_tex: Texture2D
var _node_views: Dictionary = {}
var _edge_views: Dictionary = {}
var _connect_source: int = -1

var _panning: bool = false
var _touch_positions: Dictionary = {}
var _pinch_last_dist: float = -1.0

const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 4.0
const ZOOM_STEP: float = 0.1

@onready var _game_world: Node2D = $GameWorld
@onready var _camera: Camera2D = $GameWorld/Camera2D
@onready var _context_menu: ContextMenuView = $ContextMenuLayer/ContextMenu
@onready var _node_menu: NodeMenuView = $UILayer/NodeMenu
@onready var _time_controls: TimeControlsView = $UILayer/TimeControls
@onready var _resource_picker: ResourcePickerView = $UILayer/ResourcePicker

func _ready() -> void:
	_labor_tex = load("res://assets/icons/labor.png")
	_fish_tex = load("res://assets/icons/fish.png")

	_node_menu.set_textures(_labor_tex, _fish_tex)
	_node_menu.set_game_world(_game_world)
	_node_menu.spawn_node_requested.connect(_on_spawn_node)

	_resource_picker.set_textures(_labor_tex, _fish_tex)
	_resource_picker.resource_selected.connect(_on_resource_selected)

	_context_menu.delete_pressed.connect(_on_delete_node)
	_context_menu.connect_pressed.connect(_on_connect_start)

	GameState.node_added.connect(_on_node_added)
	GameState.node_removed.connect(_on_node_removed)
	GameState.edge_added.connect(_on_edge_added)
	GameState.edge_removed.connect(_on_edge_removed)
	GameState.resource_transported.connect(_on_resource_transported)

func _on_spawn_node(type: GameState.NodeType, world_pos: Vector2) -> void:
	GameState.add_node(type, world_pos)

func _on_node_added(node_data: Dictionary) -> void:
	var scene: PackedScene = load("res://scenes/Node.tscn")
	var view: NodeView = scene.instantiate() as NodeView
	_game_world.add_child(view)
	view.position = node_data["position"]
	view.setup(node_data["id"], node_data["type"], _labor_tex, _fish_tex)
	view.node_tapped.connect(_on_node_tapped)
	GameState.tick.connect(view._on_tick)
	_node_views[node_data["id"]] = view

func _on_node_removed(node_id: int) -> void:
	if _node_views.has(node_id):
		var view: NodeView = _node_views[node_id]
		GameState.tick.disconnect(view._on_tick)
		view.queue_free()
		_node_views.erase(node_id)

func _on_edge_added(edge_data: Dictionary) -> void:
	var scene: PackedScene = load("res://scenes/Edge.tscn")
	var view: EdgeView = scene.instantiate() as EdgeView
	_game_world.add_child(view)
	view.setup(edge_data["id"], edge_data["source"], edge_data["target"])
	view.edge_tapped.connect(_on_edge_tapped)
	_edge_views[edge_data["id"]] = view

func _on_edge_removed(edge_id: int) -> void:
	if _edge_views.has(edge_id):
		_edge_views[edge_id].queue_free()
		_edge_views.erase(edge_id)

func _clear_connect_mode() -> void:
	if _connect_source >= 0 and _node_views.has(_connect_source):
		_node_views[_connect_source].set_connect_highlight(false)
	_connect_source = -1

func _on_node_tapped(node_id: int, world_pos: Vector2) -> void:
	if _connect_source >= 0:
		if node_id != _connect_source:
			GameState.add_edge(_connect_source, node_id, GameState.ResourceType.LABOR)
		_clear_connect_mode()
		_context_menu.hide()
		return
	_context_menu.node_id = node_id
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	screen_pos.y -= 100.0
	screen_pos.x -= 80.0
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var menu_size: Vector2 = _context_menu.size
	screen_pos.x = clamp(screen_pos.x, 4.0, vp_size.x - menu_size.x - 4.0)
	screen_pos.y = clamp(screen_pos.y, 4.0, vp_size.y - menu_size.y - 4.0)
	_context_menu.position = screen_pos
	_context_menu.show()

func _on_edge_tapped(edge_id: int) -> void:
	_resource_picker.show_for(edge_id)

func _on_delete_node(node_id: int) -> void:
	GameState.remove_node(node_id)

func _on_connect_start(node_id: int) -> void:
	_connect_source = node_id
	if _node_views.has(node_id):
		_node_views[node_id].set_connect_highlight(true)

func _on_resource_selected(edge_id: int, resource_type: GameState.ResourceType) -> void:
	GameState.set_edge_resource(edge_id, resource_type)

func _on_resource_transported(edge_id: int) -> void:
	if _edge_views.has(edge_id):
		_edge_views[edge_id].animate_transport()

func _zoom_at(delta: float, screen_pos: Vector2) -> void:
	var old_zoom: float = _camera.zoom.x
	var new_zoom: float = clamp(old_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if new_zoom == old_zoom:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cursor_from_center: Vector2 = screen_pos - vp_size * 0.5
	var world_before: Vector2 = _camera.global_position + cursor_from_center / old_zoom
	_camera.zoom = Vector2(new_zoom, new_zoom)
	var world_after: Vector2 = _camera.global_position + cursor_from_center / new_zoom
	_camera.position += world_before - world_after

func _get_pinch_dist() -> float:
	var keys: Array = _touch_positions.keys()
	if keys.size() < 2:
		return -1.0
	return _touch_positions[keys[0]].distance_to(_touch_positions[keys[1]])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_positions[event.index] = event.position
			if _connect_source >= 0:
				_clear_connect_mode()
		else:
			_touch_positions.erase(event.index)
		var count: int = _touch_positions.size()
		_panning = (count == 1)
		_pinch_last_dist = _get_pinch_dist() if count == 2 else -1.0
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _connect_source >= 0:
			_clear_connect_mode()
		_panning = event.pressed

func _input(event: InputEvent) -> void:
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(ZOOM_STEP, event.position)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(-ZOOM_STEP, event.position)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_panning = false

	# Context menu dismiss on outside press
	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
		pos = event.position
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
		pos = event.position
	if pressed and _context_menu.visible:
		if not _context_menu.get_global_rect().has_point(pos):
			_context_menu.hide()
			_clear_connect_mode()
			get_viewport().set_input_as_handled()
			return

	# Camera pan with mouse drag
	if _panning and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_camera.position += -event.relative / _camera.zoom
		get_viewport().set_input_as_handled()
		return

	# Touch drag: single-finger pan or two-finger pinch
	if event is InputEventScreenDrag:
		_touch_positions[event.index] = event.position
		if _panning and _touch_positions.size() == 1:
			_camera.position += -event.relative / _camera.zoom
			get_viewport().set_input_as_handled()
		elif _touch_positions.size() == 2 and _pinch_last_dist > 0:
			var new_dist: float = _get_pinch_dist()
			if new_dist > 0:
				var old_zoom: float = _camera.zoom.x
				var new_zoom: float = clamp(old_zoom * (new_dist / _pinch_last_dist), ZOOM_MIN, ZOOM_MAX)
				_camera.zoom = Vector2(new_zoom, new_zoom)
				_pinch_last_dist = new_dist
			get_viewport().set_input_as_handled()
