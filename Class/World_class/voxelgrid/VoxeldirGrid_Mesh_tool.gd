extends RefCounted
class_name VoxelGridMeshTool

var block_types:Block_Types

func _init(block_type:Block_Types) -> void:
	block_types = block_type

var  size = 0.5

# 预计算基础立方体顶点（假设size是类成员变量）
var base_ver = [
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
const FACE_OFFSETS := {
	"FRONT": Vector3(0, 0, 1),
	"BACK": Vector3(0, 0, -1),
	"LEFT": Vector3(-1, 0, 0),
	"RIGHT": Vector3(1, 0, 0),
	"TOP": Vector3(0, 1, 0),
	"BOTTOM": Vector3(0, -1, 0)
}

#定义面的朝向
const FACE_ID := [
	Vector3(0, 0, 1),
	Vector3(0, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(0, -1, 0)
]

#定义面中三角形的绘制顺序以及朝向
var faces := [
	[0, 1, 2, FACE_OFFSETS.FRONT],   # Front face triangle 1
	[0, 2, 3, FACE_OFFSETS.FRONT],   # Front face triangle 2
	[5, 4, 7, FACE_OFFSETS.BACK],    # Back face triangle 1
	[5, 7, 6, FACE_OFFSETS.BACK],    # Back face triangle 2
	[1, 5, 6, FACE_OFFSETS.LEFT],    # Left face triangle 1
	[1, 6, 2, FACE_OFFSETS.LEFT],    # Left face triangle 2
	[4, 0, 3, FACE_OFFSETS.RIGHT],   # Right face triangle 1
	[4, 3, 7, FACE_OFFSETS.RIGHT],   # Right face triangle 2
	[3, 2, 6, FACE_OFFSETS.TOP],     # Top face triangle 1
	[3, 6, 7, FACE_OFFSETS.TOP],     # Top face triangle 2
	[4, 5, 1, FACE_OFFSETS.BOTTOM],  # Bottom face triangle 1
	[4, 1, 0, FACE_OFFSETS.BOTTOM]  # Bottom face triangle 2

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

		# 根据面法线确定UV映射方式
	if normal == FACE_OFFSETS.FRONT || normal == FACE_OFFSETS.BACK:
		u = (-vertex.x + 1) / (2 * 1)
		v = (-vertex.y + 1) / (2 * 1)
	elif normal == FACE_OFFSETS.RIGHT || normal == FACE_OFFSETS.LEFT:
		u = (-vertex.z + 1) / (2 * 1)
		v = (-vertex.y - 1) / (2 * 1)
	elif normal == FACE_OFFSETS.TOP || normal == FACE_OFFSETS.BOTTOM:
		u = (-vertex.x + 1) / (2 * 1)
		v = (-vertex.z + 1) / (2 * 1)

		# 调整反向面的UV方向
	if normal == FACE_OFFSETS.BACK || normal == FACE_OFFSETS.RIGHT || normal == FACE_OFFSETS.BOTTOM:
		u = 1.0 - u

	return Vector2(u, v)

#确认面是否需要剔除
func _determine_culled_faces(block_grid: VoxelGrid, voxelgrid_array: Array[VoxelGrid]) -> Dictionary:
	var culled_faces:Dictionary = {}
	var time = Time.get_ticks_usec()
	
	for x in block_grid.SIZE:
		for y in block_grid.SIZE:
			for z in block_grid.SIZE:
				var pos = Vector3(x,y,z)
				var id = block_grid.get_block(pos)
				if id == 0:
					continue
					
				# bit位中1代表保留，0代表剔除
				var culled_mask = 0
				
				for face in FACE_OFFSETS:
					var face_offsets = FACE_OFFSETS[face]
					var adjacent_pos = pos + face_offsets
					var block_adjacent_id = block_grid.get_block(adjacent_pos)
					
					if block_adjacent_id == -1:
						var voxelgrid = voxelgrid_array[VoxelGridMeshTool.FACE_ID.find(face_offsets)]
						if voxelgrid == null:
							block_adjacent_id = 0
							
						else :
							block_adjacent_id = voxelgrid.get_block(adjacent_pos-face_offsets*64)
						
					if block_adjacent_id == 0:
						culled_mask |= 1 << FaceMask[face]
						
				if culled_mask == 0:
					continue
				
				if not culled_faces.has(id):
					culled_faces[id] = {}
				culled_faces[id][pos] = culled_mask
				
	print("面剔除耗时：", (Time.get_ticks_usec()-time)/1000.0/1000.0)
	return culled_faces
	
func _merge_faces(block_culled_faces: Dictionary) -> Dictionary:
	var time = Time.get_ticks_usec()
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
			if culled & (1 << FaceMask[face_name]) == 0:
				continue

			var axis_value = block_position[face["axis"]]
			var rects_on_axis = face["rects"]
			# 初始化轴值对应的矩形列表
			if not rects_on_axis.has(axis_value):
				rects_on_axis[axis_value] = []
				rects_on_axis[axis_value].append([block_position, Vector2.ZERO])
				continue
			rects_on_axis[axis_value].append([block_position, Vector2.ZERO])
				
	# 竖向合并处理
	for face_name in face_groups:
		var face = face_groups[face_name]
		var rects_on_axis = face["rects"]
		var merge_axis_x = face["merge_axis_x"]
		var merge_axis_y = face["merge_axis_y"]

		# 遍历每个轴向层（如每个z层）
		for axis_value in rects_on_axis:
			var rects = rects_on_axis[axis_value]
			var y_groups = {}

			# 按横向起始和宽度分组
			for rect in rects:
				var pos = rect[0]
				var size_xy = rect[1]
				var y_key = str(pos[merge_axis_y]) + "_" + str(size_xy.y)
				if not y_groups.has(y_key):
					y_groups[y_key] = []
				y_groups[y_key].append(rect)

			var merged_rects = []
			for group_key in y_groups:
				var group = y_groups[group_key]
				# 按纵向起始排序
				group.sort_custom(func(a, b): return a[0][merge_axis_x] < b[0][merge_axis_x])

				var i = 0
				while i < group.size():
					var current_rect = group[i]
					var current_x = current_rect[0][merge_axis_x]
					var current_height = current_rect[1].x

					# 尝试合并后续可连接的矩形
					var j = i + 1
					while j < group.size():
						var next_rect = group[j]
						var next_x = next_rect[0][merge_axis_x]

						# 检查纵向是否连续
						if next_x == current_x + current_height + 1:
							current_height += next_rect[1].x + 1
							j += 1
						else:
							break

					# 更新合并后的尺寸
					current_rect[1].x = current_height
					merged_rects.append(current_rect)
					i = j

			# 更新当前轴向层的矩形列表
			rects_on_axis[axis_value] = merged_rects

	# 竖向合并处理
	for face_name in face_groups:
		var face = face_groups[face_name]
		var rects_on_axis = face["rects"]
		var merge_axis_x = face["merge_axis_x"]
		var merge_axis_y = face["merge_axis_y"]

		# 遍历每个轴向层（如每个z层）
		for axis_value in rects_on_axis:
			var rects = rects_on_axis[axis_value]
			var x_groups = {}

			# 按横向起始和宽度分组
			for rect in rects:
				var pos = rect[0]
				var size_xy = rect[1]
				var x_key = str(pos[merge_axis_x]) + "_" + str(size_xy.x)
				if not x_groups.has(x_key):
					x_groups[x_key] = []
				x_groups[x_key].append(rect)

			var merged_rects = []
			for group_key in x_groups:
				var group = x_groups[group_key]
				# 按纵向起始排序
				group.sort_custom(func(a, b): return a[0][merge_axis_y] < b[0][merge_axis_y])

				var i = 0
				while i < group.size():
					var current_rect = group[i]
					var current_y = current_rect[0][merge_axis_y]
					var current_height = current_rect[1].y

					# 尝试合并后续可连接的矩形
					var j = i + 1
					while j < group.size():
						var next_rect = group[j]
						var next_y = next_rect[0][merge_axis_y]

						# 检查纵向是否连续
						if next_y == current_y + current_height + 1:
							current_height += next_rect[1].y + 1
							j += 1
						else:
							break

					# 更新合并后的尺寸
					current_rect[1].y = current_height
					merged_rects.append(current_rect)
					i = j

			# 更新当前轴向层的矩形列表
			rects_on_axis[axis_value] = merged_rects

	var return_faces = {
		"FRONT":  {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": []},
		"BACK":   {"axis": "z", "merge_axis_x": "x", "merge_axis_y": "y", "rects": []},
		"LEFT":   {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": []},
		"RIGHT":  {"axis": "x", "merge_axis_x": "y", "merge_axis_y": "z", "rects": []},
		"TOP":    {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": []},
		"BOTTOM": {"axis": "y", "merge_axis_x": "z", "merge_axis_y": "x", "rects": []}
	}
	# 最终返回合并处理后的矩形数据
	for face in face_groups:
		var list= []
		var rects = face_groups[face]["rects"].values()
		for index in rects:
			for n in index:
				list.append(n)
		return_faces[face]["rects"] = list
	
	print("面合并耗时：", (Time.get_ticks_usec()-time)/1000.0/1000.0)
	
	return return_faces

	
func generate_voxelgrid_mesh(block_grid: VoxelGrid, voxelgrid_array: Array[VoxelGrid]) -> Array:
	var culled_faces = _determine_culled_faces(block_grid, voxelgrid_array)
	
	var surfacetool = SurfaceTool.new()
	
	#array_mesh.material_override.set_shader_parameter("texture_array", set_Texture2DArray())
	
	surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)
	#surfacetool.set_custom_format(0, SurfaceTool.CUSTOM_R_FLOAT)
	
	for id in culled_faces.keys():
		var merge_faces_dictionary = _merge_faces(culled_faces[id])
		for face in merge_faces_dictionary:
			var face_data = merge_faces_dictionary[face]
			var axis = face_data["axis"]
			var merge_axis_x = face_data["merge_axis_x"]
			var merge_axis_y = face_data["merge_axis_y"]
			var face_offset = FACE_OFFSETS[face][axis]
			var face_index = [FaceMask[face] * 2, FaceMask[face] * 2 + 1]

			# 预计算需要调整的顶点索引
			var adjust_x_indices = []
			var adjust_y_indices = []
			for index in base_ver.size():
				var vertex = base_ver[index]
				if face_offset - vertex[axis] * 2 == 0:
					if vertex[merge_axis_x] > 0:
						adjust_x_indices.append(index)
					if vertex[merge_axis_y] > 0:
						adjust_y_indices.append(index)

					# 处理每个矩形区域
			for position_h_w in face_data["rects"]:
							# 复制基础顶点并进行调整
				var ver = base_ver.duplicate()
				var pos_offset = position_h_w[0]
				var size_offset = position_h_w[1]

							# 应用X轴偏移
				for idx in adjust_x_indices:
					var v = ver[idx]
					ver[idx] = Vector3(
						v.x + (size_offset.x if merge_axis_x == "x" else 0),
						v.y + (size_offset.x if merge_axis_x == "y" else 0),
						v.z + (size_offset.x if merge_axis_x == "z" else 0)
					)

				# 应用Y轴偏移
				for idx in adjust_y_indices:
					var v = ver[idx]
					ver[idx] = Vector3(
						v.x + (size_offset.y if merge_axis_y == "x" else 0),
						v.y + (size_offset.y if merge_axis_y == "y" else 0),
						v.z + (size_offset.y if merge_axis_y == "z" else 0)
					)

				# 添加顶点数据
				for face_idx in face_index:
					var indices = faces[face_idx]
					var normal = indices[3]

					for i in 3:
						var vertex = ver[indices[i]] + pos_offset
						surfacetool.set_normal(normal)
						surfacetool.set_uv(calculate_uv(ver[indices[i]], normal))
						#surfacetool.set_custom(0, Color(int_to_float(id), 0, 0))
						surfacetool.add_vertex(vertex)
		
		surfacetool.generate_tangents()
		
	return surfacetool.commit_to_arrays()
