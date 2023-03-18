var/list/ban_from_fluid = list(
	"blackpowder",
	"fungus",
	"luminol",
	"martian_flesh",
	"paper",
	"thermite",
)
//TODO: make thermite work.
/// Ban these from producing fluid from a 'cleanable'
var/list/ban_stacking_into_fluid = list(
	"ash",
	"blackpowder",
	"carbon",
	"leaves",
	"magnesium",
	"poo",
	"sodium",
	"water",
)


var/global/waterflow_enabled = TRUE

var/list/depth_levels = list(
	2,
	50,
	100,
	200,
)

var/mutable_appearance/fluid_ma

ADMIN_INTERACT_PROCS(/obj/fluid, proc/admin_clear_fluid)

/**
 * Fluid Object
 * This is our physical representation of a fluid.
 * It is a object that is applied to a turf and contains information about the fluid.
 */
/obj/fluid
	name = "fluid"
	desc = "It's a free-flowing liquid state of matter!"
	icon = 'icons/obj/fluid.dmi'
	icon_state = "15"
	anchored = 2
	layer = FLUID_LAYER
	mouse_opacity = 1

	event_handler_flags = IMMUNE_MANTA_PUSH

	var/finalcolor = "#ffffff"
	color = "#ffffff"
	var/finalalpha = 100
	alpha = 255

	var/const/max_slip_volume    = 30
	var/const/max_slip_viscosity = 10
	var/const/max_reagent_volume = 300

	/// Amount of reagents contained - should be updated mainly by the group.
	var/amt = 0

	var/const/max_viscosity = 20
	var/avg_viscosity = 1

	/// Max slowdown we can experience per slowdown type.
	var/const/max_speed_mod = 3

	/// Highest movement_speed_mod allowed.
	var/const/max_speed_mod_total = 5

	/// Scales with viscosity + depth.
	var/movement_speed_mod = 0

	// Amt req to push an item as we spread
	var/const/push_tiny_req  = 1
	var/const/push_small_req = 10
	var/const/push_med_req   = 25
	var/const/push_large_req = 50

	var/datum/fluid_group/group = 0
	var/obj/fluid/touched_other_group = 0

	// var/float_anim = 0
	var/step_sound = 0

	var/last_spread_was_blocked = FALSE

	/// Inf fluid_groups/add() is called, if this is not equal to our depth_level, we'll set it.
	var/last_depth_level = 0

	/// Stores a /obj/channel when update() is called.
	var/obj/channel/touched_channel = null

	/// A cache for the overlays we slap onto walls to make the fluid look deep.
	var/list/wall_overlay_images = 0

	/**
	 * A list of atoms we triggered a float anim on.
	 * Cleans up later on qdel()
	 */
	// var/list/floated_atoms = 0

	/// Have we finished setting up this fluid.
	var/is_setup = FALSE

	/**
	 * Amount of cardinal directions that this fluid was blocked by in last update().
	 * Cache this to skip updates on 'inner' fluid tiles of a group.
	 */
	var/blocked_dirs = 0

	/**
	 * On our last spread, which directions were blocked by perspective OBJECTSs?
	 * This saves us from doing a dumb loop to check all neighboring turfs.
	 */
	var/list/blocked_perspective_objects = list()

	/**
	 *! TL;DR - This key is used so we don't need to do a (more expensive) list search each get_connected loop iteration.
	 *
	 * This one is dumb... When a potential split happens, all adjacent fluid tiles to the split tile will be flagged with the same key.
	 *
	 * Used by: get_connected()
	 * * If it encounters all these adjacent fluid tiles, will end early so we don't waste processing time searching through a group we are 100% sure did not split.
	 */
	var/temp_removal_key = 0

	var/my_depth_level = 0

	var/do_iconstate_updates = TRUE

	var/spawned_any = FALSE

/obj/fluid/New(atom/newLoc)
	. = ..()
	if (!isnull(newLoc)) // New starts this thing without a loc. if none is defined, don't immediate delete.
		if (!waterflow_enabled)
			removed()
			return

	flags |= OPENCONTAINER | UNCRUSHABLE
	// floated_atoms = list()

	for (var/dir in cardinal)
		blocked_perspective_objects["[dir]"] = 0

	if (!fluid_ma)
		fluid_ma = new(src)


