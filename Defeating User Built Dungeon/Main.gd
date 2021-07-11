extends Node

# Major, Minor, Patch
var version = [0, 2, 1]

var currentRoom = 0
var levelChange = false

var Rooms = ["""
XXXXXXXXXXXX
X@         X
X         YX
XXDXXXXXXXXX
X         >X
XXXXXXXXXXXX
"""]

const RoomsStore = ["""
XXXXXXXXXXXX
X@         X
X         YX
XXDXXXXXXXXX
X         >X
XXXXXXXXXXXX
"""]

var game_array = []

const INTERACTS = [">", "Y", "D"]
const COLLIDES = ["X", "D"]

var inv = []

func _ready():
	get_tree().connect("files_dropped", self, "_files_dropped")
	game_array = _get_text_as_array(Rooms[0])
	_display_array(game_array)
	
	
func _input(event):
	if not game_array:
		if event.is_pressed():
			$VSplitContainer/Label.text = "World is empty, you can't continue."
		return
	var dir = Vector2(event.get_action_strength("move_right") - event.get_action_strength("move_left"), event.get_action_strength("move_down") - event.get_action_strength("move_up"))
	if dir != Vector2.ZERO or event.is_action_pressed("wait"):
		_process_turn(game_array,dir)


func _process_turn(array, dir):
	var a = _move_player(array, dir)
#	Handle Projectiles

#	Handle Enemies
	
	game_array = a
	if not levelChange:
		_display_array(game_array)
	else:
		game_array = []
		$VSplitContainer/Label.text = "You walk downstairs."
	pass


func _move_player(array, dir):
	if dir == Vector2.ZERO:
		print("You wait a minute.")
		return array
	var Pos = _find_player(array)
	print("At ", Pos)
	var Loc = Pos + dir
	print("To ", Loc)
	var Dest = array[Loc.y][Loc.x]
	var a = array
	if Dest in INTERACTS:
		a = _handle_interaction(Dest, Loc, array)
	if Dest in COLLIDES:
		return array
	
	a[Pos.y][Pos.x] = "."
	a[Loc.y][Loc.x] = "@"
	return a


func _find_player(array):
	var Pos = Vector2.ZERO
	for y in array:
		for x in y:
			if x == "@":
				return Pos
			Pos.x += 1
		Pos.x = 0
		Pos.y += 1


func _handle_interaction(type, loc, array):
	var a = array
	if type == ">":
		levelChange = true
		currentRoom += 1
	if type == "Y":
		inv.append("Y")
		print(inv)
	elif type == "D":
		var index = 0
		for spot in inv:
			if spot == "Y":
				inv.remove(index)
				a[loc.y][loc.x] = " "
			index += 1
	return a
	pass

func _files_dropped(files, screen):
	var extensions = "txt"
	
	for file in files:
#		var Bool = false
		if file.get_extension() != extensions:
			continue
#			Bool = true
#		print(file, " ", screen, Bool)
		var f = File.new()
		f.open(file, File.READ)
		var index = 1
		$VSplitContainer/Label.text = ""
		while not f.eof_reached():
			var line = f.get_line()
#			line += " "
			print(line + str(index))
			$VSplitContainer/Label.text += line
			index += 1
		pass


func _get_text_as_array(text : String):
	var a = []
	var c = text.split("\n", false)
#	print(c)
	for line in c:
		var A = []
#		var b = line.split("", false)
#		print(b)
		for Char in line:
			A.append(Char)
#			print(Char)
		a.append(A)
#	print(a)
	return a
#	pass


func _display_array(array):
	var index = 1
	var text = ""
	for y in array:
		for x in y:
			text += x
		if index < 6:
			text += "\n"
		index += 1
	$VSplitContainer/Label.text = text
