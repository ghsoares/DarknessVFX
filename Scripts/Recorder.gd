extends Control

export (float) var fps := 60.0
export (NodePath) var animationPath : NodePath
export (NodePath) var viewportPath : NodePath
export (String) var animName := "Anim"
export (ShaderMaterial) var animatedMaterial : ShaderMaterial
export (String) var outputPath := "res://Frames/"
export (String) var frameName := "Frame_{frameIdx}.png"

var anim : AnimationPlayer
var viewport : Viewport
var time : float
var animTime : float
var frame : int

func _ready() -> void:
	anim = get_node(animationPath)
	viewport = get_node(viewportPath)
	
	anim.play(animName)
	anim.advance(0)
	time = 0.0
	animTime = anim.current_animation_length
	
	frame = 0
	
	outputPath = outputPath.replace("\\", "/")
	if !outputPath.ends_with("/"): outputPath += "/"

func _process(delta: float) -> void:
	yield(get_tree(), "idle_frame")
	take_shot()
	
	time += 1.0 / fps
	animatedMaterial.set_shader_param("time", time)
	
	anim.advance(1.0 / fps)
	
	frame += 1
	var t := clamp(time / animTime, 0, 1)
	var perc = t * 100.0
	
	print(str(perc) + "% Done")
	
	if time >= animTime:
		print("Finished!")
		get_tree().quit()

func take_shot() -> void:
	var img := viewport.get_texture().get_data()
	img.flip_y()
	img.save_png(outputPath + frameName.replace("{frameIdx}", str(frame)))