/obj/fluid/proc/set_up(atom/newLoc, do_enters = TRUE)
	if (is_setup || isnull(newLoc))
		return

	is_setup = TRUE

	if (isturf(newLoc) && waterflow_enabled)
		var/turf/turf_loc = newLoc
		set_loc(turf_loc)
		turf_loc.active_liquid = src
	else
		removed()
		return


/obj/fluid/proc/done_init()
	. = FALSE
	/*
	// Maybe slow, it was broke in the first place so lets just comment it out.
	for(var/mob/M in loc)
		if (disposed)
			return
		HasEntered(M, M.loc)
		LAGCHECK(LAG_MED)

	for(var/obj/O in loc)
		LAGCHECK(LAG_MED)
		if (disposed)
			return
		if (O.submerged_images)
			HasEntered(O, O.loc)
	*/

/obj/fluid/proc/trigger_fluid_enter()
	for (var/atom/A as anything in loc)
		if (group && !group.disposed && A.event_handler_flags & USE_FLUID_ENTER)
			A.EnteredFluid(src, loc)
	if (group && !group.disposed)
		loc?.EnteredFluid(src, loc)

/obj/fluid/proc/turf_remove_cleanup(turf/the_turf)
	the_turf.active_liquid = null

/obj/fluid/disposing()
	if (group && !group.disposed && group.members)
		group.members -= src

	group = null

	/*
	for (var/atom/A in floated_atoms) // ehh i dont like doing this, but I think we need it.
		if (!A)
			continue
		animate(A)
		A.pixel_y = initial(A.pixel_y)
	floated_atoms.len = 0
	*/

	if (isturf(loc))
		turf_remove_cleanup(loc)

	name = "fluid"
	fluid_ma.icon_state = "15"
	fluid_ma.alpha = 255
	fluid_ma.color = "#ffffff"
	fluid_ma.overlays = null
	appearance = fluid_ma
	overlay_refs = null // Setting appearance removes our overlays!

	finalcolor = "#ffffff"
	finalalpha = 100
	amt = 0
	avg_viscosity = initial(avg_viscosity)
	movement_speed_mod = 0
	group = null
	touched_other_group = 0
	// float_anim = FALSE
	step_sound = FALSE
	last_spread_was_blocked = FALSE
	last_depth_level = 0
	touched_channel = null
	is_setup = FALSE
	blocked_dirs = 0
	blocked_perspective_objects["[dir]"] = 0
	my_depth_level = 0

	return ..()

/obj/fluid/get_desc(dist, mob/user)
	if (dist > 4)
		return
	if (!group || !group.reagents)
		return
	. = "<br><span class='notice'>[group.reagents.get_description(user,(RC_VISIBLE | RC_SPECTRO))]</span>"
	return

/obj/fluid/attackby(obj/item/attacking_item, mob/user)
	if (istype(attacking_item, /obj/item/mop))
		return

	// Floor overrides some construction clicks.
	if (istype(attacking_item, /obj/item/rcd) || istype(attacking_item, /obj/item/tile) || istype(attacking_item, /obj/item/sheet) || ispryingtool(attacking_item))
		var/turf/our_turf = get_turf(src)
		our_turf.Attackby(attacking_item, user)
		attacking_item.AfterAttack(our_turf, user)
		return

	. = ..()

/obj/fluid/attack_hand(mob/user)
	var/turf/our_turf = loc
	our_turf.Attackhand(user)

/// Should be called right after New() on inital group creation.
/obj/fluid/proc/add_reagents(datum/reagents/R, volume)
	if(!group)
		return
	R.trans_to(group.reagents,volume)

/// Should be called right after New() on inital group creation.
/obj/fluid/proc/add_reagent(reagent_name, volume)
	if(!group)
		return
	group.reagents.add_reagent(reagent_name,volume)


