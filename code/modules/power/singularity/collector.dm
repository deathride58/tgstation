// last_power += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT
#define RAD_COLLECTOR_EFFICIENCY 80 	// radiation needs to be over this amount to get power
#define RAD_COLLECTOR_COEFFICIENT 100
#define RAD_COLLECTOR_STORED_OUT 0.04	// (this*100)% of stored power outputted per tick. Doesn't actualy change output total, lower numbers just means collectors output for longer in absence of a source
#define RAD_COLLECTOR_MINING_CONVERSION_RATE 0.00001 //This is gonna need a lot of tweaking to get right. This is the number used to calculate the conversion of watts to research points per process()

/obj/machinery/power/rad_collector
	name = "Radiation Collector Array"
	desc = "A device which uses Hawking Radiation and plasma to produce power."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "ca"
	anchored = FALSE
	density = TRUE
	req_access = list(ACCESS_ENGINE_EQUIP)
//	use_power = NO_POWER_USE
	max_integrity = 350
	integrity_failure = 80
	var/obj/item/tank/internals/plasma/loaded_tank = null
	var/last_power = 0
	var/active = 0
	var/locked = FALSE
	var/drainratio = 1
	var/powerproduction_drain = 0.001

	var/datum/techweb/linked_techweb
	var/bitcoinproduction_drain = 0.15
	var/bitcoinmining = FALSE

/obj/machinery/power/rad_collector/anchored
	anchored = TRUE

/obj/machinery/power/rad_collector/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/rad_insulation, RAD_EXTREME_INSULATION, FALSE, FALSE)

/obj/machinery/power/rad_collector/anchored/Initialize()
	. = ..()
	if(z in GLOB.station_z_levels)
		linked_techweb = SSresearch.science_tech

/obj/machinery/power/rad_collector/Destroy()
	return ..()

/obj/machinery/power/rad_collector/process()
	if(loaded_tank)
		if(!bitcoinmining)
			if(!loaded_tank.air_contents.gases[/datum/gas/plasma])
				investigate_log("<font color='red'>out of fuel</font>.", INVESTIGATE_SINGULO)
				eject()
			else
				loaded_tank.air_contents.gases[/datum/gas/plasma][MOLES] -= powerproduction_drain*drainratio
				loaded_tank.air_contents.assert_gas(/datum/gas/tritium)
				loaded_tank.air_contents.gases[/datum/gas/tritium][MOLES] += powerproduction_drain*drainratio
				loaded_tank.air_contents.garbage_collect()

				var/power_produced = min(last_power, (last_power*RAD_COLLECTOR_STORED_OUT)+1000) //Produces at least 1000 watts if it has more than that stored
				add_avail(power_produced)
				last_power-=power_produced
		else if(linked_techweb)
			if(!loaded_tank.air_contents.gases[/datum/gas/tritium] || !loaded_tank.air_contents.gases[/datum/gas/oxygen])
				eject()
			else
				loaded_tank.air_contents.gases[/datum/gas/tritium][MOLES] -= bitcoinproduction_drain*drainratio
				loaded_tank.air_contents.gases[/datum/gas/oxygen][MOLES] -= bitcoinproduction_drain*drainratio
				loaded_tank.air_contents.assert_gas(/datum/gas/carbon_dioxide)
				loaded_tank.air_contents.gases[/datum/gas/carbon_dioxide][MOLES] += bitcoinproduction_drain*2*drainratio
				loaded_tank.air_contents.garbage_collect()
				var/bitcoins_mined = min(last_power, (last_power*RAD_COLLECTOR_STORED_OUT))
				linked_techweb.research_points += bitcoins_mined*RAD_COLLECTOR_MINING_CONVERSION_RATE
				last_power-=bitcoins_mined

/obj/machinery/power/rad_collector/attack_hand(mob/user)
	if(..())
		return
	if(anchored)
		if(!src.locked)
			toggle_power()
			user.visible_message("[user.name] turns the [src.name] [active? "on":"off"].", \
			"<span class='notice'>You turn the [src.name] [active? "on":"off"].</span>")
			var/fuel
			if(loaded_tank)
				fuel = loaded_tank.air_contents.gases[/datum/gas/plasma]
			fuel = fuel ? fuel[MOLES] : 0
			investigate_log("turned [active?"<font color='green'>on</font>":"<font color='red'>off</font>"] by [user.key]. [loaded_tank?"Fuel: [round(fuel/0.29)]%":"<font color='red'>It is empty</font>"].", INVESTIGATE_SINGULO)
			return
		else
			to_chat(user, "<span class='warning'>The controls are locked!</span>")
			return

