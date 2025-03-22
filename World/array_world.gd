extends StaticBody3D

@onready var array_mesh = $array_mesh
@onready var collision = $collision

var size = 0.5
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

const FACE_OFFSETS = {
	"FRONT": Vector3(0, 0, 1),
	"BACK": Vector3(0, 0, -1),
	"LEFT": Vector3(-1, 0, 0),
	"RIGHT": Vector3(1, 0, 0),
	"TOP": Vector3(0, 1, 0),
	"BOTTOM": Vector3(0, -1, 0)
}

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

enum FaceMask {
	FRONT = 1 << 0,
	BACK = 1 << 1,
	LEFT = 1 << 2,
	RIGHT = 1 << 3,
	TOP = 1 << 4,
	BOTTOM = 1 << 5
}

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
				culled_mask |= 1 << FACE_OFFSETS.keys().find(face)
		culled_faces[pos] = culled_mask
	return culled_faces

func set_world(list: Array):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var culled_faces = determine_culled_faces(list[0])
	
	for block_idx in range(list[0].size()):
		var pos = list[0][block_idx]
		var mask = culled_faces.get(pos, 0)
		
		for n in range(6):
			if not (mask & (1 << n)):
				# 处理面的两个三角形
				for face_idx in [n * 2, n * 2 + 1]:
					var face = faces[face_idx]
					st.set_normal(face[3])
					
					# 添加三个顶点并设置UV
					for i in range(3):
						var vertex = vertices[face[i]]
						var uv = calculate_uv(vertex, face[3])
						st.set_uv(uv)
						st.add_vertex(vertex + pos)
	
	st.generate_tangents()
	array_mesh.mesh = st.commit()
	collision.shape = array_mesh.mesh.create_trimesh_shape()
