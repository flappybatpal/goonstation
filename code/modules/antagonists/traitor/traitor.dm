/datum/antagonist/traitor
	id = ROLE_TRAITOR
	display_name = "traitor"

	/// Our initial uplink. This is only used to determine the popup shown to the player, so it isn't too important to track.
	var/obj/item/uplink/uplink
	/// A list of items that this traitor has purchased using their uplink. This tracks purchases made with any uplink, not just our own, so if a traitor is sassy and steals another antagonist's uplink, purchases will show up here too!
	var/list/datum/syndicate_buylist/purchased_items = list()
	/// If the traitor got a surplus crate, this list contains info about the items that were inside that crate.
	var/list/datum/syndicate_buylist/surplus_crate_items = list()

	give_equipment()
		if (isliving(src.owner.current))
			var/mob/living/traitor = src.owner.current
			uplink = traitor.give_antagonist_uplink(ROLE_TRAITOR)
		else
			logTheThing(LOG_DEBUG, src.owner.current, "Attempted to give antagonist equipment to [src.owner.current] but they were not of type living.")

	assign_objectives()
		var/datum/objective_set/objective_set_path
		#ifdef RP_MODE
		objective_set_path = pick(typesof(/datum/objective_set/traitor/rp_friendly))
		#else
		objective_set_path = pick(typesof(/datum/objective_set/traitor))
		#endif
		new objective_set_path(src.owner)

	do_popup(override)
		if (!override) // Display a different popup depending on the type of uplink we got
			if (!uplink)
				override = "traitorhard"
			else
				override = "traitorpda"
		..(override)

	handle_round_end(log_data)
		var/list/dat = ..() // while we could use . here instead of a cache var, this lets us manipulate the list in more ways
		if (length(dat))
			var/purchases = length(src.purchased_items)
			dat.Insert(2, "They purchased [purchases <= 0 ? "nothing" : "[purchases] item[s_es(purchases)]"] with their [syndicate_currency]![purchases <= 0 ? " [pick("Wow", "Dang", "Gosh", "Good work", "Good job")]!" : null]") // Insert at the second index, so it comes immediately after the "X was a traitor" text
			if (purchases)
				var/item_detail = "They purchased: "
				for (var/datum/syndicate_buylist/S as anything in src.purchased_items)
					item_detail += "[bicon(S.item)] [S.name], "
				item_detail = copytext(item_detail, 1, -2)
				if (length(src.surplus_crate_items))
					item_detail += "<br>Their surplus crate contained: "
					for (var/datum/syndicate_buylist/S as anything in src.surplus_crate_items)
						item_detail += "[bicon(S.item)] [S.name], "
					item_detail = copytext(item_detail, 1, -2)
				dat.Insert(3, item_detail)
		return dat
