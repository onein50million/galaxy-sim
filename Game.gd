extends Node2D

const STARS = 1

onready var star_scene = load("res://star.tscn")
var rng = RandomNumberGenerator.new()
var selected_object = null

var empires = []

func _ready():
	rng.randomize()
	for i in range(0, STARS):
			
		var new_star = star_scene.instance()
		new_star.game = self
		new_star.mass_exponent = 13
		new_star.planets = 5
		new_star.position = Vector2(
			rng.randfn(0,100),
			rng.randfn(0,100)
		)
		var new_empire = Empire.new()
		new_empire.name = "Empire %s" % i
		empires.append(new_empire)
		new_empire.owned_systems.append(new_star)
		
		add_child(new_empire)
		add_child(new_star)
func _process(delta):
	var empire_index = 0
	for empire in empires:
		$CanvasLayer/EmpireInfo/Empires.get_children()[empire_index].get_node("resources").text = ""
		$CanvasLayer/EmpireInfo/Empires.get_children()[empire_index].get_node("credits").text = "Credits: %s" % empire.credits
		$CanvasLayer/EmpireInfo/Empires.get_children()[empire_index].get_node("credits").text = "Credits: %s" % empire.credits
		for good in empire.goods:
			$CanvasLayer/EmpireInfo/Empires.get_children()[empire_index].get_node("resources").text += "%s: %.2f" % [good, empire.goods[good]]
		empire_index += 1
		
	if selected_object != null:
		$CanvasLayer/PanelContainer/HBoxContainer/general_info/object_name.text = selected_object.name
		$CanvasLayer/PanelContainer/HBoxContainer/general_info/object_mass.text = "Mass: %s" %  selected_object.mass
		$CanvasLayer/PanelContainer/HBoxContainer/planet_info.visible = selected_object.type == "planet"
		$CanvasLayer/PanelContainer/HBoxContainer/market_info.visible = selected_object.type == "planet" #all planets have markets right now, will probably adjust later
		$CanvasLayer/PanelContainer/HBoxContainer/pop_info.visible = selected_object.type == "planet"
		if selected_object.type == "planet":
			$CanvasLayer/PanelContainer/HBoxContainer/planet_info/pop_info.text = ""
			$CanvasLayer/PanelContainer/HBoxContainer/planet_info/tax_label.text = "Tax Rate: %s" % selected_object.tax_rate
			$CanvasLayer/PanelContainer/HBoxContainer/planet_info/subsidy_label.text = "Subsidy Rate: %s" % selected_object.subsidy_rate
			var total_population = 0
			var total_credits = 0
			
			var total_goods = {}
			var total_specifier_demographics = [] #array of specifiers(species, job)
			for good in selected_object.market.supply:
				total_goods[good] = 0
			
			for demographic in Globals.SPECIFIERS.size():
				var new_specifier = []
				total_specifier_demographics.append(new_specifier)
				
				for i in range(0, Globals.SPECIFIERS[demographic].LENGTH):
					var new_entry = {}
					new_entry["population"] = 0
					new_specifier.append(new_entry)
			for pop_slice in selected_object.pop_slices:
				total_population += pop_slice.population
				total_credits += pop_slice.credits
				for demographic in range(pop_slice.demographics.size()):
					total_specifier_demographics[demographic][pop_slice.demographics[demographic]].population += pop_slice.population
				
				
				for good in selected_object.market.supply:
					total_goods[good] +=pop_slice.goods[good] 
			$CanvasLayer/PanelContainer/HBoxContainer/planet_info/pop_info.text += "Population: %d\nCredits: %.2f\n" %[total_population,total_credits]
			for good in selected_object.market.supply:
				$CanvasLayer/PanelContainer/HBoxContainer/planet_info/pop_info.text += "%s: %.2f\n" %  [good,total_goods[good]]
			$CanvasLayer/PanelContainer/HBoxContainer/market_info/good_info.text = ""
			for good in selected_object.market.supply:
				$CanvasLayer/PanelContainer/HBoxContainer/market_info/good_info.text += "Good: %s, Price: %.2f, Supply: %.2f, Demand: %.2f\n" %[good,selected_object.market.price[good], selected_object.market.supply[good], selected_object.market.demand[good]]
			$CanvasLayer/PanelContainer/HBoxContainer/pop_info/pop_info.text = ""
			
			for specifier in range(total_specifier_demographics.size()):
				$CanvasLayer/PanelContainer/HBoxContainer/pop_info/pop_info.text += "%s:\n" % specifier
				for demographic in range(total_specifier_demographics[specifier].size()):
					$CanvasLayer/PanelContainer/HBoxContainer/pop_info/pop_info.text += "%s Population: %d\n" % [Globals.get_specifier_name(demographic,specifier),total_specifier_demographics[specifier][demographic].population]


func _on_apply_button_pressed():
	if selected_object != null:
		selected_object.tax_rate = $CanvasLayer/PanelContainer/HBoxContainer/planet_info/tax.value
		selected_object.subsidy_rate = $CanvasLayer/PanelContainer/HBoxContainer/planet_info/subsidy.value
