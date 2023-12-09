# Warning: F You lose at X.
extends Node

# Major, Minor, Patch
var version = [0, 19, 0, "-alpha"]
# Godot 4 Version, MP3 Support

# Future ideas - Friendly or neutral mobs, ghosts (spawn in reused rooms where player died), Pets

@onready var levelLabel : Label = $VSplitContainer/VSplitContainer/LevelLabel
@onready var statusLabel = $VSplitContainer/StatusLabel
@onready var notiTimer = $NotificationTimer
@onready var textEdit = $TextEdit

# tts
var voice = DisplayServer.tts_get_voices_for_language("en")

var currentRoom = 0
var levelChange = false
var waiting = false
# waitingOn: can be, Start, Quit, Inventory, Help, Look, or Tile Help
var waitingOn = ""
var alreadyLooking = false
var frozenInputs = false
var levelDiff = 0
var resetting = false
var restarting = false
var escaping = false
var isDarkMode = false
var pageSelect = false
var firing = false
var opposite = false
var lookLocation = Vector2.ZERO
var oldLook = ""
var currentPageShown = 1
var numOfPages = 0
var notificationType = "status"
var msgOfFinality = ""

var save_vars = ["Player", "CurrentRoom", "Rooms", "Scoring"]
var autosaveLoc = "user://autosaveDUBD.tres"
@export var game_save_class := GDScript

var Rooms = []

const RoomsStore = ["""
#############
#@         x#
#        n Y#
##D##########
#<r        >#
#############
""",
"""
#############
#OY#      #O#
# ##     L# #
#@ D      D #
#############
"""]

var game_array := []
var temp_game_array := []

# ">" - Down Stair*, "<" - Up Stair*, "Y" - Door Key*, "y" - Chest Key*, "D" - Door*, "K" - Skeleton Key*, "%" - Body*, "+" - Healing Potion*, "c" - Chest, "*" - Secret
const INTERACTS = [">", "<", "Y", "y", "D", "K", "%", "+", "c", "-", "*"]
# "#" - Wall*, "D" - Locked Door*, "X" - Old Wall*, "*" - Secret
const COLLIDES = ["#", "D", "X", "*"]
# "r" - Rat*, "n" - DiNgo*, "k" - Kobold, "g" - Goblin, "L" - Lich, "@" - Player*, "x" - Crate*, "c": Chest
const ENTITIES = ["r", "n", "k", "g", "L", "@", "x", "c"]

const ALL = {"#": "Wall"," ": "Floor", ".": "You walked here",
# Interacts
">": "Down Stair", "<": "Up Stair", "Y": "Door Key", "y": "Chest Key", "D": "a locked door", "K": "Skeleton3D Key", "%": "Body", "+": "Healing Potion", "c": "Chest",
# Entities
"r": "Rat", "n": "Dingo", "k": "Kobold", "g": "Goblin", "L": "Lich", "@": "You.", "x": "Crate",
# Weapons
"T": "Sword", "S": "Whip", "Z": "Scroll", "V": "Shovel", "E": "Trident",
# Ranged
"B": "Bow"
}

const ENTITIES_DEFINES = {
"Rat": {"Speed": 2, "Turns": 2, "Loc": Vector2.ZERO, "HP": 1, "DMG": 1, "Char": "r", "Behav": "Random", "Inv": [], "bodyDesc": "rat", "Relation": "Rats"},
"Dingo": {"Speed": 3, "Turns": 2, "Loc": Vector2.ZERO, "HP": 1, "DMG": 2, "Char": "n", "Behav": "Hungry", "Inv": [], "bodyDesc": "dingo", "Relation": "Dingos"},
"Crate": {"Speed": 0, "Turns": 0, "Loc": Vector2.ZERO, "HP": 3, "DMG": 0, "Char": "x", "Behav": "Still", "Inv": [], "bodyDesc": "crate", "Relation": "None"},
"Goblin": {"Speed": 1, "Turns": 1, "Loc": Vector2.ZERO, "HP": 2, "DMG": 0, "Char": "g", "Behav": "HunterGather", "Inv": [], "bodyDesc": "goblin", "Relation": "Goblin"},
"Kobold": {"Speed": 2, "Turns": 2, "Loc": Vector2.ZERO, "HP": 2, "DMG": 1, "Char": "k", "Behav": "Scavenger", "Inv": [], "bodyDesc": "kobold", "Relation": "Kobold"},
"Arrow": {"Speed": 3, "Turns":2, "Loc": Vector2.ZERO, "Dir": Vector2.ZERO, "HP": 1, "DMG": 1, "Char": "-", "Behav": "OnTrajectory", "Inv": [], "bodyDesc": "broken shaft", "Relation": "Projectile"}
}

const ENTITIES_HOSTILES = ["Rats", "Dingos", "Goblin", "Kobold", "Projectile"]
	
# "T" - Sword, "S" - Whip, "Z" - Scroll, "V" - Shovel (tunnel walls, 2 dmg), "B" - Bow (range 6, 1dmg), "E" - Trident
const WEAPONS = ["T", "S", "Z", "V", "B", "E"]
# Ranged - "B" - Bow
const RANGED = ["B"]

#const WEAPONS_DEFINES = {
#	"Sword": {"Char": "T", "Uses": 12, "Type": ""},
#	"Whip": {"Char": "S", "Uses": 18}
#}
# "O" - Shield, "P" - Platemail, "B" - Boots
const ARMORS = ["O", "P", "B"]
# "-" - Arrow
const PROJECTILES = ["-"]

var item = {"Char": "", "Uses": 1, "Type": "Normal", "Value": 0}
var scrollUse = ""

var actors = []
var being = {"Speed": 1, "Turns": 1, "Loc": Vector2.ZERO, "HP": 1, "DMG": 2, "Char": "", "Behav": "Random", "Inv": [], "bodyDesc": "", "Relation": "None"}
var player = {"Speed": 1, "Turns": 1, "Loc": Vector2.ZERO, "HP": 4, "DMG": 1, "Char": "@", "Behav": "Player", "Inv": [], "bodyDesc": "dead you", "Relation": "Self"}
var playerOrig = {}
var scoring = {"Kills": "", "Steps": 0, "Time (s)": 0.0}
var scoringOrig = {"Kills": "", "Steps": 0, "Time (s)": 0.0}
var scoringVars = ["Kills", "Steps", "Time (s)"]
var scoringTimer = true
var is_muted = false

var corpses = []
var body = {"Loc": Vector2.ZERO, "Inv": [], "Desc": ""}

func _ready():
	randomize()
	get_tree().connect("files_dropped", Callable(self, "_files_dropped"))
	playerOrig = player.duplicate(true)
#	First start without autosave
	if not load_game(autosaveLoc):
		levelChange = false
		Rooms.append(RoomsStore[0])
		if Rooms.size() < currentRoom:
			for x in range((currentRoom+1)-Rooms.size()):
				Rooms.append(RoomsStore[0])
		print(Rooms.size())
		game_array = _get_text_as_array(Rooms[0])
		_actors_init(game_array)
		scoring = scoringOrig.duplicate(true)
		save_game(autosaveLoc)
		levelLabel.text = "You are hunting L on floor X,\n do not fail us! \nPress F1 or question mark for help!"
		if not is_muted:
			DisplayServer.tts_speak("You are hunting L on floor X,\n do not fail us! \nPress F1 or question mark for help!", voice[0])
		statusLabel.text = "Press Anything."
		if not is_muted:
			DisplayServer.tts_speak("Press Anything.", voice[0])
		waitingOn = "Start"
	else:
#		Reload autosave
		game_array = _get_text_as_array(Rooms[currentRoom])
