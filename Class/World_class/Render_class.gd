## 管理游戏场景渲染的类
## 
## 使用计算着色器剔除不可见区块
## 使用MeshInstance3D创建
extends MeshInstance3D
class_name Render

var _floatingisland_grid:Dictionary
var _mesh:ArrayMesh

func add_mesh(floatingisland_grid: Dictionary):
	_floatingisland_grid = floatingisland_grid
	generate_mash()
	
func generate_mash():
	var surfacetool = SurfaceTool.new()
	
	var surfacetool_array:Array = Array()
	surfacetool_array.resize(13)
	surfacetool_array[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surfacetool_array[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	
	surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for floatingisland in _floatingisland_grid:
		var offset = floatingisland.floatingisland_AABB.position
		for cell in _floatingisland_grid[floatingisland]:
			for faces in _floatingisland_grid[floatingisland][cell]:
				if faces[Mesh.ARRAY_FORMAT_VERTEX] == null and faces[Mesh.ARRAY_NORMAL] == null:
					continue
				surfacetool_array[Mesh.ARRAY_VERTEX].append_array(faces[Mesh.ARRAY_VERTEX])
				surfacetool_array[Mesh.ARRAY_NORMAL].append_array(faces[Mesh.ARRAY_NORMAL])
				
	surfacetool.create_from_arrays(surfacetool_array)
	#print(surfacetool.commit_to_arrays())
	_mesh = surfacetool.commit()
	mesh = _mesh
	
