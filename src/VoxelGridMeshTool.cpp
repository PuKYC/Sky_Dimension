#include "VoxelGridMeshTool.h"

#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/templates/hash_map.hpp>

using namespace godot;

void VoxelGridMeshTool::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("generate_voxelgrid_mesh", "voxelgrid", "voxelgrid_array", "block_types"),
                         &VoxelGridMeshTool::generate_voxelgrid_mesh);

    // 添加枚举
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "FRONT", FRONT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "BACK", BACK);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "LEFT", LEFT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "RIGHT", RIGHT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "TOP", TOP);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "BOTTOM", BOTTOM);

    ClassDB::bind_integer_constant("VoxelGridMeshTool", "", "FLAGS", flags);
}

const PackedVector3Array &VoxelGridMeshTool::get_base_face_offsets()
{
    static const PackedVector3Array base_face_offsets = []()
    {
        PackedVector3Array arr;
        arr.resize(6);
        arr[FACE_ID::FRONT] = Vector3i(0, 0, -1);  // 前
        arr[FACE_ID::BACK] = Vector3i(0, 0, 1);    // 后
        arr[FACE_ID::LEFT] = Vector3i(-1, 0, 0);   // 左
        arr[FACE_ID::RIGHT] = Vector3i(1, 0, 0);   // 右
        arr[FACE_ID::TOP] = Vector3i(0, 1, 0);     // 上
        arr[FACE_ID::BOTTOM] = Vector3i(0, -1, 0); // 下
        return arr;
    }();
    return base_face_offsets;
};

Vector2 VoxelGridMeshTool::calculate_uv(Vector3 vertex, Vector3 normal) const
{
    float u = 0.0;
    float v = 0.0;

    //vertex += Vector3(1, 1, 1);

    const PackedVector3Array face_offsets = get_base_face_offsets();

    // 根据面法线确定UV映射方式
    if (normal == face_offsets[FRONT] || normal == face_offsets[BACK])
    {
        u = (vertex.x);
        v = (vertex.y);
    }
    else if (normal == face_offsets[RIGHT] || normal == face_offsets[LEFT])
    {
        u = (vertex.z);
        v = (vertex.y);
    }
    else if (normal == face_offsets[TOP] || normal == face_offsets[BOTTOM])
    {
        u = (vertex.x);
        v = (vertex.z);
    };

    // 调整反向面的UV方向
    if (normal == face_offsets[BACK] || normal == face_offsets[RIGHT] || normal == face_offsets[BOTTOM])
    {
        u = 1.0 - u;
    };

    //UtilityFunctions::print(vertex, " ", normal, " ", Vector2(u,v));

    return Vector2(u, v);
};

HashMap<int, HashMap<Vector3i, int>> VoxelGridMeshTool::determine_culled_faces(const Ref<VoxelGrid> block_grid, const Array &voxelgrid_array) const
{
    HashMap<int, HashMap<Vector3i, int>> culled_faces;
    const int SIZE = block_grid->SIZE;
    const int TOTAL_BLOCKS = SIZE * SIZE * SIZE;
    const PackedVector3Array &face_offsets = get_base_face_offsets();

    // 预加载相邻区块
    Ref<VoxelGrid> neighbors[6];
    for (int i = 0; i < 6; i++)
    {
        neighbors[i] = voxelgrid_array[i];
    }

    // 使用一维索引优化缓存访问
    for (int idx = 0; idx < TOTAL_BLOCKS; idx++)
    {
        int x = idx % SIZE;
        int y = (idx / SIZE) % SIZE;
        int z = idx / (SIZE * SIZE);

        const Vector3i pos(x, y, z);
        const int id = block_grid->get_block(pos);
        if (id == 0)
            continue;

        int culled_mask = 0;

        // 遍历所有面
        for (int i = 0; i < 6; i++)
        {
            const Vector3i adjacent_pos = pos + face_offsets[i];
            int adjacent_id = block_grid->get_block(adjacent_pos);

            // 处理边界情况
            if (adjacent_id == -1)
            {
                Ref<VoxelGrid> neighbor_grid = voxelgrid_array[i];
                if (neighbor_grid.is_valid())
                {
                    // 转换到相邻区块的坐标
                    adjacent_id = neighbor_grid->get_block(adjacent_pos - face_offsets[i] * block_grid->SIZE);
                }
                else
                {
                    adjacent_id = 0;
                }
            }

            // 设置掩码位
            if (adjacent_id == 0)
            {
                culled_mask |= (1 << i);
            }
        }

        // 如果有需要绘制的面（掩码非0），则记录
        if (culled_mask != 0)
        {
            culled_faces[id][pos] = culled_mask;
        }
    }
    // UtilityFunctions::print("面剔除 ", culled_faces);
    return culled_faces;
}

