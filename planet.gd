extends Satellite

class_name Planet

var color = Color.brown
var randomized_shape = true
var moons = 0

var pop_slices = []
var market

var last_gametime = Globals.current_time

var tax_rate = 0.1
var subsidy_rate = 0.25


func _ready():
	type = "planet"
	if randomized_shape:
		color = Color(
			rng.randf_range(0.1,0.7),
			rng.randf_range(0.1,0.8),
			rng.randf_range(0.1,0.7)
			)
		size = rng.randf_range(1.0,3.0)
	
	#Generating all possible combinations of pop slices
	#Feels like there should be a better way to do this
	var specifier_lengths = []
	var current_specifiers = []

	for specifier in Globals.SPECIFIERS:
		specifier_lengths.append(specifier.LENGTH)
		current_specifiers.append(0)
	var total_combinations = 1
	for length in specifier_lengths:
		total_combinations *= length
	for i in range(0, total_combinations):
		pop_slices.append(PopSlice.new(current_specifiers, size*10.0))
		var number_to_add = 1
		var specifier_pointer = 0
		while number_to_add > 0 and specifier_pointer < specifier_lengths.size():
			if current_specifiers[specifier_pointer] >= specifier_lengths[specifier_pointer] - 1:
				current_specifiers[specifier_pointer] = 0
				specifier_pointer += 1
			else:
				current_specifiers[specifier_pointer] += 1
				number_to_add = 0
	market = Market.new(pop_slices)



func _process(delta):
	var delta_gametime = Globals.current_time - last_gametime
	last_gametime = Globals.current_time
	for pop_slice in pop_slices:
		pop_slice.produce_goods(delta_gametime)
		pop_slice.update_population(delta_gametime)
		pop_slice.calculate_demand(delta_gametime,market)
		pop_slice.tax(delta_gametime,owned_by,tax_rate)
		pop_slice.subsidise(delta_gametime, owned_by,subsidy_rate,pop_slices.size())
	market.calculate_supply_and_demand(delta_gametime)
	market.buy_and_sell_goods(delta_gametime)
	market.update_prices(delta_gametime)
func draw_object():
	draw_circle(Vector2(0,0),size, color)

func job_shift(delta):
	
#	Unfinished
	var max_price = market.price["food"]
	var max_good = "food"
	for good in market.price:
		if market.price[good] > max_price:
			max_good = good
	var target_job = Globals.Job.FARMER
	match max_good:
		"food":
			target_job = Globals.Job.FARMER
		"minerals":
			target_job = Globals.Job.MINER
		"alloys":
			target_job = Globals.Job.REFINER
		"equipment":
			target_job = Globals.Job.OFFICER
	var ratio_moved = 0.1
	for pop_slice in pop_slices:
		var population_change = pop_slice.population*clamp(ratio_moved*delta,0,1)
		pop_slice.population -= population_change
		

class PopSlice:

	var population = 100.0
	var credits = 1000.0
	var goods = {
		food = 0.0,
		minerals = 0.0,
		alloys = 0.0,
		equipment = 0.0
	}
	var demand = {
		food = 0.0,
		minerals = 0.0,
		alloys = 0.0,
		equipment = 0.0
	}

	
	var demographics = []
	
	func _init(specifiers,new_population):
#		#order: species, job
#		species = specifiers[0]
#		job = specifiers[1]
		demographics = specifiers.duplicate(true)
#		print(specifiers)
		population = new_population
	
	func get_need(delta,good):
		match good:
			"food":
				var food_ratio = 0.25
				if demographics[Globals.SpecifierEnum.SPECIES] == Globals.Species.ALIEN:
					food_ratio *= 2.0
				return population*food_ratio*delta
			"minerals":
				if demographics[Globals.SpecifierEnum.JOB]  == Globals.Job.REFINER:
					return population*4.0 * delta 
			"alloys":
				if demographics[Globals.SpecifierEnum.JOB] == Globals.Job.OFFICER:
					return population * 4.0 * delta
			"equipment":
				return population* 0.01 * delta
		return 0
	func calculate_demand(delta,market):
		var credits_left = credits
		var seconds_wanted = 1
		for good in goods:
			demand[good] = 0
			demand[good] += max(0,get_need(delta,good)*seconds_wanted - goods[good])
			demand[good] = min(demand[good],credits_left/market.price[good])
			credits_left -= demand[good]*market.price[good]
