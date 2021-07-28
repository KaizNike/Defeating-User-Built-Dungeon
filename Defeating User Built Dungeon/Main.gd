extends Node

# Major, Minor, Patch
var version = [0, 4, 1, "-alpha"]
# Latest - Week 4 Update - New Visuals

# Future ideas - Friendly or neutral mobs

onready var levelLabel = $VSplitContainer/LevelLabel
onready var statusLabel = $VSplitContainer/StatusLabel

var currentRoom = 0
var levelChange = false
var waiting = false
var levelDiff = 0

var Rooms = []

const RoomsStore = ["""
############
#@         #
#     rr  Y#
##D#########
#<r       >#
############
""",
"""
#############
#OY#      #O#
# ##     L# #
#@ D      D #
#############
"""]

var game_array = []

const INTERACTS = [">", "<", "Y", "D", "K", "%"]
const COLLIDES = ["#", "D", "X"]
const ENTITIES = ["r", "k", "g", "L", "@"]
const WEAPONS = ["T", "S"]
const ARMORS = ["O", "P", "B"]

var inv = []
var item = {"Char": "", "Uses": 1}

var actors = []
var being = {"Speed": 1, "Turns": 1, "Loc": Vector2.ZERO, "HP": 1, "DMG": 2, "Char": "", "Behav": "Random"}
var player = {"Speed": 1, "Turns": 1, "Loc": Vector2.ZERO, "HP": 3, "DMG": 1, "Char": "@", "Behav": "Player"}

func _ready():
	randomize()
	get_tree().connect("files_dropped", self, "_files_dropped")
	Rooms.append(RoomsStore[0])
	game_array = _get_text_as_array(Rooms[0])
	_actors_init(game_array)
	$VSplitContainer/LevelLabel.text = "You are hunting L on floor X,\n do not fail us!"
	$VSplitContainer/StatusLabel.text = "Press Anything"
	waiting = true
	
class SortingActors:
	static func sort_descending(a,b):
		if a.Turns > b.Turns:
			return true
		return false
	
func _actors_init(array):
	for y in range(array.size()):
		for x in range(array[0].size()):
			if array[y][x] in ENTITIES:
				_being_init(Vector2(x,y),array[y][x])
	if actors.size() > 1:
		actors.sort_custom(SortingActors, "sort_descending")
	print(actors)
	
# If found in entities, add to array
func _being_init(Loc, Char):
	var Being = being.duplicate(true)
	if Char == "r":
		Being.Speed = 2
		Being.Turns = 2
		Being.DMG = 1
	elif Char == "@":
		player.Loc = Loc
		actors.append(player)
		print(player)
		return
	else:
		return
	## Should happen if in if elif group
	Being.Loc = Loc
	Being.Char = Char
	print(Being)
	actors.append(Being)
#	print(actors)
	
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
			if currentRoom > -1:
				levelLabel.text = "World is empty, you can't continue."
				statusLabel.text = "Drag and drop a .txt"
				$NotificationTimer.start()
		return
	if waiting and event.is_pressed():
		waiting = false
		_display_array(game_array)
		_status_bar_update()
		return
	var dir = Vector2(event.get_action_strength("move_right") - event.get_action_strength("move_left"), event.get_action_strength("move_down") - event.get_action_strength("move_up"))
	if dir != Vector2.ZERO or event.is_action_pressed("wait"):
		_process_turn(game_array,dir)


func _process_turn(array, dir):
#	var a = _move_player(array, dir)
#	Handle Projectiles

#	Handle Enemies
	var a = _move_actors(array, dir)
	_reset_actor_turns()
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


func _move_player(array, dir, actor):
	if dir == Vector2.ZERO:
		print("You wait a minute.")
		return array
#	var Pos = _find_player(array)
	var Pos = actor.Loc
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
	actor.Loc += dir
	return a

