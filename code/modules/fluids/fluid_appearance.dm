///! BE WARNED THIS PROC HAS A REPLICA UP ABOVE IN FLUID GROUP UPDATE_LOOP. DO NOT CHANGE THIS ONE WITHOUT MAKING THE SAME CHANGES UP THERE OH GOD I HATE THIS
/obj/fluid/update_icon(neighbor_was_removed = FALSE)
	if(!group || !group.reagents)
		return

	name = group.master_reagent_name ? group.master_reagent_name : group.reagents.get_master_reagent_name() //TODO: Maybe obscure later?

	var/color_changed = FALSE
	var/datum/color/average = group.average_color ? group.average_color : group.reagents.get_average_color()
	finalalpha = max(25, (average.a / 255) * group.max_alpha)
	finalcolor = rgb(average.r, average.g, average.b)
	if (color != finalcolor)
		color_changed = TRUE
	animate(src, color = finalcolor, alpha = finalalpha, time = 5)

	if (neighbor_was_removed)
		last_spread_was_blocked = FALSE
		clear_overlay()

	var/last_icon = icon_state

	if (last_spread_was_blocked || (group && group.amt_per_tile > group.required_to_spread))
		icon_state = "15"
	else
		var/dirs = 0
		for (var/target_dir in cardinal)
			var/turf/simulated/target_turf = get_step(src, target_dir)
			if (target_turf && target_turf.active_liquid && target_turf.active_liquid.group == group)
				dirs |= target_dir
		icon_state = num2text(dirs)

		if (overlay_refs && length(overlay_refs))
			clear_overlay()

	if ((color_changed || last_icon != icon_state) && last_spread_was_blocked)
		update_perspective_overlays()

/// Fancy perspective overlaying.
/// TODO: Redo this so corners don't overlay each other.
/obj/fluid/proc/update_perspective_overlays()
	if (icon_state != "15")
		return

	var/blocked = FALSE
	for( var/target_dir in cardinal )
		if (target_dir == SOUTH) // No south perspective!
			continue

		if (blocked_perspective_objects["[target_dir]"])
			blocked = TRUE
			if (target_dir == NORTH)
				display_overlay("[target_dir]",0,32)
			else
				display_overlay("[target_dir]",(target_dir == EAST) ? 32 : -32,0)
		else
			clear_overlay("[target_dir]")

	if (!blocked) // Nothing adjacent!
		clear_overlay()

	if (overlay_refs && length(overlay_refs))
		if (overlay_refs["1"] && overlay_refs["8"]) // NORTH & EAST
			display_overlay("9",-32,32) // NORTHEAST
		else
			clear_overlay("9") // NORTHEAST
		if (overlay_refs["1"] && overlay_refs["4"]) // NORTH & WEST
			display_overlay("5",32,32) // NORTHWEST
		else
			clear_overlay("5") // NORTHWEST

/// Perspective overlays.
/obj/fluid/proc/display_overlay(overlay_key, pox, poy)
	var/image/overlay = null
	if (!wall_overlay_images)
		wall_overlay_images = list()

	if (wall_overlay_images[overlay_key])
		overlay = wall_overlay_images[overlay_key]
	else
		overlay = image('icons/obj/fluid.dmi', "blank")

	var/over_obj = !(istype(loc, /turf/simulated/wall) || istype(loc,/turf/unsimulated/wall/)) //HEY HEY MBC THIS SMELLS THINK ABOUT IT LATER
	overlay.layer = over_obj ? 4 : layer
	overlay.icon_state = "wall_[overlay_key]_[last_depth_level]"
	overlay.pixel_x = pox
	overlay.pixel_y = poy
	wall_overlay_images[overlay_key] = overlay

	UpdateOverlays(overlay, overlay_key)

/obj/fluid/proc/clear_overlay(key = 0)
	if (!key)
		ClearAllOverlays()
	else if(key && wall_overlay_images && wall_overlay_images[key])
		ClearSpecificOverlays(key)
