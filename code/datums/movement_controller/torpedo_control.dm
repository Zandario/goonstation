/datum/movement_controller/torpedo_control
	var/obj/machinery/torpedo_console/master

/datum/movement_controller/torpedo_control/New(master)
	..()
	src.master = master

/datum/movement_controller/torpedo_control/disposing()
	master = null
	..()

/datum/movement_controller/torpedo_control/keys_changed(mob/user, keys, changed)
	if (changed & (KEY_FORWARD|KEY_BACKWARD|KEY_RIGHT|KEY_LEFT))
		if (keys & KEY_FORWARD)
			master.moveTarget(NORTH)
		if (keys & KEY_BACKWARD)
			master.moveTarget(SOUTH)
		if (keys & KEY_RIGHT)
			master.moveTarget(EAST)
		if (keys & KEY_LEFT)
			master.moveTarget(WEST)
	return

/datum/movement_controller/torpedo_control/process_move(mob/owner, keys)
	return 0

/datum/movement_controller/torpedo_control/hotkey(mob/user, name)
	..()
	if (master.controller != user)
		return
	switch (name)
		if("fire")
			master.fire()
		if("exit")
			master.inUse = FALSE
			master.exit()

/datum/movement_controller/torpedo_control/modify_keymap(client/C)
	..()
	C.apply_keybind("torpedo")
