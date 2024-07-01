/obj/channel
	anchored = ANCHORED
	density = 0
	icon = 'icons/obj/fluid.dmi'
	icon_state = "channel"
	name = "channel"
	desc = "A channel that can restrict liquid flow in one direction."
	flags = ALWAYS_SOLID_FLUID

	/// Fluid on the side that my Dir points to will need this amount to be able to cross.
	var/required_to_pass = 150


/obj/channel/New()
	..()
	src.invisibility = INVIS_ALWAYS_ISH
