extends Node

const translation_dict = {
	"@": "Player",
	"#": "Wall",
	"x": "Floor",
	"n": "Crate",
	"D": "Door",
	"<": "Wall",
	">": "Wall",
	"r": "Rat",
	" ": "Floor"
}

func stack_alike_strings():
	var input_array = [
		"#############",
		"#@         x",
		"#        n #",
		"##D#########",
		"#<r        >#",
	]

	var output_array = []

	for row in input_array:
		var stacked_row = []
		var current_string = ""
		for Char in row:
			var translated_char = translation_dict[Char]
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
	for row in output_array:
		print(row)

func _ready():
	stack_alike_strings()
