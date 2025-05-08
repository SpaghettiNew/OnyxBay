/obj/item/material/twohanded/heavy_circular_saw
	name = "Heavy-Duty circular saw"
	desc = "For industrial-purpose cutting."
	icon = 'modular_stir/ushm_r.dmi'
	icon_state = "ushm_r"
	item_state = "ushm_r"
	hitsound = 'sound/effects/fighting/circsawhit.ogg'
	force = 15
	force_divisor = 0.5
	unwielded_force_divisor = 0.2
	sharp = 0
	edge = 0
	armor_penetration = 40
	w_class = ITEM_SIZE_HUGE
	mod_handy_w = 1.2
	mod_weight_w = 2.0
	mod_reach_w = 1.5
	mod_handy_u = 0.4
	mod_weight_u = 1.5
	mod_reach_u = 1.0
	slot_flags = SLOT_BACK
	force_wielded = 30
	attack_verb = list("attacked", "chopped", "cleaved", "torn", "cut")
	applies_material_colour = 0
	unbreakable = 1 // Because why should it break at all
	material_amount = 8
	var/saw_toggled_on = FALSE
	var/cutting_in_progress = FALSE
	var/toggle_on_sound = SFX_WELDER_ACTIVATE
	var/toggle_off_sound = SFX_WELDER_DEACTIVATE
	var/obj/item/circular_saw_blade/blade = /obj/item/circular_saw_blade

	drop_sound = SFX_DROP_AXE
	pickup_sound = SFX_PICKUP_AXE

/obj/item/material/twohanded/heavy_circular_saw/Initialize()
	if(ispath(blade))
		blade = new blade

	update_icon()

	. = ..()

/obj/item/material/twohanded/heavy_circular_saw/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W, /obj/item/circular_saw_blade))
		if(blade)
			to_chat(user, "Remove the current blade first.")
			return

		if(src.saw_toggled_on)
			if(istype(user, /mob/living/carbon/human))
				var/mob/living/carbon/human/H = user
				var/obj/item/organ/external/l_hand = H.get_organ(BP_L_HAND)
				var/obj/item/organ/external/r_hand = H.get_organ(BP_R_HAND)

				var/hand_that_will_be_cutted_off = user.get_active_hand()

				if(hand_that_will_be_cutted_off == l_hand)
					l_hand.droplimb(0, DROPLIMB_BLUNT)
				else
					r_hand.droplimb(0, DROPLIMB_BLUNT)
					
				if (H.can_feel_pain())
				H.emote("scream")
				return

			else
				to_chat(user, "<span class='danger'>Stop the saw first!</span>")
				return

		if(!user.drop(W, src))
			return
		blade = W

		user.visible_message("[user] slots \a [W] into \the [src].", "You slot \a [W] into \the [src].")
		update_icon()
		return

	..()

/obj/item/material/twohanded/heavy_circular_saw/attack_hand(mob/user as mob)
	if(blade && user.get_inactive_hand() == src)
		if(!saw_toggled_on)
			user.visible_message("[user] removes \the [blade] from \the [src].", "You remove \the [blade] from \the [src].")
			user.pick_or_drop(blade)
			blade = null
			update_icon()
		else
			to_chat(user, "<span class='danger'>Stop the saw first!</span>")

	else
		..()

/obj/item/material/twohanded/heavy_circular_saw/attack_self(mob/user as mob)
	setCuttingOn(!saw_toggled_on, usr)
	return


/obj/item/material/twohanded/heavy_circular_saw/proc/setCuttingOn(set_cutting, mob/M)
	var/turf/T = get_turf(src)
	//If we're turning it on
	if(set_cutting && !saw_toggled_on)
		if(M)
			to_chat(M, "<span class='notice'>You switch the [src] on.</span>")
		else if(T)
			T.visible_message("<span class='danger'>\The [src] turns on.</span>")

		playsound(get_turf(src), GET_SFX(toggle_on_sound), 100, TRUE)
		sharp = 1
		edge = 1
		damtype = "brute"
		hitsound = 'sound/effects/flare.ogg' // Surprisingly it sounds just perfect
		saw_toggled_on = TRUE
		set_light(1.0, 0.5, 2, 4.0, "#e38f46")
		update_icon()
		set_next_think(world.time)
		return
	//Otherwise
	else if(!set_cutting && saw_toggled_on)
		set_next_think(0)
		if(M)
			to_chat(M, "<span class='notice'>You switch \the [src] off.</span>")
		else if(T)
			T.visible_message("<span class='warning'>\The [src] turns off.</span>")
		playsound(get_turf(src), GET_SFX(toggle_off_sound), 100, TRUE)
		sharp = 0
		edge = 0
		damtype = "brute"
		hitsound = initial(hitsound)
		saw_toggled_on = FALSE
		set_light(0)
		update_icon()


///

