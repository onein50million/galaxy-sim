extends Stellar

class_name Satellite

const GRAVITATIONAL_CONSTANT = 6.6743*pow(10,-11)

var pericenter_time = 0
export var semimajor_axis = 30
export var semiminor_axis = 25
export var argument_periapsis = PI


var randomized = false


func _ready():
	pass

func _process(delta):
	var period = TAU*sqrt(pow(semimajor_axis,3)/(GRAVITATIONAL_CONSTANT*get_parent().mass))
	var eccentricity = sqrt(1-(pow(semiminor_axis,2)/pow(semimajor_axis,2)))
	if not randomized:
		var rng = RandomNumberGenerator.new()
		rng.randomize()
		pericenter_time = rng.randf_range(0,period)
		argument_periapsis = rng.randf_range(0,TAU)
		randomized = true
	
	var mean_motion = TAU/period
	var mean_anomaly = mean_motion*(Globals.current_time-pericenter_time)
	var eccentric_anomaly = find_eccentric_anomaly(mean_anomaly,eccentricity)
	var true_anomaly = 2*atan(sqrt((1+eccentricity)/(1-eccentricity))*tan(eccentric_anomaly/2))
	var heliocentric_distance = semimajor_axis*(1-eccentricity*cos(eccentric_anomaly))
	
#	position = Vector2(
#		semimajor_axis*(cos(eccentric_anomaly-eccentricity)) + sqrt(pow(semimajor_axis,2)-pow(semiminor_axis,2)),
#		semiminor_axis*sin(eccentric_anomaly)
#	)
	
	position = Vector2(
		heliocentric_distance*cos(true_anomaly + argument_periapsis),
		heliocentric_distance*sin(true_anomaly + argument_periapsis)
	)


func draw_object():
	draw_circle(Vector2(0,0),0.1, Color.black)

func find_eccentric_anomaly(mean_anomaly, eccentricity):
	var potential_eccentric_anomaly = 0
	for _i in range(0,3):
		potential_eccentric_anomaly = mean_anomaly + eccentricity*sin(potential_eccentric_anomaly)
	return potential_eccentric_anomaly
