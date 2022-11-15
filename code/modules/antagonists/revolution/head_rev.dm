/// Effectively traitor lite, with random objectives and no uplink. Created through a random event.
/datum/antagonist/head_rev
	id = ROLE_HEAD_REV
	display_name = "head rev"

/datum/antagonist/sleeper_agent/announce()
	boutput(owner.current, "<h3><span class='alert'>You have awakened as a Revolutionary Head [display_name]!</span></h3>")
