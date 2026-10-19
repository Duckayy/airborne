extends Node
class_name ShopData

const UPGRADES = [
	{
		"id": "speed_boost",
		"name": "Swift Boots",
		"description": "Move A Lil Faster",
		"cost": 50,
		"stat": "speed",
		"amount": 2.0,
		"max_level": 5,
	},
		{
		"id": "sprint_boost",
		"name": "",
		"description": "",
		"cost": 75,
		"stat": "sprint_speed",
		"amount": 3.0,
		"max_level": 5,
	},
		{
		"id": "health_up",
		"name": "Reinforced Armor",
		"description": "Increase Max HP",
		"cost": 100,
		"stat": "max_health",
		"amount": 25.0,
		"max_level": 5,
	},
		{
		"id": "stamina_up",
		"name": "Sprinter Lunges",
		"description": "Move Faster A Lil Longer",
		"cost": 80,
		"stat": "max_stamina",
		"amount": 20.0,
		"max_level": 5,
	},
		{
		"id": "jump_boost",
		"name": "Kangaroo Legs",
		"description": "Jump to the moon",
		"cost": 60,
		"stat": "jump_velocity",
		"amount": 3.0,
		"max_level": 3,
	},
		{
		"id": "stamina_regen",
		"name": "Vaccuum Lungs",
		"description": "Stamina fegenerates faster (Save some air for the rest of us)",
		"cost": 90,
		"stat": "stamina_regen",
		"amount": 5.0,
		"max_level": 4,
	},
	
]
