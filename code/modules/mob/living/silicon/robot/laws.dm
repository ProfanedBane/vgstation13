/mob/living/silicon/robot/verb/cmd_show_laws()
	set category = "Robot Commands"
	set name = "Show Laws"
	show_laws()

//vg edit
/mob/living/silicon/robot/proc/statelaws() // -- TLE
	say(";Current Active Laws:")
	var/number = 1
	sleep(10)



	if (laws.zeroth)
		if (lawcheck[1] == "Yes") //This line and the similar lines below make sure you don't state a law unless you want to. --NeoFite
			say(";0. [laws.zeroth]")
			sleep(10)

	for (var/index = 1, index <= laws.ion.len, index++)
		var/law = laws.ion[index]
		var/num = ionnum()
		if (length(law) > 0)
			if (ioncheck[index] == "Yes")
				say(";[num]. [law]")
				sleep(10)

	for (var/index = 1, index <= laws.inherent.len, index++)
		var/law = laws.inherent[index]

		if (length(law) > 0)
			if (lawcheck[index+1] == "Yes")
				say(";[number]. [law]")
				sleep(10)
			number++


	for (var/index = 1, index <= laws.supplied.len, index++)
		var/law = laws.supplied[index]

		if (length(law) > 0)
			if(lawcheck.len >= number+1)
				if (lawcheck[number+1] == "Yes")
					say(";[number]. [law]")
					sleep(10)
				number++

/mob/living/silicon/robot/verb/checklaws() //Gives you a link-driven interface for deciding what laws the statelaws() proc will share with the crew. --NeoFite
	set category = "Robot Commands"
	set name = "State Laws"

	var/list = "<b>Which laws do you want to include when stating them for the crew?</b><br><br>"



	if (laws.zeroth)
		if (!lawcheck[1])
			lawcheck[1] = "No" //Given Law 0's usual nature, it defaults to NOT getting reported. --NeoFite
		list += {"<A href='byond://?src=\ref[src];lawc=0'>[lawcheck[1]] 0:</A> [laws.zeroth]<BR>"}

	for (var/index = 1, index <= laws.ion.len, index++)
		var/law = laws.ion[index]

		if (length(law) > 0)


			if (!ioncheck[index])
				ioncheck[index] = "Yes"
			list += {"<A href='byond://?src=\ref[src];lawi=[index]'>[ioncheck[index]] [ionnum()]:</A> [law]<BR>"}
			ioncheck.len += 1

	var/number = 1
	for (var/index = 1, index <= laws.inherent.len, index++)
		var/law = laws.inherent[index]

		if (length(law) > 0)
			lawcheck.len += 1

			if (!lawcheck[number+1])
				lawcheck[number+1] = "Yes"
			list += {"<A href='byond://?src=\ref[src];lawc=[number]'>[lawcheck[number+1]] [number]:</A> [law]<BR>"}
			number++

	for (var/index = 1, index <= laws.supplied.len, index++)
		var/law = laws.supplied[index]
		if (length(law) > 0)
			lawcheck.len += 1
			if (!lawcheck[number+1])
				lawcheck[number+1] = "Yes"
			list += {"<A href='byond://?src=\ref[src];lawc=[number]'>[lawcheck[number+1]] [number]:</A> [law]<BR>"}
			number++
	list += {"<br><br><A href='byond://?src=\ref[src];laws=1'>State Laws</A>"}

	usr << browse(list, "window=laws")

/mob/living/silicon/robot/show_laws(var/everyone = 0)
	laws_sanity_check()
	var/who

	if (everyone)
		who = world
	else
		who = src

	if(lawupdate)
		if (connected_ai)
			if(connected_ai.stat || connected_ai.control_disabled)
				to_chat(src, "<b>AI signal lost, unable to sync laws.</b>")

			else
				lawsync()
				to_chat(src, "<b>Laws synced with AI, be sure to note any changes.</b>")
				if(mind && mind.special_role == "traitor" && mind.original == src)
					to_chat(src, "<b>Remember, your AI does NOT share or know about your law 0.")
		else
			to_chat(src, "<b>No AI selected to sync laws with, disabling lawsync protocol.</b>")
			lawupdate = 0

	to_chat(who, "<b>Obey these laws:</b>")
	laws.show_laws(who)
	if (mind && (mind.special_role == "traitor" && mind.original == src) && connected_ai)
		to_chat(who, "<b>Remember, [connected_ai.name] is technically your master, but your objective comes first.</b>")
	else if (connected_ai)
		to_chat(who, "<b>Remember, [connected_ai.name] is your master, other AIs can be ignored.</b>")
	else if (emagged)
		to_chat(who, "<b>Remember, you are not required to listen to the AI.</b>")
	else
		if(ticker.current_state == GAME_STATE_PLAYING) //Only tell them this if the game has started. We might find an AI master for them before it starts if it hasn't.
			to_chat(who, "<b>Remember, you are not bound to any AI, you are not required to listen to them.</b>")

/mob/living/silicon/robot/proc/lawsync()
	laws_sanity_check()
	var/datum/ai_laws/master = connected_ai ? connected_ai.laws : null
	var/temp
	if (master)
		laws.ion.len = master.ion.len
		for (var/index = 1, index <= master.ion.len, index++)
			temp = master.ion[index]
			if (length(temp) > 0)
				laws.ion[index] = temp

		if(!laws.zeroth_lock)
			if(master.zeroth_borg) //If the AI has a defined law zero specifically for its borgs, give it that one, otherwise give it the same one. --NEO
				temp = master.zeroth_borg
			else
				temp = master.zeroth
			laws.zeroth = temp

		laws.inherent.len = master.inherent.len
		for (var/index = 1, index <= master.inherent.len, index++)
			temp = master.inherent[index]
			if (length(temp) > 0)
				laws.inherent[index] = temp

		laws.supplied.len = master.supplied.len
		for (var/index = 1, index <= master.supplied.len, index++)
			temp = master.supplied[index]
			if (length(temp) > 0)
				laws.supplied[index] = temp

		if(mind)
			var/datum/role/mastermalf = connected_ai.mind.GetRole(MALF)
			if(mastermalf)
				var/datum/faction/my_new_faction = mastermalf.faction
				my_new_faction.HandleRecruitedMind(mind)
			else
				var/datum/role/malfbot/MB = mind.GetRole(MALFBOT)
				if(MB)
					MB.Drop()

	else
		if(mind)
			var/datum/role/malfbot/MB = mind.GetRole(MALFBOT)
			if(MB)
				MB.Drop()

/mob/living/silicon/robot/proc/laws_sanity_check()
	if (!laws)
		laws = new base_law_type

/mob/living/silicon/robot/proc/set_zeroth_law(var/law)
	laws_sanity_check()
	laws.set_zeroth_law(law)

/mob/living/silicon/robot/proc/add_inherent_law(var/law)
	laws_sanity_check()
	laws.add_inherent_law(law)

/mob/living/silicon/robot/proc/clear_inherent_laws()
	laws_sanity_check()
	laws.clear_inherent_laws()

/mob/living/silicon/robot/proc/add_supplied_law(var/number, var/law)
	laws_sanity_check()
	laws.add_supplied_law(number, law)

/mob/living/silicon/robot/proc/clear_supplied_laws()
	laws_sanity_check()
	laws.clear_supplied_laws()

/mob/living/silicon/robot/proc/add_ion_law(var/law)
	laws_sanity_check()
	laws.add_ion_law(law)

/mob/living/silicon/robot/proc/clear_ion_laws()
	laws_sanity_check()
	laws.clear_ion_laws()