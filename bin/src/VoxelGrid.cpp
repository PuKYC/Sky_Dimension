#include "VoxelGrid.h"
#include "VoxelGridRLE.h"

void VoxelGrid::_bind_methods()
{
    BIND_CONSTANT(SIZE);
    // 基础操作方法
    ClassDB::bind_method(D_METHOD("set_block", "position", "id"), &VoxelGrid::set_block);
    ClassDB::bind_method(D_METHOD("get_block", "position"), &VoxelGrid::get_block);
    ClassDB::bind_method(D_METHOD("is_valid", "position"), &VoxelGrid::is_valid);
    ClassDB::bind_method(D_METHOD("get_raw_data"), &VoxelGrid::get_raw_data);
    ClassDB::bind_method(D_METHOD("fill"), &VoxelGrid::fill);

    // RLE转换方法（需要调整参数类型为Ref）
    ClassDB::bind_static_method("VoxelGrid", D_METHOD("to_rle", "grid"),
                                &VoxelGrid::to_rle);

    ClassDB::bind_static_method("VoxelGrid", D_METHOD("from_rle", "rle_data"),
                                &VoxelGrid::from_rle);
};

VoxelGrid::VoxelGrid(){
    VoxelGrid::_init();
}

void VoxelGrid::_init()
{
    grid.resize(SIZE * SIZE * SIZE);
    grid.fill(0);
}

void VoxelGrid::fill(int fill)
{
    grid.fill(fill);
}

int VoxelGrid::get_index(Vector3i v3) const
{
    return v3.x + v3.y * SIZE + v3.z * SIZE * SIZE;
}

bool VoxelGrid::is_valid(Vector3i v3) const
{
    return (
        v3.x >= 0 && v3.x < SIZE &&
        v3.y >= 0 && v3.y < SIZE &&
        v3.z >= 0 && v3.z < SIZE);
}

void VoxelGrid::set_block(Vector3i v3, int id)
{
    if (is_valid(v3))
    {
        grid[get_index(v3)] = id;
    }
}

int VoxelGrid::get_block(Vector3i v3) const
{
    if (is_valid(v3))
    {
        return grid[get_index(v3)];
    }
    return -1;
}

Ref<VoxelGridRLE> VoxelGrid::to_rle(const Ref<VoxelGrid> vg)
{
    Ref<VoxelGridRLE> rle;
    rle->compress(vg->grid);
    return rle;
}

Ref<VoxelGrid> VoxelGrid::from_rle(const Ref<VoxelGridRLE> vgr)
{
    Ref<VoxelGrid> grid;
    grid->grid = vgr->decompress();
    return grid;
}

PackedByteArray VoxelGrid::get_raw_data()
{
    return grid.duplicate();
}

PackedVector3Array VoxelGrid::get_occupied_blocks() const 
{
    // 实现获取所有非空block的位置
    PackedVector3Array positions;
    for (int x = 0; x < SIZE; x++) {
        for (int y = 0; y < SIZE; y++) {
            for (int z = 0; z < SIZE; z++) {
                if (get_block(Vector3i(x,y,z))) {
                    positions.append(Vector3(x,y,z));
                }
            }
        }
    }
    return positions;
}