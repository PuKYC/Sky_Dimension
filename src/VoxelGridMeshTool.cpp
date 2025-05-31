#include "VoxelGridMeshTool.h"

#include <godot_cpp/variant/vector3.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/surface_tool.hpp>
#include <godot_cpp/templates/hash_map.hpp>

using namespace godot;

void VoxelGridMeshTool::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("generate_voxelgrid_mesh", "voxelgrid", "voxelgrid_array", "block_types", "offset"),
                         &VoxelGridMeshTool::generate_voxelgrid_mesh);

    // 添加枚举
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "FRONT", FRONT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "BACK", BACK);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "LEFT", LEFT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "RIGHT", RIGHT);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "TOP", TOP);
    ClassDB::bind_integer_constant("VoxelGridMeshTool", "FACE_ID", "BOTTOM", BOTTOM);
}

const PackedVector3Array &VoxelGridMeshTool::get_base_face_offsets()
{
    static const PackedVector3Array base_face_offsets = []()
    {
        PackedVector3Array arr;
        arr.resize(6);
        arr[FACE_ID::FRONT] = Vector3(0, 0, -1);  // 前
        arr[FACE_ID::BACK] = Vector3(0, 0, 1);    // 后
        arr[FACE_ID::LEFT] = Vector3(-1, 0, 0);   // 左
        arr[FACE_ID::RIGHT] = Vector3(1, 0, 0);   // 右
        arr[FACE_ID::TOP] = Vector3(0, 1, 0);     // 上
        arr[FACE_ID::BOTTOM] = Vector3(0, -1, 0); // 下
        return arr;
    }();
    return base_face_offsets;
};

const Array &VoxelGridMeshTool::get_base_faces()
{
    static const Array base_faces = []()
    {
        const PackedVector3Array &base_face_offsets = VoxelGridMeshTool::get_base_face_offsets();
        Array base_faces_arr;

        // 定义面数据: [顶点索引1, 顶点索引2, 顶点索引3, 面ID]
        const int face_data[12][4] = {
            // FRONT
            {5, 4, 7, FACE_ID::FRONT},
            {5, 7, 6, FACE_ID::FRONT},
            // BACK
            {0, 1, 2, FACE_ID::BACK},
            {0, 2, 3, FACE_ID::BACK},
            // LEFT
            {1, 5, 6, FACE_ID::LEFT},
            {1, 6, 2, FACE_ID::LEFT},
            // RIGHT
            {4, 0, 3, FACE_ID::RIGHT},
            {4, 3, 7, FACE_ID::RIGHT},
            // TOP
            {3, 2, 6, FACE_ID::TOP},
            {3, 6, 7, FACE_ID::TOP},
            // BOTTOM
            {4, 5, 1, FACE_ID::BOTTOM},
            {4, 1, 0, FACE_ID::BOTTOM}};

        base_faces_arr.resize(12);
        for (int i = 0; i < 12; i++)
        {
            Array face;
            face.resize(4);
            face[0] = face_data[i][0];
            face[1] = face_data[i][1];
            face[2] = face_data[i][2];
            face[3] = base_face_offsets[face_data[i][3]];
            base_faces_arr[i] = face;
        }

        return base_faces_arr;
    }();
    return base_faces;
};

// C++11 线程安全版本（推荐）
const PackedVector3Array VoxelGridMeshTool::get_base_block_ver()
{
    static const PackedVector3Array base_ver = []
    {
        PackedVector3Array arr;
        arr.resize(8);
        arr[0] = Vector3(0.5, -0.5, 0.5);
        arr[1] = Vector3(-0.5, -0.5, 0.5);
        arr[2] = Vector3(-0.5, 0.5, 0.5);
        arr[3] = Vector3(0.5, 0.5, 0.5);
        arr[4] = Vector3(0.5, -0.5, -0.5);
        arr[5] = Vector3(-0.5, -0.5, -0.5);
        arr[6] = Vector3(-0.5, 0.5, -0.5);
        arr[7] = Vector3(0.5, 0.5, -0.5);
        return arr;
    }();
    return base_ver;
}

