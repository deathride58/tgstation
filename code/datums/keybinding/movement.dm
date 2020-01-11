/datum/keybinding/movement
	category = CATEGORY_MOVEMENT
	weight = WEIGHT_HIGHEST
	var/associated_dir

/datum/keybinding/movement/down(client/user)
	if(user.mob in SSvelocity.tracked_objects)
		var/movement_dir
		for(var/_key in user.keys_held)
			movement_dir = movement_dir | user.movement_keys[_key]
		switch(movement_dir) // Yeah this is ugly but better performance wise
			if(NORTH)
				user.mob.wish_x = 0
				user.mob.wish_y = 1
			if(NORTHEAST)
				user.mob.wish_x = 0.7
				user.mob.wish_y = 0.7
			if(EAST)
				user.mob.wish_x = 1
				user.mob.wish_y = 0
			if(SOUTHEAST)
				user.mob.wish_x = 0.7
				user.mob.wish_y = -0.7
			if(SOUTH)
				user.mob.wish_x = 0
				user.mob.wish_y = -1
			if(SOUTHWEST)
				user.mob.wish_x = -0.7
				user.mob.wish_y = -0.7
			if(WEST)
				user.mob.wish_x = -1
				user.mob.wish_y = 0
			if(NORTHWEST)
				user.mob.wish_x = -0.7
				user.mob.wish_y = 0.7

/datum/keybinding/movement/up(client/user)
	if(user.mob in SSvelocity.tracked_objects)
		var/movement_dir
		for(var/_key in user.keys_held)
			movement_dir = movement_dir | user.movement_keys[_key]
		if(!movement_dir)
			user.mob.wish_x = 0
			user.mob.wish_y = 0
		
		switch(movement_dir) // Yeah this is ugly but better performance wise
			if(NORTH)
				user.mob.wish_x = 0
				user.mob.wish_y = 1
			if(NORTHEAST)
				user.mob.wish_x = 0.7
				user.mob.wish_y = 0.7
			if(EAST)
				user.mob.wish_x = 1
				user.mob.wish_y = 0
			if(SOUTHEAST)
				user.mob.wish_x = 0.7
				user.mob.wish_y = -0.7
			if(SOUTH)
				user.mob.wish_x = 0
				user.mob.wish_y = -1
			if(SOUTHWEST)
				user.mob.wish_x = -0.7
				user.mob.wish_y = -0.7
			if(WEST)
				user.mob.wish_x = -1
				user.mob.wish_y = 0
			if(NORTHWEST)
				user.mob.wish_x = -0.7
				user.mob.wish_y = 0.7
/datum/keybinding/movement/north
	hotkey_keys = list("W", "North")
	classic_keys = list("North")
	name = "North"
	full_name = "Move North"
	description = "Moves your character north"
	associated_dir = NORTH

/datum/keybinding/movement/south
	hotkey_keys = list("S", "South")
	classic_keys = list("South")
	name = "South"
	full_name = "Move South"
	description = "Moves your character south"
	associated_dir = SOUTH

/datum/keybinding/movement/west
	hotkey_keys = list("A", "West")
	classic_keys = list("West")
	name = "West"
	full_name = "Move West"
	description = "Moves your character left"
	associated_dir = WEST

/datum/keybinding/movement/east
	hotkey_keys = list("D", "East")
	classic_keys = list("East")
	name = "East"
	full_name = "Move East"
	description = "Moves your character east"
	associated_dir = EAST
