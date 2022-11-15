/client/proc/gearspawn_traitor()
	set category = "Commands"
	set name = "Call Syndicate"
	set desc="Teleports useful items to your location."

	if (usr.stat || !isliving(usr) || isintangible(usr))
		usr.show_text("You can't use this command right now.", "red")
		return

	var/uplink_path = get_uplink_type(usr, /obj/item/uplink/syndicate)
	var/obj/item/uplink/syndicate/U = new uplink_path(usr.loc)
	if (!usr.put_in_hand(U))
		U.set_loc(get_turf(usr))
		usr.show_text("<h3>Uplink spawned. You can find it on the floor at your current location.</h3>", "blue")
	else
		usr.show_text("<h3>Uplink spawned. You can find it in your active hand.</h3>", "blue")

	if (usr.mind && istype(usr.mind))
		U.lock_code_autogenerate = 1
		U.setup(usr.mind)
		usr.show_text("<h3>The password to your uplink is '[U.lock_code]'.</h3>", "blue")
		usr.mind.store_memory("<B>Uplink password:</B> [U.lock_code].")

	usr.verbs -= /client/proc/gearspawn_traitor

	return

/client/proc/gearspawn_wizard()
	set category = "Commands"
	set name = "Call Wizards"
	set desc="Teleports useful items to your location."

	if (usr.stat || !isliving(usr) || isintangible(usr))
		usr.show_text("You can't use this command right now.", "red")
		return

	if (!ishuman(usr))
		boutput(usr, "<span class='alert'>You must be a human to use this!</span>")
		return

	var/mob/living/carbon/human/H = usr

	equip_wizard(H, 1)

	usr.verbs -= /client/proc/gearspawn_wizard

	return

/mob/living/proc/give_antagonist_uplink(role_id)
	var/obj/item/uplink/uplink
	if (!ishuman(src))
		boutput(src, "<span class='alert'>Due to your lack of opposable thumbs, the Syndicate was unable to provide you with an uplink. That's biology for you.</span>")
		return FALSE
	var/mob/living/carbon/human/H = src
	var/obj/item/uplink_source = null
	var/loc_string = ""

	// step 1 of uplinkification: find a source! prioritize PDAs, then try headsets
	if (istype(H.belt, /obj/item/device/pda2) || (istype(H.belt, /obj/item/device/radio) && (role_id != ROLE_SPY_THIEF)))
		uplink_source = H.belt
		loc_string = "on your belt"
	else if (istype(H.wear_id, /obj/item/device/pda2))
		uplink_source = H.wear_id
		loc_string = "in your ID slot"
	else if (istype(H.r_store, /obj/item/device/pda2))
		uplink_source = H.r_store
		loc_string = "in your pocket"
	else if (istype(H.l_store, /obj/item/device/pda2))
		uplink_source = H.l_store
		loc_string = "in your pocket"
	else if (istype(H.ears, /obj/item/device/radio))
		uplink_source = H.ears
		loc_string = "on your head"

	// step 2 of uplinkification: put the actual uplink into the item, and save info about it to the owner's memory
	// if we find a valid item source, then we create one
	if (istype(uplink_source, /obj/item/device/pda2))
		var/uplink_path = get_uplink_type(H, /obj/item/uplink/integrated/pda)
		uplink = new uplink_path(uplink_source)
	else if (istype(uplink_source, /obj/item/device/radio))
		var/uplink_path = get_uplink_type(H, /obj/item/uplink/integrated/radio)
		uplink = new uplink_path(uplink_source)
	else
		if (role_id == ROLE_SPY_THIEF)
			var/obj/item/device/pda2/P = new /obj/item/device/pda2(get_turf(H))
			var/obj/item/uplink/integrated/pda/spy/T = new /obj/item/uplink/integrated/pda/spy(P)
			uplink = P
			uplink_source = P
			if (!(H.equip_if_possible(P, H.slot_in_backpack)))
				loc_string = "on the ground beneath you"
			else
				loc_string = "in [H.back] on your back"
		else
			var/uplink_path = get_uplink_type(H, /obj/item/uplink/syndicate)
			var/obj/item/uplink/syndicate/S = new uplink_path(get_turf(H))
			uplink = S
			uplink_source = S
			S.lock_code_autogenerate = TRUE
			if (!(H.equip_if_possible(S, H.slot_in_backpack)))
				loc_string = "on the ground beneath you"
			else
				loc_string = "in [H.back] on your back"
		uplink.setup(H, uplink_source)

	// step 3 of uplinkification: inform the player about it and store the code in their memory
	if (istype(uplink_source, /obj/item/device/pda2))
		boutput(H, "The Syndicate have cunningly disguised an uplink as your [uplink_source.name] [loc_string]. Simply enter the the code <b>\"[uplink.lock_code]\"</b> as the ringtone in its Messenger app to unlock its hidden features.")
		logTheThing(LOG_DEBUG, H, "Traitor PDA uplink created: [uplink_source.name]. Location given: [loc_string]. Code: [uplink.lock_code]")
		H.store_memory("<b>Uplink password:</b> [uplink.lock_code].")
	else if (istype(uplink_source, /obj/item/device/radio))
		var/obj/item/device/radio/R = uplink_source
		boutput(H, "The Syndicate have cunningly disguised an uplink as your [uplink_source.name] [loc_string]. Simply dial the frequency <b>\"[R.traitor_frequency]\"</b> to unlock its hidden features.")
		logTheThing(LOG_DEBUG, H, "Traitor uplink created: [uplink_source.name]. Location given: [loc_string]. Frequency: [R.traitor_frequency]")
		H.store_memory("<b>Uplink frequency:</b> [R.traitor_frequency].")
	else
		boutput(H, "The Syndicate have provided you with a standalone uplink [loc_string]. Simply dial the frequency <b>\"[uplink.lock_code]\"</b> to unlock its hidden features.")
		logTheThing(LOG_DEBUG, H, "Traitor standalone uplink created: [uplink_source.name]. Location given: [loc_string]. Frequency: [uplink.lock_code]")
		H.store_memory("<b>Uplink frequency:</b> [uplink.lock_code].")

	return uplink

