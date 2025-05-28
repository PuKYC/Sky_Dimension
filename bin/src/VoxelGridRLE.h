#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"

using namespace godot;

class VoxelGrid;

class VoxelGridRLE : public RefCounted
{
    GDCLASS(VoxelGridRLE, RefCounted);

private:
    Array compressed_data;
    Dictionary index_map;

    void add_segment(int type, int length);
    void build_index();

protected:
    static void _bind_methods();

public:
    VoxelGridRLE() = default;
    ~VoxelGridRLE() override = default;

    // Compression/Decompression
    void compress(const PackedByteArray &grid);
    PackedByteArray decompress() const;

    // Conversion
    Ref<VoxelGrid> to_voxel_grid();
    static Ref<VoxelGridRLE> from_voxel_grid(Ref<VoxelGrid> grid);

    // Block access
    int get_block(Vector3i v3) const;

    // Validation
    bool validate();
};