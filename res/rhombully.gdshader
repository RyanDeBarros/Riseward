shader_type canvas_item;

uniform float warp = 0.5;
varying float k;
varying float kinv;

void vertex() {
	k = (warp + 0.5) / (warp + 1.0);
	kinv = 1.0 / k;
}

void fragment() {
	float y = UV.y;
	if (y >= k) {
		y = UV.y * (1.0 + warp) - warp;
	}
	else {
		y = UV.y * 0.5 * kinv;
	}
	COLOR = texture(TEXTURE, vec2(UV.x, y));
}
