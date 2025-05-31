#pragma once

#include "godot_cpp/classes/resource.hpp"
#include "godot_cpp/classes/wrapped.hpp"
#include "godot_cpp/classes/texture2d_array.hpp"

using namespace godot;

class BlockTypes : public Resource
{
    GDCLASS(BlockTypes, Resource);

private:
    Dictionary blocks;

protected:
    static void _bind_methods();

public:
    BlockTypes() = default;
    ~BlockTypes() override = default;

    static BlockTypes add_blocks_of_sqlite();
    void add_block(int id);
    Dictionary get_block(int id);

    static String get_block_name();
    static int get_block_texture2d_id();
    static Texture2DArray get_blocks_texture2darray();
};