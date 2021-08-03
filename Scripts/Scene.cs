using System;
using Godot;

[Tool]
public class Scene : Spatial
{

    [Export]
    public Vector2 displacementTiling = new Vector2(8f, 8f);
    [Export]
    public Vector2 displacementMotion = new Vector2(8f, 8f);
    [Export]
    public float displacementDepth = 1f;
    [Export]
    public float displacementAmount = 2f;

    [Export]
    public float lightSteps = 2f;
    [Export]
    public Texture lightGradient;

    [Export]
    public float riftRadius = 16f;
    [Export]
    public float riftInnerRadius = 8f;
    [Export]
    public float riftInnerDepthSub = 16f;
    [Export]
    public float riftOuterDepthSub = 8f;
    [Export]
    public float riftDepth = 8f;
    [Export]
    public Texture riftCrackNoise;
    [Export]
    public Vector2 riftCrackTiling = new Vector2(32f, 32f);
    [Export]
    public Vector2 riftCrackWarpTiling = new Vector2(64f, 64f);
    [Export]
    public float riftCrackWarpAmount = 4f;

    [Export]
    public float riftCrackOff = .5f;
    [Export]
    public float riftCrackWidth = .1f;

    [Export(PropertyHint.Range, "0,1")]
    public float riftPercentage = .5f;

    [Export]
    public Vector2 riftFogMotion = new Vector2(32f, 32f);
    [Export]
    public Vector2 riftFogTiling = new Vector2(4f, 4f);
    [Export]
    public float riftFogAmplitude = 1f;
    [Export]
    public float riftFogWidth = .1f;
    [Export]
    public Color riftFogColor = new Color(1f, 1f, 1f);

    [Export]
    public Texture brickTex;
    [Export]
    public Vector2 brickTexScale = new Vector2(1f, 1f);
    [Export]
    public Color brickColor = new Color(1f, 1f, 1f);

    [Export]
    public Vector2 brickTiling = new Vector2(32f, 8f);
    [Export]
    public float brickOffset = 32f;
    [Export]
    public float brickRadius = 1f;
    [Export]
    public float brickWidth = .1f;
    [Export]
    public float brickDepth = .25f;

    [Export]
    public Vector3 lightOff = new Vector3(0f, 32f, 0f);
    [Export]
    public Color lightColor = new Color(1f, 1f, 1f);
    [Export]
    public float lightPower = 1f;
    [Export]
    public float lightRange = 32f;
    [Export]
    public float lightVolumetricPower = 1f;
    [Export]
    public float lightVolumetricRange = 1f;
    [Export]
    public float lightVolumetricTangent = 1f;
    [Export]

    public float animationTime = 0f;
    [Export]
    public float timeScale = 1f;

    [Export]
    public ShaderMaterial[] materialsToUpdate = new ShaderMaterial[0];

    public override void _Process(float delta)
    {
        SetShaderParam("displacementTiling", displacementTiling);
        SetShaderParam("displacementMotion", displacementMotion);
        SetShaderParam("displacementDepth", displacementDepth);
        SetShaderParam("displacementAmount", displacementAmount);
        SetShaderParam("displacementTiling", displacementTiling);

        SetShaderParam("lightSteps", lightSteps);
        SetShaderParam("lightGradient", lightGradient);

        SetShaderParam("riftRadius", riftRadius);
        SetShaderParam("riftInnerRadius", riftInnerRadius);
        SetShaderParam("riftInnerDepthSub", riftInnerDepthSub);
        SetShaderParam("riftOuterDepthSub", riftOuterDepthSub);
        SetShaderParam("riftDepth", riftDepth);
        SetShaderParam("riftCrackNoise", riftCrackNoise);
        SetShaderParam("riftCrackTiling", riftCrackTiling);
        SetShaderParam("riftCrackWarpTiling", riftCrackWarpTiling);
        SetShaderParam("riftCrackWarpAmount", riftCrackWarpAmount);

        SetShaderParam("riftCrackOff", riftCrackOff);
        SetShaderParam("riftCrackWidth", riftCrackWidth);
        SetShaderParam("riftPercentage", riftPercentage);

        SetShaderParam("riftFogMotion", riftFogMotion);
        SetShaderParam("riftFogTiling", riftFogTiling);
        SetShaderParam("riftFogAmplitude", riftFogAmplitude);
        SetShaderParam("riftFogWidth", riftFogWidth);
        SetShaderParam("riftFogColor", riftFogColor);

        SetShaderParam("brickTex", brickTex);
        SetShaderParam("brickTexScale", brickTexScale);
        SetShaderParam("brickColor", brickColor);

        SetShaderParam("brickTiling", brickTiling);
        SetShaderParam("brickOffset", brickOffset);
        SetShaderParam("brickRadius", brickRadius);
        SetShaderParam("brickWidth", brickWidth);
        SetShaderParam("brickDepth", brickDepth);

        SetShaderParam("lightOff", lightOff);
        SetShaderParam("lightColor", lightColor);
        SetShaderParam("lightPower", lightPower);
        SetShaderParam("lightRange", lightRange);
        SetShaderParam("lightVolumetricPower", lightVolumetricPower);
        SetShaderParam("lightVolumetricRange", lightVolumetricRange);
        SetShaderParam("lightVolumetricTangent", lightVolumetricTangent);
        
        SetShaderParam("animationTime", animationTime);
        SetShaderParam("timeScale", timeScale);
    }

    private void SetShaderParam(string name, object val)
    {
        foreach (ShaderMaterial mat in materialsToUpdate)
        {
            mat.SetShaderParam(name, val);
        }
    }
}
