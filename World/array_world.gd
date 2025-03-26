extends StaticBody3D

@onready var array_mesh = $array_mesh
@onready var collision = $collision

@export var  size = 0.5

var vertices = [
	Vector3(size, -size, size),
	Vector3(-size, -size, size),
	Vector3(-size, size, size),
	Vector3(size, size, size),
	Vector3(size, -size, -size),
	Vector3(-size, -size, -size),
	Vector3(-size, size, -size),
	Vector3(size, size, -size)
]

#定义面的朝向
const FACE_OFFSETS = {
	"FRONT": Vector3(0, 0, 1),
	"BACK": Vector3(0, 0, -1),
	"LEFT": Vector3(-1, 0, 0),
	"RIGHT": Vector3(1, 0, 0),
	"TOP": Vector3(0, 1, 0),
	"BOTTOM": Vector3(0, -1, 0)
}

#定义面中三角形的绘制顺序以及朝向
var faces = [
	[0, 1, 2, FACE_OFFSETS.FRONT],   # Front face triangle 1
	[0, 2, 3, FACE_OFFSETS.FRONT],   # Front face triangle 2
	[5, 4, 7, FACE_OFFSETS.BACK],    # Back face triangle 1
	[5, 7, 6, FACE_OFFSETS.BACK],    # Back face triangle 2
	[1, 5, 6, FACE_OFFSETS.LEFT],    # Left face triangle 1
	[1, 6, 2, FACE_OFFSETS.LEFT],    # Left face triangle 2
	[4, 0, 3, FACE_OFFSETS.RIGHT],   # Right face triangle 1
	[4, 3, 7, FACE_OFFSETS.RIGHT],   # Right face triangle 2
	[4, 5, 1, FACE_OFFSETS.BOTTOM],  # Bottom face triangle 1
	[4, 1, 0, FACE_OFFSETS.BOTTOM],  # Bottom face triangle 2
	[3, 2, 6, FACE_OFFSETS.TOP],     # Top face triangle 1
	[3, 6, 7, FACE_OFFSETS.TOP]      # Top face triangle 2
]

#定义每个面是否渲染面的bit位或索引
var FaceMask = {
	"FRONT":0,
	"BACK":1,
	"LEFT":2,
	"RIGHT":3,
	"TOP":4,
	"BOTTOM":5
}

#实现每个面正确的uv映射
func calculate_uv(vertex: Vector3, normal: Vector3) -> Vector2:
	var u = 0.0
	var v = 0.0
	var half_size = size
	
	# 根据面法线确定UV映射方式
	if normal == FACE_OFFSETS.FRONT || normal == FACE_OFFSETS.BACK:
		u = (-vertex.x + half_size) / (2 * half_size)
		v = (-vertex.y + half_size) / (2 * half_size)
	elif normal == FACE_OFFSETS.RIGHT || normal == FACE_OFFSETS.LEFT:
		u = (-vertex.z + half_size) / (2 * half_size)
		v = (-vertex.y - half_size) / (2 * half_size)
	elif normal == FACE_OFFSETS.TOP || normal == FACE_OFFSETS.BOTTOM:
		u = (-vertex.x + half_size) / (2 * half_size)
		v = (-vertex.z + half_size) / (2 * half_size)

	# 调整反向面的UV方向
	if normal == FACE_OFFSETS.BACK || normal == FACE_OFFSETS.RIGHT || normal == FACE_OFFSETS.BOTTOM:
		u = 1.0 - u
		
	return Vector2(u, v)

#确认面是否需要剔除
func determine_culled_faces(block_positions: Array) -> Dictionary:
	var position_set = {}
	for pos in block_positions:
		position_set[pos] = true
	
	var culled_faces = {}
	for pos in block_positions:
		var culled_mask = 0
		for face in FACE_OFFSETS:
			var adjacent_pos = pos + FACE_OFFSETS[face]
			if position_set.has(adjacent_pos):
				culled_mask |= 1 << FaceMask[face]
		if culled_mask == 63:
			continue
		culled_faces[pos] = culled_mask
	return culled_faces

