extends Node

signal tick
signal node_added(node_data: Dictionary)
signal node_removed(node_id: int)
signal edge_added(edge_data: Dictionary)
signal edge_removed(edge_id: int)

enum NodeType { WORKER, SEA }
enum ResourceType { LABOR, FISH }

const RESOURCE_NAMES: Array[String] = ["Labor", "Fish"]
const TICK_INTERVAL_1X: float = 1.0
const TICK_INTERVAL_2X: float = 0.5

var nodes: Dictionary = {}  # id -> Dictionary
var edges: Dictionary = {}  # id -> Dictionary
var _next_node_id: int = 0
var _next_edge_id: int = 0
var _tick_timer: float = 0.0
var _tick_interval: float = TICK_INTERVAL_1X
var paused: bool = true
var speed_multiplier: int = 1  # 1 or 2

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if paused:
		return
	_tick_timer += delta
	if _tick_timer >= _tick_interval:
		_tick_timer -= _tick_interval
		_do_tick()

func set_speed(mult: int) -> void:
	speed_multiplier = mult
	if mult == 2:
		_tick_interval = TICK_INTERVAL_2X
	else:
		_tick_interval = TICK_INTERVAL_1X

func add_node(type: NodeType, position: Vector2) -> int:
	var id: int = _next_node_id
	_next_node_id += 1
	var inventory: Dictionary = {}
	nodes[id] = {
		"id": id,
		"type": type,
		"position": position,
		"inventory": inventory
	}
	node_added.emit(nodes[id])
	return id

func remove_node(node_id: int) -> void:
	if not nodes.has(node_id):
		return
	# Remove all edges connected to this node
	var edges_to_remove: Array[int] = []
	for eid: int in edges:
		var e: Dictionary = edges[eid]
		if e["source"] == node_id or e["target"] == node_id:
			edges_to_remove.append(eid)
	for eid: int in edges_to_remove:
		remove_edge(eid)
	nodes.erase(node_id)
	node_removed.emit(node_id)

func add_edge(source_id: int, target_id: int, resource_type: ResourceType) -> int:
	# Prevent duplicate edges
	for eid: int in edges:
		var e: Dictionary = edges[eid]
		if e["source"] == source_id and e["target"] == target_id:
			return -1
	var id: int = _next_edge_id
	_next_edge_id += 1
	edges[id] = {
		"id": id,
		"source": source_id,
		"target": target_id,
		"resource_type": resource_type
	}
	edge_added.emit(edges[id])
	return id

func remove_edge(edge_id: int) -> void:
	if not edges.has(edge_id):
		return
	edges.erase(edge_id)
	edge_removed.emit(edge_id)

func set_edge_resource(edge_id: int, resource_type: ResourceType) -> void:
	if edges.has(edge_id):
		edges[edge_id]["resource_type"] = resource_type

func get_node_inventory_count(node_id: int, res: ResourceType) -> int:
	if not nodes.has(node_id):
		return 0
	var inv: Dictionary = nodes[node_id]["inventory"]
	return inv.get(res, 0)

func _add_to_inventory(node_id: int, res: ResourceType, amount: int) -> void:
	if not nodes.has(node_id):
		return
	var inv: Dictionary = nodes[node_id]["inventory"]
	inv[res] = inv.get(res, 0) + amount

func _sub_from_inventory(node_id: int, res: ResourceType, amount: int) -> int:
	if not nodes.has(node_id):
		return 0
	var inv: Dictionary = nodes[node_id]["inventory"]
	var have: int = inv.get(res, 0)
	var taken: int = min(have, amount)
	inv[res] = have - taken
	return taken

func _do_tick() -> void:
	# 1. Worker nodes produce labor (if under capacity)
	for node_id: int in nodes:
		var n: Dictionary = nodes[node_id]
		if n["type"] == NodeType.WORKER:
			var current: int = n["inventory"].get(ResourceType.LABOR, 0)
			if current < 1:
				_add_to_inventory(node_id, ResourceType.LABOR, 1)

	# 2. Move resources along edges
	for edge_id: int in edges:
		var e: Dictionary = edges[edge_id]
		var res: ResourceType = e["resource_type"]
		var src: int = e["source"]
		var tgt: int = e["target"]
		var taken: int = _sub_from_inventory(src, res, 1)
		if taken > 0:
			_add_to_inventory(tgt, res, taken)

	# 3. Sea nodes convert labor -> fish
	for node_id: int in nodes:
		var n: Dictionary = nodes[node_id]
		if n["type"] == NodeType.SEA:
			var labor: int = n["inventory"].get(ResourceType.LABOR, 0)
			if labor > 0:
				n["inventory"][ResourceType.LABOR] = 0
				_add_to_inventory(node_id, ResourceType.FISH, labor)

	tick.emit()
