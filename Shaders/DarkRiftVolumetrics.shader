shader_type spatial;
render_mode unshaded;

const int LIGHT_STEPS = 60;

uniform vec2 displacementTiling = vec2(8f);
uniform vec2 displacementMotion = vec2(8f);
uniform float displacementDepth = 1f;
uniform float displacementAmount = 2f;

uniform float riftRadius = 16f;
uniform float riftInnerRadius = 8f;
uniform float riftInnerDepthSub = 1f;
uniform float riftOuterDepthSub = 1f;
uniform float riftDepth = 8f;
uniform sampler2D riftCrackNoise : hint_albedo;
uniform vec2 riftCrackTiling = vec2(32f);
uniform vec2 riftCrackWarpTiling = vec2(64f);
uniform float riftCrackWarpAmount = 4f;

uniform float riftCrackOff = .5f;
uniform float riftCrackWidth = .1f;

uniform float riftPercentage : hint_range(0f, 1f) = .5f;

uniform vec2 brickTiling = vec2(32f, 8f);
uniform float brickOffset = 32f;
uniform float brickRadius = 1f;
uniform float brickWidth = .1f;
uniform float brickDepth = .25f;

uniform float lightVolumetricPower = 1f;
uniform float lightVolumetricRange = 1f;
uniform float lightVolumetricTangent = 1f;
uniform vec4 lightColor : hint_color = vec4(1f);

uniform float riftFogOffset = 0f;
uniform vec2 riftFogMotion = vec2(32f);
uniform vec2 riftFogTiling = vec2(128f);
uniform float riftFogAmplitude = 1f;
uniform float riftFogWidth = 1f;
uniform vec4 riftFogColor : hint_color = vec4(1f);

uniform vec2 riftFogRadius = vec2(2f, 4f);

uniform float animationTime = 0f;
uniform float timeScale = 1f;

varying float time;

void vertex() {
	POSITION = vec4(VERTEX, 1f);
	time = animationTime + TIME * timeScale;
}

float SampleRift(vec3 pos) {
	vec2 warpUv = pos.xz / riftCrackWarpTiling;
	float a = (texture(riftCrackNoise, warpUv).r * 2f - 1f) * 3.1415;
	vec2 warp = vec2(cos(a), sin(a)) * riftCrackWarpAmount;
	
	vec2 uv = (pos.xz + warp) / riftCrackTiling;
	float n = texture(riftCrackNoise, uv).r;
	
	n = abs(n - riftCrackOff) / riftCrackWidth;
	n = 1f - clamp(n, 0f, 1f);
	
	return n;
}

float SampleBrick(vec3 pos) {
	float h = 0f;
	
	vec2 gridIdx = floor(pos.xz / brickTiling);
	vec2 grid = fract((pos.xz + vec2(gridIdx.y * brickOffset, 0f)) / brickTiling) * brickTiling;
	grid -= brickTiling * .5f;
	
	vec2 brickSize = brickTiling - vec2(brickRadius * 1f);
	
	vec2 d = abs(grid) - brickSize * .5f;
	float brickDst = length(max(d, 0f)) + min(max(d.x, d.y), 0f);
	
	float t = brickDst / (brickRadius * .5f);
	h = clamp(t, 0f, 1f) * -brickDepth;
	
	return h;
}