#		var mine = _return_array_to_text(game_array)
#		_stack_alike_strings(mine)
		var yindex = 0
		var xindex = 0
		for y in game_array:
			for x in y:
				print(x + " : " + str(xindex) + ", " + str(yindex))
				xindex += 1
			xindex = 0
			yindex += 1
		_actors_init(game_array)
		waiting = true
		waitingOn = "Start"
		levelLabel.text = "You returned!\n You still hunt L on floor X.\n  Currently on: " + str(currentRoom+1) + "\nPress F1 or question mark for help!"
		statusLabel.text = "Press Anything."
		if not is_muted:
			DisplayServer.tts_speak("You returned!\n You still hunt L on floor X.\n  Currently on: " + str(currentRoom+1) + "\nPress F1 or question mark for help!\nPress anything.", voice[0])
		
	
class SortingActors:
	static func sort_descending(a,b):
		if a.Turns > b.Turns:
			return true
		return false
	
func _actors_init(array):
	for y in range(array.size()):
		for x in range(array[y].size()):
			if array[y][x] in ENTITIES:
				_being_init(Vector2(x,y),array[y][x])
	if actors.size() > 1:
		actors.sort_custom(Callable(SortingActors, "sort_descending"))
		Globals.emit_signal("init_automatons_for_data_sound", actors, Vector2(game_array[0].size(), game_array.size()))
#		$CellMusicChatGPT3.init_automatons(actors,Vector2(game_array[0].size(), game_array.size()))
	print(actors)
	
# TODO
# Possibilites Here, iterate through ENTITIES_DEFINES or a match
# If found in entities, add to array
func _being_init(Loc, Char):
	var Being = being.duplicate(true)
	if Char == "r":
		Being = ENTITIES_DEFINES.Rat.duplicate(true)
	elif Char == "n":
		Being = ENTITIES_DEFINES.Dingo.duplicate(true)
	elif Char == "@":
		player.Loc = Loc
		actors.append(player)
		print(player)
		return
	elif Char == "x":
		Being = ENTITIES_DEFINES.Crate.duplicate(true)
	elif Char == "g":
		Being = ENTITIES_DEFINES.Goblin.duplicate(true)
	elif Char == "k":
		Being = ENTITIES_DEFINES.Kobold.duplicate(true)
	else:
		return
	## Should happen if in if elif group
	Being.Loc = Loc
	Being.Char = Char
	_spawn_item_inside_container(Being.Inv,Char)
	print(Being)
	actors.append(Being)
#	print(actors)
	
func _input(event):
#	Everything that causes input to be ignored
	if event is InputEventMouseMotion or (waiting and waitingOn == "Quit"):
		return
	var dir = Vector2(event.get_action_strength("move_right") - event.get_action_strength("move_left"), event.get_action_strength("move_down") - event.get_action_strength("move_up"))
	print(event.as_text())
#	print(escaping)
	if event.is_action_pressed("escape"):
		if waiting and waitingOn == "Inventory" or waitingOn == "Help" or waitingOn == "Look" or waitingOn == "Examination":
			if waitingOn == "Look" or waitingOn == "Examination":
				temp_game_array.clear()
				alreadyLooking = false
			_display_array(game_array)
			_status_bar_update()
			waiting = false
			waitingOn = ""
			return
		statusLabel.text = "Escape again to quit."
		DisplayServer.tts_speak(statusLabel.text, voice[0])
		if escaping:
			if OS.get_name() == "HTML5":
				levelLabel.text = ""
				statusLabel.text = "Game quit."
				if not is_muted:
					DisplayServer.tts_speak("Game quit, goodbye!", voice[0])
				waiting = true
				waitingOn = "Quit"
			else:
				get_tree().quit(0)
		escaping = true
		return
	if event.is_action_pressed("mute"):
		var master_sound = AudioServer.get_bus_index("Master")
		var isMusicOn = !AudioServer.is_bus_mute(master_sound)
		AudioServer.set_bus_mute(master_sound,isMusicOn)
		is_muted = !is_muted
	if event.is_action_pressed("look_while_level_editing") and textEdit.visible:
		if is_muted:
			print("Muted.")
		else:
			DisplayServer.tts_speak(_stack_alike_strings(textEdit.text), voice[0])
			return
	if waitingOn == "Examination" and dir:
		waitingOn = "Look"
	if waitingOn == "Look" and event.is_pressed():
		_handle_look(event, dir)
		return
	if event.is_action_pressed("look") and not alreadyLooking:
		waitingOn = "Look"
		waiting = true
		lookLocation = player["Loc"]
		temp_game_array = game_array.duplicate(true)
		if not is_muted:
			DisplayServer.tts_speak("You begin looking around, press escape to cancel.", voice[0])
		_handle_look(event, Vector2.ZERO)
		oldLook = "@"
		alreadyLooking = true
		return
	if event.is_action_pressed("enter_level_editor") and not waitingOn:
		$VSplitContainer.visible = opposite
		opposite = !opposite
		frozenInputs = opposite
		textEdit.visible = opposite
#		Copy current level to editor
		if textEdit.visible:
			if not is_muted:
				DisplayServer.tts_speak("Now level editing.", voice[0])
			textEdit.grab_focus()
			textEdit.text = ""
			textEdit.text = levelLabel.text
			if not game_array:
				textEdit.text = ""
			return
		else:
			levelLabel.grab_focus()
			DisplayServer.tts_speak("No longer editing.", voice[0], 50, 1.0, 1.0, 0, true)
	if event.is_action_released("ui_move") and textEdit.visible:
		var loc = Vector2(textEdit.get_caret_line(),textEdit.get_caret_column())
#		var line = textEdit.get_word_under_cursor()
		var line = textEdit.get_line(loc.x)
		print(str(loc)+" "+line)
		if not is_muted:
			DisplayServer.tts_speak(str(loc)+" "+ line,voice[0],50,1.0,1.0,0,true)
	if event.is_action_pressed("save_level") and textEdit.visible:
