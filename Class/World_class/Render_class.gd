## 管理游戏场景渲染的类
## 
## 使用计算着色器剔除不可见区块
## 使用MeshInstance3D创建
extends MeshInstance3D
class_name Render

var _floatingisland_grid := {}
var _mesh:ArrayMesh

func add_mesh(floatingisland_grid: Dictionary):
	_floatingisland_grid = floatingisland_grid
	generate_mash()
	
func generate_mash():
	var surfacetool = SurfaceTool.new()
	
	surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for floatingisland in _floatingisland_grid:
		var offset = floatingisland.floatingisland_AABB.position
		for cell in _floatingisland_grid[floatingisland]:
			var mesh_array = _floatingisland_grid[floatingisland][cell]
			for index in range(mesh_array[Mesh.ARRAY_VERTEX].size()):
				var vertex = mesh_array[Mesh.ARRAY_VERTEX][index] + offset
				surfacetool.set_normal(mesh_array[Mesh.ARRAY_NORMAL][index])
				surfacetool.set_uv(mesh_array[Mesh.ARRAY_TEX_UV][index])
				surfacetool.add_vertex(vertex)
				
				
	_mesh = surfacetool.commit()
	mesh = _mesh
	
