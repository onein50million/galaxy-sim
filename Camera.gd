extends Node2D

const PAN_MODIFIER = 1.1

var panning = false
var prev_mouse_position

func _ready():
	prev_mouse_position = get_global_mouse_position()

func _input(event):
	if event.is_action_pressed("zoom_in"):
		zoom(1.1, get_global_mouse_position())
	if event.is_action_pressed("zoom_out"):
		zoom(0.9, get_global_mouse_position())
	if event.is_action_pressed("reset_zoom"):
		var new_transform = Transform2D.IDENTITY
		get_viewport().canvas_transform = new_transform
func _process(delta):
	var delta_mouse_position = prev_mouse_position - get_global_mouse_position()
	prev_mouse_position = get_global_mouse_position()
	
	if Input.is_action_pressed("pan"):
		get_viewport().canvas_transform = get_viewport().canvas_transform.translated(-delta_mouse_position/PAN_MODIFIER)
func zoom(amount, zoom_position):

	var canvas_zoom_position = get_viewport().canvas_transform.xform(zoom_position)
	
	get_viewport().canvas_transform.origin += -canvas_zoom_position
	get_viewport().canvas_transform = get_viewport().canvas_transform.scaled(Vector2(amount,amount))
	get_viewport().canvas_transform.origin += canvas_zoom_position
