local chunkPropertyUtils = {}

-- imported functions

local tRemove = table.remove

-- module code

function chunkPropertyUtils.getNestCount(map, chunk)
    return map.chunkToNests[chunk] or 0
end

function chunkPropertyUtils.getWormCount(map, chunk)
    return map.chunkToWorms[chunk] or 0
end

function chunkPropertyUtils.setWormCount(map, chunk, count)
    if (count == 0) then
	map.chunkToWorms[chunk] = nil
    else
	map.chunkToWorms[chunk] = count
    end
end

function chunkPropertyUtils.setNestCount(map, chunk, count)
    if (count == 0) then
	map.chunkToNests[chunk] = nil
    else
	map.chunkToNests[chunk] = count
    end
end

function chunkPropertyUtils.getNestCount(map, chunk)
    return map.chunkToNests[chunk] or 0
end

function chunkPropertyUtils.getChunkBase(map, chunk)
    return map.chunkToBase[chunk]
end

function chunkPropertyUtils.setChunkBase(map, chunk, base)
    map.chunkToBase[chunk] = base
end

function chunkPropertyUtils.getWormCount(map, chunk)
    return map.chunkToWorms[chunk] or 0
end

function chunkPropertyUtils.getEnemyStructureCount(map, chunk)
    return (map.chunkToNests[chunk] or 0) + (map.chunkToWorms[chunk] or 0)
end

function chunkPropertyUtils.getRetreatTick(map, chunk)
    return map.chunkToRetreats[chunk] or 0
end

function chunkPropertyUtils.getRallyTick(map, chunk)
    return map.chunkToRallys[chunk] or 0
end

function chunkPropertyUtils.setRallyTick(map, chunk, tick)
    map.chunkToRallys[chunk] = tick 
end

function chunkPropertyUtils.setRetreatTick(map, chunk, tick)
    map.chunkToRetreats[chunk] = tick
end

function chunkPropertyUtils.setResourceGenerator(map, chunk, resourceGenerator)
    if (resourceGenerator == 0) then
	map.chunkToResource[chunk] = nil
    else
	map.chunkToResource[chunk] = resourceGenerator
    end
end

function chunkPropertyUtils.getResourceGenerator(map, chunk)
    return map.chunkToResource[chunk] or 0
end

function chunkPropertyUtils.addResourceGenerator(map, chunk, delta)
    map.chunkToResource[chunk] = (map.chunkToResource[chunk] or 0) + delta
end

function chunkPropertyUtils.getPlayerBaseGenerator(map, chunk)
    return map.chunkToPlayerBase[chunk] or 0
end

function chunkPropertyUtils.addSquadToChunk(map, chunk, squad)
    if (chunk ~= squad.chunk) then
	local chunkToSquad = map.chunkToSquad
	chunkPropertyUtils.removeSquadFromChunk(map, squad)
	if not chunkToSquad[chunk] then
	    chunkToSquad[chunk] = {}
	end
	chunkToSquad[chunk][#chunkToSquad[chunk]+1] = squad

	squad.chunk = chunk
    end
end

function chunkPropertyUtils.removeSquadFromChunk(map, squad)
    local chunkToSquad = map.chunkToSquad
    if squad.chunk then
	local squads = chunkToSquad[squad.chunk]
	if squads then
	    for i=#squads, 1, -1 do    
		if (squads[i] == squad) then
		    tRemove(squads, i)
		    break
		end
	    end
	    if (#squads == 0) then
		chunkToSquad[squad.chunk] = nil
	    end
	end
    end
end

function chunkPropertyUtils.getSquadsOnChunk(map, chunk)
    return map.chunkToSquad[chunk] or {}
end

function chunkPropertyUtils.setPlayerBaseGenerator(map, chunk, playerGenerator)
    if (playerGenerator == 0) then
	map.chunkToPlayerBase[chunk] = nil
    else
	map.chunkToPlayerBase[chunk] = playerGenerator
    end
end

function chunkPropertyUtils.addPlayerBaseGenerator(map, chunk, playerGenerator)
    map.chunkToPlayerBase[chunk] = (map.chunkToPlayerBase[chunk] or 0) + playerGenerator
end

return chunkPropertyUtils