func merge_faces(block_culled_faces: Dictionary) -> Dictionary:
	var block_positions = block_culled_faces.keys()
	
	# 定义面组配置，明确合并方向轴
	var face_groups = {
		"FRONT":  {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": {}},
		"BACK":   {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": {}},
		"LEFT":   {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": {}},
		"RIGHT":  {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": {}},
		"TOP":    {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": {}},
		"BOTTOM": {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": {}}
	}
	
	# 把单个面按横向合并或添加
	for block_position in block_positions:
		var culled = block_culled_faces[block_position]
		for face_name in face_groups:
			var face = face_groups[face_name]
			# 跳过被剔除的面（假设 FaceMask 是全局枚举）
			if culled & (1 << FaceMask[face_name]) != 0:
				continue
			
			var axis_value = block_position[face["axis"]]
			var rects_on_axis = face["rects"]
			var merge_axis = face["merge_axis_x"]  # 合并方向轴（例如x/z）
			
			# 初始化轴值对应的矩形列表
			if not rects_on_axis.has(axis_value):
				rects_on_axis[axis_value] = []
				rects_on_axis[axis_value].append([block_position, Vector2.ZERO])
				continue
			
			# 尝试与现有矩形合并
			var merged = false
			for rect in rects_on_axis[axis_value]:
				var rect_pos: Vector3 = rect[0]
				var rect_size: Vector2 = rect[1]
				
				# 检查Y轴是否对齐（单维度合并需确保另一轴固定）
				if block_position[face["merge_axis_y"]] != rect_pos[face["merge_axis_y"]]:
					continue
				
				# 向左合并（当前方块位于矩形左侧）
				if block_position[merge_axis] == rect_pos[merge_axis] - 1:
					rect[0][merge_axis] -= 1  # 矩形起点左移
					rect[1].x += 1           # 宽度增加
					merged = true
					break
				
				# 向右合并（当前方块位于矩形右侧）
				elif block_position[merge_axis] == rect_pos[merge_axis] + rect_size.x + 1:
					rect[1].x += 1
					merged = true
					break
			
			# 无法合并时添加新矩形
			if not merged:
				rects_on_axis[axis_value].append([block_position, Vector2.ZERO])
	
	var return_face = {
		"FRONT":  {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": []},
		"BACK":   {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": []},
		"LEFT":   {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": []},
		"RIGHT":  {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": []},
		"TOP":    {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": []},
		"BOTTOM": {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": []}
	}
	# 最终返回合并处理后的矩形数据
	var w_h_size = Vector3.ZERO
	for face in face_groups: 
		var list= []
		var rects = face_groups[face]["rects"].values()
		var merge_axis_x = face_groups[face]["merge_axis_x"]
		var merge_axis_y = face_groups[face]["merge_axis_y"]
		for index in rects:
			for n in index:
				w_h_size[merge_axis_x] = n[1].x
				w_h_size[merge_axis_y] = n[1].y
				list.append([n[0], w_h_size])
		return_face[face]["rects"] = list
	return return_face

	

func set_world(list: Array):
	var surfacetool = SurfaceTool.new()
	surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var culled_faces = determine_culled_faces(list[0])

	for block_idx in range(list[0].size()):
		var pos = list[0][block_idx]
		var mask = culled_faces.get(pos, 0)

		for n in range(6):
			if not (mask & (1 << n)):
				# 处理面的两个三角形
				for face_idx in [n * 2, n * 2 + 1]:
					var face = faces[face_idx]
					surfacetool.set_normal(face[3])
					# 添加三个顶点并设置UV
					for i in range(3):
						var vertex = vertices[face[i]]
						var uv = calculate_uv(vertex, face[3])
						surfacetool.set_uv(uv)
						surfacetool.add_vertex(vertex + pos)

	surfacetool.generate_tangents()
	array_mesh.mesh = surfacetool.commit()
	collision.shape = array_mesh.mesh.create_trimesh_shape()
