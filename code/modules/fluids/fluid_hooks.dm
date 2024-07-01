
/obj/event_handler_flags = USE_FLUID_ENTER

/obj/EnteredFluid(obj/fluid/F)
	//object submerged overlays
	if(src.submerged_images && (src.is_submerged != F.my_depth_level))
		for(var/image/I as anything in src.submerged_images)
			I.color = F.finalcolor
			I.alpha = F.finalalpha
		if((src.submerged_images && length(src.submerged_images)))
			src.show_submerged_image(depth = F.my_depth_level)

	..()
	return

/obj/ExitedFluid(obj/fluid/F)
	if (src.submerged_images && src.is_submerged != 0)
		if (F.disposed)
			src.show_submerged_image(depth = 0)
			return

		if (isturf(src.loc))
			var/turf/T = src.loc
			if (!T.active_liquid || (T.active_liquid && (T.active_liquid.volume < depth_levels[1])))
				src.show_submerged_image(depth = 0)
				return
		else
			src.show_submerged_image(depth = 0)
			return
	..()
	return


/mob/living/EnteredFluid(obj/fluid/F, atom/oldloc)
	//SUBMERGED OVERLAYS
	if (src.is_submerged != F.my_depth_level)
		for (var/image/I as anything in src.submerged_images)
			I.color = F.finalcolor
			I.alpha = F.finalalpha
		src.show_submerged_image(depth = F.my_depth_level)
	..()
	return


/mob/living/ExitedFluid(obj/fluid/F)
	if(src.is_submerged == 0)
		return

	if(QDELETED(F))
		src.show_submerged_image(depth = 0)
		return

	else if(isturf(src.loc))
		var/turf/T = src.loc
		if(!T.active_liquid || (T.active_liquid && (T.active_liquid.volume < depth_levels[1])))
			src.show_submerged_image(depth = 0)
			return
	else
		src.show_submerged_image(depth = 0)
		return

	..()
	return


/mob/living/carbon/EnteredFluid(obj/fluid/F, atom/oldloc, do_reagent_reaction = TRUE)

	/// Did the entering atom cross from a non-fluid to a fluid tile?
	var/entered_group = TRUE

	//SLIPPING
	//only slip if edge tile

	var/turf/T = get_turf(oldloc)
	if(T?.active_liquid)
		entered_group = FALSE

	if(entered_group && (src.loc != oldloc))
		if((F.volume > 0) && (F.volume <= F.max_slip_volume) && (F.avg_viscosity <= F.max_slip_viscosity))
			var/master_block_slippy = F.group.reagents.get_master_reagent_slippy(F.group)
			switch(master_block_slippy)
				if(0)
					var/slippery = (1 - (F.avg_viscosity/F.max_slip_viscosity)) * 50
					var/checks = 10
					for(var/thing in oldloc)
						if(istype(thing, /obj/machinery/door))
							slippery = 0
						checks--
						if(checks <= 0)
							break

					if(prob(slippery) && src.slip())
						src.visible_message(SPAN_ALERT("<b>[src]</b> slips on [F]!"),\
						SPAN_ALERT("You slip on [F]!"))

				// Space lube.
				// This code bit is shit but i'm too lazy to make it Real right now.
				// The proper implementation should also make exceptions for ice and stuff.
				if(-1)
					src.remove_pulling()
					src.changeStatus("knockdown", 3.5 SECONDS)
					boutput(src, SPAN_NOTICE("You slipped on [F]!"))
					playsound(T, 'sound/misc/slip.ogg', 50, TRUE, -3)
					var/atom/target = get_edge_target_turf(src, src.dir)
					src.throw_at(target, 12, 1, throw_type = THROW_SLIP)

				// Superlube
				if(-2)
					src.remove_pulling()
					src.changeStatus("knockdown", 6 SECONDS)
					playsound(T, 'sound/misc/slip.ogg', 50, TRUE, -3)
					boutput(src, SPAN_NOTICE("You slipped on [F]!"))
					var/atom/target = get_edge_target_turf(src, src.dir)
					src.throw_at(target, 30, 1, throw_type = THROW_SLIP)
					random_brute_damage(src, 10)



	// Possibility to consume reagents.
	// (Each reagent should return 0 in its reaction_[type]() proc if reagents should be removed from fluid)
	if(do_reagent_reaction && F.group?.reagents?.reagent_list && (F.volume > CHEM_EPSILON))
		F.group.last_reacted = F
		var/react_volume = (F.volume > 10) ? (F.volume / 2) : F.volume
		react_volume = min(react_volume, 100) //capping the react volume
		var/list/reacted_ids = F.group.reagents.reaction(src, TOUCH, react_volume,1,F.group.members.len, entered_group)
		var/volume_fraction = F.group.reagents.total_volume ? (react_volume / F.group.reagents.total_volume) : 0

		for(var/current_id in reacted_ids)
			if(!src.group)
				return

			var/datum/reagent/current_reagent = F?.group.reagents.reagent_list[current_id]
			if(!current_reagent)
				continue

			F.group.reagents.remove_reagent(current_id, current_reagent.volume * volume_fraction)

		// if(length(reacted_ids))
		// 	src.UpdateIcon()


	..()


/mob/living/carbon/human/EnteredFluid(obj/fluid/F, atom/oldloc)
	/// Did the entering atom cross from a non-fluid to a fluid tile?
	var/entered_group = TRUE

	//SLIPPING
	//only slip if edge tile

	var/turf/T = get_turf(oldloc)
	if(T?.active_liquid)
		entered_group = FALSE

	//BLOODSTAINS
	if(F.group.master_reagent_id == "blood" || F.group.master_reagent_id == "bloodc" || F.group.master_reagent_id == "hemolymph") // Replace with a blood reagent check proc
		if(src.lying)
			if(src.wear_suit)
				src.wear_suit.add_blood(F)
				src.update_bloody_suit()
			else if(src.w_uniform)
				src.w_uniform.add_blood(F)
				src.update_bloody_uniform()
		else
			if(src.shoes)
				src.shoes.add_blood(F)
				src.update_bloody_shoes()
			else
				src.add_blood(F)

		F.add_tracked_blood(src)
		src.update_bloody_feet()

	var/do_reagent_reaction = TRUE

	if(F.my_depth_level == 1)
		if(!src.lying && src.shoes && src.shoes.hasProperty ("chemprot") && (src.shoes.getProperty("chemprot") >= 5)) //sandals do not help
			do_reagent_reaction = FALSE
			if(!src.wear_suit || !HAS_FLAG(src.wear_suit.c_flags, SPACEWEAR)) // suits can go over shoes
				F.group.reagents.reaction(src.shoes, TOUCH, F.group.amt_per_tile, can_spawn_fluid = FALSE)

	if(entered_group) //if entered_group == 1, it may not have been set yet
		if(isturf(oldloc))
			if(T.active_liquid)
				entered_group = FALSE

	..(F, oldloc, do_reagent_reaction)
	return
