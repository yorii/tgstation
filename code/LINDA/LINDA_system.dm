/turf/proc/CanAtmosPass(turf/T)
	if(!istype(T))	return 0
	var/R
	if(blocks_air || T.blocks_air)
		R = 1

	for(var/obj/O in contents)
		if(!O.CanAtmosPass(T))
			R = 1
			if(O.BlockSuperconductivity()) 	//the direction and open/closed are already checked on CanAtmosPass() so there are no arguments
				var/D = get_dir(src, T)
				atmos_supeconductivity |= D
				D = get_dir(T, src)
				T.atmos_supeconductivity |= D
				return 0						//no need to keep going, we got all we asked

	for(var/obj/O in T.contents)
		if(!O.CanAtmosPass(src))
			R = 1
			if(O.BlockSuperconductivity())
				var/D = get_dir(src, T)
				atmos_supeconductivity |= D
				D = get_dir(T, src)
				T.atmos_supeconductivity |= D
				return 0

	var/D = get_dir(src, T)
	atmos_supeconductivity &= ~D
	D = get_dir(T, src)
	T.atmos_supeconductivity &= ~D

	if(!R)
		return 1

/atom/movable/proc/CanAtmosPass()
	return 1

/atom/proc/CanPass(atom/movable/mover, turf/target, height=1.5)
	return (!density || !height)

/turf/CanPass(atom/movable/mover, turf/target, height=1.5)
	if(!target) return 0

	if(istype(mover)) // turf/Enter(...) will perform more advanced checks
		return !density

	else // Now, doing more detailed checks for air movement and air group formation
		if(target.blocks_air||blocks_air)
			return 0

		for(var/obj/obstacle in src)
			if(!obstacle.CanPass(mover, target, height))
				return 0
		for(var/obj/obstacle in target)
			if(!obstacle.CanPass(mover, src, height))
				return 0

		return 1

/atom/movable/proc/BlockSuperconductivity() // objects that block air and don't let superconductivity act. Only firelocks atm.
	return 0

/turf/proc/CalculateAdjacentTurfs()
	atmos_adjacent_turfs_amount = 0
	for(var/direction in cardinal)
		var/turf/T = get_step(src, direction)
		if(!istype(T))
			continue
		var/counterdir = get_dir(T, src)
		if(CanAtmosPass(T))
			atmos_adjacent_turfs_amount += 1
			atmos_adjacent_turfs |= direction
			if(!(T.atmos_adjacent_turfs & counterdir))
				T.atmos_adjacent_turfs_amount += 1
			T.atmos_adjacent_turfs |= counterdir
		else
			atmos_adjacent_turfs &= ~direction
			if(T.atmos_adjacent_turfs & counterdir)
				T.atmos_adjacent_turfs_amount -= 1
			T.atmos_adjacent_turfs &= ~counterdir

//returns a list of adjacent turfs that can share air with this one.
//alldir includes adjacent diagonal tiles that can share
//	air with both of the related adjacent cardinal tiles
/turf/proc/GetAtmosAdjacentTurfs(alldir = 0)
	if (!istype(src, /turf/simulated))
		return list()

	var/adjacent_turfs = list()

	var/turf/simulated/curloc = src
	for (var/direction in cardinal)
		if(!(curloc.atmos_adjacent_turfs & direction))
			continue

		var/turf/simulated/S = get_step(curloc, direction)
		if (istype(S))
			adjacent_turfs += S
	if (!alldir)
		return adjacent_turfs

	for (var/direction in diagonals)
		var/matchingDirections = 0
		var/turf/simulated/S = get_step(curloc, direction)

		for (var/checkDirection in cardinal)
			if(!(S.atmos_adjacent_turfs & checkDirection))
				continue
			var/turf/simulated/checkTurf = get_step(S, checkDirection)

			if (checkTurf in adjacent_turfs)
				matchingDirections++

			if (matchingDirections >= 2)
				adjacent_turfs += S
				break

	return adjacent_turfs

/atom/movable/proc/air_update_turf(command = 0)
	if(!istype(loc,/turf) && command)
		return
	var/turf/T = get_turf(loc)
	T.air_update_turf(command)

/turf/proc/air_update_turf(command = 0)
	if(command)
		CalculateAdjacentTurfs()
	SSair.add_to_active(src,command)

/atom/movable/proc/move_update_air(turf/T)
    if(istype(T,/turf))
        T.air_update_turf(1)
    air_update_turf(1)

/atom/movable/proc/atmos_spawn_air(text, amount) //because a lot of people loves to copy paste awful code lets just make a easy proc to spawn your plasma fires
	var/turf/simulated/T = get_turf(src)
	if(!istype(T))
		return
	T.atmos_spawn_air(text, amount)

var/const/SPAWN_HEAT = 1
var/const/SPAWN_20C = 2
var/const/SPAWN_TOXINS = 4
var/const/SPAWN_OXYGEN = 8
var/const/SPAWN_CO2 = 16
var/const/SPAWN_NITROGEN = 32

var/const/SPAWN_N2O = 64

var/const/SPAWN_AIR = 256

/turf/simulated/proc/atmos_spawn_air(flag, amount)
	if(!text || !amount || !air)
		return

	var/datum/gas_mixture/G = new

	if(flag & SPAWN_20C)
		G.temperature = T20C

	if(flag & SPAWN_HEAT)
		G.temperature += 1000

	if(flag & SPAWN_TOXINS)
		G.gases[GAS_PL][MOLES] += amount
	if(flag & SPAWN_OXYGEN)
		G.gases[GAS_O2][MOLES] += amount
	if(flag & SPAWN_CO2)
		G.gases[GAS_CO2][MOLES] += amount
	if(flag & SPAWN_NITROGEN)
		G.gases[GAS_N2][MOLES] += amount

	if(flag & SPAWN_N2O)
		G.gases[GAS_N2O][MOLES] += amount

	if(flag & SPAWN_AIR)
		G.gases[GAS_O2][MOLES] += MOLES_O2STANDARD * amount
		G.gases[GAS_N2][MOLES] += MOLES_N2STANDARD * amount

	air.merge(G)
	SSair.add_to_active(src, 0)