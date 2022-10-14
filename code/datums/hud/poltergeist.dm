/datum/hud/wraith/poltergeist
	var/atom/movable/screen/well_dist
	var/atom/movable/screen/leave_master

/datum/hud/wraith/poltergeist/New(M)
	..()
	//recycling sprites cauze lazy
	well_dist = create_screen("well_dist","Well Distance", 'icons/mob/wraith_ui.dmi', "poltergeist_cd", "EAST, NORTH-1", HUD_LAYER, tooltipTheme = "well_dist")
	leave_master = create_screen("leave_master","Leave Master", 'icons/mob/wraith_ui.dmi', "leave_master", "EAST, NORTH-2", HUD_LAYER, tooltipTheme = "well_dist")
	set_visible(leave_master, 0)

/datum/hud/wraith/poltergeist/clear_master()
	master = null
	..()

/datum/hud/wraith/poltergeist/relay_click(id, mob/user, list/params)
	if (id == "leave_master")
		if (ispoltergeist(master))
			var/mob/wraith/poltergeist/P = master
			P.exit_master()

/datum/hud/wraith/poltergeist/proc/set_leave_master(on)
	set_visible(leave_master, on)

/datum/hud/wraith/poltergeist/proc/update_well_dist(dist)

	if (dist <= 99)
		well_dist.maptext = "<div style='font-size:14px; color:maroon;text-align:center;'>[dist]</div>"
		well_dist.maptext_y = 4
	else if (dist <= 999)
		well_dist.maptext = "<div style='font-size:10px; color:maroon;text-align:center;'>[dist]</div>"
		well_dist.maptext_y = 8
	else if (dist <= 9999)
		well_dist.maptext = "<div style='font-size:8px; color:maroon;text-align:center;'>[dist]</div>"
		well_dist.maptext_y = 8
	else
		well_dist.maptext = "<div style='font-size:8px; color:maroon;text-align:center;'>+</div>"
		well_dist.maptext_y = 8
