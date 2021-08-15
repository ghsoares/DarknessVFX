using System;
using Godot;

/*
var alive = 0;
var readyToAttack = 0;
var id = 0;
var attackSize = 3;

function getAlive() {
    alive = 0;
    readyToAttack = 0;

    for (spirit of my_spirits) {
        if (spirit.hp > 0) {
            alive++;
            if (spirit.size >= attackSize) readyToAttack++;
        }
    }
}

function length(vec) {
    return Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2))
}

function distance(vec1, vec2) {
    return Math.sqrt(Math.pow(vec2[0] - vec1[0], 2) + Math.pow(vec2[1] - vec1[1], 2))
}

function harvestBehaviour(spirit, id) {
    if (spirit.energy == 0) spirit.set_mark("Harvest");
    else if (spirit.energy == spirit.energy_capacity) spirit.set_mark("Unload");

    var stationary = id < 10;

    if (stationary) {
        if (spirit.energy < spirit.energy_capacity) spirit.set_mark("Harvest");
        else spirit.set_mark("Unload");
    }

    if (spirit.mark == "Harvest") {
        if (distance(spirit.position, star_zxq.position) >= 200) {
            spirit.move(star_zxq.position);
        } else {
            spirit.energize(spirit);
        }
    } else if (spirit.mark == "Unload") {
        if (distance(spirit.position, base.position) >= 200 || stationary) {
            spirit.move(base.position);
        } else {
            spirit.energize(base);
        }
    }
}

function attackNearBehaviour(spirit, id) {
    if (spirit.sight.enemies.length > 0) {
        var en = spirit.sight.enemies[0];
        en = spirits[en];
        spirit.move(en.position);
        spirit.energize(en);
    }
}

function mergeBehaviour(spirit, id) {
    if (alive > 25 && spirit.size < 3) {
        if (spirit.sight.friends.length > 0) {
            for (var i = 0; i < spirit.sight.friends.length; i++) {
                var fr = spirit.sight.friends[i];
                fr = spirits[fr];
                if (fr.size >= 3) continue;
                spirit.move(fr.position);
                spirit.merge(fr);
                break;
            }
        }
    }
}

function attackBehaviour(spirit, id) {
    if (readyToAttack >= 50 && id < readyToAttack - 25) {
        spirit.move(enemy_base.position);
        spirit.energize(enemy_base);
    }
}

getAlive();

console.log(`Alive: ${alive} ready to attack: ${readyToAttack}`);

for (spirit of my_spirits) {
    if (spirit.hp <= 0) continue;

    harvestBehaviour(spirit, id);
    mergeBehaviour(spirit, id);
    attackBehaviour(spirit, id);
    attackNearBehaviour(spirit, id);

    id++;
}
*/

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
