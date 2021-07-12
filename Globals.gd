extends Node

var current_time = 0

const FLOAT_EPSILON = 0.01

enum Species  {
	HUMAN,
	ALIEN,
	LENGTH
}
#	var species

enum Job {
	FARMER,
	MINER,
	REFINER,
	OFFICER,
	LENGTH
}


const SPECIFIERS = [Species,Job]
enum SpecifierEnum {
	SPECIES,
	JOB,
	LENGTH
}


func _ready():
	pass

func _process(delta):
	current_time += delta

func get_specifier_name(target_specifier, index):
	for specifier in SPECIFIERS[index]:
		if SPECIFIERS[index][specifier] == target_specifier:
			return specifier
	return "UNKNOWN SPECIFIER"
