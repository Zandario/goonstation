/datum/hud/funimage
	click_check = 0

/datum/hud/funimage/New(I)
	create_screen("image", "Fun Image (click to remove)", I, "", "1, 1", HUD_LAYER_3)
	..()

/datum/hud/funimage/relay_click(id, mob/user)
	if (id == "image")
		remove_client(user.client)