vec3 SceneLight(vec3 pos) {
	pos.xz /= 1f + clamp(pos.y / lightVolumetricRange, 0f, 1f) * lightVolumetricTangent;
	
	vec3 l = vec3(0f);
	
	float rift = SampleRift(pos);
	//float rift= 1f;
	
	float centerDst = length(pos.xz);
	float rad1 = mix(0f, riftInnerRadius, riftPercentage);
	float rad2 = mix(riftInnerRadius, riftRadius, riftPercentage);
	//float dstT = ((centerDst - rad1) / (rad2 - rad1));
	
	float dstSub = 0f;
	
	if (centerDst < rad1) {
		float dstT = 1f - centerDst / rad1;
		dstSub = dstT * riftInnerDepthSub;
	} else {
		float dstT = (centerDst - rad1) / (rad2 - rad1);
		dstSub = dstT * riftOuterDepthSub;
	}
	
	rift -= dstSub;
	
	rift -= 1f;
	rift += riftPercentage * 1f;
	
	float riftN = rift;
	rift = clamp(rift, 0f, 1f);
	
	float lightT = rift * clamp(1f - pos.y / lightVolumetricRange, 0f, 1f);
	
	float s = texture(riftCrackNoise, (pos.xz + time * vec2(8f)) / 64f).r;
	s = s < .5f ? (1f - sqrt(1f - pow(2f * s, 2f))) / 2f : (sqrt(1f - pow(-2f * s + 2f, 2f)) + 1f) / 2f;
	
	lightT *= s;
	l += lightColor.xyz * lightT * lightVolumetricPower;
	
	return l;
}

vec4 SceneFog(vec3 p) {
	vec4 f = vec4(0f);
	
	float n = 0f;
	int iterations = 3;
	
	vec2 uv = vec2(
		length(p.xz),
		atan(p.z, p.x)
	);
	uv.y += uv.x * .05f;
	uv.y /= radians(180f);
	
	for (int i = 0; i < iterations; i++) {
		float mt = float(i) / float(iterations - 1);
		vec2 m = mix(riftFogMotion * .25f, riftFogMotion, mt);
		
		float lN = texture(riftCrackNoise, (uv + m * time) / riftFogTiling).r;
		lN = pow(lN * 2f, 4f) / 2f;
		n += clamp(lN, 0f, 1f);
	}
	
	n /= float(iterations);
	
	float centerDst = length(p.xz);
	float rT = 1f - (centerDst - riftFogRadius.x) / (riftFogRadius.y - riftFogRadius.x);
	rT = clamp(rT, 0f, 1f);
	float addT = rT;
	n = mix(n, 1f, 1f - clamp(centerDst / riftFogRadius.x, 0f, 1f));
	
	float h = riftFogOffset + n * riftFogAmplitude;
	h += clamp((centerDst - riftFogRadius.x) / (riftFogRadius.y - riftFogRadius.x), 0f, 1f) * 10f * riftPercentage;
	float fogT = 1f;
	
	fogT *= 1f - clamp((p.y + riftDepth - h) / riftFogWidth, 0f, 1f);
	f += riftFogColor * fogT * 32f * rT;
	
	return f;
}

vec3 Light(vec3 from, vec3 to) {
	vec3 l = vec3(0f);
	
	float spacing = 1f / float(LIGHT_STEPS);
	
	for (int i = 0; i < LIGHT_STEPS; i++) {
		float t = float(i) * spacing;
		vec3 p = from * (1f - t) + to * t;
		
		l += SceneLight(p);
	}
	
	l /= float(LIGHT_STEPS);
	
	return l;
}

vec4 Fog(vec3 from, vec3 to) {
	vec4 f = vec4(0f);
	
	float spacing = 1f / float(LIGHT_STEPS);
	
	for (int i = 0; i < LIGHT_STEPS; i++) {
		float t = float(i) * spacing;
		vec3 p = from * (1f - t) + to * t;
		
		f += SceneFog(p);
	}
	
	f /= float(LIGHT_STEPS);
	f.a = clamp(f.a, 0f, 1f);
	
	return f;
}

void fragment() {
	vec3 col = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	
	// Calculate view world coords
	vec3 ndc = vec3(SCREEN_UV, 0.0) * 2.0 - 1.0;
	vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_coords.xyz /= view_coords.w;
	vec3 world_cam_pos = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec4 world_coords = CAMERA_MATRIX * vec4(view_coords.xyz, 1.0);
	
	// Calculates pixel world position
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	if (depth >= 1f) discard;
	ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	vec4 world = CAMERA_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	
	vec4 f = Fog(world_cam_pos, world_position);
	col = mix(col, f.rgb, f.a);
	
	col += Light(world_cam_pos, world_position);
	
	//col =fract(world_position * .1f);
	
	ALBEDO = col;
}