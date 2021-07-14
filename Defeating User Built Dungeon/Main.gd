extends Node

# Major, Minor, Patch
var version = [0, 3, 1, "-alpha"]

onready var levelLabel = $VSplitContainer/LevelLabel
onready var statusLabel = $VSplitContainer/StatusLabel

var currentRoom = 0
var levelChange = false
var levelDiff = 0

var Rooms = []

const RoomsStore = ["""
XXXXXXXXXXXX
X@         X
X         YX
XXDXXXXXXXXX
X<    r   >X
XXXXXXXXXXXX
"""]

var game_array = []

const INTERACTS = [">", "<", "Y", "D"]
const COLLIDES = ["X", "D"]
const ENTITIES = ["r"]

var inv = []

func _ready():
	get_tree().connect("files_dropped", self, "_files_dropped")
	Rooms.append(RoomsStore[0])
	game_array = _get_text_as_array(Rooms[0])
	_display_array(game_array)
	_status_bar_update()
	
	
func _input(event):
	if event.is_action_pressed("version_display"):
		statusLabel.text = "v " + str(version[0]) + "." + str(version[1]) + "." + str(version[2]) + version[3]
		$NotificationTimer.start()
	if not game_array:
		if event.is_pressed():
			var index = 0
			for room in Rooms:
				if index == currentRoom:
					_change_level()
					return
				index += 1
			levelLabel.text = "World is empty, you can't continue."
			statusLabel.text = "Drag and drop a .txt"
			$NotificationTimer.start()
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
		if levelDiff == 1:
			levelLabel.text = "You walk downstairs."
		elif levelDiff == -1:
			levelLabel.text = "You walk upstairs."
			if currentRoom == -1:
				levelLabel.text += "\nYou leave the dungeon."
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
	if Dest in INTERACTS or Dest in ENTITIES:
		a = _handle_interaction(Dest, Loc, array)
	if Dest in COLLIDES or Dest in ENTITIES:
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
		levelDiff = 1
		currentRoom += 1
	elif type == "<":
		levelChange = true
		levelDiff = -1
		currentRoom -= 1
	elif type == "Y":
		inv.append("Y")
		print(inv)
	elif type == "D":
		var index = 0
		for spot in inv:
			if spot == "Y":
				inv.remove(index)
				a[loc.y][loc.x] = " "
			index += 1
	elif type in ENTITIES:
		if type == "r":
			a[loc.y][loc.x] = " "
	return a
	pass

func _files_dropped(files, screen):
	var fileIndex = 0
	var extensions = "txt"
	if currentRoom < 0:
		print("Can't enter, player exited.")
		return
	for file in files:
#		var Bool = false
		if file.get_extension() != extensions:
			continue
#			Bool = true
#		print(file, " ", screen, Bool)
		var f = File.new()
		f.open(file, File.READ)
		var data = ""
		var index = 1
		levelLabel.text = ""
		while not f.eof_reached():
			if index > 6:
				break
			var line = f.get_line()
			print(line + str(index))
			if index < 6:
				line += "\n"
			data += line
#			levelLabel.text += line
#			if index < 6:
#				levelLabel.text += "\n"
			index += 1
		f.close()
		print(data)
		if fileIndex == 0 and levelChange:
			Rooms.append(data)
			_change_level()
		elif fileIndex == 0 and not levelChange:
			print("OK")
			Rooms.insert(currentRoom, data)
			if Rooms.size() > 1:
				Rooms.remove(currentRoom + 1)
			_change_level()
		else:
			Rooms.append(data)
			_change_level()
			print(Rooms)
		fileIndex += 1
		pass

# Call when array has that many indexed of rooms
func _change_level():
	levelChange = false
	if currentRoom == -1:
		levelLabel.text = "You have left."
		return
	var store = ""
	if currentRoom == 9:
		store = RoomsStore[1]
	else:
		store = Rooms[currentRoom]
		
	game_array = _get_text_as_array(store)
	_display_array(game_array)
	_status_bar_update()
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


func _display_array(array : Array):
	var index = 1
	var text = ""
	for y in array:
		for x in y:
			text += x
		if index < 6:
			text += "\n"
		index += 1
	levelLabel.text = text

func _status_bar_update():
	var text = ""
	var size = Rooms.size() - 1
	if size < 0:
		statusLabel.text = "No Rooms."
		return
	var current = currentRoom
	if current < 0:
		text = "Bye bye!"
	for x in range(10):
		if x < current:
			text += "@"
		else:
			if x == 9:
				text += "X"
			elif size >= x:
				text += str(x+1)
			else:
				text += "."
		text += " "
		statusLabel.text = text
	


func _on_NotificationTimer_timeout():
	_status_bar_update()
