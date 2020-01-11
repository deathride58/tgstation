// Aight, so how does velocity work?
// Basically, instead of the old method where movement is literally just repeatedly spamming the relevant direction verbs,
// movement is instead handled by storing the client's move input as a vector (yes i know it's two seperate vars but byond
// doesnt have real vectors so shush). This vector is then used as a multiplier alongside world.time for acceleration calcs
// that get processed here in the velocity subsystem.

SUBSYSTEM_DEF(velocity)
	name = "Velocity"
	wait = 1 //SS_TICKER means this runs every tick
	init_order = INIT_ORDER_VELOCITY
	flags = SS_TICKER
	priority = FIRE_PRIORITY_VELOCITY
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	var/list/tracked_objects = list()

/datum/controller/subsystem/velocity/fire()
	var/list/cached_objs = tracked_objects
	var/cur_x
	var/cur_y
	var/objvel_x
	var/objvel_y
	var/natspeed_x
	var/natspeed_y
	var/turf/T
	//The reason why this for loop isn't a proc is to squeeze as much performance as possible out of this
	for(var/atom/movable/AM in cached_objs)
		objvel_x = AM.vel_x
		objvel_y = AM.vel_y
		natspeed_x = abs(AM.wish_x*AM.vel_maxnaturalspeed)
		natspeed_y = abs(AM.wish_y*AM.vel_maxnaturalspeed)
		objvel_x = CLAMP(abs(objvel_x) < natspeed_x ? CLAMP((objvel_x + (AM.wish_x*AM.vel_accelerate)), -natspeed_x, natspeed_x) : objvel_x, -AM.vel_maxspeed, AM.vel_maxspeed)
		objvel_y = CLAMP(abs(objvel_y) < natspeed_y ? CLAMP((objvel_y + (AM.wish_y*AM.vel_accelerate)), -natspeed_y, natspeed_y) : objvel_y, -AM.vel_maxspeed, AM.vel_maxspeed)
		if(!(objvel_x == 0) || !(objvel_y == 0))
			cur_x = AM.step_x + objvel_x
			cur_y = AM.step_y + objvel_y
			T = AM.loc
			NORMALIZE_STEP(T, cur_x, cur_y)
			AM.Move(T, get_dir(AM.loc, T), cur_x, cur_y)
			objvel_x = (objvel_x > 0 ? max(objvel_x-AM.vel_friction,0) : min(objvel_x+AM.vel_friction,0))
			objvel_y = (objvel_y > 0 ? max(objvel_y-AM.vel_friction,0) : min(objvel_y+AM.vel_friction,0))
		AM.vel_x = objvel_x
		AM.vel_y = objvel_y

	/*var/x = thing.step_x
	var/y = thing.step_y
	var/turf/place = thing.loc
	x += dist * sin(deg)
	y += dist * cos(deg)
	NORMALIZE_STEP(place, x, y)
	return thing.Move(place, get_dir(thing.loc, place), x, y)*/

