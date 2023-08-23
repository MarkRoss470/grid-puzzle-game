extends BaseMaterial3D
class_name EdgeDetectMaterial

func _init():
	self.next_pass = ShaderMaterial.new()
	self.next_pass.shader = preload("res://shaders/EdgeDetect.tres")
	self.next_pass.set_shader_parameter("MainColour", Color.WHITE)
	self.next_pass.set_shader_parameter("EdgeColour", self.albedo_color)
	
	if self.emission_enabled:
		self.next_pass.set_shader_parameter("MainColour", self.emission)