/obj/fluid/Crossed(atom/movable/A) //TODO: Incorporate touch_modifier?
	..()
	if (!group || !group.reagents || disposed || istype(A,/obj/fluid)  || group.disposed || istype(src, /obj/fluid/airborne))
		return

	my_depth_level = last_depth_level

	/*
	if (float_anim)
		if (istype(A, /atom/movable) && !isobserver(A) && !istype(A, /mob/living/critter/small_animal/bee) && !istype(A, /obj/critter/domestic_bee))
			var/atom/movable/AM = A
			if (!AM.anchored)
				animate_bumble(AM, floatspeed = 8, Y1 = 3, Y2 = 0)
				floated_atoms += AM
	*/

	if (A.event_handler_flags & USE_FLUID_ENTER)
		A.EnteredFluid(src, A.last_turf)

/obj/fluid/Uncrossed(atom/movable/AM)
	. = ..()

	/*
	var/cancel_float = 0
	if (AM.loc == newloc)
		cancel_float = 1
	*/

	/*
	if (src.float_anim && isturf(newloc))
		var/turf/T = newloc
		if (!T.active_liquid || (T.active_liquid && T.active_liquid.amt < depth_levels[depth_levels.len-1]))
			cancel_float = 1
	else
		cancel_float = 1

	if (src.float_anim && cancel_float)
		if (istype(AM, /atom/movable) && !isobserver(AM) && !istype(AM, /mob/living/critter/small_animal/bee) && !istype(AM, /obj/critter/domestic_bee))
			animate(AM)
			AM.pixel_y = initial(AM.pixel_y)
			floated_atoms -= AM
	*/

	if ((AM.event_handler_flags & USE_FLUID_ENTER) && !istype(src, /obj/fluid/airborne))
		AM.ExitedFluid(src)

/obj/fluid/proc/force_mob_to_ingest(mob/M, mult = 1)//called when mob is drowning
	if (!M)
		return
	if (!group || !group.reagents || !group.reagents.reagent_list)
		return

	var/react_volume = amt > 10 ? (amt * 0.5) : (amt)
	react_volume = min(react_volume, 20) * mult
	if (M.reagents)
		// Don't push out other reagents if we are full.
		react_volume = min(react_volume, abs(M.reagents.maximum_volume - M.reagents.total_volume))
	group.reagents.reaction(M, INGEST, react_volume, 1, group.members.len)
	group.reagents.trans_to(M, react_volume)


/obj/fluid/proc/add_tracked_blood(atom/movable/AM as mob|obj)
	AM.tracked_blood = list("bDNA" = blood_DNA, "btype" = blood_type, "color" = color, "count" = rand(2,6))
	if (ismob(AM))
		var/mob/target_mob = AM
		target_mob.set_clothing_icon_dirty()


/obj/fluid/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	..()
	if(!group || !group.reagents || !length(group.members))
		return

	group.last_temp_change = world.time

	// Deduce exposed temperature by amt of members in the group.
	group.reagents.temperature_reagents(exposed_temperature, exposed_volume, 100, 15, TRUE)

/obj/fluid/ex_act()
	removed()

/obj/fluid/proc/removed(sfx = FALSE)
	if (disposed)
		return

	if (sfx)
		playsound(src.loc, 'sound/impact_sounds/Liquid_Slosh_1.ogg', 25, TRUE)

	if (group)
		if (!group.remove(src))
			qdel(src)
	else
		qdel(src)

	for(var/atom/A as anything in loc)
		if (A && A.flags & FLUID_SUBMERGE)
			var/mob/living/M = A
			var/obj/O = A
			if (istype(M))
				Uncrossed(M)
				M.show_submerged_image(0)
			else if (istype(O))
				if (O.submerged_images)
					Uncrossed(O)
					if ((O.submerged_images && length(O.submerged_images)) && (O.is_submerged != 0))
						O.show_submerged_image(0)