#			assert(demand[good] > -Globals.FLOAT_EPSILON)
	func update_population(delta):

			var food_wanted = get_need(delta,"food")
			var food_used = min(goods.food,food_wanted)	
			goods.food -= food_used
			if food_wanted > 0:
				population += (population * (-0.019 + 0.02*(food_used/food_wanted))) * delta
				
			var equipment_wanted = get_need(delta,"equipment")
			var equipment_used = min(goods.equipment,equipment_wanted)	
			goods.equipment -= equipment_used
			if equipment_wanted > 0:
				population += (population * (0.03*(equipment_used/equipment_wanted))) * delta
			assert(population >= -Globals.FLOAT_EPSILON)
	func produce_goods(delta):
		match demographics[Globals.SpecifierEnum.JOB]:
			Globals.Job.FARMER:
				var food_ratio = 0.5
				goods.food += pow(population,0.9)* food_ratio * delta
			Globals.Job.MINER:
				var minerals_ratio = 0.1
				goods.minerals += population*minerals_ratio * delta
			Globals.Job.REFINER:
				var alloy_ratio = 4.0
				var minerals_wanted = population*alloy_ratio * delta
				var minerals_used = min(goods.minerals,minerals_wanted)
				goods.minerals -= minerals_used
				goods.alloys += minerals_used/alloy_ratio
			Globals.Job.OFFICER:
				var equipment_ratio = 4.0
				var alloys_wanted = population * equipment_ratio * delta
				var alloys_used = min(goods.alloys,alloys_wanted)
				goods.alloys -= alloys_used
				goods.equipment += alloys_used/equipment_ratio
	func tax(delta,taxer,tax_rate):
		var tax_period = 300
		var credits_taxed = credits*tax_rate * delta / tax_period
		taxer.credits += credits_taxed
		credits -= credits_taxed
		for good in goods:
			var amount_taxed = goods[good]*tax_rate * delta / tax_period
			taxer.goods[good] += amount_taxed
			goods[good] -= amount_taxed
			
	func subsidise(delta,subsidiser,subsidy_rate,num_pop_slices):
		var subsidy_period = 300
		var credits_subsidised = (subsidiser.credits*subsidy_rate * delta / subsidy_period) / num_pop_slices
		subsidiser.credits -= credits_subsidised
		credits += credits_subsidised
		for good in goods:
			var amount_subsidised = (subsidiser.goods[good]*subsidy_rate * delta / subsidy_period )/ num_pop_slices
			subsidiser.goods[good] -= amount_subsidised
			goods[good] += amount_subsidised
		

class Market:
	var pop_slices
	var supply = {
		food = 0.0,
		minerals = 0.0,
		alloys = 0.0,
		equipment = 0.0
	}
	var demand = {
		food = 0.0,
		minerals = 0.0,
		alloys = 0.0,
		equipment = 0.0
	}
	
	var price = {
		food = 1.0,
		minerals = 0.01,
		alloys = 1.0,
		equipment = 1.0
	}
	
	func _init(planet_pop_slices):
		self.pop_slices = planet_pop_slices

	func calculate_supply_and_demand(delta):
		for good in supply:
			supply[good] = 0.0
			demand[good] = 0.0
			for pop_slice in pop_slices:
				supply[good] += pop_slice.goods[good]
				demand[good] += pop_slice.demand[good]
	
	func buy_and_sell_goods(delta):
		for good in supply:
			var total_traded_goods = min(supply[good],demand[good])
			var total_ratio_bought = 0.0
			var total_ratio_sold = 0.0
			var amount_sold = 0.0
			var amount_bought = 0.0
			var credits_gained = 0.0
			var credits_lost = 0.0
			
			if supply[good] > 0:
				total_ratio_sold = clamp(demand[good]/supply[good],0.0,1.0)
			if demand[good] > 0:
				total_ratio_bought = clamp(supply[good]/demand[good],0.0,1.0)
			for pop_slice in pop_slices:
				var sold_goods = pop_slice.goods[good] * total_ratio_sold
				pop_slice.goods[good] -= sold_goods
				pop_slice.credits += sold_goods*price[good]
				credits_gained += sold_goods*price[good]
				amount_sold += sold_goods
#				assert(pop_slice.credits >= -Globals.FLOAT_EPSILON)
				
				var bought_goods = pop_slice.demand[good] * total_ratio_bought
				pop_slice.goods[good] += bought_goods
				pop_slice.credits -= bought_goods*price[good]
				credits_lost += bought_goods*price[good]
				amount_bought = bought_goods
#				assert(pop_slice.credits >= -Globals.FLOAT_EPSILON)
#			print("credits delta: %s" % (credits_gained-credits_lost))
#			print("actual amount sold: %s"%(amount_sold + amount_bought))
#			print("total traded goods: %s" % total_traded_goods)
#			print("Total ratio sold: %s\nTotal Ratio Bought: %s" %[total_ratio_sold,total_ratio_bought])
#			print(amount_sold)
	func update_prices(delta):
		for good in supply:
			if supply[good] > demand[good]:
				price[good] -= price[good]*1*delta
			if supply[good] < demand[good]:
				price[good] += price[good]*1*delta
			price[good] = max(price[good],Globals.FLOAT_EPSILON)
