#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include <godot_cpp/classes/array_mesh.hpp>

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

    float block_size = 0.5;

    Ref<ArrayMesh> generate_voxelgrid_mesh(const Ref<VoxelGrid> voxelgtid, const Array &voxelgrid_array, const Object *block_types, Vector3 offset) const;

private:
    static const PackedVector3Array get_base_face_offsets();
    static const Array get_base_faces();
    static const PackedVector3Array get_base_block_ver();

    Vector2 calculate_uv(Vector3 vertex, Vector3 normal) const;
    Dictionary determine_culled_faces(const Ref<VoxelGrid> block_grid, const Array &voxelgrid_array) const;
    Dictionary merge_faces(const Dictionary& culled_faces) const;

protected:
    static void _bind_methods();
};
