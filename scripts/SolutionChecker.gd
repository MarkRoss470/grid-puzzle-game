extends Node

class_name SolutionChecker

# Class representing a solution
class Solution:
	# Whether the solution is right
	var is_correct: bool
	# An array of [x, y] coordinates of the cells which are wrong
	# This is not (necessarily) the cells which are in the wrong rotation
	# It's the cells whose rules are broken because of a cell in the wrong rotation 
	var wrong_cells: Array
	
	# Simple constructor
	func _init(c: bool, w: Array = []):
		self.is_correct = c
		self.wrong_cells = w

# TODO: check actual solutions
static func check_solution(puzzle: Array, solution: Array) -> Solution:
	if solution[0][0] == 1:
		return Solution.new(false, [[0, 0]])
	return Solution.new(true)
