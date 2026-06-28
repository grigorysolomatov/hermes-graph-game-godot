class_name NodeMenuView
extends Control

signal spawn_node_requested(type: GameState.NodeType, world_pos: Vector2)

const EXPANDED_OFFSET: float = -120.0
const COLLAPSED_OFFSET: float = 0.0

var _collapsed: bool = false
var _tween: Tween
var _drag_type: GameState.NodeType = GameState.NodeType.WORKER
var _dragging: bool = false
var _ghost = null
var _game_world: Node2D = null
var _labor_tex: Texture2D = null
var _fish_tex: Texture2D = null

@onready var _toggle_btn: Button = $ToggleBtn
@onready var _worker_btn: Button = $Panel/HBox/WorkerBtn
@onready var _sea_btn: Button = $Panel/HBox/SeaBtn

func set_textures(labor: Texture2D, fish: Texture2D) -> void:
	_labor_tex = labor
	_fish_tex = fish

func set_game_world(world: Node2D) -> void:
	_game_world = world

func _on_toggle_pressed() -> void:
	_collapsed = !_collapsed
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _collapsed:
		_tween.tween_property(self, "offset_top", COLLAPSED_OFFSET, 0.25)
		_toggle_btn.text = "+"
	else:
		_tween.tween_property(self, "offset_top", EXPANDED_OFFSET, 0.25)
		_toggle_btn.text = "-"

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _input(event: InputEvent) -> void:
	# Detect drag start from a press inside a node button
	if not _dragging:
		var screen_pos: Vector2 = Vector2.ZERO
		var is_press: bool = false
		if event is InputEventScreenTouch and event.pressed:
			screen_pos = event.position
			is_press = true
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			screen_pos = event.position
			is_press = true
		if is_press and is_instance_valid(_worker_btn) and is_instance_valid(_sea_btn):
			if _worker_btn.get_global_rect().has_point(screen_pos):
				_drag_type = GameState.NodeType.WORKER
				_dragging = true
				_spawn_ghost(screen_pos)
				get_viewport().set_input_as_handled()
				return
			elif _sea_btn.get_global_rect().has_point(screen_pos):
				_drag_type = GameState.NodeType.SEA
				_dragging = true
				_spawn_ghost(screen_pos)
				get_viewport().set_input_as_handled()
				return
		return

	# Already dragging: track motion and release
	var pos: Vector2 = Vector2.ZERO
	var released: bool = false
	var has_event: bool = true

	if event is InputEventScreenTouch:
		pos = event.position
		released = not event.pressed
	elif event is InputEventScreenDrag:
		pos = event.position
	elif event is InputEventMouseMotion:
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		released = not event.pressed
	else:
		has_event = false

	if not has_event:
		return

	if _ghost != null:
		_ghost.global_position = _screen_to_world(pos)

	if released:
		_finish_drag(pos)
		get_viewport().set_input_as_handled()

func _spawn_ghost(screen_pos: Vector2) -> void:
	if _game_world == null:
		return
	var scene: PackedScene = load("res://scenes/Node.tscn")
	_ghost = scene.instantiate()
	_game_world.add_child(_ghost)
	_ghost.setup_ghost(_drag_type, _labor_tex, _fish_tex)
	_ghost.global_position = _screen_to_world(screen_pos)

func _finish_drag(screen_pos: Vector2) -> void:
	_dragging = false
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	# Cancel if released inside the NodeMenu panel
	if get_global_rect().has_point(screen_pos):
		return
	var world_pos: Vector2 = _screen_to_world(screen_pos)
	spawn_node_requested.emit(_drag_type, world_pos)
