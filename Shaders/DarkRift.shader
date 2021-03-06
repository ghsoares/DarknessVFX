shader_type spatial;
render_mode unshaded;

const float SURFACE_DST = .01;
const int MAX_STEPS = 64;
const float MAX_DISTANCE = 256f;
const float NORMAL_EPSILON = .1f;

const int LIGHT_STEPS = 100;

uniform vec2 displacementTiling = vec2(8f);
uniform vec2 displacementMotion = vec2(8f);
uniform float displacementDepth = 1f;
uniform float displacementAmount = 2f;

uniform vec3 sunDir = vec3(1f, -1f, 1f);
uniform float lightSteps = 2f;
uniform sampler2D lightGradient : hint_albedo;

uniform float riftRadius = 16f;
uniform float riftInnerRadius = 8f;
uniform float riftDepth = 8f;
uniform sampler2D riftCrackNoise : hint_albedo;
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

uniform sampler2D brickTex : hint_albedo;
uniform vec2 brickTexScale = vec2(1f);
uniform vec4 brickColor : hint_color = vec4(1f);

uniform vec2 brickTiling = vec2(32f, 8f);
uniform float brickOffset = 32f;
uniform float brickRadius = 1f;
uniform float brickWidth = .1f;
uniform float brickDepth = .25f;

uniform float zNear = .05f;
uniform float zFar = 500f;

uniform vec3 lightOff = vec3(0f, 32f, 0f);
uniform vec4 lightColor : hint_color = vec4(1f);
uniform float lightPower = 1f;
uniform float lightRange = 32f;
uniform float lightVolumetricPower = 1f;
uniform float lightVolumetricRange = 1f;
uniform float lightVolumetricTangent = 1f;

uniform float animationTime = 0f;
uniform float timeScale = 1f;

varying mat4 mv;
varying float time;

void vertex() {
	mv = MODELVIEW_MATRIX;
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
	
	float centerDst = length(pos.xz);
	float rad1 = mix(0f, riftInnerRadius, riftPercentage);
	float rad2 = mix(riftInnerRadius, riftRadius, riftPercentage);
	float dstT = ((centerDst - rad1) / (rad2 - rad1));
	
	rift -= dstT * 2f;
	
	rift -= 1f;
	rift += riftPercentage * 1f;
	
	float riftN = rift;
	rift = clamp(rift, 0f, 1f);
	float h = mix(0f, -riftDepth, rift) + SampleBrick(pos);
	
	float breakT = clamp(1f - abs(riftN) / 1f, 0f, 1f);
	h += breakT * .25f * riftPercentage; 
	
	return pos.y - h;
}

vec3 SceneLight(vec3 pos) {
	pos.xz /= 1f + clamp(pos.y / lightVolumetricRange, 0f, 1f) * lightVolumetricTangent;
	
	vec3 l = vec3(0f);
	
	float rift = SampleRift(pos);
	
	float centerDst = length(pos.xz);
	float rad1 = mix(0f, riftInnerRadius, riftPercentage);
	float rad2 = mix(riftInnerRadius, riftRadius, riftPercentage);
	float dstT = ((centerDst - rad1) / (rad2 - rad1));
	
	rift -= dstT * 2f;
	
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
		vec2 motion = mix(riftFogMotion * -.5f, riftFogMotion * 1f, t);
		riftN += texture(riftCrackNoise, (pos.xz + time * motion) / riftFogTiling).r;
	}
	riftN /= float(iterations);
	
	float riftF = riftN * riftFogAmplitude;
	riftF = riftDepth - riftF;
	
	float riftT = 1f - clamp((pos.y + riftF) / riftFogWidth, 0f, 1f);
	riftT = pow(riftT, 2f);
	
	return riftT;
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
	
	float light = dot(worldNormal, -normalize(sunDir)) * .5f + .5f;
	light = floor(light * lightSteps) / (lightSteps - 1f);
	vec3 lightC = texture(lightGradient, vec2(light)).rgb;
	
	vec2 gridIdx = floor(world.xz / brickTiling);
	vec2 grid = fract((world.xz + vec2(gridIdx.y * brickOffset, 0f)) / brickTiling);
	
	vec3 col = texture(brickTex, grid * brickTexScale).rgb * brickColor.rgb;
	col *= lightC;
	
	vec3 lightO = (world - lightOff);
	vec3 lightDir = normalize(lightO);
	light = dot(worldNormal, -lightDir) * .5f + .5f;
	light *= clamp(1f - length(lightO / lightRange), 0f, 1f) * lightPower;
	light = floor(light * lightSteps) / (lightSteps - 1f);
	lightC = texture(lightGradient, vec2(light)).rgb * lightColor.rgb;
	
	col += lightC;
	
	float riftT = Fog(world);
	col = mix(col, riftFogColor.rgb, riftT);
	
	col += Light(camera, world);
	
	vec4 ndc = PROJECTION_MATRIX * INV_CAMERA_MATRIX * vec4(world, 1f);
	float writeDepth = (ndc.z / ndc.w) * .5f + .5f;
	
	ALBEDO = col;
	DEPTH = writeDepth;
}


