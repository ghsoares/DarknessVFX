tool

extends Spatial

export var  displacementTiling := Vector2(8, 8)
export var  displacementMotion := Vector2(8, 8)
export var  displacementDepth := 1.0
export var  displacementAmount := 2.0

export var  lightSteps := 2.0
export var  lightGradient : GradientTexture

export var  riftRadius := 16.0
export var  riftInnerRadius := 8.0
export var  riftInnerDepthSub := 16.0
export var  riftOuterDepthSub := 8.0
export var  riftDepth := 8.0
export var  riftCrackNoise : NoiseTexture
export var  riftCrackTiling := Vector2(32, 32)
export var  riftCrackWarpTiling := Vector2(64, 64)
export var  riftCrackWarpAmount := 4.0

export var  riftCrackOff := .5
export var  riftCrackWidth := .1

export var  riftPercentage := .5

export var  riftFogMotion := Vector2(32, 32)
export var  riftFogTiling := Vector2(4, 4)
export var  riftFogAmplitude := 1.0
export var  riftFogWidth := .1
export var riftFogColor := Color(1, 1, 1)

export var  brickTex : Texture
export var  brickTexScale := Vector2(1, 1)
export var brickColor := Color(1, 1, 1)

export var  brickTiling := Vector2(32, 8)
export var  brickOffset := 32
export var  brickRadius := 1.0
export var  brickWidth := .1
export var  brickDepth := .25

export var lightOff := Vector3(0, 32, 0)
export var lightColor := Color(1, 1, 1)
export var lightPower := 1.0
export var lightRange := 32.0
export var lightVolumetricPower := 1.0
export var lightVolumetricRange := 1.0
export var lightVolumetricTangent := 1.0
export var animationTime := 0.0
export var timeScale := 1.0

export (Array, ShaderMaterial) var materialsToUpdate := []

func _process(_delta: float) -> void:
	_set_shader_param("displacementTiling", displacementTiling);
	_set_shader_param("displacementMotion", displacementMotion);
	_set_shader_param("displacementDepth", displacementDepth);
	_set_shader_param("displacementAmount", displacementAmount);
	_set_shader_param("displacementTiling", displacementTiling);

	_set_shader_param("lightSteps", lightSteps);
	_set_shader_param("lightGradient", lightGradient);

	_set_shader_param("riftRadius", riftRadius);
	_set_shader_param("riftInnerRadius", riftInnerRadius);
	_set_shader_param("riftInnerDepthSub", riftInnerDepthSub);
	_set_shader_param("riftOuterDepthSub", riftOuterDepthSub);
	_set_shader_param("riftDepth", riftDepth);
	_set_shader_param("riftCrackNoise", riftCrackNoise);
	_set_shader_param("riftCrackTiling", riftCrackTiling);
	_set_shader_param("riftCrackWarpTiling", riftCrackWarpTiling);
	_set_shader_param("riftCrackWarpAmount", riftCrackWarpAmount);

	_set_shader_param("riftCrackOff", riftCrackOff);
	_set_shader_param("riftCrackWidth", riftCrackWidth);
	_set_shader_param("riftPercentage", riftPercentage);

	_set_shader_param("riftFogMotion", riftFogMotion);
	_set_shader_param("riftFogTiling", riftFogTiling);
	_set_shader_param("riftFogAmplitude", riftFogAmplitude);
	_set_shader_param("riftFogWidth", riftFogWidth);
	_set_shader_param("riftFogColor", riftFogColor);

	_set_shader_param("brickTex", brickTex);
	_set_shader_param("brickTexScale", brickTexScale);
	_set_shader_param("brickColor", brickColor);

	_set_shader_param("brickTiling", brickTiling);
	_set_shader_param("brickOffset", brickOffset);
	_set_shader_param("brickRadius", brickRadius);
	_set_shader_param("brickWidth", brickWidth);
	_set_shader_param("brickDepth", brickDepth);

	_set_shader_param("lightOff", lightOff);
	_set_shader_param("lightColor", lightColor);
	_set_shader_param("lightPower", lightPower);
	_set_shader_param("lightRange", lightRange);
	_set_shader_param("lightVolumetricPower", lightVolumetricPower);
	_set_shader_param("lightVolumetricRange", lightVolumetricRange);
	_set_shader_param("lightVolumetricTangent", lightVolumetricTangent);
	
	_set_shader_param("animationTime", animationTime);
	_set_shader_param("timeScale", timeScale);

func _set_shader_param(name: String, val) -> void:
	for mat in materialsToUpdate:
		mat.set_shader_param(name, val)

