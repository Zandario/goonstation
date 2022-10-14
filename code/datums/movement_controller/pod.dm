/datum/movement_controller/pod

	var/obj/machinery/vehicle/owner

	var/next_move = 0


	var/input_x = 0
	var/input_y = 0
	var/input_dir = 0

	var/velocity_x = 0
	var/velocity_y = 0
	var/velocity_dir = 0
	var/velocity_magnitude = 0

	var/velocity_max = 6
	var/velocity_max_no_input = 5
	var/accel = 2

	var/min_delay = 14

	var/matrix/M

	var/braking = 0
	var/brake_decel_mult = 0.3

	var/last_dir = 0

	var/shooting = FALSE

/datum/movement_controller/pod/New(owner)
	..()
	src.owner = owner
	M = matrix()

/datum/movement_controller/pod/disposing()
	owner = null
	..()

/datum/movement_controller/pod/keys_changed(mob/user, keys, changed)
	if(user != src.owner.pilot)
		return

	if (istype(src.owner, /obj/machinery/vehicle/escape_pod) || !owner)
		return

	if(changed & KEY_SHOCK)
		shooting = keys & KEY_SHOCK

	if (changed & (KEY_FORWARD|KEY_BACKWARD|KEY_RIGHT|KEY_LEFT|KEY_RUN|KEY_BOLT))
		if (!owner.engine) // fuck it, no better place to put this, only triggers on presses
			boutput(user, "[owner.ship_message("WARNING! No engine detected!")]")
			return

		braking = keys & (KEY_RUN | KEY_BOLT)

		input_x = 0
		input_y = 0
		if (keys & KEY_FORWARD)
			input_y += 1
		if (keys & KEY_BACKWARD)
			input_y -= 1
		if (keys & KEY_RIGHT)
			input_x += 1
		if (keys & KEY_LEFT)
			input_x -= 1

		var/input_magnitude = vector_magnitude(input_x, input_y)
		if (input_magnitude)
			input_x /= input_magnitude
			input_y /= input_magnitude
			input_dir = vector_to_dir(input_x,input_y)

		owner.set_dir(input_dir)
		owner.facing = input_dir

		if (input_magnitude)
			if (input_dir & (input_dir-1))
				owner.set_dir(NORTH)
				owner.transform = turn(M,arctan(input_y,input_x))
			else
				owner.transform = null
		last_dir = owner.dir

		if (input_x || input_y)
			attempt_move(user)


/datum/movement_controller/pod/update_owner_dir(atom/movable/ship) //after move, update dir
	owner.set_dir(last_dir)

/datum/movement_controller/pod/process_move(mob/user, keys)
	if(user != src.owner.pilot)
		return FALSE

	if (istype(src.owner, /obj/machinery/vehicle/escape_pod))
		return FALSE

	var/can_user_act = user && user == owner.pilot && !user.getStatusDuration("stunned") && !user.getStatusDuration("weakened") && !user.getStatusDuration("paralysis") && !isdead(user)

	if(shooting && owner.m_w_system?.active && can_user_act && !GET_COOLDOWN(owner.m_w_system, "fire"))
		owner.fire_main_weapon(user)

	if (next_move > world.time)
		return next_move - world.time

	velocity_magnitude = 0
	if (can_user_act)
		if (owner?.engine?.active)
			//We're on autopilot before the warp, NO FUCKING IT UP!
			if (owner.engine.warp_autopilot)
				return FALSE

			velocity_x	+= input_x * accel
			velocity_y  += input_y * accel


			if (owner.rcs && input_x == 0 && input_y == 0)
				braking = 1

			//braking
			if (braking)
				if(input_x * velocity_x <= 0)
					velocity_x = velocity_x * brake_decel_mult
				if(input_y * velocity_y <= 0)
					velocity_y = velocity_y * brake_decel_mult

				if (abs(velocity_x) + abs(velocity_y) < 1.3)
					velocity_x = 0
					velocity_y = 0

			//normalize and force speed cap
			velocity_magnitude = vector_magnitude(velocity_x, velocity_y)
			var/vel_max = velocity_max
			if (!input_x && !input_y)
				vel_max = velocity_max_no_input

			vel_max /= (owner.speed ? owner.speed : 1)

			if (velocity_magnitude > vel_max)
				velocity_x /= velocity_magnitude
				velocity_y /= velocity_magnitude

				velocity_x *= vel_max
				velocity_y *= vel_max

			velocity_dir = vector_to_dir(velocity_x,velocity_y)
			owner.flying = velocity_dir
	if (!velocity_magnitude)
		velocity_magnitude = vector_magnitude(velocity_x, velocity_y)


	var/delay = 0

	if (velocity_magnitude)
		delay = 10 / velocity_magnitude

	if (velocity_dir & (velocity_dir-1))
		delay *= DIAG_MOVE_DELAY_MULT

	delay = min(delay,min_delay)

	if (delay)
		var/target_turf = get_step(owner, velocity_dir)

		owner.glide_size = (32 / delay) * world.tick_lag
		for(var/mob/M in owner) //hey maybe move this somewhere better later. idk man its all chill thou, its all cool, dont worry about it buddy
			M.glide_size = owner.glide_size
			M.animate_movement = SYNC_STEPS

		step(owner, velocity_dir)
		owner.glide_size = (32 / delay) * world.tick_lag

		if (owner.loc != target_turf)
			velocity_x = 0
			velocity_y = 0
			velocity_magnitude = 0

		for(var/mob/M in owner) //hey maybe move this somewhere better later. idk man its all chill thou, its all cool, dont worry about it buddy
			M.glide_size = owner.glide_size
			M.animate_movement = SYNC_STEPS

	else
		delay = 1 // stopped

	next_move = world.time + delay
	return delay

/datum/movement_controller/pod/modify_keymap(client/C)
	..()
	C.apply_keybind("pod")
