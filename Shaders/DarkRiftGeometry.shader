shader_type spatial;

const float SURFACE_DST = .01;
const int MAX_STEPS = 64;
const float MAX_DISTANCE = 256f;
const float NORMAL_EPSILON = .3f;

uniform float lightSteps = 4f;
uniform sampler2D lightGradient : hint_albedo;

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

uniform sampler2D brickTex : hint_albedo;
uniform vec2 brickTexScale = vec2(1f);
uniform vec4 brickColor : hint_color = vec4(1f);

uniform vec2 brickTiling = vec2(32f, 8f);
uniform float brickOffset = 32f;
uniform float brickRadius = 1f;
uniform float brickWidth = .1f;
uniform float brickDepth = .25f;

uniform float animationTime = 0f;
uniform float timeScale = 1f;

varying float time;

void vertex() {
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

float Scene(vec3 pos) {
	float sx = sin((pos.x + displacementMotion.x * time) * 3.1415f / displacementTiling.x);
	float sz = cos((pos.z + displacementMotion.y * time) * 3.1415f / displacementTiling.y);
	
	float dT = clamp(-pos.y / displacementDepth, 0f, 1f);
	
	pos.x += sx * displacementAmount * dT;
	pos.z += sz * displacementAmount * dT;
	
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
	float h = mix(0f, -riftDepth, rift) + SampleBrick(pos);
	
	float breakT = clamp(1f - abs(riftN) / 2f, 0f, 1f);
	breakT = pow(breakT, 4f);
	h += breakT * 1f * riftPercentage; 
	
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
	//float st = riftDepth / float(MAX_STEPS);
	float prevDst = Scene(ro + rd * d);
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 pos = ro + rd * d;
		float sceneDst = Scene(pos);
		
		float dstAdd = sceneDst > 0f ? sceneDst * .2f : sceneDst * .1f;
		d += dstAdd;
		pos += rd * dstAdd;
		
		if (d > MAX_DISTANCE || abs(sceneDst) <= SURFACE_DST) break;
	}
	return d;
}

void fragment() {
	vec3 world = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 camera = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 dir = normalize(world - camera);
	vec3 worldNormal = (CAMERA_MATRIX * vec4(NORMAL, 0f)).xyz;
	
	vec3 ro = world - dir * SURFACE_DST;
	vec3 rd = dir;
	
	float depth = RayMarch(ro, rd);
	if (depth < MAX_DISTANCE) {
		world = ro + rd * depth;
		worldNormal = Normal(world);
	} else {
		discard;
	}
	
	vec2 gridIdx = floor(world.xz / brickTiling);
	vec2 grid = fract((world.xz + vec2(gridIdx.y * brickOffset, 0f)) / brickTiling);
	
	vec3 col = texture(brickTex, grid * brickTexScale).rgb * brickColor.rgb;
	
	vec4 ndc = PROJECTION_MATRIX * INV_CAMERA_MATRIX * vec4(world, 1f);
	float writeDepth = (ndc.z / ndc.w) * .5f + .5f;
	
	NORMAL = (INV_CAMERA_MATRIX * vec4(worldNormal, 0f)).xyz;
	ALBEDO = col;
	DEPTH = writeDepth;
}

void light() {
	float light = dot(NORMAL, LIGHT) * .5f + .5f;
	light = floor(light * lightSteps) / (lightSteps - 1f);
	
	DIFFUSE_LIGHT = ALBEDO * texture(lightGradient, vec2(light)).rgb;
	SPECULAR_LIGHT = vec3(0f);
}
