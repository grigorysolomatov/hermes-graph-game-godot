class_name NodeMenuView
extends Control

signal spawn_node_requested(type: GameState.NodeType, world_pos: Vector2)

const EXPANDED_OFFSET: float = -156.0
const COLLAPSED_OFFSET: float = -36.0

var _collapsed: bool = false
var _tween: Tween
var _drag_type: GameState.NodeType = GameState.NodeType.WORKER
var _dragging: bool = false
var _ghost = null
var _game_world: Node2D = null
var _labor_tex: Texture2D = null
var _fish_tex: Texture2D = null

@onready var _toggle_btn: Button = $ToggleBtn

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

func _on_worker_drag_started() -> void:
	_begin_drag(GameState.NodeType.WORKER)

func _on_sea_drag_started() -> void:
	_begin_drag(GameState.NodeType.SEA)

func _begin_drag(type: GameState.NodeType) -> void:
	_drag_type = type
	_dragging = true

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	var pos: Vector2 = Vector2.ZERO
	var released: bool = false
	if event is InputEventScreenTouch:
		pos = event.position
		released = not event.pressed
	elif event is InputEventMouseMotion:
		pos = event.position
	elif event is InputEventMouseButton:
		pos = event.position
		released = not event.pressed
	else:
		return

	if _ghost == null and _game_world != null:
		_spawn_ghost(pos)
	if _ghost != null:
		_ghost.global_position = _screen_to_world(pos)

	if released:
		_finish_drag(pos)

func _spawn_ghost(_screen_pos: Vector2) -> void:
	var scene: PackedScene = load("res://scenes/Node.tscn")
	_ghost = scene.instantiate()
	_game_world.add_child(_ghost)
	_ghost.setup_ghost(_drag_type, _labor_tex, _fish_tex)

func _finish_drag(screen_pos: Vector2) -> void:
	_dragging = false
	if _ghost != null:
		var world_pos: Vector2 = _screen_to_world(screen_pos)
		_ghost.queue_free()
		_ghost = null
		spawn_node_requested.emit(_drag_type, world_pos)
