extends Node
## Handles smooth open/close animations for all UI panels.

var _active_panel: Control = null
var _is_transitioning: bool = false

func open_panel(panel: Control) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_active_panel = panel
	panel.visible = true
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.95, 0.95)
	panel.pivot_offset = panel.size / 2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func(): _is_transitioning = false)

func close_panel(panel: Control, callback: Callable = Callable()) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	panel.pivot_offset = panel.size / 2
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.10).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(panel, "scale", Vector2(0.97, 0.97), 0.10).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func():
		panel.visible = false
		panel.scale = Vector2.ONE
		panel.modulate = Color.WHITE
		_is_transitioning = false
		_active_panel = null
		if callback.is_valid():
			callback.call()
	)

func is_panel_open() -> bool:
	return _active_panel != null and _active_panel.visible