void quick_sort(Array &arr, const int &merge_axis)
{
    struct SortHelper
    {
        static int partition(Array &arr, int low, int high, int axis)
        {
            const Variant pivot = arr[high];
            int i = low - 1;

            for (int j = low; j <= high - 1; j++)
            {
                if (compare_blocks(arr[j], pivot, axis))
                {
                    i++;
                    Variant tmp = arr[i];
                    arr[i] = arr[j];
                    arr[j] = tmp;
                }
            }
            Variant tmp = arr[i + 1];
            arr[i + 1] = arr[high];
            arr[high] = tmp;
            return i + 1;
        }

        static void sort(Array &arr, int low, int high, int axis)
        {
            if (low < high)
            {
                int pi = partition(arr, low, high, axis);
                sort(arr, low, pi - 1, axis);
                sort(arr, pi + 1, high, axis);
            }
        }

        static bool compare_blocks(const Variant &a, const Variant &b, int axis)
        {
            const Array &arr_a = a;
            const Array &arr_b = b;
            return arr_a[0].operator Vector3i()[axis] < arr_b[0].operator Vector3i()[axis];
        }
    };

    if (arr.size() > 0)
    {
        // UtilityFunctions::print(arr);
        SortHelper::sort(arr, 0, arr.size() - 1, merge_axis);
    }
}