Vector2 VoxelGridMeshTool::calculate_uv(Vector3 vertex, Vector3 normal) const
{
    float u = 0.0;
    float v = 0.0;

    const PackedVector3Array face_offsets = get_base_face_offsets();

    // 根据面法线确定UV映射方式
    if (normal == face_offsets[FRONT] || normal == face_offsets[BACK])
    {
        u = (-vertex.x + 1) / (2 * 1);
        v = (-vertex.y + 1) / (2 * 1);
    }
    else if (normal == face_offsets[RIGHT] || normal == face_offsets[LEFT])
    {
        u = (-vertex.z + 1) / (2 * 1);
        v = (-vertex.y - 1) / (2 * 1);
    }
    else if (normal == face_offsets[TOP] || normal == face_offsets[BOTTOM])
    {
        u = (-vertex.x + 1) / (2 * 1);
        v = (-vertex.z + 1) / (2 * 1);
    };

    // 调整反向面的UV方向
    if (normal == face_offsets[BACK] || normal == face_offsets[RIGHT] || normal == face_offsets[BOTTOM])
    {
        u = 1.0 - u;
    };
    return Vector2(u + 0.25, v + 0.25);
};

Dictionary VoxelGridMeshTool::determine_culled_faces(const Ref<VoxelGrid> block_grid, const Array &voxelgrid_array) const
{
    Dictionary culled_faces;
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

        Vector3i pos(x, y, z);
        int id = block_grid->get_block(pos);
        if (id == 0)
            continue;

        int culled_mask = 0;

        // 遍历所有面
        for (int i = 0; i < 6; i++)
        {
            Vector3 adjacent_pos = pos + face_offsets[i];
            int adjacent_id = block_grid->get_block(adjacent_pos);

            // 处理边界情况
            if (adjacent_id == -1)
            {
                Ref<VoxelGrid> neighbor_grid = voxelgrid_array[i];
                if (neighbor_grid.is_valid())
                {
                    // 转换到相邻区块的坐标
                    Vector3 neighbor_pos = adjacent_pos - face_offsets[i] * block_grid->SIZE;
                    adjacent_id = neighbor_grid->get_block(neighbor_pos);
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
            if (culled_mask == 0)
                continue;

            // 更新结果字典
            if (!culled_faces.has(id))
            {
                culled_faces[id] = Dictionary();
            }
            Dictionary id_dict = culled_faces[id];
            id_dict[pos] = culled_mask;

            // culled_faces[pos] = culled_mask;
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
        SortHelper::sort(arr, 0, arr.size() - 1, merge_axis);
    }
}

Dictionary VoxelGridMeshTool::merge_faces(const Dictionary &block_culled_faces) const
{
    Array block_positions = block_culled_faces.keys();
    // UtilityFunctions::print(123456,block_positions);

    Dictionary return_faces;

    // 定义面组配置结构
    struct FaceGroup
    {
        int axis;
        int merge_axis_x;
        int merge_axis_y;
        HashMap<int, Array> rects;
    };

    HashMap<FACE_ID, FaceGroup> face_groups;
    face_groups[FRONT] = {2, 0, 1, HashMap<int, Array>()};
    face_groups[BACK] = {2, 0, 1, HashMap<int, Array>()};
    face_groups[LEFT] = {0, 1, 2, HashMap<int, Array>()};
    face_groups[RIGHT] = {0, 1, 2, HashMap<int, Array>()};
    face_groups[TOP] = {1, 2, 0, HashMap<int, Array>()};
    face_groups[BOTTOM] = {1, 2, 0, HashMap<int, Array>()};

    // 第一阶段：收集面数据
    for (int i = 0; i < block_positions.size(); i++)
    {
        Vector3i block_position = block_positions[i];
        int culled = block_culled_faces[block_position];
        // UtilityFunctions::print(258);
        for (KeyValue<FACE_ID, FaceGroup> &entry : face_groups)
        {
            const FACE_ID &face_name = entry.key;
            FaceGroup &face = entry.value;

            if (((culled & (1 << face_name))) == 0)
            {
                // UtilityFunctions::print("Processing face: ", face_name,
                //                         " at position: ", block_position,
                //                         "culled ", culled,
                //                    "tc", (culled & (1 << face_name)));
                continue;
            };

            int axis_value = block_position[face.axis];
            if (!face.rects.has(axis_value))
            {
                Array new_array;
                new_array.append(Array::make(block_position, Vector2i()));
                face.rects[axis_value] = new_array;
            }
            else
            {
                face.rects[axis_value].append(Array::make(block_position, Vector2i()));
            }
            // UtilityFunctions::print(1);
        }
    }

    // 合并处理函数
    auto process_merging = [](FaceGroup &face, bool vertical)
    {
        HashMap<int, Array> &rects_on_axis = face.rects;
        const int &merge_axis_x_b = vertical ? face.merge_axis_y : face.merge_axis_x;
        const int &merge_axis_y_b = vertical ? face.merge_axis_x : face.merge_axis_y;

        // 定义轴向常量（假设X=0，Y=1）
        const int MAIN_AXIS = 0;  // 主轴（如水平方向为X）
        const int CROSS_AXIS = 1; // 次轴（如水平方向为Y）

        // 动态切换轴向
        const int &merge_axis_main = vertical ? CROSS_AXIS : MAIN_AXIS;
        const int &merge_axis_cross = vertical ? MAIN_AXIS : CROSS_AXIS;

        for (KeyValue<int, Array> &axis_entry : rects_on_axis)
        {
            Array &rects = axis_entry.value;
            HashMap<String, Array> groups;

            // 分组
            for (int i = 0; i < rects.size(); i++)
            {
                Array rect = rects[i];
                Vector3i pos = rect[0];
                Vector2i size = rect[1];

                String key = String::num_int64(pos[merge_axis_y_b]) + "_" + String::num_int64(size[merge_axis_main]);
                if (!groups.has(key))
                {
                    groups[key] = Array();
                }
                groups[key].append(rect);
        }

        // 合并相邻方块
        Array merged_rects;
        for (const KeyValue<String, Array> &group_entry : groups)
        {
            Array group = group_entry.value;

            // 排序
            quick_sort(group, merge_axis_x_b);

            int i = 0;
            while (i < group.size())
            {
                Array current = group[i];
                Vector3i current_pos = current[0];
                Vector2i current_size = current[1];

                int j = i + 1;
                while (j < group.size())
                {
                    Array next = group[j];
                    Vector3i next_pos = next[0];
                    Vector2i next_size = next[1]; // 显式转换Variant到Vector2i

                    if (next_pos[merge_axis_x_b] == current_pos[merge_axis_x_b] + current_size[merge_axis_cross] + 1)
                    {
                        current_size[merge_axis_cross] += next_size[merge_axis_cross] + 1; // 现在可以正确访问x成员
                        j++;
                    }
                    else
                    {
                        break;
                    }
                }

                current[1] = current_size;
                merged_rects.append(current);
                i = j;
            }
        }

        axis_entry.value = merged_rects;
    }
};

// 横向和纵向合并
for (KeyValue<FACE_ID, FaceGroup> &entry : face_groups)
{
    process_merging(entry.value, false); // 横向
    process_merging(entry.value, true);  // 纵向
}

// 构建返回数据结构
Dictionary result;
const FACE_ID faces[] = {FRONT, BACK, LEFT, RIGHT, TOP, BOTTOM};
for (const FACE_ID &face : faces)
{
    Dictionary face_data;
    face_data["axis"] = face_groups[face].axis;
    face_data["merge_axis_x"] = face_groups[face].merge_axis_x;
    face_data["merge_axis_y"] = face_groups[face].merge_axis_y;

    Array final_rects;
    for (const KeyValue<int, Array> &axis_entry : face_groups[face].rects)
    {
        Array rects = axis_entry.value;
        for (int i = 0; i < rects.size(); i++)
        {
            final_rects.append(rects[i]);
        }
    }

    face_data["rects"] = final_rects;
    result[face] = face_data;
}
    // UtilityFunctions::print("面合并 ", result);
return result;
}

float int_to_float(int id) {
    float f;
    std::memcpy(&f, &id, sizeof(f)); // 将id的二进制位复制到float
    return f;
}

Ref<ArrayMesh> VoxelGridMeshTool::generate_voxelgrid_mesh(const Ref<VoxelGrid> voxelgtid, const Array &voxelgrid_array, const Object *block_types, Vector3 offset) const
{
    // 剔除面计算
    Dictionary culled_faces = determine_culled_faces(voxelgtid, voxelgrid_array);

    Ref<SurfaceTool> surfacetool = memnew(SurfaceTool);

    PackedVector3Array FACE_OFFSETS = get_base_face_offsets();
    PackedVector3Array base_ver = get_base_block_ver();
    Array faces = get_base_faces();

    // 获取字典所有键
    Array keys = culled_faces.keys();
    Dictionary merge_faces_dict;
    for (int i = 0; i < keys.size(); ++i)
    {
        merge_faces_dict[keys[i]] = merge_faces(culled_faces[keys[i]]);
    }

    surfacetool->begin(Mesh::PRIMITIVE_TRIANGLES);
    surfacetool->set_custom_format(0, SurfaceTool::CUSTOM_R_FLOAT);

    for (int j = 0; j < 6; ++j)
    {
        Array face_index = Array::make(j * 2, j * 2 + 1);

        for (int i = 0; i < keys.size(); ++i)
        {
            const Dictionary &merge_face = merge_faces_dict[keys[i]];
            const Dictionary &face_data = merge_face[j];

            // 解析面数据
            int axis = face_data["axis"];
            int merge_axis_x = face_data["merge_axis_x"];
            int merge_axis_y = face_data["merge_axis_y"];
            float face_offset = FACE_OFFSETS[j][axis];

            // 顶点调整索引
            Array adjust_x_indices;
            Array adjust_y_indices;
            for (int k = 0; k < base_ver.size(); ++k)
            {
                Vector3 vertex = base_ver[k];
                if (Math::abs(face_offset - vertex[axis] * 2) < CMP_EPSILON)
                {
                    if (vertex[merge_axis_x] > 0)
                        adjust_x_indices.append(k);
                    if (vertex[merge_axis_y] > 0)
                        adjust_y_indices.append(k);
                }
                // UtilityFunctions::print(Math::abs(face_offset - vertex[axis] * 2));
                // UtilityFunctions::print(face_offset, " ", vertex[axis]);
            }

            // UtilityFunctions::print(adjust_x_indices);
            // UtilityFunctions::print(adjust_y_indices);

            // 处理每个矩形区域
            Array rects = face_data["rects"];
            if (rects.size() == 0)
            {
                continue;
            }
            for (int r = 0; r < rects.size(); ++r)
            {
                Array position_h_w = rects[r];
                Vector3 pos_offset = position_h_w[0];
                Vector2 size_offset = position_h_w[1];

                // 复制顶点数据
                Array ver = base_ver.duplicate();

                // 调整X轴顶点
                for (int x_idx = 0; x_idx < adjust_x_indices.size(); ++x_idx)
                {
                    int idx = adjust_x_indices[x_idx];
                    Vector3 v = ver[idx];
                    ver[idx] = Vector3(
                        v.x + (merge_axis_x == 0 ? size_offset.x : 0),
                        v.y + (merge_axis_x == 1 ? size_offset.x : 0),
                        v.z + (merge_axis_x == 2 ? size_offset.x : 0));
                }
                // UtilityFunctions::print(merge_axis_x, size_offset);

                // 调整Y轴顶点
                for (int y_idx = 0; y_idx < adjust_y_indices.size(); ++y_idx)
                {
                    int idx = adjust_y_indices[y_idx];
                    Vector3 v = ver[idx];
                    ver[idx] = Vector3(
                        v.x + (merge_axis_y == 0 ? size_offset.y : 0),
                        v.y + (merge_axis_y == 1 ? size_offset.y : 0),
                        v.z + (merge_axis_y == 2 ? size_offset.y : 0));
                }
                // UtilityFunctions::print(merge_axis_y, size_offset);
                // UtilityFunctions::print(ver);
                //  添加顶点数据
                for (int f = 0; f < face_index.size(); ++f)
                {
                    int face_idx = face_index[f];
                    Array indices = faces[face_idx];
                    Vector3 normal = indices[3];
                    // UtilityFunctions::print("face_index ",face_index," indices ",indices," normal ",normal);

                    for (int v_idx = 0; v_idx < 3; ++v_idx)
                    {
                        int vert_index = indices[v_idx];
                        Vector3 vertex = ver[vert_index].operator Vector3() + pos_offset + offset;
                        // Vector3 vertex = ver[vert_index].operator Vector3() + pos_offset;

                        surfacetool->set_normal(normal);
                        surfacetool->set_uv(calculate_uv(ver[vert_index], normal));
                        surfacetool->set_custom(0, Color(int_to_float(i), 0, 0));
                        surfacetool->add_vertex(vertex);
                    }
                }
            }
        }
    }
    // surfacetool->generate_tangents();
    return surfacetool->commit();
}