/obj/item/circular_saw_blade
	name = "circular saw blade"
	desc = "Good for cutting walls and ATM-s."
	icon = 'icons/obj/items.dmi'
	icon_state = "nucleardisk"
	item_state = "card-id"
	w_class = ITEM_SIZE_TINY

	drop_sound = SFX_DROP_DISK
	pickup_sound = SFX_PICKUP_DISK

	is_poi = TRUE
	var/blade_resource = 3

///

/datum/element/circularsaw_sawable
	element_flags = ELEMENT_DETACH

/datum/element/circularsaw_sawable/attach(datum/target)
	. = ..()

	var/atom/target_atom = target
	if(!istype(target_atom))
		return ELEMENT_INCOMPATIBLE

	// register_signal(target_atom, SIGNAL_INDCIRCSAW_CUTTING, /datum/element/circularsaw_sawable/proc/start_indcircsaw_cutting(atom/clicked, mob/user))
	register_signal(target_atom, SIGNAL_ATTACKBY, /datum/element/circularsaw_sawable/proc/is_sawing_tool)

	// target_atom.verbs |= /atom/proc/indcircsaw_cutting

/datum/element/circularsaw_sawable/detach(datum/source, ...)
	unregister_signal(source, SIGNAL_ATTACKBY)

	// var/atom/target_atom = source

	// target_atom.verbs -= /atom/proc/indcircsaw_cutting

	return ..()

/datum/element/circularsaw_sawable/proc/is_sawing_tool(obj/item/tool, mob/user, atom/A, click_params)
	if(istype(tool, /obj/item/material/twohanded/heavy_circular_saw))
		A.indcircsaw_cutting(tool, user, A, click_params)
		return TRUE
	return FALSE

///

/atom/proc/indcircsaw_cutting(obj/item/material/twohanded/heavy_circular_saw/tool, mob/user, atom/A, click_params)
	if(!tool.saw_toggled_on)
		to_chat(user, "<span class='notice'>You mush turn [tool] first.</span>")
		return

	if(!tool.blade)
		to_chat(user, "<span class='notice'>[tool] have no blade.</span>")
		return

	if(tool.cutting_in_progress)
		to_chat(user, "<span class='notice'>[tool] is bussy.</span>")
		return

	playsound(loc, 'sound/items/Welder.ogg', 100, 1)
	INVOKE_ASYNC(tool, /obj/item/material/twohanded/heavy_circular_saw/proc/circularsaw_cutting_sparking, A)
	var/atom/movable/fake_overlay/circularsaw_cutting_overlay/effect = new(get_turf(A))

	if(!do_after(user, 20, A))
		tool.circularsaw_cutting_stop_sparking()
		qdel(effect)
		return
	
	if(istype(A, /turf/simulated/wall/))
		var/turf/simulated/wall/W = A
		W.dismantle_wall()
	else if(istype(A, /turf/simulated/floor/))
		var/turf/simulated/floor/F = A
		if(F.flooring)
			F.make_plating()
		else
			F.ReplaceWithLattice()
	else if(istype(A, /obj/structure/))
		var/turf/simulated/floor/S = A
		S.Destroy()
	else if(istype(A, /obj/machinery/))
		var/turf/simulated/floor/M = A
		M.Destroy()

	if(tool.blade)
		if(tool.blade.blade_resource <= 1)
			qdel(tool.blade)
			tool.blade = null
			to_chat(user, "<span class='notice'>[tool]'s blade shatters.</span>")
		else
			tool.blade.blade_resource -= 1

	tool.circularsaw_cutting_stop_sparking()
	qdel(effect)

///

/obj/item/material/twohanded/heavy_circular_saw/proc/circularsaw_cutting_sparking(atom/target) // Process of welding something
	var/datum/effect/effect/system/spark_spread/spark = new /datum/effect/effect/system/spark_spread(volume = 30)
	spark.set_up(1, 1, target)
	cutting_in_progress = TRUE
	while(cutting_in_progress)
		sleep(3)
		spark.start()

/obj/item/material/twohanded/heavy_circular_saw/proc/circularsaw_cutting_stop_sparking()
	cutting_in_progress = FALSE

/atom/movable/fake_overlay/circularsaw_cutting_overlay
	density = FALSE
	anchored = TRUE
	layer = ABOVE_PROJECTILE_LAYER
	plane = DEFAULT_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	icon = 'icons/effects/effects.dmi'
	icon_state = "circularsaw_sawing"

/atom/movable/fake_overlay/circularsaw_cutting_overlay/Initialize(mapload)
	. = ..()
	set_light(0.6, 0.5, 1.5, 2, "#e38f46")
	AddOverlays(emissive_appearance(icon, "[icon_state]-ea"))

///

/turf/simulated/wall/Initialize(mapload, materialtype, rmaterialtype)
	AddElement(/datum/element/circularsaw_sawable)
	. = ..()

/turf/simulated/floor/Initialize(mapload, ...)
	AddElement(/datum/element/circularsaw_sawable)
	. = ..()
	
/obj/structure/Initialize()
	AddElement(/datum/element/circularsaw_sawable)
	. = ..()

/obj/machinery/Initialize()
	AddElement(/datum/element/circularsaw_sawable)
	. = ..()
	
	