# yield(get_tree(), "idle_frame")
func _move_actors(array, dir):
	var a = array
	for Actor in actors:
		if Actor.Turns == 0:
			continue
		if Actor.Behav == "Player":
			a = _move_player(a, dir, Actor)
#			actor.Loc += dir
			Actor.Turns -= 1
			if Actor.Turns > 0:
#				actors.sort_custom(SortingActors, "sort_descending")
				return a
		elif Actor.Behav == "Random":
			var x = randi()%3-1
			var y = 0
			if x == 0:
				y = randi()%3-1
			var actorDir = Vector2(x,y)
			print(actorDir)
#					var actorDir = Vector2(-1,0)
			var actorLoc = Actor.Loc + actorDir
			if actorLoc.y > (a.size()-1) or actorLoc.x > (a.size()-1):
				continue
			var Dest = a[actorLoc.y][actorLoc.x]
			if Dest in ENTITIES:
				var targetIndex = 0
				for targetActor in actors:
					if targetActor.Char == Dest and targetActor.Loc == actorLoc and not targetActor.Char == Actor.Char:
						targetActor.HP -= Actor.DMG
						if targetActor.HP < 1:
							if targetActor.Char == "@":
								$VSplitContainer/StatusLabel.text = "You are slain."
							actors.remove(targetIndex)
							a[actorLoc.y][actorLoc.x] = "%"
							break
						if targetActor.Char == "@":
							$VSplitContainer/StatusLabel.text = "You got hit for " + str(Actor.DMG) + " DMG!"
							$NotificationTimer.start()
					targetIndex += 1
				pass
			if Dest in COLLIDES or Dest in ENTITIES or Dest in INTERACTS:
				continue
			else:
				a[Actor.Loc.y][Actor.Loc.x] = " "
				a[actorLoc.y][actorLoc.x] = Actor.Char
				Actor.Loc = actorLoc
				Actor.Turns -= 1
				if Actor.Turns > 0:
#					actors.sort_custom(SortingActors, "sort_descending")
					print(actors)
	return a


func _reset_actor_turns():
	for actor in actors:
		actor.Turns = actor.Speed

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
		var I = item
		I.Char = "Y"
		inv.append(I)
		print(inv)
		$VSplitContainer/StatusLabel.text = "Grabbed a key."
		$NotificationTimer.start()
	elif type == "D":
		var result = _find_and_use_item("Y")
		if result:
			a[loc.y][loc.x] = " "
#		var index = 0
#		for spot in inv:
#			if spot == "Y":
#				inv.remove(index)
#				a[loc.y][loc.x] = " "
#			index += 1
	elif type in ENTITIES:
		if _handle_damage_from_player(type, loc):
			a[loc.y][loc.x] = "%"
			var actorIndex = 0
			for actor in actors:
				if actor.Char == type and actor.Loc == loc:
					actors.remove(actorIndex)
					break
				actorIndex += 1
	return a
	pass

# true if dead otherwise false
func _handle_damage_from_player(targetChar, targetLoc) -> bool:
	var DMG = 0
	for actor in actors:
		if actor.Behav == "Player":
			DMG = actor.DMG
			break
	for actor in actors:
		if actor.Char == targetChar and actor.Loc == targetLoc:
			actor.HP -= DMG
			$VSplitContainer/StatusLabel.text = "You deal " + str(DMG) + " DMG to " + str(targetChar)
			$NotificationTimer.start()
			if actor.HP < 1:
				return true
			break
	return false


func _find_and_use_item(Item):
	var spotIndex = 0
	for spot in inv:
		if typeof(spot) == 18:
			if "Char" in spot and "Uses" in spot:
				if spot.Char == Item:
#					print("OK!")
					spot.Uses -= 1
					if spot.Uses == 0:
						inv.remove(spotIndex)
						print(inv)
					return true
					
					
		spotIndex += 1
	# If item not found
	return false
	

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
	actors.clear()
	_actors_init(game_array)
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
		return
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
