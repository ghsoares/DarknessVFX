using System;
using System.Linq;
using Godot;

public class Renderer : Control
{
    AnimationPlayer anim;
    Viewport view;
    float time;
    float elapsed;
    float animDuration;
    int frame;

    [Export] public float fps = 60f;
    [Export] public NodePath animationPath;
    [Export] public NodePath viewportPath;
    [Export] public string animName = "Anim";
    [Export] public String outputPath = "res://Frames/";
    [Export] public String frameName = "Frame_{frameIdx}.png";

    public override void _Ready()
    {
        anim = GetNode<AnimationPlayer>(animationPath);
        view = GetNode<Viewport>(viewportPath);

        anim.PlaybackProcessMode = AnimationPlayer.AnimationProcessMode.Manual;
        anim.Play(animName);
        anim.Advance(0);
        time = 0f;
        animDuration = anim.CurrentAnimationLength;

        frame = 0;

        outputPath = outputPath.Replace("\\", "/");
        if (!outputPath.EndsWith("/")) outputPath += "/";
    }

    public override async void _Process(float delta)
    {
        await ToSignal(GetTree(), "idle_frame");
        TakeShot();

        time += 1f / fps;
        elapsed += delta;

        anim.Advance(1f / fps);

        frame += 1;
        float t = Mathf.Clamp(time / animDuration, 0f, 1f);
        float perc = t * 100f;

        float speed = time / elapsed;
        float remaining = (animDuration - time) / speed;

        GD.Print($"{perc.ToString("0.0")}% Done (Remaining: {remaining.ToString("0")} seconds)");

        if (time >= animDuration)
        {
            GD.Print("Finished!");
            GetTree().Quit();
        }
    }

    private void TakeShot()
    {
        Image img = view.GetTexture().GetData();
        img.FlipY();
        img.SavePng(outputPath + frameName.Replace("{frameIdx}", frame.ToString()));
    }
}