/// Returns a list of created fluid tiles.
/obj/fluid/proc/update()
	if(!group || group.disposed) //uh oh
		removed()
		return
	var/list/updated_fluids = list()

	last_spread_was_blocked = TRUE
	touched_channel = null
	blocked_dirs = null
	spawned_any = FALSE

	var/turf/target_turf
	if(!waterflow_enabled)
		return
	for(var/dir in cardinal)
		blocked_perspective_objects["[dir]"] = 0
		target_turf = get_step(src, dir)
		if(!target_turf) // The fuck? h o w
			continue
		if (!IS_VALID_FLUID_TURF(target_turf))
			blocked_dirs++
			if (IS_PERSPECTIVE_WALL(target_turf))
				blocked_perspective_objects["[dir]"] = 1
			continue
		if (target_turf.active_liquid && !target_turf.active_liquid.disposed)
			blocked_dirs++
			if (target_turf.active_liquid.group && target_turf.active_liquid.group != group)
				touched_other_group = target_turf.active_liquid.group
				target_turf.active_liquid.icon_state = "15"
			continue

		if(!target_turf.density)
			var/succ = TRUE
			var/push_thing = FALSE
			for(var/obj/thing as anything in target_turf.contents)
				var/found = FALSE
				if (IS_SOLID_TO_FLUID(thing))
					found = TRUE
				else if (!push_thing && !thing.anchored)
					push_thing = thing

				if (found)
					if(thing.density || (thing.flags & FLUID_DENSE))
						succ = FALSE
						blocked_dirs++
						if (IS_PERSPECTIVE_BLOCK(thing))
							blocked_perspective_objects["[dir]"] = 1
						break

					if (istype(thing,/obj/channel))
						touched_channel = thing // Save this for later, we can't make use of it yet.
						succ = FALSE
						break

			if(succ && group && !group.disposed) // Group went missing? ok im doin a check here lol
				spawned_any = TRUE
				src.icon_state = "15"
				var/obj/fluid/new_fluid = new /obj/fluid
				new_fluid.set_up(target_turf, FALSE)
				if (!new_fluid || !group || group.disposed)
					continue // set_up may decide to remove new_fluid

				new_fluid.amt = group.amt_per_tile
				new_fluid.name = name
				new_fluid.color = finalcolor
				new_fluid.finalcolor = finalcolor
				new_fluid.alpha = finalalpha
				new_fluid.finalalpha = finalalpha
				new_fluid.avg_viscosity = avg_viscosity
				new_fluid.last_depth_level = last_depth_level
				new_fluid.my_depth_level = last_depth_level
				new_fluid.step_sound = step_sound
				new_fluid.movement_speed_mod = movement_speed_mod

				if (group)
					group.add(new_fluid, group.amt_per_tile)
					new_fluid.group = group
				else
					var/datum/fluid_group/new_fluid_group = new
					new_fluid_group.add(new_fluid, group.amt_per_tile)
					new_fluid.group = new_fluid_group
				updated_fluids += new_fluid // Store the new fluid in the list of updated fluids.

				new_fluid.done_init()

				last_spread_was_blocked = FALSE

				if (push_thing && prob(50))
					if (last_depth_level <= 3)
						if (isitem(push_thing))
							var/obj/item/victim_item = push_thing
							if (victim_item.w_class <= last_depth_level)
								step_away(victim_item, src)
					else
						step_away(push_thing, src)

				new_fluid.trigger_fluid_enter()

	if (spawned_any && prob(40))
		playsound(loc, 'sound/misc/waterflow.ogg', 30, TRUE, 7)

	return updated_fluids

/**
 * Kind of like a breadth-first search.
 *
 * @param adjacent_match_quit
 * * Default: 0
 *
 * @returns
 * * All fluids connected to src.
 *
 * Further documentation:
 * - If adjacent_match_quit > 0, we will check fluids for a temp_removal_key that matches our own.
 * - Subtract 1 when we do find one.
 * - If adjacent_match_quit reaches 0, abort the search. (Used to early detect when a split fails)
 */
