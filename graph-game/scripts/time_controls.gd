class_name TimeControlsView
extends Control

const EXPANDED_OFFSET: float = -152.0
const COLLAPSED_OFFSET: float = -32.0

var _collapsed: bool = false
var _tween: Tween

@onready var _toggle_btn: Button = $ToggleBtn
@onready var _pause_btn: Button = $Panel/VBox/PauseBtn
@onready var _speed1_btn: Button = $Panel/VBox/Speed1Btn
@onready var _speed2_btn: Button = $Panel/VBox/Speed2Btn

func _ready() -> void:
	_set_active_speed(1)

func _on_toggle_pressed() -> void:
	_collapsed = !_collapsed
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _collapsed:
		_tween.tween_property(self, "offset_left", COLLAPSED_OFFSET, 0.25)
		_toggle_btn.text = "<"
	else:
		_tween.tween_property(self, "offset_left", EXPANDED_OFFSET, 0.25)
		_toggle_btn.text = ">"

func _on_pause_pressed() -> void:
	GameState.paused = true
	_set_active_speed(-1)

func _on_speed1_pressed() -> void:
	GameState.paused = false
	GameState.set_speed(1)
	_set_active_speed(1)

func _on_speed2_pressed() -> void:
	GameState.paused = false
	GameState.set_speed(2)
	_set_active_speed(2)

func _set_active_speed(active: int) -> void:
	var highlight: Color = Color(0.4, 0.8, 1.0)
	var normal: Color = Color(0.9, 0.9, 0.9)
	_pause_btn.add_theme_color_override("font_color", normal)
	_speed1_btn.add_theme_color_override("font_color", normal)
	_speed2_btn.add_theme_color_override("font_color", normal)
	match active:
		-1: _pause_btn.add_theme_color_override("font_color", highlight)
		1: _speed1_btn.add_theme_color_override("font_color", highlight)
		2: _speed2_btn.add_theme_color_override("font_color", highlight)
