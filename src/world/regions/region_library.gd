class_name RegionLibrary
extends Resource
## Every region, so saves and exits can refer to regions by id. File: data/world/regions.tres.

@export var regions: Array[RegionData] = []


func find(id: StringName) -> RegionData:
	for region in regions:
		if region.id == id:
			return region
	return null