HashMap<VoxelGridMeshTool::FACE_ID, VoxelGridMeshTool::FaceGroup> VoxelGridMeshTool::merge_faces(const HashMap<Vector3i, int> &block_culled_faces) const
{
    HashMap<FACE_ID, FaceGroup> face_groups;
    face_groups[FRONT] = {2, 1, 0, HashMap<int, Array>()};
    face_groups[BACK] = {2, 0, 1, HashMap<int, Array>()};
    face_groups[LEFT] = {0, 2, 1, HashMap<int, Array>()};
    face_groups[RIGHT] = {0, 1, 2, HashMap<int, Array>()};
    face_groups[TOP] = {1, 2, 0, HashMap<int, Array>()};
    face_groups[BOTTOM] = {1, 0, 2, HashMap<int, Array>()};

    // 第一阶段：收集面数据
    for (const KeyValue<Vector3i, int> pos_culled : block_culled_faces)
    {
        // UtilityFunctions::print(258);
        for (KeyValue<FACE_ID, FaceGroup> &entry : face_groups)
        {
            const FACE_ID &face_name = entry.key;
            FaceGroup &face = entry.value;

            if (((pos_culled.value & (1 << face_name))) == 0)
            {
                // UtilityFunctions::print("Processing face: ", face_name,
                //                         " at position: ", block_position,
                //                         "culled ", culled,
                //                    "tc", (culled & (1 << face_name)));
                continue;
            };

            int axis_value = pos_culled.key[face.axis];
            if (!face.rects.has(axis_value))
            {
                Array new_array;
                new_array.append(Array::make(pos_culled.key, Vector2i()));
                face.rects[axis_value] = new_array;
            }
            else
            {
                face.rects[axis_value].append(Array::make(pos_culled.key, Vector2i()));
            }
            // UtilityFunctions::print(1);
        }
    }

    // 合并处理函数
    auto process_merging = [](FaceGroup &face, bool vertical)
    {
        HashMap<int, Array> &rects_on_axis = face.rects;

        // 轴映射优化：预先计算所有轴索引
        const int axis_group = vertical ? face.merge_axis_x : face.merge_axis_y;
        const int axis_sort = vertical ? face.merge_axis_y : face.merge_axis_x;
        const int axis_merge = vertical ? 0 : 1; // 0:宽度, 1:高度

        for (KeyValue<int, Array> &axis_entry : rects_on_axis)
        {
            // 关键修复：使用只读引用访问原始数据（避免悬空引用）
            const Array &original_rects = axis_entry.value;
            const int rect_count = original_rects.size();

            HashMap<Vector2i, Array> groups;

            // 分组阶段：零复制访问
            for (int i = 0; i < rect_count; i++)
            {
                const Array &rect = original_rects[i];
                const Vector3i &pos = rect[0].operator Vector3i();
                const Vector2i &size = rect[1].operator Vector2i();

                // 使用高效分组方式（自动创建缺失组）
                const Vector2i key(pos[axis_group], size[axis_merge]);
                Array &group = groups[key]; // 自动创建空数组（如果不存在）
                group.append(rect);         // 添加原始Variant引用
            }

            // 合并结果容器
            Array merged_rects;

            // 处理每个分组
            for (KeyValue<Vector2i, Array> &group_entry : groups)
            {
                Array &group = group_entry.value;
                const int group_size = group.size();

                // 仅当需要时排序 (2+元素)
                if (group_size > 1)
                {
                    quick_sort(group, axis_sort);
                }

                int i = 0;
                while (i < group_size)
                {
                    // 获取当前矩形（使用常量引用避免拷贝）
                    const Array &current = group[i];
                    const Vector3i &current_pos = current[0].operator Vector3i();
                    const Vector2i &current_size_ref = current[1].operator Vector2i();

                    // 需要修改尺寸，创建副本
                    Vector2i current_size = current_size_ref;

                    const int current_start = current_pos[axis_sort];
                    int current_end = current_start + current_size[axis_merge];
                    int j = i + 1;

                    // 合并相邻矩形
                    while (j < group_size)
                    {
                        const Array &next = group[j];
                        const Vector3i &next_pos = next[0].operator Vector3i();
                        const Vector2i &next_size = next[1].operator Vector2i();

                        // 直接比较坐标值
                        if (next_pos[axis_sort] == current_end + 1)
                        {
                            current_end += next_size[axis_merge] + 1;
                            j++;
                        }
                        else
                        {
                            break;
                        }
                    }

                    // 更新最终尺寸
                    current_size[axis_merge] = current_end - current_start;

                    // 创建新矩形（复用位置数据）
                    Array merged_rect;
                    merged_rect.append(current_pos);  // 原始位置
                    merged_rect.append(current_size); // 新尺寸
                    merged_rects.append(merged_rect);

                    i = j; // 跳过已合并项
                }
            }

            // 移动语义安全替换原数据
            axis_entry.value = std::move(merged_rects);
        }
    };

    // 横向和纵向合并
    for (KeyValue<FACE_ID, FaceGroup> &entry : face_groups)
    {
        process_merging(entry.value, false); // 横向
        process_merging(entry.value, true);  // 纵向
    }

    return face_groups;
}

float int_to_float(int id)
{
    float f;
    std::memcpy(&f, &id, sizeof(f)); // 将id的二进制位复制到float
    return f;
}