/obj/fluid/proc/get_connected_fluids(adjacent_match_quit = 0)
	if (!group)
		return list(src)

	var/list/connected_fluids = list()
	var/list/queue = list(src)
	var/list/visited = list()
	var/turf/target_turf

	var/obj/fluid/current_fluid = null
	var/visited_changed = FALSE

	while(queue.len)
		current_fluid = queue[1]
		queue.Cut(1, 2)

		for(var/dir in cardinal)
			target_turf = get_step(current_fluid, dir)
			if (!VALID_FLUID_CONNECTION(current_fluid, target_turf))
				continue
			if(!target_turf.active_liquid.group)
				target_turf.active_liquid.removed()
				continue

			/**
			 *! Old method : search through 'visited' for 'target_turf.active_liquid'.
			 * Probably slow when you have big groups!!
			 */
			// if(target_turf.active_liquid in visited)
			// 	continue
			// visited += target_turf.active_liquid

			/**
			 *! New method : Add the liquid at a specific index.
			 * To check whether the node has already been visited, just compare the len of the visited group from before + after the index has been set.
			 * Probably slower for small groups and much faster for large groups.
			 */
			visited_changed = length(visited)
			visited["[target_turf.active_liquid.x]_[target_turf.active_liquid.y]_[target_turf.active_liquid.z]"] = target_turf.active_liquid
			visited_changed = (visited.len != visited_changed)

			if (visited_changed)
				queue += target_turf.active_liquid
				connected_fluids += target_turf.active_liquid

				if (adjacent_match_quit)
					if (temp_removal_key && src != target_turf.active_liquid && temp_removal_key == target_turf.active_liquid.temp_removal_key)
						adjacent_match_quit--
						if (adjacent_match_quit <= 0)
							return 0 //bud nippin

	return connected_fluids
/**
 * Sorry for copy paste, this ones a bit diff.
 * Return turfs of members nearby, stop at a number
 *
 *? Only used by elecflash right now.
 *
 * @param stop_at
 * * At how many fluids should we stop counting.
 *
 * @returns
 * * All fluids connected to src.
 */
/obj/fluid/proc/get_connected_fluid_members(stop_at = 0)
	if(!group)
		return list(src)

	var/list/connected_fluids = list()
	var/list/queue = list(src)
	var/list/visited = list()
	var/turf/target_turf

	var/obj/fluid/current_fluid = null
	var/visited_changed = FALSE

	while(queue.len)
		current_fluid = queue[1]
		queue.Cut(1, 2)

		for(var/dir in cardinal)
			target_turf = get_step(current_fluid, dir)
			if(!VALID_FLUID_CONNECTION(current_fluid, target_turf))
				continue
			if (target_turf.active_liquid.group != group)
				continue

			/**
			 *! Old method : search through 'visited' for 'target_turf.active_liquid'.
			 * Probably slow when you have big groups!!
			 */
			// if(target_turf.active_liquid in visited)
			// 	continue
			// visited += target_turf.active_liquid

			/**
			 *! New method : Add the liquid at a specific index.
			 * To check whether the node has already been visited, just compare the len of the visited group from before + after the index has been set.
			 * Probably slower for small groups and much faster for large groups.
			 */
			visited_changed = length(visited)
			visited["[target_turf.active_liquid.x]_[target_turf.active_liquid.y]_[target_turf.active_liquid.z]"] = target_turf.active_liquid
			visited_changed = (visited.len != visited_changed)

			if (visited_changed)
				queue += target_turf.active_liquid
				connected_fluids += target_turf

				if (stop_at > 0 && length(connected_fluids) >= stop_at)
					return connected_fluids

/obj/fluid/proc/try_connect_to_adjacent()
	var/turf/target_turf
	for(var/dir in cardinal)
		target_turf = get_step(src, dir)
		if(!target_turf)
			continue
		if(!target_turf.active_liquid || target_turf.active_liquid.disposed)
			continue
		if (target_turf.active_liquid && target_turf.active_liquid.group && group != target_turf.active_liquid.group)
			target_turf.active_liquid.group.join(group)
		LAGCHECK(LAG_HIGH)


//! Hey this isn't being called at all right now. Moved its blood spread shit up into spread() so we don't call this function that basically does nothing
/*
/obj/fluid/proc/flow_towards(list/obj/fluid_list, push_stuff = TRUE)
	if(!length(fluid_list))
		return
	if(!group || !group.reagents)
		return

	var/push_class = 0
	if (push_stuff)
		if (amt >= push_tiny_req)
			push_class = 1
		if (amt >= push_small_req)
			push_class = 2
		if (amt >= push_med_req)
			push_class = 3
		if (amt >= push_large_req)
			push_class = 4

	for (var/obj/fluid/target_fluid in fluid_list)
		LAGCHECK(LAG_HIGH)
		if(!target_fluid)
			continue

		//copy blood stuff
		if (blood_DNA && !target_fluid.blood_DNA)
			target_fluid.blood_DNA = blood_DNA
		if (blood_type && !target_fluid.blood_type)
			target_fluid.blood_type = blood_type
		continue

		if (push_class)
			for (var/obj/item/target_item in loc)
				LAGCHECK(LAG_HIGH)
				if (prob(15) && !target_item.anchored && target_item.w_class <= push_class)
					step_towards(target_item, target_fluid.loc)
					break
			if (push_class >= 4 && prob(30))
				LAGCHECK(LAG_HIGH)
				for (var/mob/living/target_mob in loc)
					step_towards(target_mob, target_fluid.loc)
					break
*/

