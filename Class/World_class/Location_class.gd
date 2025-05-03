## 可视范围数据的传递和更新
extends RefCounted
class_name Location

var location_aabb: AABB
var location_floatingisland_cell: Dictionary

signal location_floatingisland_updeta(location_floatingisland)

func _init(Location_size: Vector3) -> void:
	location_aabb = AABB(Vector3.ZERO, Location_size)

## 更新可视范围内的数据
func location_update(player_posi: Vector3, floatingisland_gridpartition: World_manager):
	location_aabb.position += player_posi - location_aabb.get_center()
	location_floatingisland_cell = floatingisland_gridpartition.query_floatingisland_cell(location_aabb)
	
	print(location_floatingisland_cell)
	emit_signal("location_floatingisland_updeta", location_floatingisland_cell)
	
