shader_type spatial;

// 声明Texture2DArray
uniform sampler2DArray texture_array : source_color, filter_nearest;

varying flat uint index;

void vertex() {
	index = floatBitsToUint(CUSTOM0.r);
}

// 片元着色器中使用数据
void fragment() {
    vec4 color = texture(texture_array, vec3(UV, float(index)));
    ALBEDO = color.rgb;
}