/proc/equip_conspirator(mob/living/carbon/human/traitor_mob)
	if (!(traitor_mob && ishuman(traitor_mob)))
		return

	if (ticker?.mode && istype(ticker.mode, /datum/game_mode/conspiracy))
		var/datum/game_mode/conspiracy/C = ticker.mode
		var/the_frequency = C.agent_radiofreq

		var/obj/item/device/radio/headset/H
		if (istype(traitor_mob.ears, /obj/item/device/radio/headset))
			H = traitor_mob.ears
		else
			H = new /obj/item/device/radio/headset(traitor_mob)
			if (!traitor_mob.r_store)
				traitor_mob.equip_if_possible(H, traitor_mob.slot_r_store)
			else if (!traitor_mob.l_store)
				traitor_mob.equip_if_possible(H, traitor_mob.slot_l_store)
			else if (istype(traitor_mob.back, /obj/item/storage/) && traitor_mob.back.contents.len < 7)
				traitor_mob.equip_if_possible(H, traitor_mob.slot_in_backpack)
			else
				traitor_mob.put_in_hand_or_drop(H)
		H.wiretap = new /obj/item/device/radio_upgrade/conspirator
		H.secure_classes["z"] = RADIOCL_SYNDICATE
		H.set_secure_frequency("z",the_frequency)

	traitor_mob.show_antag_popup("conspiracy")

/proc/equip_spy_theft(mob/living/carbon/human/traitor_mob)
	if (!(traitor_mob && ishuman(traitor_mob)))
		return

	if (!traitor_mob.r_store)
		traitor_mob.equip_if_possible(new /obj/item/camera/spy(traitor_mob), traitor_mob.slot_r_store)
	else if (!traitor_mob.l_store)
		traitor_mob.equip_if_possible(new /obj/item/camera/spy(traitor_mob), traitor_mob.slot_l_store)
	else if (istype(traitor_mob.back, /obj/item/storage/) && traitor_mob.back.contents.len < 7)
		traitor_mob.equip_if_possible(new /obj/item/camera/spy(traitor_mob), traitor_mob.slot_in_backpack)
	else
		var/obj/F2 = new /obj/item/camera/spy(get_turf(traitor_mob))
		traitor_mob.put_in_hand_or_drop(F2)

	traitor_mob.give_antagonist_uplink(ROLE_SPY_THIEF)
	traitor_mob.show_antag_popup("spythief")


