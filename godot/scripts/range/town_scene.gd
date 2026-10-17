class_name TownScene
extends SkirmishScene
## Scene root for MAP-3 "Town" (town.tscn): the Skirmish rules on TownData's tables.


func map_id() -> String:
	return "town"


func map_data() -> GDScript:
	return TownData
