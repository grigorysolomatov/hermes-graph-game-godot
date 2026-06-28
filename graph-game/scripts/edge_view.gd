class_name EdgeView
extends Node2D

signal edge_tapped(edge_id: int)

const ARROW_LEN: float = 16.0
const ARROW_HALF: float = 8.0
const LINE_COLOR: Color = Color(0.8, 0.8, 0.8, 0.9)
const NODE_RADIUS: float = 36.0
const DOT_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const DOT_RADIUS: float = 6.0

var edge_id: int = -1
var source_id: int = -1
var target_id: int = -1

var _line: Line2D
var _arrow: Polygon2D
var _world_from: Vector2 = Vector2.ZERO
var _world_to: Vector2 = Vector2.ZERO

var _transport_t: float = -1.0
var _transport_tween: Tween

func _ready() -> void:
	_line = Line2D.new()
	_line.width = 3.0
	_line.default_color = LINE_COLOR
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_NONE
	add_child(_line)

	_arrow = Polygon2D.new()
	_arrow.color = LINE_COLOR
	add_child(_arrow)

func setup(id: int, src: int, tgt: int) -> void:
	edge_id = id
	source_id = src
	target_id = tgt

func _process(_delta: float) -> void:
	_redraw()
	if _transport_t >= 0.0:
		queue_redraw()

func _draw() -> void:
	if _transport_t >= 0.0:
		draw_circle(_world_from.lerp(_world_to, _transport_t), DOT_RADIUS, DOT_COLOR)

func animate_transport() -> void:
	_transport_t = 0.0
	if is_instance_valid(_transport_tween):
		_transport_tween.kill()
	_transport_tween = create_tween()
	_transport_tween.tween_property(self, "_transport_t", 1.0, GameState._tick_interval)
	_transport_tween.tween_callback(func() -> void:
		_transport_t = -1.0
		queue_redraw()
	)

func _redraw() -> void:
	if not GameState.nodes.has(source_id) or not GameState.nodes.has(target_id):
		return
	var from: Vector2 = GameState.nodes[source_id]["position"]
	var to: Vector2 = GameState.nodes[target_id]["position"]
	var dir: Vector2 = (to - from).normalized()
	var p0: Vector2 = from + dir * NODE_RADIUS
	var p1: Vector2 = to - dir * (NODE_RADIUS + ARROW_LEN)
	_world_from = p0
	_world_to = to - dir * NODE_RADIUS

	_line.clear_points()
	_line.add_point(p0)
	_line.add_point(p1)

	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var tip: Vector2 = to - dir * NODE_RADIUS
	var base: Vector2 = tip - dir * ARROW_LEN
	_arrow.polygon = PackedVector2Array([
		tip,
		base + perp * ARROW_HALF,
		base - perp * ARROW_HALF
	])

func _input(event: InputEvent) -> void:
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
	if _is_near_line_world(world_pos, 20.0):
		edge_tapped.emit(edge_id)
		get_viewport().set_input_as_handled()

func _is_near_line_world(point: Vector2, threshold: float) -> bool:
	var seg: Vector2 = _world_to - _world_from
	var seg_len: float = seg.length()
	if seg_len < 1.0:
		return false
	var t: float = (point - _world_from).dot(seg) / (seg_len * seg_len)
	t = clamp(t, 0.0, 1.0)
	var closest: Vector2 = _world_from + seg * t
	return point.distance_to(closest) <= threshold
