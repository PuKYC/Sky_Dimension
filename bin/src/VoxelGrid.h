#pragma once

#include "godot_cpp/classes/ref_counted.hpp"
#include "godot_cpp/classes/wrapped.hpp"

using namespace godot;

class VoxelGridRLE;

class VoxelGrid : public RefCounted
{
    GDCLASS(VoxelGrid, RefCounted);

private:

    PackedByteArray grid;

    int get_index(Vector3i v3)const;
    bool is_valid(Vector3i v3) const;

protected:
    static void _bind_methods();

public:
    VoxelGrid();
    ~VoxelGrid() override = default;

    static const int SIZE = 64;

    void _init();

    void fill(int fill);

    PackedVector3Array get_occupied_blocks() const;

    // block操作
    void set_block(Vector3i v3, int id);
    int get_block(Vector3i v3) const;

    // 与压缩转换
    static Ref<VoxelGridRLE> to_rle(const Ref<VoxelGrid> vg);
    static Ref<VoxelGrid> from_rle(const Ref<VoxelGridRLE> vgr);

    // 测试使用
    PackedByteArray get_raw_data();
};