#		Save level and present
		var take = _clean_pasted_text(textEdit.text)
		print(take)
		if not take:
			return
		if not levelChange:
			Rooms[currentRoom] = take
		else:
			Rooms.append(take)
		_change_level()
		$VSplitContainer.visible = opposite
		opposite = !opposite
		frozenInputs = opposite
		textEdit.visible = opposite
		return
	if (waiting and pageSelect) and (event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up")):
		if event.is_action_pressed("ui_page_down"):
			if currentPageShown == numOfPages:
				_show_inv(currentPageShown)
			else:
				_show_inv(currentPageShown + 1)
			return
		if event.is_action_pressed("ui_page_up"):
			if currentPageShown == 1:
				_show_inv(1)
			else:
				_show_inv(currentPageShown - 1)
		return
	elif (waiting and waitingOn == "Help" or waitingOn == "Tile Help") and (event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up")):
		if event.is_action_pressed("ui_page_down"):
			if currentPageShown == numOfPages:
				_show_help(currentPageShown)
				return
			else:
				_show_help(currentPageShown + 1)
			return
		if event.is_action_pressed("ui_page_up"):
			if currentPageShown == 1:
				_show_help(currentPageShown)
				return
			else:
				_show_help(currentPageShown - 1)
		return
	if waitingOn == "Examination":
		return
#	if event is InputEventKey and event.scancode == KEY_SHIFT:
#		print("shift")
#	print(_get_text_as_array(OS.clipboard))
#	Ignores inputs past essential ones
	if frozenInputs:
		return
	if event.is_action_pressed("help"):
		waiting = true
		waitingOn = "Help"
		print(waitingOn)
		currentPageShown = 1
#		Update with pages
		numOfPages = 5
		_show_help(currentPageShown)
		return
	if event.is_action_pressed("tile_help"):
		waiting = true
		waitingOn = "Tile Help"
		print(waitingOn)
		currentPageShown = 1
#		Update with tiles pages
		numOfPages = 4
		_show_help(currentPageShown)
		return
#	All waits before here
	if waiting and event.is_pressed():
		alreadyLooking = false
		pageSelect = false
		waiting = false
		waitingOn = ""
		_display_array(game_array)
		_status_bar_update()
		return
	if escaping and event.is_pressed():
		_status_bar_update()
		escaping = false
	elif firing and event.is_pressed():
		var fireDir = Vector2(event.get_action_strength("fire_right") - event.get_action_strength("fire_left"), event.get_action_strength("fire_down") - event.get_action_strength("fire_up"))
		print(fireDir)
		if not fireDir and _handle_move_input(event, dir):
			firing = false
			statusLabel.text = "Firing canceled."
			if not is_muted:
				DisplayServer.tts_speak("Firing canceled.", voice[0])
			notiTimer.start()
		print("FIRE")
		if Input.is_key_pressed(16777359):
			_fireBow(player, 9)		
		if event.is_action_pressed("fire_up"):
			_fireBow(player, 8)		
		if Input.is_key_pressed(16777357):
			_fireBow(player, 7)		
		if event.is_action_pressed("fire_right"):
			_fireBow(player, 6)		
		if Input.is_key_pressed(16777355):
			_fireBow(player, 5)		
		if event.is_action_pressed("fire_left"):
			_fireBow(player, 4)		
		if Input.is_key_pressed(16777353):
			_fireBow(player, 3)		
		if event.is_action_pressed("fire_down"):
			_fireBow(player, 2)		
		if Input.is_key_pressed(16777351):
			_fireBow(player, 1)
		return
	elif event.is_action_pressed("paste") and DisplayServer.clipboard_get():
		var take = DisplayServer.clipboard_get()
		print(take)
		take = _clean_pasted_text(take)
		print(take)
		if not take:
			return
		if not levelChange:
			Rooms[currentRoom] = take
		else:
			Rooms.append(take)
		_change_level()
		return
	if event.is_action_pressed("version_display"):
		statusLabel.text = "v " + str(version[0]) + "." + str(version[1]) + "." + str(version[2]) + version[3]
		if not is_muted:
			DisplayServer.tts_speak("Version" + str(version[0]) + "." + str(version[1]) + "." + str(version[2]) + version[3], voice[0])
		notiTimer.start()
		return
	elif event.is_action_pressed("dark_mode"):
		if !isDarkMode:
			var color = Color8(25,7,48)
			RenderingServer.set_default_clear_color(color)
			isDarkMode = true
			return
		else:
			var color = Color8(218,122,138)
			RenderingServer.set_default_clear_color(color)
			isDarkMode = false
			return
	elif event.is_action_pressed("restart"):
		if restarting:
			# Delete autosave and start anew
			delete_save(autosaveLoc)
			await _show_save_deletion()
			start_over()
			restarting = false
			return
		else:
			levelLabel.text = "Press `Shift` + `r` again to restart!\nThis will delete all progress!"
			if not is_muted:
				DisplayServer.tts_speak("Press `Shift` + `r` again to restart!\nThis will delete all progress!", voice[0])
			statusLabel.text = "In restart mode."
			restarting = true
			if not is_muted:
				DisplayServer.tts_speak("In restart mode.", voice[0])
	elif event.is_action_pressed("reset"):
		if resetting:
			# Load from last autosave (should be made when files inserted or level changed.)
			resetting = false
			if load_game(autosaveLoc):
				print("Game Reset!")
				_change_level()
			pass
		else:
			levelLabel.text = "Press 'r' again to reset!"
			if not is_muted:	
				DisplayServer.tts_speak("Press 'r' again to reset!", voice[0])
			statusLabel.text = "In reset mode."
			resetting = true
			if not is_muted:
				DisplayServer.tts_speak("In reset mode.", voice[0])
		pass
	elif resetting and event.is_pressed():
		resetting = false
		_display_array(game_array)
		statusLabel.text = "Cancelled the reset."
		if not is_muted:
			DisplayServer.tts_speak("Cancelled the reset.", voice[0])
		notiTimer.start()
#		_status_bar_update()
		return
	elif restarting and event.is_pressed() and event is InputEventKey and not event.keycode == KEY_SHIFT:
		restarting = false
		_display_array(game_array)
		statusLabel.text = "Didn't restart."
		if not is_muted:
			DisplayServer.tts_speak("Game didn't restart.", voice[0])
		notiTimer.start()
		return
	elif event.is_action_pressed("inventory"):
		currentPageShown = 1
		_show_inv(currentPageShown)
	elif event.is_action_pressed("heal"):
		if _find_and_use_item("+", player):
			statusLabel.text = "You heal to " + str(player.HP) + "."
			if not is_muted:	
				DisplayServer.tts_speak("You heal to " + str(player.HP) + ".", voice[0])
		else:
			statusLabel.text = "No healing in inventory!"
			if not is_muted:
				DisplayServer.tts_speak("No way to heal in inventory.", voice[0])
		notiTimer.start()
	elif event.is_action_pressed("use_scroll"):
		if _find_and_use_item("Z", player):
			if scrollUse == "Lightning":
				print("Lightning used start!")
				var targetActor = {}
				var closestDistance = 100
				var actorIndex = 0
				var finalActorIndex = 0
				for actor in actors:
#					print(actor)
					var skip = false
					for relation in ENTITIES_HOSTILES:
						if actor.Relation == relation:
							skip = false
							break
						else:
							skip = true
					if skip:
						continue
					var distance = get_distance(player.Loc, actor.Loc)
					if distance < closestDistance:
						targetActor = actor
						closestDistance = distance
						finalActorIndex = actorIndex
					actorIndex += 1
				if targetActor:
					targetActor.HP -= 5
					statusLabel.text = "Lightning strikes " + targetActor.Char + " for 5 DMG."
					if not is_muted:
						DisplayServer.tts_speak("Lightning strikes " + targetActor.Char + " for 5 damage.", voice[0])
					notiTimer.start()
					if targetActor.HP < 1:
						var a = game_array
						a[targetActor.Loc.y][targetActor.Loc.x] = "%"
						_display_array(a)
						_add_corpse(targetActor)
				else:
					statusLabel.text = "Lightning misses."
					if not is_muted:
						DisplayServer.tts_speak("Lightning misses.", voice[0])
					notiTimer.start()
			scrollUse = ""
	elif event.is_action_pressed("fire"):
		var test = false
		for item in RANGED:
			if _find_item(item, player):
				test = true
				break
		if test == false:
			statusLabel.text = "No ranged weapon!"
			if not is_muted:
				DisplayServer.tts_speak("No ranged weapon!", voice[0])
			notiTimer.start()
			return
		firing = true
		print(firing)
		statusLabel.text = "Numpad to fire!"
		if not is_muted:
			DisplayServer.tts_speak("Numpad to fire!", voice[0])
#			var targetActor = {}
#			var closestDistance = 100
#			var actorIndex = 0
#			var finalActorIndex = 0
#			for actor in actors:
#				var skip = false
#				for relation in ENTITIES_HOSTILES:
#					if actor.Relation == relation:
#						break
#					else:
#						skip = true
#				if skip:
#					continue
#				var distance = get_distance(player.Loc, actor.Loc)
#				if distance < closestDistance:
#					targetActor = actor
#					closestDistance = distance
#					finalActorIndex = actorIndex
#				actorIndex += 1
	if not game_array:
		if event.is_pressed():
			var index = 0
			for room in Rooms:
				if index == currentRoom:
					_change_level()
					return
				index += 1
			if currentRoom > -1:
				levelLabel.text = "Press '~' or 'L' to enter level editor (Ctrl+S to save), or drag'n'drop or copy'n'paste a level in!"
				if OS.get_name() == "HTML5":
					levelLabel.text += " On web you may need to use the browser's Edit -> Paste."
				if not is_muted:
					DisplayServer.tts_speak(levelLabel.text, voice[0])
				statusLabel.text = "World is empty."
				if not is_muted:
					DisplayServer.tts_speak("World is empty.", voice[0])
				notiTimer.start()
		return
	if not waitingOn:
		_handle_move_input(event, dir)
	if waitingOn == "Start":
		waitingOn = ""
		waiting = false


func _physics_process(delta):
	if scoringTimer:
		scoring["Time (s)"] += delta

func verify_save(save):
	if not save:
		return false
	var size = 0
	var currentRoom = 0
	for v in save_vars:
		var inside = save.get(v)
		print(v)
		print(inside)
		if inside == null:
			return false
		if v == "Rooms":
			size = inside.size()
		elif v == "CurrentRoom":
			currentRoom = inside
		elif v == "Scoring":
#			var insideScoring = save["Scoring"]
			if scoringVars.size() != inside.size():
				return false
			if not inside.has_all(scoringVars):
				return false
			pass
	if size < (currentRoom + 1):
		print("Not enough rooms in save!")
		return false
	return true


func save_game(loc):
	var new_save = game_save_class.new()
	new_save.Player = player
	new_save.CurrentRoom = currentRoom
	new_save.Rooms = Rooms
	new_save.Scoring = scoring.duplicate(true)
	print(new_save.Scoring)
	var error = ResourceSaver.save(new_save, loc)
	if error != 0:
		print("Error saving!")
		print(error)


func load_game(loc) -> bool:
	var dir = DirAccess.open(loc)
	if not dir:
		print("save not found!")
		return false
	
	var loaded_save = load(loc)
	if not verify_save(loaded_save):
		print("verify failed!")
		return false
		
	player = loaded_save.Player
	currentRoom = loaded_save.CurrentRoom
	Rooms = loaded_save.Rooms
	scoring = loaded_save.Scoring.duplicate(true)
	
	return true


func delete_save(loc) -> bool:
	var dir = DirAccess.open(loc)
	if not dir:
		print("save not found!")
		return false
		
	var result = dir.remove(loc)
	if result == 0:
		return true
	else:
		return false


func _show_save_deletion() -> void:
#	var text = ""
	var store = ""
	for x in range(24):
		var text = ""
		for y in range(6):
			text += store
			if y < 6:
				text += "\n"
		levelLabel.text = text
		await get_tree().create_timer(0.1).timeout
		store += "X"
	return
	

func start_over():
	Rooms.clear()
	Rooms.append(RoomsStore[0])
	player = playerOrig.duplicate(true)
	currentRoom = 0
	actors.clear()
	corpses.clear()
	game_array = _get_text_as_array(Rooms[0])
	_actors_init(game_array)
	scoring = scoringOrig.duplicate(true)
	save_game(autosaveLoc)
	levelLabel.text = "You are hunting L on floor X,\n do not fail us!" + "\nPress F1 or question mark for help!"
	waiting = true
	waitingOn = "Start"
	statusLabel.text = "Press Anything"
	if not is_muted:
		DisplayServer.tts_speak("You are hunting L on floor X,\n do not fail us!" + "\nPress F1 or question mark for help!", voice[0])
	
func _process_turn(array, dir):
#	var a = _move_player(array, dir)
#	Handle Projectiles

#	Handle Enemies
	var A = _move_actors(array, dir)
	_reset_actor_turns()
	if msgOfFinality:
		if not is_muted:
			DisplayServer.tts_speak("You are slain.", voice[0])
		msgOfFinality = ""
	await get_tree().process_frame
	game_array = A.duplicate()
	if not levelChange:
		_display_array(game_array)
	else:
		game_array.clear()
		if currentRoom == 9:
			_change_level()
			levelLabel.text = "You arrive at a most dark arena!"
			notificationType = "level"
			$NotificationTimer.start()
			return
		if levelDiff == 1:
			levelLabel.text = "You walk downstairs."
		elif levelDiff == -1:
			levelLabel.text = "You walk upstairs."
			if currentRoom == -1:
#				levelLabel.text += "\nYou leave the dungeon."
				levelLabel.text += "\nScores:\n" + "Time: " + str(scoring['Time (s)']) + "\nSteps: " + str(scoring.Steps) + "\nKills:\n" + str(scoring.Kills)
		if not is_muted:
			DisplayServer.tts_speak(levelLabel.text, voice[0])
	
func _handle_look(event, dir):
	var TTStext = ""
	lookLocation += dir
	if alreadyLooking and event.is_action_pressed("look"):
		_handle_examine(lookLocation)
		return
	if lookLocation.x < 0 or lookLocation.x > temp_game_array[0].size() - 1 or lookLocation.y < 0 or lookLocation.y >temp_game_array.size() - 1:
		statusLabel.text + "You see: " + "the bounds."
		if not is_muted:
			DisplayServer.tts_speak("You see: " + "the bounds.", voice[0])
		lookLocation -= dir
		notificationType = "status"
		notiTimer.start()
		return
	print(temp_game_array[lookLocation.y][lookLocation.x])
	if temp_game_array[lookLocation.y][lookLocation.x] in ALL.keys():
		statusLabel.text = "You see: " +  str(ALL[temp_game_array[lookLocation.y][lookLocation.x]])
		TTStext = str("You look and see: "+ALL[temp_game_array[lookLocation.y][lookLocation.x]]+" @ "+str(Vector2(lookLocation.x,lookLocation.y)))
	else:
		statusLabel.text = "You can't _recognize that."
		TTStext = "You can't _recognize that."
	temp_game_array[lookLocation.y-dir.y][lookLocation.x-dir.x] = oldLook
	if temp_game_array[lookLocation.y-dir.y][lookLocation.x-dir.x] == "":
		temp_game_array[lookLocation.y-dir.y][lookLocation.x-dir.x] = " "
	notificationType = "status"
	notiTimer.start()
	oldLook = temp_game_array[lookLocation.y][lookLocation.x]
	temp_game_array[lookLocation.y][lookLocation.x] = "?"
	_display_array(temp_game_array)
	if not is_muted:
#		yield(tts,"utterance_end")
#		tts.stop()
#		yield(get_tree(),"idle_frame")
		DisplayServer.tts_speak(TTStext, voice[0])
		
# WORKING ON
func _handle_examine(dest:Vector2):
	var target = oldLook
#	IF PLAYER LOOKS AT SELF
	if target == "@":
		statusLabel.text = "Via own eyes, floor: " + str(currentRoom + 1)
		var text = _stack_alike_strings(_return_array_to_text(game_array))
		if not is_muted:
			DisplayServer.tts_speak((statusLabel.text+text), voice[0])
			pass
		pass
#	IF PLAYER LOOKS AT SOMETHING
	elif target in ENTITIES:
		for actor in actors:
			if actor.Char == target and actor.Loc == dest:
				levelLabel.text = str(actor)
				statusLabel.text = "Examining: " + actor.Char + " @ " + str(dest)
				waitingOn = "Examination"
				if not is_muted:
					DisplayServer.tts_stop()
					DisplayServer.tts_speak("You carefully examine this, " +str(actor),voice[0])
					pass
				break
		pass
#	HANDLE MORE THINGS
	pass


func _handle_move_input(event, dir) -> bool:
	if dir != Vector2.ZERO or event.is_action_pressed("wait"):
		_process_turn(game_array,dir)
		return true
	return false

# Edits the array and returns to _move_actors(), handles player centered actions
func _move_player(array, dir, actor) -> Array:
	scoring.Steps += 1
	if dir == Vector2.ZERO:
		print("You wait a minute.")
		statusLabel.text = "You wait a minute."
		if not is_muted:
			DisplayServer.tts_speak("You wait a minute.", voice[0])
		notiTimer.start()
		return array
#	var Pos = _find_player(array)
	var Pos = actor.Loc
	print("At ", Pos)
	var Loc = Pos + dir
	if Loc.x < 0 or Loc.x > array[0].size() - 1 or Loc.y < 0 or Loc.y > array.size() - 1:
		statusLabel.text = "You touch the bounds."
		if not is_muted:
			DisplayServer.tts_speak("You touch the bounds.", voice[0])
		notiTimer.start()
		return array
	print("To ", Loc)
	var Dest = array[Loc.y][Loc.x]
	var a = array
	if Dest in INTERACTS or Dest in ENTITIES:
		a = _handle_player_interaction(Dest, Loc, array)
	if Dest in COLLIDES or Dest in ENTITIES:
		if Dest in COLLIDES:
			statusLabel.text = "You feel: " + str(ALL[Dest])
			if not is_muted:
				DisplayServer.tts_speak("You feel: " + ALL[Dest], voice[0])
		return array
	if Dest in WEAPONS:
		_grab_weapon(Dest)
	if Dest in ARMORS:
		_grab_armor(Dest)
	
	a[Pos.y][Pos.x] = "."
	a[Loc.y][Loc.x] = "@"
	actor.Loc += dir
	if not is_muted:	
		DisplayServer.tts_speak(actor.Char + str(actor.Loc), voice[0])
#	yield(tts,"utterance_end")
#	tts.stop()
#	yield(get_tree(),"idle_frame")
	return a

# Needs rework into a nonloop to get yields working for speech
func _move_actors(array, dir) -> Array:
#	Duplicate here?
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
		elif Actor.Behav == "Still":
			continue
		elif Actor.Behav == "Hunter":
			continue
		elif Actor.Behav == "OnTrajectory":
			var actorLoc = Actor.Loc + Actor.Dir
			if actorLoc.x < 0 or actorLoc.x > array[0].size() - 1 or actorLoc.y < 0 or actorLoc.y > array.size() - 1:
				continue
			var Dest = a[actorLoc.y][actorLoc.x]
			if Dest in COLLIDES:
				print("Hits wall.")
				_add_corpse(Actor)
				a[Actor.Loc.y][Actor.Loc.x] = "%"
			elif Dest in ENTITIES:
				var targetIndex = 0
				for targetActor in actors:
					if targetActor.Char == Dest and targetActor.Loc == actorLoc:
						targetActor.HP -= Actor.DMG
						Actor.HP -= Actor.DMG
						if Actor.HP < 1:
							_add_corpse(Actor)
							a[Actor.Loc.y][Actor.Loc.x] = "%"
						if targetActor.HP < 1:
							if targetActor.Char == "@":
								statusLabel.text = "You are slain."
								msgOfFinality = "You are slain."
							_add_corpse(targetActor)
#							actors.pop_at(targetIndex)
							a[actorLoc.y][actorLoc.x] = "%"
							break
						if targetActor.Char == "@":
							statusLabel.text = "You got hit for " + str(Actor.DMG) + " DMG!"
							if not is_muted:	
								DisplayServer.tts_speak("You got hit for " + str(Actor.DMG) + " DMG!", voice[0])
#							yield(tts,"utterance_end")
#							tts.stop()
#							yield(get_tree(),"idle_frame")
							notiTimer.start()
							break
					targetIndex += 1
			elif Dest in COLLIDES or Dest in ENTITIES or Dest in WEAPONS or Dest in PROJECTILES or Dest in ARMORS:
				print("Hits object.")
				_add_corpse(Actor)
				a[Actor.Loc.y][Actor.Loc.x] = "%"
#				if not is_muted:
#					DisplayServer.tts_speak(Actor.Char + " hit by arrow, dies @ " + Actor.Loc)
#				yield(tts,"utterance_end")
#				tts.stop()
#				yield(get_tree(),"idle_frame")
			else:
				a[Actor.Loc.y][Actor.Loc.x] = " "
				a[actorLoc.y][actorLoc.x] = Actor.Char
				Actor.Loc = actorLoc
#				if not is_muted:
#					DisplayServer.tts_speak(Actor.Char + str(Actor.Loc))
#				yield(tts,"utterance_end")
#				tts.stop()
#				yield(get_tree(),"idle_frame")
				Actor.Turns -= 1
		elif Actor.Behav == "Hungry":
			var actorDir = Vector2.ZERO
			print("A Hungry One At: " + str(Actor.Loc))
			print(corpses.size())
			if corpses.size() > 0:
				print("Hunger for corpses.")
				var distance = 100
				var finalCorpse = {}
				for corpse in corpses:
					var checkDistance = get_distance(Actor.Loc,corpse.Loc)
					if checkDistance < distance:
						distance = checkDistance
						finalCorpse = corpse
				actorDir = Vector2(clamp(finalCorpse.Loc.x-Actor.Loc.x,-1,1),clamp(finalCorpse.Loc.y-Actor.Loc.y,-1,1))
			else:
				print("Hunger for actors.")
				var distance = 100
				var finalActor = {}
				for actor in actors:
					if actor.Relation != "Dingos":
						var checkDistance = get_distance(Actor.Loc,actor.Loc)
						if checkDistance < distance:
							distance = checkDistance
							finalActor = actor
				print(finalActor.Loc)
				print(Actor.Loc)
				actorDir = Vector2(clamp(finalActor.Loc.x-Actor.Loc.x,-1,1), clamp(finalActor.Loc.y-Actor.Loc.y,-1,1))
				print(actorDir)
			var actorLoc = Actor.Loc + actorDir
			print("Hungry One To: " + str(actorLoc))
			var Dest = a[actorLoc.y][actorLoc.x]
			if Dest in ENTITIES:
				var targetIndex = 0
				for targetActor in actors:
					if targetActor.Char == Actor.Char:
						targetIndex += 1
						continue
					if targetActor.Char == Dest and targetActor.Loc == actorLoc:
						targetActor.HP -= Actor.DMG
						if targetActor.HP < 1:
							if targetActor.Char == "@":
								statusLabel.text = "You are slain."
								msgOfFinality = "You are slain."
							_add_corpse(targetActor)
#							actors.pop_at(targetIndex)
							a[actorLoc.y][actorLoc.x] = "%"
#							if not is_muted:
#								DisplayServer.tts_speak(Actor.Char + " dies.")
#							yield(tts,"utterance_end")
#							tts.stop()
#							yield(get_tree(),"idle_frame")
							break
						if targetActor.Char == "@":
							statusLabel.text = "You got hit for " + str(Actor.DMG) + " DMG!"
							if not is_muted:
								DisplayServer.tts_speak("You got hit for " + str(Actor.DMG) + " DMG!", voice[0])
#							yield(tts,"utterance_end")
#							tts.stop()
#							yield(get_tree(),"idle_frame")
							notiTimer.start()
							break
					targetIndex += 1
			if Dest in INTERACTS:
				if _handle_actor_interaction(Actor,Dest,actorLoc):
					continue
			if Dest in COLLIDES or Dest in ENTITIES:
				continue
			else:
				a[Actor.Loc.y][Actor.Loc.x] = " "
				a[actorLoc.y][actorLoc.x] = Actor.Char
				Actor.Loc = actorLoc
#				if not is_muted:
#					DisplayServer.tts_speak(Actor.Char + str(Actor.Loc))
#				yield(tts,"utterance_end")
#				tts.stop()
#				yield(get_tree(),"idle_frame")
				Actor.Turns -= 1
		elif Actor.Behav == "Random":
			var x = randi()%3-1
			var y = 0
			if x == 0:
				y = randi()%3-1
			var actorDir = Vector2(x,y)
			print(actorDir)
#					var actorDir = Vector2(-1,0)
			var actorLoc = Actor.Loc + actorDir
			if actorLoc.x < 0 or actorLoc.x > array[0].size() - 1 or actorLoc.y < 0 or actorLoc.y > array.size() - 1:
				continue
			var Dest = a[actorLoc.y][actorLoc.x]
			if Dest in ENTITIES:
				var targetIndex = 0
				for targetActor in actors:
					if (targetActor.Char == Actor.Char or targetActor.Relation == Actor.Relation) and targetActor.Char == Dest:
						break
					if targetActor.Char == Actor.Char or targetActor.Relation == Actor.Relation:
						targetIndex += 1
						continue
					if targetActor.Char == Dest and targetActor.Loc == actorLoc:
						targetActor.HP -= Actor.DMG
						if targetActor.HP < 1:
							if targetActor.Char == "@":
								statusLabel.text = "You are slain."
								msgOfFinality = "You are slain."
							_add_corpse(targetActor)
#							actors.pop_at(targetIndex)
							a[actorLoc.y][actorLoc.x] = "%"
							break
						if targetActor.Char == "@":
							statusLabel.text = "You got hit for " + str(Actor.DMG) + " DMG!"
							if not is_muted:
								DisplayServer.tts_speak("You got hit for " + str(Actor.DMG) + " DMG!", voice[0])
#							yield(tts,"utterance_end")
#							tts.stop()
#							yield(get_tree(),"idle_frame")
							notiTimer.start()
							break
					targetIndex += 1
				pass
			if Dest in INTERACTS:
				if _handle_actor_interaction(Actor,Dest, actorLoc):
					continue
			if Dest in COLLIDES or Dest in ENTITIES or Dest in WEAPONS or Dest in PROJECTILES or Dest in ARMORS:
				continue
			else:
				a[Actor.Loc.y][Actor.Loc.x] = " "
				a[actorLoc.y][actorLoc.x] = Actor.Char
				Actor.Loc = actorLoc
#				if not is_muted:
#					DisplayServer.tts_speak(Actor.Char + str(Actor.Loc))
#				yield(tts,"utterance_end")
#				tts.stop()
#				yield(get_tree(),"idle_frame")
				Actor.Turns -= 1
#				if Actor.Turns > 0:
#					actors.sort_custom(SortingActors, "sort_descending")
#					print(actors)
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


func get_distance(selfLoc:Vector2, targetLoc:Vector2):
	return sqrt(pow(selfLoc.x-targetLoc.x, 2) + pow(selfLoc.y-targetLoc.y,2))

func _handle_actor_interaction(actor, type, loc) -> bool:
	if actor.Char == "r":
		if type == "Y":
			var I = item.duplicate(false)
			I.Char = "Y"
			I.type = "door"
			actor.Inv.append(I)
			return false
		else:
			return true
	elif actor.Char == "n":
		if type == "%":
			for corpse in corpses:
				if loc == corpse.Loc:
					for item in corpse.Inv:
						actor.Inv.append(item)
					actor.Behav = "Random"
					return false
			return true
		else:
			return true
	else:
		return true


func _handle_player_interaction(type, loc, array):
	var a = array
	if type == ">":
		levelChange = true
		levelDiff = 1
		Rooms[currentRoom] = levelLabel.text
		currentRoom += 1
	elif type == "<":
		levelChange = true
		levelDiff = -1
		Rooms[currentRoom] = levelLabel.text
		currentRoom -= 1
	elif type == "Y":
		var I = item.duplicate(false)
		I.Char = "Y"
		I.Type = "door"
		_add_item_to_player_inv(I)
		print(player.Inv)
		statusLabel.text = "Grabbed a " + I.Type + " key."
		if not is_muted:
			DisplayServer.tts_speak("Grabbed a " + I.Type + " key.", voice[0])
		notiTimer.start()
	elif type == "y":
		var I = item.duplicate(false)
		I.Char = "y"
		I.Type = "chest"
		_add_item_to_player_inv(I)
		print(player.Inv)
		statusLabel.text = "Grabbed a " + I.Type + " key."
		if not is_muted:
			DisplayServer.tts_speak("Grabbed a " + I.Type + " key.", voice[0])
		notiTimer.start()
	elif type == "+":
		var I = item.duplicate(false)
		I.Char = "+"
		I.Type = "Lesser"
		I.Uses = 3
		I.Value = 1
		_add_item_to_player_inv(I)
		print(player.Inv)
		statusLabel.text = "Got a " + I.Type + " heal potion."
		if not is_muted:
			DisplayServer.tts_speak("Got a " + I.Type + " heal potion.", voice[0])
		notiTimer.start()
	elif type == "-":
		var I = item.duplicate(true)
		I.Char = "-"
		I.Uses = 6
		_add_item_to_player_inv(I)
		statusLabel.text = "Found " + str(I.Uses) + " ammo!"
		if not is_muted:
			DisplayServer.tts_speak("Found " + str(I.Uses) + " ammo!", voice[0])
		notiTimer.start()
	elif type == "c":
		var result = _find_and_use_item("y", player)
		if result:
			a[loc.y][loc.x] = " "
			var I = item.duplicate(true)
			I.Char = "B"
			I.Uses = 12
			I.Value = 2
			I.Type = "Long"
			_add_item_to_player_inv(I)
			statusLabel.text = "Looted Bow! Fire with X!"
			if not is_muted:
				DisplayServer.tts_speak("Looted Bow! Fire with X!", voice[0])
			notiTimer.start()
	elif type == "D":
		var result = _find_and_use_item("Y", player)
		if result:
			a[loc.y][loc.x] = " "
	elif type == "%":
		var bodyIndex = 0
		for Body in corpses:
			if Body.Loc == loc:
				var T = "You loot " + Body.Desc + ". For "
				if not Body.Inv:
					T += "nothing!"
				else:
					for item in Body.Inv:
						_add_item_to_player_inv(item)
						T += item.Char
				print(player.Inv)
				statusLabel.text = T
				if not is_muted:
					DisplayServer.tts_speak(T, voice[0])
				notiTimer.start()
				corpses.pop_at(bodyIndex)
			bodyIndex += 1
	elif type in ENTITIES:
		if _handle_damage_from_player(type, loc):
			a[loc.y][loc.x] = "%"
			for actor in actors:
				if actor.Char == type and actor.Loc == loc:
					_add_corpse(actor)
					scoring.Kills += actor.Char
	return a
	pass


func _grab_weapon(Char):
	match Char:
		"B":
			var I = item.duplicate(true)
			I.Char = "B"
			I.Uses = 6
			I.Value = 1
			I.Type = "Straight"
			_add_item_to_player_inv(I)
			statusLabel.text = "Looted Bow! Fire with X!"
			if not is_muted:
				DisplayServer.tts_speak("Looted Bow! Fire with X!", voice[0])
			notiTimer.start()

# Future - Weapons and Armor Update
func _grab_armor(Char):
	match Char:
		"O":
			pass
		"P":
			pass
		"B":
			pass

func _add_item_to_player_inv(item):
	var inventory = player.Inv
	for spot in inventory:
		if item.Char == spot.Char and item.Type == spot.Type:
			spot.Uses += item.Uses
			return
	inventory.append(item)

func _show_help(shownPage):
	currentPageShown = shownPage
	print("Starting Help + " + str(shownPage) + " Paged.")
	var text = ""
	var altText = ""
	if waitingOn == "Help":
		match shownPage:
			1:
				text += "Movement:\nNorth: W, Up Arrow\nSouth: S, Down Arrow\nWest: A, Left Arrow\nEast: D, Right Arrow\nWait: . 'Period'"
				altText += "Page 1/5, Page down for more"
			2:
				text += "Gameplay:\nLook: K\nMute Sound: F3, | 'Pipe'"
				altText += "Page 2/5, Page down for more"
			3:
				text += "Items:\nOpen Inventory: I\nHeal: + 'Plus'\nScroll: Z\nFire: X + Keypad"
				altText += "Page 3/5, Page down for more"
			4:
				text += "Level editing:\nEnter level editor: Ctrl + L or ~ 'Tilde'\nSave level: Ctrl + S\nPaste Level: Ctrl + V\nHear level: Ctrl + K  "
				altText += "Page 4/5, Page down for more"
			5:
				text += "System:\nQuit or Back out: Escape\nReset Level: R\nRestart Game: Shift + R\nDark Mode: Shift + D\nVersion Display: V"
				altText += "Page 5/5, Page up for more"
	elif waitingOn == "Tile Help":
		match shownPage:
			1:
				text += "Interactables:\n"
				for Char in INTERACTS:
					text += Char
				altText += "Page 1/4, Page down for more"
			2:
				text += "Collidables:\n"
				for Char in COLLIDES:
					text += Char
				altText += "Page 2/4, Page down for more"
			3:
				text += "Beings:\n"
				for Char in ENTITIES:
					text += Char
				altText += "Page 3/4, Page down for more"
			4:
				text += "Weapons:\n"
				for Char in WEAPONS:
					text += Char
				for Char in RANGED:
					text += Char
				altText += "Page 4/4, Page up for more"
	print(text)
	levelLabel.text = text
	statusLabel.text = altText
	if not is_muted:
		DisplayServer.tts_stop()
		await get_tree().process_frame
		DisplayServer.tts_speak("Help: "+text+altText, voice[0])
#		DisplayServer.tts_speak(altText, voice[0])
		

func _show_inv(shownPage):
	currentPageShown = shownPage
	var items = 0
	for Item in player.Inv:
		items += 1
	if items > 5:
		var moreText = ""
		var pages = items / 5
		if items % 5 != 0:
			pages += 1
		pageSelect = true
		if shownPage == pages:
			moreText = " Page Up for more."
		else:
			moreText = " Page Down for more."
		statusLabel.text = str(currentPageShown) + "/" + str(pages) + moreText
		if not is_muted:
			DisplayServer.tts_speak(str(currentPageShown) + " out of " + str(pages) + moreText, voice[0])
		numOfPages = pages
	var text = ""
	var itemIndex = 1
	print((shownPage * 5) - 5)
	for Item in player.Inv:
		print(itemIndex)
		if itemIndex < (shownPage * 5) - 5:
			itemIndex += 1
			continue
		if itemIndex > (shownPage * 5):
			break
		var name = _get_item_name(Item.Char, Item.Type)
		if not name:
			continue
		var line = name + " Uses: " + str(Item.Uses)
		text += line
		text += "\n"
		itemIndex += 1
	if not text:
		text = "Your inventory is empty!"
	levelLabel.text = text
	if not is_muted:
		DisplayServer.tts_stop()
		await get_tree().process_frame
		DisplayServer.tts_speak("Inventory: "+text, voice[0])
	waiting = true
	waitingOn = "Inventory"
		

func _get_item_name(Char, Type) -> String:
	match Char:
		"-":
			return Type + " Ammo"
		"B":
			return Type + " Bow"
		"Y":
			return Type + " Key"
		"+":
			return Type + " Heal Pot"
		"Z":
			return "Scroll of " + Type
	return ""

func _add_corpse(targetActor):
	var actorIndex = 0
	for actor in actors:
		if actor.Loc == targetActor.Loc and actor.Char == targetActor.Char:
			break
		actorIndex += 1
	var Body = body.duplicate(true)
	Body.Desc = targetActor.bodyDesc
	Body.Inv = targetActor.Inv.duplicate()
	Body.Loc = targetActor.Loc
	corpses.append(Body)
	print(corpses)
	var check = actors.pop_at(actorIndex)
	

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
			statusLabel.text = "You deal " + str(DMG) + " DMG to " + str(targetChar)
			if not is_muted:
				DisplayServer.tts_speak("You deal " + str(DMG) + " DMG to " + str(targetChar), voice[0])
			notiTimer.start()
			if actor.HP < 1:
				return true
			break
	return false

#Future - Weapons and Armor Update
#Behavs: RangedAI, RangedPlayer, MeleeAI, MeleePlayer, HunterGatherer, Scavenger 
func _find_and_use_weapon(Actor, Behav):
	
	for item in Actor.Inv:
		if item.Char in WEAPONS:
			pass


func _find_and_use_item(Item, Actor):
	var spotIndex = 0
	for spot in Actor.Inv:
		if typeof(spot) == 18:
			if "Char" in spot and "Uses" in spot:
				if spot.Char == Item:
#					print("OK!")
					if Item == "+":
						Actor.HP += spot.Value
						print(Actor.Char + " healed to: " + str(Actor.HP))
					elif Item == "Z":
						scrollUse = spot.Type
					spot.Uses -= 1
					if spot.Uses == 0:
						Actor.Inv.pop_at(spotIndex)
					return true
					
					
		spotIndex += 1
	# If item not found
	return false
	
func _find_item(Item, Actor) -> bool:
	var spotIndex = 0
	for spot in Actor.Inv:
		if typeof(spot) == 18:
			if "Char" in spot and "Uses" in spot:
				if spot.Char == Item:
					return true
		spotIndex += 1
	# If item not found
	return false


func _spawn_item_inside_container(containerInv : Array, containerType):
	var Item = item.duplicate(true)
	if containerType == "x":
		var rand = randi()%2
		match rand:
			0:
				Item.Char = "+"
				Item.Type = "Lesser"
				Item.Uses = 2
				Item.Value = 1
			1:
				Item.Char = "Z"
				Item.Type = "Lightning"
				Item.Uses = 1
	# finish
	elif containerType == "g":
		var rand = randi()%100
		if rand < 8:
			Item.Char = "S"
			Item.Uses = 25
		if rand > 8 and rand < 18:
			Item.Char = "B"
			Item.Type = "Hunting"
			Item.Uses = 8
		if rand > 89:
			Item.Char = "T"
			Item.Type = "Short"
			Item.Uses = 18
	elif containerType == "k":
		var rand = randi()%100
		if rand < 9:
			Item.Char = "V"
			Item.Type = "Digging"
			Item.Uses = 11
		if rand > 90:
			Item.Chat = "B"
			Item.Type = "Hunting Short"
			Item.Uses = 6
	if Item.Char == "":
		return
	containerInv.append(Item)

func _files_dropped(files, screen):
	var fileIndex = 0
	var extensions = "txt"
	if currentRoom < 0:
		print("Can't enter, player exited.")
		return
	for File in files:
		if (fileIndex + currentRoom) > 9:
			print("Thaz alotta files!")
			return
#		var Bool = false
		if File.get_extension() != extensions:
			continue
#			Bool = true
#		print(file, " ", screen, Bool)
		var f = FileAccess.open(File, File.READ)
		var data = ""
		var index = 1
		levelLabel.text = ""
		var textLength = 0
		var longestTextLength = 0
		var ifFailed = false
		while not f.eof_reached():
			if index > 6:
				$VSplitContainer/StatusLabel.text = "Max Rows: 6."
				if not is_muted:
					DisplayServer.tts_speak("Max Rows: 6", voice[0])
				$NotificationTimer.start()
				break
			var line = f.get_line()
			if line.length() > 24:
				$VSplitContainer/StatusLabel.text = "Max Columns: " + str(line.length()) + "/24."
				if not is_muted:
					DisplayServer.tts_speak("Max Columns: " + str(line.length()) + " of 24.", voice[0])
				$NotificationTimer.start()
				ifFailed = true
				break
			if index == 1:
				longestTextLength = line.length()
			else:
				if line.length() > longestTextLength:
					longestTextLength = line.length()
			index += 1
		f.close()
		if ifFailed:
			continue
		f = File.new()
		index = 1
		f.open(File,File.READ)
		while not f.eof_reached():
			if index > 6:
				break
			var line = f.get_line()
			if line.length() < longestTextLength:
				for space in range(longestTextLength - line.length()):
					line += " "
			print(str(index) + ": " + line)
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
				Rooms.pop_at(currentRoom + 1)
			_change_level()
		else:
			Rooms.append(data)
			_change_level()
			print(Rooms)
		fileIndex += 1
		pass
#	save_game(autosaveLoc)

# Call when array has that many indexed of rooms
func _change_level():
	levelChange = false
	if currentRoom == -1:
		levelLabel.text = "You have left."
		if not is_muted:
			DisplayServer.tts_speak("You have left.", voice[0])
		return
	var store = ""
	if currentRoom == 9:
		store = RoomsStore[1]
		if Rooms.size() > 9:
			Rooms[9] = store
		else:
			Rooms.append(store)
	else:
		store = Rooms[currentRoom]
		
	
	save_game(autosaveLoc)
	game_array = _get_text_as_array(store)
	corpses.clear()
	actors.clear()
	_actors_init(game_array)
	_display_array(game_array)
	if $NotificationTimer.is_stopped():
		_status_bar_update()
	pass

func _get_text_as_array(text : String):
	var a = []
	var c = text.split("\n", false)
	var longestTextLength = 0
	for line in c:
		if line.length() > longestTextLength:
			longestTextLength = line.length()
#	print(c)
	for line in c:
		var A = []
#		var b = line.split("", false)
#		print(b)
		for Char in line:
			A.append(Char)
#			print(Char)
		if longestTextLength > line.length():
			for spot in range(longestTextLength - line.length()):
				A.append(" ")
		a.append(A)
#	print(a)
	return a
#	pass

func _return_array_to_text(a:Array) -> String:
	var Return = ""
	for row in a:
		for Char in row:
			Return += Char
		Return += "\n"
	print(Return)
	return Return

#func _get_array_as_text(text:String) -> Array:
#	var array = []
#	var textSplit = text.split("\n")
#	for line in textSplit:
#		var lineInArray = []
#		for Char in line:
#			lineInArray.append(Char)
#		array.append(lineInArray)
#	return array

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
#	DisplayServer.tts_speak(text)

func _status_bar_update():
	var text = ""
	var size = Rooms.size() - 1
	if size < 0:
		statusLabel.text = "No Rooms."
		if not is_muted:
			DisplayServer.tts_speak("No Rooms.", voice[0])
		return
	var current = currentRoom
	if current < 0:
		text = "Bye bye!"
		if not is_muted:
			DisplayServer.tts_speak("Bye bye!", voice[0])
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
	
func _clean_pasted_text(text:String) -> String:
	var c = text.split("\r\n", false)
	for line in c:
		for Char in line:
			if Char == "\t":
				Char = " "
	var longestTextLength = 0
	var index = 1
	var returnValue = ""
	for line in c:
		if line.length() > longestTextLength:
			longestTextLength = line.length()
			if longestTextLength > 24:
				$VSplitContainer/StatusLabel.text = "Max Columns: " + str(longestTextLength) + "/24"
				if not is_muted:
					DisplayServer.tts_speak("Max Columns: " + str(longestTextLength) + " of 24", voice[0])
				$NotificationTimer.start()
				line = line.substr(0,24)
				longestTextLength = 24
	for line in c:
		if line.length() < longestTextLength:
			for spot in range(longestTextLength - line.length()):
				line += " "
		if index < 7:
			returnValue += line + "\n"
		else:
			$VSplitContainer/StatusLabel.text = "Max Rows: 6"
			if not is_muted:
				DisplayServer.tts_speak("Max Rows: 6", voice[0])
			$NotificationTimer.start()
			break
		index += 1
	
	return returnValue


func _fireBow(Actor, Dir):
	match Dir:
		9:
			Dir = Vector2(1,-1)
		8:
			Dir = Vector2(0,-1)
		7:
			Dir = Vector2(-1,-1)
		6:
			Dir = Vector2(1,0)
		5:
			firing = false
			return
		4:
			Dir = Vector2(-1,0)
		3:
			Dir = Vector2(1,1)
		2:
			Dir = Vector2(0,1)
		1:
			Dir = Vector2(-1,1)
	var bow = _find_and_use_item("B", Actor)
	var arrow = _find_and_use_item("-", Actor)
	if bow and arrow:
		var A = ENTITIES_DEFINES.Arrow.duplicate(true)
		A.Loc = Actor.Loc + Dir
		if game_array[A.Loc.y][A.Loc.x] in COLLIDES:
			statusLabel.text = "Your shot hits the wall."
			if not is_muted:
				DisplayServer.tts_speak("Your shot hits the wall.", voice[0])
			notiTimer.start()
			firing = false
			return
		for targetActor in actors:
			if targetActor.Loc == A.Loc:
				targetActor.HP -= A.DMG
				A.HP -= A.DMG
				statusLabel.text = "Your shot hit " + A.Char + " for " + str(A.DMG)
				if not is_muted:
					DisplayServer.tts_speak("Your shot hit " + A.Char + " for " + str(A.DMG), voice[0])
				if targetActor.HP < 1:
					_add_corpse(targetActor)
					game_array[targetActor.Loc.y][targetActor.Loc.x] = "%"
				firing = false
				return
		A.Dir = Dir
		game_array[A.Loc.y][A.Loc.x] = "-"
		_display_array(game_array)
		actors.append(A)
		firing = false
		if Actor.Char == "@":
			_status_bar_update()
	else:
		if Actor.Char == "@":
			var text = ""
			if not bow:
				text += "Bow"
				if not arrow:
					text += " + Arrows"
			else:
				if not arrow:
					text += "Arrows"
			statusLabel.text = "Missing: " + text
			if not is_muted:
				("Missing: " + text)

func _stack_alike_strings(S:String) -> String:
#	var input_array = [
#		"#############",
#		"#@         x",
#		"#        n #",
#		"##D#########",
#		"#<r        >#",
#	]

	var output_array = []
	var hold = S.split("\n")
	for row in hold:
		var stacked_row = []
		var current_string = ""
		for Char in row:
#			if Char == "\n":
#				continue
			var translated_char = ALL[Char]
			if current_string == "":
				current_string = translated_char + " times 1"
			elif current_string.find(translated_char) == 0:
				var space_count = current_string.split(" times ")[1].to_int()
				space_count += 1
				current_string = translated_char + " times " + str(space_count)
			else:
				stacked_row.append(current_string)
				current_string = translated_char + " times 1"
		stacked_row.append(current_string)
		stacked_row.append("Next row")
		output_array.append(", ".join(stacked_row))

	# Print the stacked arrays
	return str(output_array)

func _on_NotificationTimer_timeout():
	match notificationType:
		"status":
			_status_bar_update()
		"level":
			_display_array(game_array)
			notificationType = "status"
		"both":
			_status_bar_update()
			_display_array(game_array)
			notificationType = "status"