/obj/fluid/proc/debug_search()
	var/list/C = get_connected_fluids()
	var/obj/fluid/F
	var/c = pick("#0099ff","#dddddd","#ff7700")

	for (var/i = 1, i <= C.len, i++)
		F = C[i]
		F.finalcolor = c
		animate( F, color = F.finalcolor, alpha = finalalpha, time = 5 )
		sleep(0.1 SECONDS)

/obj/fluid/proc/admin_clear_fluid()
	set name = "Clear Fluid"
	if(group)
		group.evaporate()
	else
		qdel(src)


//HASENTERED CLLAS
// HASEXITED CALLS

//messy i know, but this works for me and is Optimal to avoid type checking


/obj/EnteredFluid(obj/fluid/target_fluid)
	// Object submerged overlays
	if (submerged_images && (is_submerged != target_fluid.my_depth_level))
		for (var/image/I in submerged_images)
			I.color = target_fluid.finalcolor
			I.alpha = target_fluid.finalalpha
		if ((submerged_images && length(submerged_images)))
			show_submerged_image(target_fluid.my_depth_level)

	..()

/obj/ExitedFluid(obj/fluid/target_fluid)
	if (submerged_images && is_submerged != 0)
		if (target_fluid.disposed)
			show_submerged_image(0)
			return

		if (isturf(loc))
			var/turf/target_turf = loc
			if (!target_turf.active_liquid || (target_turf.active_liquid && target_turf.active_liquid.amt < depth_levels[1]))
				show_submerged_image(0)
				return
		else
			show_submerged_image(0)
			return
	..()

/mob/living/EnteredFluid(obj/fluid/target_fluid, atom/oldloc)
	//SUBMERGED OVERLAYS
	if (is_submerged != target_fluid.my_depth_level)
		for (var/image/I in submerged_images)
			I.color = target_fluid.finalcolor
			I.alpha = target_fluid.finalalpha
		show_submerged_image(target_fluid.my_depth_level)
	..()

/mob/living/ExitedFluid(obj/fluid/target_fluid)
	if (is_submerged == FALSE)
		return

	if (target_fluid.disposed)
		show_submerged_image(0)
		return
	else if (isturf(loc))
		var/turf/target_turf = loc
		if(!target_turf.active_liquid || (target_turf.active_liquid && target_turf.active_liquid.amt < depth_levels[1]))
			show_submerged_image(0)
			return
	else
		show_submerged_image(0)
		return
	..()