Array VoxelGridMeshTool::generate_voxelgrid_mesh(const Ref<VoxelGrid> voxelgtid, const Array &voxelgrid_array, const Object *block_types) const
{
    // 剔除面计算
    HashMap<int, HashMap<Vector3i, int>> culled_faces = determine_culled_faces(voxelgtid, voxelgrid_array);

    PackedVector3Array FACE_OFFSETS = get_base_face_offsets();

    // 获取字典所有键
    HashMap<int, HashMap<FACE_ID, FaceGroup>> merge_faces_dict;
    for (const KeyValue<int, HashMap<Vector3i, int>> &key_v : culled_faces)
    {
        merge_faces_dict[key_v.key] = merge_faces(key_v.value);
    }

    PackedVector3Array vec_all;
    PackedInt32Array in_all;
    PackedFloat32Array id_all;
    PackedVector2Array uv_all;
    PackedVector3Array na_all;

    for (const auto &id_fece : merge_faces_dict)
    {
        for (const auto &fece_group : id_fece.value)
        {
            PackedVector3Array vec;
            PackedInt32Array in;
            PackedFloat32Array id;
            PackedVector2Array uv;
            PackedVector3Array na;

            HashMap<Vector3i, int> in_map;
            const Vector3 n = FACE_OFFSETS[fece_group.key];
            for (const auto &rects : fece_group.value.rects)
            {
                int r_v_s = rects.value.size();
                for (int r_size = 0; r_size < r_v_s; r_size++)
                {
                    // UtilityFunctions::print(rects.value[i], " ", index);
                    const Array &rv = rects.value[r_size];
                    PackedVector3Array index;
                    index.resize(4);

                    const auto &fg = fece_group.value; // 提前获取引用

                    // 使用ptrw()直接操作内存，避免set()的函数调用开销
                    Vector3 *w = index.ptrw();
                    const Vector3 &base = rv[0];
                    const Vector2i &v2 = rv[1].operator Vector2();

                    // 直接初始化顶点
                    w[0] = base;
                    w[1] = base;
                    w[2] = base;
                    w[3] = base;

                    // 直接修改内存中的向量分量
                    w[1][fg.merge_axis_x] += v2.x;
                    w[2][fg.merge_axis_y] += v2.y;
                    w[3][fg.merge_axis_x] += v2.x;
                    w[3][fg.merge_axis_y] += v2.y;

                    PackedInt32Array index_int;
                    index_int.resize(4); // 预分配内存

                    // 使用ptrw()直接写入结果
                    int32_t *iw = index_int.ptrw();

                    for (int i = 0; i < 4; i++)
                    {
                        const Vector3 &key = w[i]; // 直接使用已计算的内存地址

                        // HashMap查找优化（单次哈希计算）
                        auto it = in_map.find(key);
                        if (it)
                        {
                            iw[i] = it->value;
                        }
                        else
                        {
                            const int size = vec.size();

                            vec.append(key);
                            id.append(int_to_float(id_fece.key));
                            uv.append(calculate_uv(key, n));
                            na.append(n);

                            in_map[key] = size;
                            iw[i] = size;
                        }
                    }

                    // UtilityFunctions::print(index);

                    PackedInt32Array in_in;
                    in_in.resize(6);

                    in_in[0] = index_int[0];
                    in_in[1] = index_int[3];
                    in_in[2] = index_int[1];
                    in_in[3] = index_int[0];
                    in_in[4] = index_int[2];
                    in_in[5] = index_int[3];

                    in.append_array(in_in);
                }
            }

            // 对顶点索引进行偏移计算
            const int size = in.size();
            const int vec_all_size = vec_all.size();
            // 获取可写指针（直接访问底层内存）
            int32_t *data = in.ptrw();

            // 高效遍历修改
            for (int i = 0; i < size; ++i)
            {
                data[i] += vec_all_size;
            }

            vec_all.append_array(vec);
            in_all.append_array(in);
            id_all.append_array(id);
            uv_all.append_array(uv);
            na_all.append_array(na);
        }
    }

    if (vec_all.size() == 0)
        return Array();

    Array arr_in;
    arr_in.resize(Mesh::ARRAY_MAX);

    arr_in[Mesh::ARRAY_VERTEX] = vec_all;
    arr_in[Mesh::ARRAY_TEX_UV] = uv_all;
    arr_in[Mesh::ARRAY_CUSTOM0] = id_all;
    arr_in[Mesh::ARRAY_NORMAL] = na_all;
    arr_in[Mesh::ARRAY_INDEX] = in_all;

    // UtilityFunctions::print(arr_in)

    
    return arr_in;
}