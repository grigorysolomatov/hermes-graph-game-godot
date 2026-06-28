extends Control

var _labor_tex: Texture2D
var _fish_tex: Texture2D
var _node_views: Dictionary = {}
var _edge_views: Dictionary = {}
var _connect_source: int = -1

@onready var _game_world: Node2D = $GameWorld
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

func _on_node_tapped(node_id: int, world_pos: Vector2) -> void:
	if _connect_source >= 0:
		if node_id != _connect_source:
			GameState.add_edge(_connect_source, node_id, GameState.ResourceType.LABOR)
		_connect_source = -1
		_context_menu.hide()
		return
	_context_menu.node_id = node_id
	var screen_pos: Vector2 = get_viewport().get_canvas_transform() * world_pos
	screen_pos.y -= 70.0
	screen_pos.x -= 80.0
	_context_menu.position = screen_pos
	_context_menu.show()

func _on_edge_tapped(edge_id: int) -> void:
	_resource_picker.show_for(edge_id)

func _on_delete_node(node_id: int) -> void:
	GameState.remove_node(node_id)

func _on_connect_start(node_id: int) -> void:
	_connect_source = node_id

func _on_resource_selected(edge_id: int, resource_type: GameState.ResourceType) -> void:
	GameState.set_edge_resource(edge_id, resource_type)

func _input(event: InputEvent) -> void:
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
			_connect_source = -1
