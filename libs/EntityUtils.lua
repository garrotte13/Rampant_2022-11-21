local entityUtils = {}

-- imports

local mapUtils = require("MapUtils")
local constants = require("Constants")

-- constants

local BUILDING_PHEROMONES = constants.BUILDING_PHEROMONES

local PLAYER_BASE_GENERATOR = constants.PLAYER_BASE_GENERATOR

local NEST_BASE = constants.NEST_BASE
local WORM_BASE = constants.WORM_BASE

local DEFINES_DIRECTION_EAST = defines.direction.east
local DEFINES_WIRE_TYPE_RED = defines.wire_type.red
local DEFINES_WIRE_TYPE_GREEN = defines.wire_type.green

-- imported functions

local getChunkByIndex = mapUtils.getChunkByIndex

local mFloor = math.floor

-- module code

local function getEntityOverlapChunks(regionMap, entity)
    local boundingBox = entity.prototype.selection_box;
    
    local leftTopChunk
    local rightTopChunk
    local leftBottomChunk
    local rightBottomChunk
    
    if (boundingBox ~= nil) then
        local center = entity.position
        local topXOffset
        local topYOffset
        
        local bottomXOffset
        local bottomYOffset
        
        if (entity.direction == DEFINES_DIRECTION_EAST) then
            topXOffset = boundingBox.left_top.y
            topYOffset = boundingBox.left_top.x
            bottomXOffset = boundingBox.right_bottom.y
            bottomYOffset = boundingBox.right_bottom.x
        else
            topXOffset = boundingBox.left_top.x
            topYOffset = boundingBox.left_top.y
            bottomXOffset = boundingBox.right_bottom.x
            bottomYOffset = boundingBox.right_bottom.y
        end
        
        local leftTopChunkX = mFloor((center.x + topXOffset) * 0.03125)
        local leftTopChunkY = mFloor((center.y + topYOffset) * 0.03125)
        
        -- used to force things on chunk boundary to not spill over 0.0001
        local rightTopChunkX = mFloor((center.x + bottomXOffset - 0.0001) * 0.03125)
        local rightTopChunkY = leftTopChunkY
        
        -- used to force things on chunk boundary to not spill over 0.0001
        local leftBottomChunkX = leftTopChunkX
        local leftBottomChunkY = mFloor((center.y + bottomYOffset - 0.0001) * 0.03125)
	
        local rightBottomChunkX = rightTopChunkX 
        local rightBottomChunkY = leftBottomChunkY
        
        leftTopChunk = getChunkByIndex(regionMap, leftTopChunkX, leftTopChunkY)
        if (leftTopChunkX ~= rightTopChunkX) then
            rightTopChunk = getChunkByIndex(regionMap, rightTopChunkX, rightTopChunkY)
        end
        if (leftTopChunkY ~= leftBottomChunkY) then
            leftBottomChunk = getChunkByIndex(regionMap, leftBottomChunkX, leftBottomChunkY)
        end
        if (leftTopChunkX ~= rightBottomChunkX) and (leftTopChunkY ~= rightBottomChunkY) then
            rightBottomChunk = getChunkByIndex(regionMap, rightBottomChunkX, rightBottomChunkY)
        end
    end
    return leftTopChunk, rightTopChunk, leftBottomChunk, rightBottomChunk
end

function entityUtils.addRemovePlayerEntity(regionMap, entity, natives, addObject, creditNatives)
    local leftTop, rightTop, leftBottom, rightBottom
    local entityValue
    if (BUILDING_PHEROMONES[entity.type] ~= nil) and (entity.force.name == "player") then
        entityValue = BUILDING_PHEROMONES[entity.type]

        leftTop, rightTop, leftBottom, rightBottom = getEntityOverlapChunks(regionMap, entity)
        if not addObject then
    	    if creditNatives then
    		natives.points = natives.points + entityValue
    	    end
    	    entityValue = -entityValue
    	end
    	if (leftTop ~= nil) then
    	    leftTop[PLAYER_BASE_GENERATOR] = leftTop[PLAYER_BASE_GENERATOR] + entityValue
    	end
    	if (rightTop ~= nil) then
    	    rightTop[PLAYER_BASE_GENERATOR] = rightTop[PLAYER_BASE_GENERATOR] + entityValue
    	end
    	if (leftBottom ~= nil) then
    	    leftBottom[PLAYER_BASE_GENERATOR] = leftBottom[PLAYER_BASE_GENERATOR] + entityValue
    	end
    	if (rightBottom ~= nil) then
    	    rightBottom[PLAYER_BASE_GENERATOR] = rightBottom[PLAYER_BASE_GENERATOR] + entityValue
    	end
    end
