if unitGroupUtilsG then
    return unitGroupUtilsG
end
local unitGroupUtils = {}

-- imports

local mapUtils = require("MapUtils")
local constants = require("Constants")
local chunkPropertyUtils = require("ChunkPropertyUtils")
local chunkUtils = require("ChunkUtils")
local movementUtils = require("MovementUtils")

-- constants

local DEFINES_GROUP_FINISHED = defines.group_state.finished

local SQUAD_QUEUE_SIZE = constants.SQUAD_QUEUE_SIZE

local DEFINES_GROUP_STATE_ATTACKING_TARGET = defines.group_state.attacking_target
local DEFINES_GROUP_STATE_ATTACKING_DISTRACTION = defines.group_state.attacking_distraction

local SQUAD_RETREATING = constants.SQUAD_RETREATING
local SQUAD_GUARDING = constants.SQUAD_GUARDING

local NO_RETREAT_SQUAD_SIZE_BONUS_MAX = constants.NO_RETREAT_SQUAD_SIZE_BONUS_MAX

local AI_MAX_BITER_GROUP_SIZE = constants.AI_MAX_BITER_GROUP_SIZE
local AI_SQUAD_MERGE_THRESHOLD = constants.AI_SQUAD_MERGE_THRESHOLD

-- imported functions

local tRemove = table.remove

local mRandom = math.random

local findMovementPosition = movementUtils.findMovementPosition
local removeSquadFromChunk = chunkPropertyUtils.removeSquadFromChunk

local mLog = math.log10

local mMin = math.min

local getSquadsOnChunk = chunkPropertyUtils.getSquadsOnChunk

local getNeighborChunks = mapUtils.getNeighborChunks

-- module code

function unitGroupUtils.findNearbyRetreatingSquad(map, chunk)

    local squads = getSquadsOnChunk(map, chunk)
    for i=1,#squads do
        local squad = squads[i]
        local unitGroup = squad.group
        if unitGroup and unitGroup.valid and (squad.status == SQUAD_RETREATING) then
            return squad
        end
    end

    local neighbors = getNeighborChunks(map, chunk.x, chunk.y)

    for i=1,#neighbors do
        local neighbor = neighbors[i]
        if neighbor ~= -1 then
            squads = getSquadsOnChunk(map, neighbor)
            for squadIndex=1,#squads do
                local squad = squads[squadIndex]
                local unitGroup = squad.group
                if unitGroup and unitGroup.valid and (squad.status == SQUAD_RETREATING) then
                    return squad
                end
            end
        end
    end
    return nil
end

function unitGroupUtils.findNearbySquad(map, chunk)

    local squads = getSquadsOnChunk(map, chunk)
    for i=1,#squads do
        local squad = squads[i]
        local unitGroup = squad.group
        if unitGroup and unitGroup.valid then
            return squad
        end
    end

    local neighbors = getNeighborChunks(map, chunk.x, chunk.y)

    for i=1,#neighbors do
        local neighbor = neighbors[i]
        if neighbor ~= -1 then
            squads = getSquadsOnChunk(map, neighbor)
            for squadIndex=1,#squads do
                local squad = squads[squadIndex]
                local unitGroup = squad.group
                if unitGroup and unitGroup.valid then
                    return squad
                end
            end
        end
    end

    return nil
end

function unitGroupUtils.createSquad(position, surface, group, settlers)
    local unitGroup = group or surface.create_unit_group({position=position})

    local squad = {
        group = unitGroup,
        status = SQUAD_GUARDING,
        penalties = {},
        rabid = false,
        frenzy = false,
        settlers = settlers or false,
        kamikaze = false,
        frenzyPosition = {x = 0,
                          y = 0},
        cycles = 10,
        maxDistance = 0,
        groupNumber = unitGroup.group_number,
        originPosition = {x = 0,
                          y = 0},
        chunk = -1
    }

    if position then
        squad.originPosition.x = position.x
        squad.originPosition.y = position.y
    elseif group then
        squad.originPosition.x = group.position.x
        squad.originPosition.y = group.position.y
    end

    return squad
end

function unitGroupUtils.cleanSquads(natives, iterator)
    local squads = natives.groupNumberToSquad
    local map = natives.map

    local k, squad = next(squads, iterator)
    local nextK
    for i=1,2 do
        if not k then
            return nil
        elseif not squad.group.valid then
            removeSquadFromChunk(map, squad)
            if (map.regroupIterator == k) then
                map.regroupIterator = nil
            end
            nextK,squad = next(squads, k)
            squads[k] = nil
            k = nextK
        end
    end
    return k
end

function unitGroupUtils.membersToSquad(cmd, size, members, overwriteGroup)
    for i=1,size do
        local member = members[i]
        if member.valid and (overwriteGroup or (not overwriteGroup and not member.unit_group)) then
            member.set_command(cmd)
        end
    end
end

function unitGroupUtils.calculateKamikazeThreshold(memberCount, natives)
    local squadSizeBonus = mLog((memberCount / natives.attackWaveMaxSize) + 0.1) + 1
    return natives.kamikazeThreshold + (NO_RETREAT_SQUAD_SIZE_BONUS_MAX * squadSizeBonus)
end

function unitGroupUtils.recycleBiters(natives, biters)
    local unitCount = #biters
    for i=1,unitCount do
        biters[i].destroy()
    end
    natives.points = natives.points + (unitCount * natives.unitRefundAmount)
end

function unitGroupUtils.regroupSquads(natives, iterator)
    local map = natives.map
    local squads = natives.groupNumberToSquad

    local k, squad = iterator, nil
    for i=1,SQUAD_QUEUE_SIZE do
        k,squad = next(squads, k)
        if not k then
            return nil
        else
            local group = squad.group
            if group and group.valid then
                local groupState = group.state
                if (groupState ~= DEFINES_GROUP_STATE_ATTACKING_TARGET) and
                    (groupState ~= DEFINES_GROUP_STATE_ATTACKING_DISTRACTION)
                then
                    local memberCount = #group.members
                    if (memberCount < AI_SQUAD_MERGE_THRESHOLD) then
                        local status = squad.status
                        local chunk = squad.chunk

                        if (chunk ~= -1) then
                            for _,mergeSquad in pairs(getSquadsOnChunk(map, chunk)) do
                                if (mergeSquad ~= squad) then
                                    local mergeGroup = mergeSquad.group
                                    if mergeGroup and mergeGroup.valid and (mergeSquad.status == status) then
                                        local mergeGroupState = mergeGroup.state
                                        if (mergeGroupState ~= DEFINES_GROUP_STATE_ATTACKING_TARGET) and
                                            (mergeGroupState ~= DEFINES_GROUP_STATE_ATTACKING_DISTRACTION)
                                        then
                                            local mergeMembers = mergeGroup.members
                                            local mergeCount = #mergeMembers
                                            if ((mergeCount + memberCount) < AI_MAX_BITER_GROUP_SIZE) then
                                                for memberIndex=1, mergeCount do
                                                    group.add_member(mergeMembers[memberIndex])
                                                end
                                                mergeGroup.destroy()
                                            end
                                            squad.status = SQUAD_GUARDING
                                            memberCount = memberCount + mergeCount
                                            if (memberCount > AI_SQUAD_MERGE_THRESHOLD) then
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return k
end

unitGroupUtilsG = unitGroupUtils
return unitGroupUtils
