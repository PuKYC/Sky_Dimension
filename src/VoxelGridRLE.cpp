#include "VoxelGridRLE.h"
#include "VoxelGrid.h"

void VoxelGridRLE::_bind_methods() {
    // 核心压缩/解压方法
    ClassDB::bind_method(D_METHOD("compress", "grid"), &VoxelGridRLE::compress);
    ClassDB::bind_method(D_METHOD("decompress"), &VoxelGridRLE::decompress);
    
    // 体素数据查询
    ClassDB::bind_method(D_METHOD("get_block", "position"), &VoxelGridRLE::get_block);
    
    // 格式验证
    ClassDB::bind_method(D_METHOD("validate"), &VoxelGridRLE::validate);
    
    // 格式转换
    ClassDB::bind_method(D_METHOD("to_voxel_grid"), &VoxelGridRLE::to_voxel_grid);
    
    // 静态工厂方法（需要处理参数类型适配）
    ClassDB::bind_static_method("VoxelGridRLE", D_METHOD("from_voxel_grid", "grid"),
        &VoxelGridRLE::from_voxel_grid,
        TypedArray<VoxelGrid>());
}

void VoxelGridRLE::add_segment(int type, int length)
{
    // 直接预分配内存，避免多次扩容
    static thread_local PackedInt32Array com;
    com.resize(2);

    com[0] = static_cast<int32_t>(type);
    com[1] = static_cast<int32_t>(length);

    // 将数据移动到外层数组（避免拷贝）
    compressed_data.append(std::move(com));
}

void VoxelGridRLE::build_index()
{
    index_map.clear();

    int total = 0;
    const auto size = compressed_data.size();
    for (size_t i = 0; i < size; ++i)
    {
        index_map[total] = i;
        // 获取当前元素（Variant类型）
        static Array entry = compressed_data[i];
        // 显式转换为整数
        static int length = static_cast<int>(entry[1]);
        total += length;
    }
}

void VoxelGridRLE::compress(const PackedByteArray &grid)
{
    compressed_data.clear();
    if (grid.is_empty())
    {
        return;
    };

    int current_type = grid[0];
    int count = 1;

    int grid_size = grid.size();
    for (int i = 1; i < grid_size; ++i)
    {
        if (grid[i] == current_type)
        {
            count += 1;
        }
        else
        {
            add_segment(current_type, count);
            current_type = grid[i];
            count = 1;
        }
    }
    add_segment(current_type, count);
    build_index();
}

PackedByteArray VoxelGridRLE::decompress() const
{
    PackedByteArray grid;
    grid.resize(64 * 64 * 64);

    int ptr = 0; // Godot通常使用有符号int
    int com_size = compressed_data.size();
    for (int seg_idx = 0; seg_idx < com_size; ++seg_idx)
    {
        Array segment = compressed_data[seg_idx];

        int length = segment[1];
        for (int i = 0; i < length; ++i)
        {
            if (ptr + i < grid.size())
            {
                grid[ptr + i] = segment[0];
            }
        }
        ptr += length;
    }

    return grid;
}

Ref<VoxelGrid> VoxelGridRLE::to_voxel_grid()
{
    return VoxelGrid::from_rle(this);
}

Ref<VoxelGridRLE> VoxelGridRLE::from_voxel_grid(Ref<VoxelGrid> grid)
{
    Ref<VoxelGridRLE> rle;
    rle->compress(grid->get_raw_data());
    return rle;
}

int VoxelGridRLE::get_block(Vector3i v3) const
{
    int index = v3.x + v3.y * 64 + v3.z * 4096;
    Array keys = index_map.keys();
    keys.sort();

    int pos = keys.bsearch(index);
    if (pos >= keys.size())
    {
        return 0;
    }
    int seg_idx = index_map[keys[pos]];
    Array seg = compressed_data[seg_idx];
    return seg[0];
}

bool VoxelGridRLE::validate()
{
    int total = 0;

    Array com = compressed_data;
    int com_size = com.size();
    for (int i = 0; i < com_size; ++i)
    {
        static Array seg = compressed_data[i];
        total += static_cast<int>(seg[1]);
    }
    return total == 64 * 64 * 64;
}