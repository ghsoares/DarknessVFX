shader_type spatial;
render_mode unshaded;

const float SURFACE_DST = .01;
const int MAX_STEPS = 64;
const float MAX_DISTANCE = 256f;
const float NORMAL_EPSILON = .1f;

uniform vec2 displacementTiling = vec2(8f);
uniform vec2 displacementMotion = vec2(8f);
uniform float displacementDepth = 1f;
uniform float displacementAmount = 2f;

uniform vec3 sunDir = vec3(1f, -1f, 1f);
uniform float lightSteps = 2f;
uniform sampler2D lightGradient;

uniform float riftRadius = 16f;
uniform float riftInnerRadius = 8f;
uniform float riftDepth = 8f;
uniform sampler2D riftCrackNoise;
uniform vec2 riftCrackTiling = vec2(32f);
uniform vec2 riftCrackWarpTiling = vec2(64f);
uniform float riftCrackWarpAmount = 4f;

uniform float riftCrackOff = .5f;
uniform float riftCrackWidth = .1f;

uniform float riftPercentage : hint_range(0f, 1f) = .5f;

uniform vec2 riftFogMotion = vec2(32f);
uniform vec2 riftFogTiling = vec2(4f);
uniform float riftFogAmplitude = 1f;
uniform float riftFogWidth = .1f;
uniform vec4 riftFogColor : hint_color = vec4(1f);

uniform sampler2D brickTex;
uniform vec2 brickTexScale = vec2(1f);
uniform vec4 brickColor : hint_color = vec4(1f);

uniform vec2 brickTiling = vec2(32f, 8f);
uniform float brickOffset = 32f;
uniform float brickRadius = 1f;
uniform float brickWidth = .1f;
uniform float brickDepth = .25f;

uniform float zNear = .05f;
uniform float zFar = 500f;

varying mat4 it_mv;
varying float time;

void vertex() {
	it_mv = inverse(transpose(MODELVIEW_MATRIX));
	time = TIME;
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

float Scene(vec3 pos) {
	float sx = sin((pos.x + displacementMotion.x * time) * 3.1415f / displacementTiling.x);
	float sz = cos((pos.z + displacementMotion.y * time) * 3.1415f / displacementTiling.y);
	
	float dT = clamp(-pos.y / displacementDepth, 0f, 1f);
	
	pos.x += sx * displacementAmount * dT;
	pos.z += sz * displacementAmount * dT;
	
	float rift = SampleRift(pos);
	
	float centerDst = length(pos.xz);
	float rad1 = mix(0f, riftInnerRadius, riftPercentage);
	float rad2 = mix(riftInnerRadius, riftRadius, riftPercentage);
	rift -= ((centerDst - rad1) / (rad2 - rad1)) * 2f;
	
	rift -= 1f;
	rift += riftPercentage * 1f;
	
	rift = clamp(rift, 0f, 1f);
	float h = mix(0f, -riftDepth, rift) + SampleBrick(pos);
	//float h = SampleBrick(pos);
	return pos.y - h;
}

vec3 Normal(vec3 pos) {
	float d = Scene(pos);
	vec2 e = vec2(NORMAL_EPSILON, 0.0);
	vec3 n = d - vec3(
		Scene(pos - e.xyy),
		Scene(pos - e.yxy),
		Scene(pos - e.yyx));
	return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd) {
	float d = 0f;
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 pos = ro + rd * d;
		float sceneDst = Scene(pos);
		
		float dstAdd = sceneDst > 0f ? sceneDst * .1f : sceneDst * .1f;
		d += dstAdd;
		pos += rd * dstAdd;
		
		if (d > MAX_DISTANCE || abs(sceneDst) <= SURFACE_DST) break;
	}
	return d;
}

float Fog(vec3 pos) {
	float riftN = 0f;
	
	int iterations = 3;
	for (int i = 0; i < iterations; i++) {
		float t = float(i) / float(iterations - 1);
		vec2 motion = mix(riftFogMotion * .5f, riftFogMotion * 1f, t);
		riftN += texture(riftCrackNoise, (pos.xz + time * motion) / riftFogTiling).r;
	}
	riftN /= float(iterations);
	
	float riftF = riftN * riftFogAmplitude;
	riftF = riftDepth - riftF;
	
	float riftT = 1f - clamp((pos.y + riftF) / riftFogWidth, 0f, 1f);
	
	return riftT;
}

void fragment() {
	vec3 world = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).rgb;
	vec3 camera = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).rgb;
	vec3 dir = normalize(world - camera);
	vec3 worldNormal = (CAMERA_MATRIX * vec4(NORMAL, 0f)).rgb;
	
	vec3 ro = world - dir * SURFACE_DST;
	vec3 rd = dir;
	
	float depth = RayMarch(ro, rd);
	if (depth < MAX_DISTANCE) {
		world = ro + rd * depth;
		worldNormal = Normal(world);
	}
	
	float light = dot(worldNormal, -normalize(sunDir)) * .5f + .5f;
	light = floor(light * lightSteps) / (lightSteps - 1f);
	vec3 lightC = texture(lightGradient, vec2(light)).rgb;
	
	vec2 gridIdx = floor(world.xz / brickTiling);
	vec2 grid = fract((world.xz + vec2(gridIdx.y * brickOffset, 0f)) / brickTiling);
	
	vec3 col = texture(brickTex, grid * brickTexScale).rgb * brickColor.rgb;
	col *= lightC;
	
	float riftT = Fog(world);
	col = mix(col, riftFogColor.rgb, riftT);
	
	/*
	float4 clip_pos = mul(UNITY_MATRIX_VP, float4(ray_pos, 1.0));
	o.zvalue = clip_pos.z / clip_pos.w;
	*/
	
	//MODELVIEW_MATRIX
	//
	float writeDepth = (it_mv * vec4(world, 1f)).z;
	
	ALBEDO = col;
	//DEPTH = writeDepth * 1f;
}


