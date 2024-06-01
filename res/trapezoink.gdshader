shader_type canvas_item;

uniform float topshrink = 0.2;
varying float k;

void vertex() {
	k = topshrink * (1.0 - UV.y);
}

void fragment() {
	float x = 0.5 + (UV.x - 0.5) / (1.0 - 2.0 * k);
	COLOR = texture(TEXTURE, vec2(x, UV.y));
	if (x <= 0.001 || x >= 0.999) {
		COLOR.a = 0.0;
	}
}