/mob/living/carbon/EnteredFluid(obj/fluid/target_fluid, atom/oldloc, do_reagent_reaction = TRUE)
	/// Did the entering atom cross from a non-fluid to a fluid tile?
	var/entered_group = TRUE
	// SLIPPING
	//? Only slip if edge tile.
	var/turf/target_turf = get_turf(oldloc)
	if (target_turf?.active_liquid)
		entered_group = FALSE

	if (entered_group && (loc != oldloc))
		if (target_fluid.amt > 0 && target_fluid.amt <= target_fluid.max_slip_volume && target_fluid.avg_viscosity <= target_fluid.max_slip_viscosity)
			var/master_block_slippy = target_fluid.group.reagents.get_master_reagent_slippy(target_fluid.group)
			switch(master_block_slippy)
				if(0)
					var/slippery = (1 - (target_fluid.avg_viscosity / target_fluid.max_slip_viscosity)) * 50
					var/checks = 10
					for (var/thing in oldloc)
						if (istype(thing, /obj/machinery/door))
							slippery = 0
						checks--
						if (checks <= 0)
							break
					if (prob(slippery) && slip())
						visible_message(
							"<span class='alert'><b>[src]</b> slips on [target_fluid]!</span>",
							"<span class='alert'>You slip on [target_fluid]!</span>",
						)
				if(-1) //space lube. this code bit is shit but i'm too lazy to make it Real right now. the proper implementation should also make exceptions for ice and stuff.
					remove_pulling()
					changeStatus("weakened", 3.5 SECONDS)
					boutput(src, "<span class='notice'>You slipped on [target_fluid]!</span>")
					playsound(target_turf, 'sound/misc/slip.ogg', 50, TRUE, -3)
					var/atom/target = get_edge_target_turf(src, dir)
					throw_at(target, 12, 1, throw_type = THROW_SLIP)
				if(-2) //superlibe
					remove_pulling()
					changeStatus("weakened", 6 SECONDS)
					playsound(target_turf, 'sound/misc/slip.ogg', 50, TRUE, -3)
					boutput(src, "<span class='notice'>You slipped on [target_fluid]!</span>")
					var/atom/target = get_edge_target_turf(src, dir)
					throw_at(target, 30, 1, throw_type = THROW_SLIP)
					random_brute_damage(src, 10)


	/**
	 * Possibility to consume reagents.
	 * Each reagent should return 0 in its reaction_[type]() proc if reagents should be removed from fluid.
	 */
	if (do_reagent_reaction && target_fluid.group.reagents && target_fluid.group.reagents.reagent_list && target_fluid.amt > CHEM_EPSILON)
		target_fluid.group.last_reacted = target_fluid
		var/react_volume = target_fluid.amt > 10 ? (target_fluid.amt * 0.5) : (target_fluid.amt)
		react_volume = min(react_volume, 100) // Capping the react amt.
		var/list/reacted_ids = target_fluid.group.reagents.reaction(src, TOUCH, react_volume, 1, target_fluid.group.members.len, entered_group)
		var/volume_fraction  = target_fluid.group.reagents.total_volume ? (react_volume / target_fluid.group.reagents.total_volume) : 0

		for(var/current_id in reacted_ids)
			if (!group)
				return
			var/datum/reagent/current_reagent = target_fluid?.group.reagents.reagent_list[current_id]
			if (!current_reagent)
				continue
			target_fluid.group.reagents.remove_reagent(current_id, current_reagent.volume * volume_fraction)
		/*
		if (length(reacted_ids))
			UpdateIcon()
		*/

	..()

/mob/living/carbon/human/EnteredFluid(obj/fluid/target_fluid, atom/oldloc)
	/// Did the entering atom cross from a non-fluid to a fluid tile?
	var/entered_group = TRUE
	// SLIPPING
	//? Only slip if edge tile.
	var/turf/target_turf = get_turf(oldloc)
	if (target_turf?.active_liquid)
		entered_group = FALSE

	// BLOODSTAINS
	if (target_fluid.group.master_reagent_id == "blood" || target_fluid.group.master_reagent_id == "bloodc")
		if (target_fluid.group.master_reagent_id == "blood")
			// if (ishuman(M))
			if (lying)
				if (wear_suit)
					wear_suit.add_blood(target_fluid)
					set_clothing_icon_dirty()
				else if (w_uniform)
					w_uniform.add_blood(target_fluid)
					set_clothing_icon_dirty()
			else if (shoes)
				shoes.add_blood(target_fluid)
				set_clothing_icon_dirty()
			target_fluid.add_tracked_blood(src)
			// else if (isliving(M))// || isobj(AM))
			// 	M.add_blood(target_fluid)
			// 	if (!M.anchored)
			// 		target_fluid.add_tracked_blood(M)
	var/do_reagent_reaction = TRUE

	if (target_fluid.my_depth_level == 1)
		if(!lying && shoes && shoes.hasProperty ("chemprot") && (shoes.getProperty("chemprot") >= 5)) //sandals do not help
			do_reagent_reaction = FALSE

	if (entered_group) //if entered_group == 1, it may not have been set yet
		if (isturf(oldloc))
			if (target_turf.active_liquid)
				entered_group = FALSE

	..(target_fluid, oldloc, do_reagent_reaction)