end

local function addBaseToChunk(chunk, entity, base)
    local indexChunk
    local indexBase
    if (entity.type == "unit-spawner") then
	indexChunk = chunk[NEST_BASE]
	indexBase = base.nests
    elseif (entity.type == "turret") then
	indexChunk = chunk[WORM_BASE]
	indexBase = base.worms
    end
    indexChunk[entity.unit_number] = base
    indexBase[entity.unit_number] = entity
end

local function removeBaseFromChunk(chunk, entity)
    local indexChunk
    if (entity.type == "unit-spawner") then
	indexChunk = chunk[NEST_BASE]
    elseif (entity.type == "turret") then
	indexChunk = chunk[WORM_BASE]
    end
    local base = indexChunk[entity.unit_number]
    local indexBase
    if base then
	if (entity.type == "unit-spawner") then
	    indexBase = base.nests
	elseif (entity.type == "turret") then
	    indexBase = base.worms
	end
	indexBase[entity.unit_number] = nil
    end
end


function entityUtils.addEnemyBase(regionMap, entity, base)
    local entityType = entity.type
    if ((entityType == "unit-spawner") or (entityType == "turret")) and (entity.force.name == "enemy") then
        local leftTop, rightTop, leftBottom, rightBottom = getEntityOverlapChunks(regionMap, entity)
	
	if (leftTop ~= nil) then
	    addBaseToChunk(leftTop, entity, base)
	end
	if (rightTop ~= nil) then
	    addBaseToChunk(rightTop, entity, base)
	end
	if (leftBottom ~= nil) then
	    addBaseToChunk(leftBottom, entity, base)
	end
	if (rightBottom ~= nil) then
	    addBaseToChunk(rightBottom, entity, base)
	end	
    end
end

function entityUtils.removeEnemyBase(regionMap, entity)
    local entityType = entity.type
    if ((entityType == "unit-spawner") or (entityType == "turret")) and (entity.force.name == "enemy") then
	local leftTop, rightTop, leftBottom, rightBottom = getEntityOverlapChunks(regionMap, entity)

	if (leftTop ~= nil) then
	    removeBaseFromChunk(leftTop, entity)
	end
	if (rightTop ~= nil) then
	    removeBaseFromChunk(rightTop, entity)
	end
	if (leftBottom ~= nil) then
	    removeBaseFromChunk(leftBottom, entity)
	end
	if (rightBottom ~= nil) then
	    removeBaseFromChunk(rightBottom, entity)
	end
    end
end

function entityUtils.makeImmortalEntity(surface, entity)
    local repairPosition = entity.position
    local repairName = entity.name
    local repairForce = entity.force
    local repairDirection = entity.direction

    local wires
    if (entity.type == "electric-pole") then
	wires = entity.neighbours
    end
    entity.destroy()
    local newEntity = surface.create_entity({position=repairPosition,
					     name=repairName,
					     direction=repairDirection,
					     force=repairForce})
    if wires then
	for connectType,neighbourGroup in pairs(wires) do
	    if connectType == "copper" then
		for _,v in pairs(neighbourGroup) do
		    newEntity.connect_neighbour(v);
		end
	    elseif connectType == "red" then
		for _,v in pairs(neighbourGroup) do
		    newEntity.connect_neighbour({wire = DEFINES_WIRE_TYPE_RED, target_entity = v});
		end
	    elseif connectType == "green" then
		for _,v in pairs(neighbourGroup) do
		    newEntity.connect_neighbour({wire = DEFINES_WIRE_TYPE_GREEN, target_entity = v});
		end
	    end
	end
    end

    newEntity.destructible = false
end

return entityUtils
