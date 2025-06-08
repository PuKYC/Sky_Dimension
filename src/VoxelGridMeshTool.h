#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/templates/hash_map.hpp>

#include "VoxelGrid.h"

using namespace godot;

class VoxelGridMeshTool : public RefCounted
{
    GDCLASS(VoxelGridMeshTool, RefCounted)

public:
    VoxelGridMeshTool() = default;
    ~VoxelGridMeshTool() override = default;

    enum FACE_ID
    {
        FRONT = 0,
        BACK = 1,
        LEFT = 2,
        RIGHT = 3,
        TOP = 4,
        BOTTOM = 5
    };

    // 启用：顶点 + 法线 + UV + 自定义属性0 + 索引
    static const uint32_t flags =
        Mesh::ARRAY_FORMAT_NORMAL |
        Mesh::ARRAY_FORMAT_TEX_UV |
        Mesh::ARRAY_FORMAT_CUSTOM0 | // 启用自定义属性0
        (Mesh::ARRAY_CUSTOM_R_FLOAT << Mesh::ARRAY_FORMAT_CUSTOM0_SHIFT) |
        Mesh::ARRAY_FORMAT_INDEX |
        Mesh::ARRAY_FLAG_COMPRESS_ATTRIBUTES;

    Array generate_voxelgrid_mesh(const Ref<VoxelGrid> voxelgtid, const Array &voxelgrid_array, const Object *block_types) const;

private:
    static const PackedVector3Array &get_base_face_offsets();

    // 定义面组配置结构
    struct FaceGroup
    {
        int axis;
        int merge_axis_x;
        int merge_axis_y;
        HashMap<int, Array> rects;
    };

    Vector2 calculate_uv(Vector3 vertex, Vector3 normal) const;
    HashMap<int, HashMap<Vector3i, int>> determine_culled_faces(const Ref<VoxelGrid> block_grid, const Array &voxelgrid_array) const;
    HashMap<FACE_ID, FaceGroup> merge_faces(const HashMap<Vector3i, int> &block_culled_faces) const;

protected:
    static void _bind_methods();
};