/proc/equip_syndicate(mob/living/carbon/human/synd_mob, var/leader = 0)
	if (!ishuman(synd_mob))
		return

	if(leader == 1)
		synd_mob.equip_if_possible(new /obj/item/clothing/head/helmet/space/syndicate/commissar_cap(synd_mob), synd_mob.slot_head)
		synd_mob.equip_if_possible(new /obj/item/clothing/suit/space/syndicate/commissar_greatcoat(synd_mob), synd_mob.slot_wear_suit)
		synd_mob.equip_if_possible(new /obj/item/device/radio/headset/syndicate/leader(synd_mob), synd_mob.slot_ears)
		synd_mob.equip_if_possible(new /obj/item/swords_sheaths/nukeop(synd_mob), synd_mob.slot_r_hand)
		synd_mob.equip_if_possible(new /obj/item/device/nukeop_commander_uplink(synd_mob), synd_mob.slot_l_hand)
	else
		synd_mob.equip_if_possible(new /obj/item/device/radio/headset/syndicate(synd_mob), synd_mob.slot_ears)

	synd_mob.equip_if_possible(new /obj/item/clothing/under/misc/syndicate(synd_mob), synd_mob.slot_w_uniform)
	synd_mob.equip_if_possible(new /obj/item/clothing/shoes/swat/noslip(synd_mob), synd_mob.slot_shoes)
	synd_mob.equip_if_possible(new /obj/item/clothing/gloves/swat(synd_mob), synd_mob.slot_gloves)
	synd_mob.equip_if_possible(new /obj/item/storage/backpack/syndie/tactical(synd_mob), synd_mob.slot_back)
	synd_mob.equip_if_possible(new /obj/item/clothing/mask/gas/swat/syndicate(synd_mob), synd_mob.slot_wear_mask)
	synd_mob.equip_if_possible(new /obj/item/clothing/glasses/sunglasses(synd_mob), synd_mob.slot_glasses)
	synd_mob.equip_if_possible(new /obj/item/requisition_token/syndicate(synd_mob), synd_mob.slot_r_store)
	synd_mob.equip_if_possible(new /obj/item/tank/emergency_oxygen/extended(synd_mob), synd_mob.slot_l_store)

	synd_mob.equip_sensory_items()

	var/obj/item/card/id/syndicate/I = new /obj/item/card/id/syndicate(synd_mob) // for whatever reason, this is neccessary
	if(leader)
		I = new /obj/item/card/id/syndicate/commander(synd_mob)
	I.icon_state = "id"
	I.icon = 'icons/obj/items/card.dmi'
	synd_mob.equip_if_possible(I, synd_mob.slot_wear_id)

	var/obj/item/implant/revenge/microbomb/M = new /obj/item/implant/revenge/microbomb(synd_mob)
	M.implanted = 1
	synd_mob.implant.Add(M)
	M.implanted(synd_mob)

/proc/alive_player_count()
	. = 0
	for(var/client/C)
		var/mob/M = C.mob
		if(!M || istype(M, /mob/new_player))
			continue
		if (!isdead(M) && isliving(M))
			.++

/// returns a decimal representing the percentage of alive crew that are also antags
/proc/get_alive_antags_percentage()
	var/alive = alive_player_count()
	var/alive_antags = ticker.mode.traitors.len + length(ticker.mode.Agimmicks)

	for (var/datum/mind/antag in ticker.mode.traitors)
		var/mob/M = antag.current
		if (!M) continue
		if (!M.client || isdead(M))
			alive_antags--
	for (var/datum/mind/antag in ticker.mode.Agimmicks)
		var/mob/M = antag.current
		if (!M) continue
		if (!M.client || isdead(M))
			alive_antags--

	if (!alive)
		return 0
	else
		return (alive_antags / alive)

/// returns a decimal representing the percentage of dead crew (non-observers) to all crew
/proc/get_dead_crew_percentage()
	var/all = 0
	var/dead = 0
	var/observer = 0

	for(var/client/C)
		var/mob/M = C.mob
		if(!M || isnewplayer(M)) continue
		if (isdead(M) && !isliving(M))
			dead++
			if (M.mind?.joined_observer)
				observer++
		all++

	if (!all)
		return 0
	else
		return ((dead - observer) / all)

/// Associative list of role defines and their respective client preferences.
var/list/roles_to_prefs = list(
	ROLE_TRAITOR = "be_traitor",
	ROLE_SPY_THIEF = "be_spy",
	ROLE_NUKEOP = "be_syndicate",
	ROLE_VAMPIRE = "be_vampire",
	ROLE_GANG_LEADER = "be_gangleader",
	ROLE_WIZARD = "be_wizard",
	ROLE_CHANGELING = "be_changeling",
	ROLE_WEREWOLF = "be_werewolf",
	ROLE_BLOB = "be_blob",
	ROLE_WRAITH = "be_wraith",
	ROLE_HEAD_REV = "be_revhead",
	ROLE_CONSPIRATOR = "be_conspirator",
	ROLE_ARCFIEND = "be_arcfiend",
	ROLE_FLOCKMIND = "be_flock",
	ROLE_MISC = "be_misc"
	)

/**
  * Return the name of a preference variable for the given role define.
  *
  * Arguments:
  * * role - role to return a client preference for.
  */
/proc/get_preference_for_role(var/role)
	return roles_to_prefs[role]


/**
  * Returns a path of a (presumably) valid uplink dependent on the user's mind.
  *
  * Arguments:
  * * target - the mob that will own the uplink.
  *	* uplink - the path of the uplink type that you wish to spawn
  */
/proc/get_uplink_type(mob/target, obj/item/uplink/uplink)
	var/added_text
	switch(target?.mind?.special_role)
		if(ROLE_TRAITOR)
			added_text = "traitor"
		if(ROLE_SPY_THIEF) //Uses its own proc to create it, but leaving this here in case a refactor of it comes by
			added_text = "spy_thief"
		if("spy")
			added_text = "spy"
		if(ROLE_HEAD_REV)
			added_text = "rev"
		if(ROLE_NUKEOP)
			added_text = "nukeop"
		if(ROLE_OMNITRAITOR)
			added_text = "omni"
	return text2path("[uplink]/[added_text]")
