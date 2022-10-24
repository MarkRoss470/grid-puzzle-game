extends Path

# What object to call the on_puzzle_solve method of when the signal reaches the end of the wire
export(NodePath) var on_complete_path
var on_complete: Node
export(int) var on_complete_param := 0
# How many points the circle that is extruded to make the wire should have
export(int) var num_points := 16
# The radius of the wire
export(float) var radius := 0.02
# The distance between edge loops on the wire
export(float) var edge_loop_distance := 0.1
# How long the signal should take to get to the end of the wire
export(float) var travel_time := 1.0
# What material the wire should have
# Material should have parameter 'signal_travel' from 0 to 1 controlling how much of the wire the signal has travelled
# It should also have a parameter called 'curve_length' which gives the total length of the curve
export(Material) var wire_material

var completed := false
var signal_travel: float = 0

# Called if the puzzle was loaded as solved from a saved game
# Should have the same effect as on_puzzle_solve but instantly
func load_solved(_i: int):
	completed = true
	signal_travel = 1
	on_complete.load_solved(on_complete_param)
	wire_material.set_shader_param("signal_travel", signal_travel)

# Called on correct solution
func on_puzzle_solve(_i: int):
	# Don't call on_puzzle_solve here, wait until signal reaches end of wire
	completed = true

# Called on incorrect solution
func on_puzzle_unsolve(_i: int):
	completed = false
	# Do call on_puzzle_unsolve herem as the signal instantly retracts on unsolve
	on_complete.on_puzzle_unsolve(on_complete_param)

# Called when the node enters the scene tree for the first time.
func _ready():
	on_complete = get_node(on_complete_path)
	# Duplicate material so as not to interfere with other wires using the same material
	wire_material = wire_material.duplicate()
	wire_material.set_shader_param("curve_length", self.curve.get_baked_length())

	# Create a new polygon
	var poly := CSGPolygon.new()
	# Create a new array of Vector2s to represent the polygon's vertices
	var pool := PoolVector2Array()

	# Populate the array with the points of a circle
	for i in range(num_points):
		# Calculate angle in radians
		var angle := (float(i) / num_points) * 2 * PI
		# Calculate and add point
		pool.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	
	# Set up the polygon to use the point array
	poly.polygon = pool
	# Set up the polygon to follow this path
	poly.mode = CSGPolygon.MODE_PATH

	poly.path_interval_type = CSGPolygon.PATH_INTERVAL_DISTANCE
	poly.path_interval = edge_loop_distance

	# Set what path for the polygon to extrude along
	# self.get_path() returns a NodePath (e.g. "res://...") pointing to this object, which is the path for the wire to follow
	poly.path_node = self.get_path()
	# Set the polygon's material
	poly.material = wire_material

	# Add the wire as a child
	add_child(poly)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# If signal travelling toward end but has not reached it
	if completed and signal_travel < 1:
		print(signal_travel)
		# Increase signal_travel relative to how much time has passed
		signal_travel += delta / travel_time

		# If the signal has reached the end of the wire, call on_complete.on_puzzle_solve()
		if signal_travel >= 1:
			signal_travel = 1
			on_complete.on_puzzle_solve(on_complete_param)
		
		# Update the shader to reflect the new signal_travel value
		wire_material.set_shader_param("signal_travel", signal_travel)
	
	# If signal travelling back but has not reached it
	elif (not completed) and signal_travel != 0:
		# Decrease signal_travel relative to how much time has passed
		signal_travel -= delta / travel_time

		# No need to call on_complete.on_puzzle_unsolve() here, as it was already called in self.on_puzzle_unsolve()
		if signal_travel < 0:
			signal_travel = 0
		
		# Update the shader to reflect the new signal_travel value
		wire_material.set_shader_param("signal_travel", signal_travel)