/obj/machinery/power/rad_collector/can_be_unfasten_wrench(mob/user, silent)
	if(loaded_tank)
		if(!silent)
			to_chat(user, "<span class='warning'>Remove the plasma tank first!</span>")
		return FAILED_UNFASTEN
	return ..()

/obj/machinery/power/rad_collector/default_unfasten_wrench(mob/user, obj/item/wrench/W, time = 20)
	. = ..()
	if(. == SUCCESSFUL_UNFASTEN)
		if(anchored)
			connect_to_network()
		else
			disconnect_from_network()

/obj/machinery/power/rad_collector/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/device/analyzer) && loaded_tank)
		atmosanalyzer_scan(loaded_tank.air_contents, user)
	else if(istype(W, /obj/item/tank/internals/plasma))
		if(!anchored)
			to_chat(user, "<span class='warning'>[src] needs to be secured to the floor first!</span>")
			return TRUE
		if(loaded_tank)
			to_chat(user, "<span class='warning'>There's already a plasma tank loaded!</span>")
			return TRUE
		if(!user.transferItemToLoc(W, src))
			return
		loaded_tank = W
		update_icons()
	else if(W.GetID())
		if(allowed(user))
			if(active)
				locked = !locked
				to_chat(user, "<span class='notice'>You [locked ? "lock" : "unlock"] the controls.</span>")
			else
				to_chat(user, "<span class='warning'>The controls can only be locked when \the [src] is active!</span>")
		else
			to_chat(user, "<span class='danger'>Access denied.</span>")
			return TRUE
	else
		return ..()

/obj/machinery/power/rad_collector/wrench_act(mob/living/user, obj/item/wrench)
	default_unfasten_wrench(user, wrench, 0)
	return TRUE

/obj/machinery/power/rad_collector/crowbar_act(mob/living/user, obj/item/crowbar)
	if(loaded_tank)
		if(locked)
			to_chat(user, "<span class='warning'>The controls are locked!</span>")
			return TRUE
		eject()
		return TRUE
	else
		to_chat(user, "<span class='warning'>There isn't a tank loaded!</span>")
		return TRUE

/obj/machinery/power/rad_collector/multitool_act(mob/living/user, obj/item/multitool)
	if(!linked_techweb)
		to_chat(user, "<span class='warning'>[src] isn't linked to a research system!</span>")
	if(locked)
		to_chat(user, "<span class='warning'>[src] is locked!</span>")
	if(active)
		to_chat(user, "<span class='warning'>[src] is currently active, producing [bitcoinmining ? "research points":"power"].</span>")
	bitcoinmining = !bitcoinmining
	to_chat(user, "<span class='warning'>You [bitcoinmining ? "enable":"disable"] the research point production feature of [src].</span>")
	return TRUE

/obj/machinery/power/rad_collector/examine(mob/user)
	. = ..()
	if(active)
		if(!bitcoinmining)
			to_chat(user, "<span class='notice'>[src]'s display states that it is processing [DisplayPower(last_power)].</span>")
		else
			to_chat(user, "<span class='notice'>[src]'s display states that it is producing a total of [last_power*RAD_COLLECTOR_MINING_CONVERSION_RATE] research points.</span>")

/obj/machinery/power/rad_collector/obj_break(damage_flag)
	if(!(stat & BROKEN) && !(flags_1 & NODECONSTRUCT_1))
		eject()
		stat |= BROKEN

/obj/machinery/power/rad_collector/proc/eject()
	locked = FALSE
	var/obj/item/tank/internals/plasma/Z = src.loaded_tank
	if (!Z)
		return
	Z.forceMove(drop_location())
	Z.layer = initial(Z.layer)
	Z.plane = initial(Z.plane)
	src.loaded_tank = null
	if(active)
		toggle_power()
	else
		update_icons()

/obj/machinery/power/rad_collector/rad_act(pulse_strength)
	if(loaded_tank && active && pulse_strength > RAD_COLLECTOR_EFFICIENCY)
		last_power += (pulse_strength-RAD_COLLECTOR_EFFICIENCY)*RAD_COLLECTOR_COEFFICIENT

/obj/machinery/power/rad_collector/proc/update_icons()
	cut_overlays()
	if(loaded_tank)
		add_overlay("ptank")
	if(stat & (NOPOWER|BROKEN))
		return
	if(active)
		add_overlay("on")


/obj/machinery/power/rad_collector/proc/toggle_power()
	active = !active
	if(active)
		icon_state = "ca_on"
		flick("ca_active", src)
	else
		icon_state = "ca"
		flick("ca_deactive", src)
	update_icons()
	return

#undef RAD_COLLECTOR_EFFICIENCY
#undef RAD_COLLECTOR_COEFFICIENT
#undef RAD_COLLECTOR_STORED_OUT
