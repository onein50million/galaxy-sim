extends Node2D

class_name Stellar

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var mass_significand: int = 1
var mass_exponent: int = 1
var planets = 0
var size = 5.0
var type = "stellar"
var mass = mass_significand*pow(10,mass_exponent)
var game

var owned_by

onready var planet_scene = load("res://planet.tscn")

var rng = RandomNumberGenerator.new()
var is_highlighted = false
var is_selected = false
# Called when the node enters the scene tree for the first time.
func _ready():
	for empire in game.empires:
		if self in empire.owned_systems:
			owned_by = empire
	type = "star"
	rng.randomize()
	print(mass)
	for i in range(0, planets):
		var new_planet = planet_scene.instance()
		new_planet.name = "Planet %d" % i
		new_planet.mass_exponent = mass_exponent - 1
		new_planet.semimajor_axis = rng.randf_range(15,50)
		new_planet.semiminor_axis = rng.randf_range(15,new_planet.semimajor_axis)
		new_planet.game = game
		new_planet.owned_by = owned_by
		add_child(new_planet)


func _input(event):
	if event.is_action_pressed("select") and is_highlighted:
		game.selected_object = self

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mass = mass_significand*pow(10,mass_exponent)
	is_selected = game.selected_object == self
	is_highlighted = get_local_mouse_position().length() < size and not is_selected
	update()

func _draw():
	if is_selected:
		draw_circle(Vector2.ZERO, size*1.1, Color.yellow)
	draw_object()
	if is_highlighted:
		draw_circle(Vector2.ZERO, size, Color.red)

func draw_object():
	draw_circle(Vector2(0,0),size, Color.yellow)

