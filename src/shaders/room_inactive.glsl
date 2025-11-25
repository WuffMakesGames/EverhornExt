vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
	vec4 tex_col = Texel(tex, texture_coords);
	tex_col.rgb *= 0.6;
	return tex_col;
}