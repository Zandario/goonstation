TYPEINFO(/obj/naval_mine)
	mats = 16

/obj/naval_mine
	name = "naval mine"
	desc = "This looks explosive!"
	icon = 'icons/obj/sealab_objects.dmi'
	icon_state = "mine_0"
	density = 1
	anchored = UNANCHORED

	deconstruct_flags = DECON_WRENCH | DECON_WELDER | DECON_MULTITOOL

	var/active = TRUE

	var/powerupsfx = 'sound/items/miningtool_on.ogg'
	var/powerdownsfx = 'sound/items/miningtool_off.ogg'

	var/boom_str = 26


/obj/naval_mine/New()
	..()
	animate_bumble(src)
	add_simple_light("naval_mine", list(255, 102, 102, 40))


/obj/naval_mine/get_desc()
	. += "It is [active ? "armed" : "disarmed"]."


/obj/naval_mine/ex_act(severity)
	return //nah


/obj/naval_mine/proc/boom()
	if(src.active)
		logTheThing(
			LOG_BOMBING,
			src.fingerprintslast,
			"A naval mine explodes at [log_loc(src)]. Last touched by [src.fingerprintslast ? "[src.fingerprintslast]" : "*null*"]."
		)
		src.blowthefuckup(boom_str)


/obj/naval_mine/attack_hand(var/mob/living/carbon/human/user)
	src.add_fingerprint(user)

	active = !active
	if(active)
		playsound(src.loc, powerupsfx, 50, 1, 0.1, 1)
		user.visible_message(SPAN_NOTICE("[user] activates [src]."), SPAN_NOTICE("You activate [src]."))
	else
		playsound(src.loc, powerdownsfx, 50, 1, 0.1, 1)
		user.visible_message(SPAN_NOTICE("[user] disarms [src]."),SPAN_NOTICE("You disarm [src]."))


/obj/naval_mine/attackby(obj/item/I, mob/user)
	if(isscrewingtool(I) || ispryingtool(I) || ispulsingtool(I))
		src.Attackhand(user)
	else
		boom()


/obj/naval_mine/Bumped(M as mob|obj)
	if(!istype(M, /mob/living/critter/aquatic) && !istype(M, /obj/critter/gunbot))
		boom()


/obj/naval_mine/bullet_act(var/obj/projectile/P)
	boom()



/obj/naval_mine/standard
	name = "standard naval mine"



/obj/naval_mine/rusted
	name = "rusted naval mine"
	icon_state = "mine_1"
	boom_str = 15



/obj/naval_mine/vandalized
	name = "vandalized naval mine"
	icon_state = "mine_2"
	boom_str = 29



/obj/naval_mine/syndicate
	name = "syndicate naval mine"
	icon_state = "mine_3"
	boom_str = 32
