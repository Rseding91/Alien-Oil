require "defines"

local destroyOilOnDetonation = true
local pollute = true
local requiredArtifacts = 250
local floor = math.floor
local abs = math.abs
local random = math.random
local setupChestName = "logistic-chest-storage"
local setupPillarsName = "stone-wall"
local setupPipesName = "pipe-to-ground"


script.on_configuration_changed(function(data)
  if global.entityMaxHealth == nil then
    local entityPrototypes = game.entity_prototypes
    global.entityMaxHealth = {
      [setupChestName] = entityPrototypes[setupChestName].max_health,
      [setupPillarsName] = entityPrototypes[setupPillarsName].max_health,
      [setupPipesName] = entityPrototypes[setupPipesName].max_health
    }
  end
  
  if global.crashedShipCrashed == nil then
    global.crashedShipCrashed = false
  end
end)

function printToAllPlayers(message)
	for _,v in pairs(game.players) do
		v.print(message)
	end
end

remote.add_interface("alien-oil", {
	spawnship = function()
		if not spawnCrashedShip(floor((game.player.position.x / 32) - 1), floor((game.player.position.y / 32) - 1), game.player.surface) then
			game.player.print("Crashed ship already exists. Use the ship locator to find it.")
		end
	end,
	resetship = function()
		global.crashedShip = nil
		global.crashedShipCrashed = false
		printToAllPlayers("Reset successful.")
	end
})

function ticker()
	if global.crashedShip ~= nil or global.collectors ~= nil or global.builders ~= nil then
		if global.ticks == nil or global.ticks == 0 then
			global.ticks = 9
			tickSetups()
		else
			global.ticks = global.ticks - 1
		end
	else
		script.on_event(defines.events.on_tick, nil)
	end
end

script.on_load(function()
  if global.crashedShip ~= nil or global.collectors ~= nil or global.builders ~= nil then
    script.on_event(defines.events.on_tick, ticker)
  end
end)

script.on_init(function()
  if global.entityMaxHealth == nil then
    local entityPrototypes = game.entity_prototypes
    global.entityMaxHealth = {
      [setupChestName] = entityPrototypes[setupChestName].max_health,
      [setupPillarsName] = entityPrototypes[setupPillarsName].max_health,
      [setupPipesName] = entityPrototypes[setupPipesName].max_health
    }
  end
  
  if global.crashedShipCrashed == nil then
    global.crashedShipCrashed = false
  end
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	local x = floor(event.area.left_top.x / 32)
	local y = floor(event.area.left_top.y / 32)
	
	if global.crashedShipCrashed == false then
		-- y < 200 because f-mod generates the "red planet" at y > 200 and might erase the ship
		if x > 93 or x < -93 or y > 93 or y < -93 and y < 200 then
			if random(100) <= 2 then
				spawnCrashedShip(x, y, event.surface)
			end
		end
	end
end)

function spawnCrashedShip(x, y, surface)
	local shipPosition
	local tileName
	
	if global.crashedShip == nil then
		shipPosition = {x = floor((x * 32) + random(5, 25)), y = floor((y * 32) + random(5, 25))}
		tileName = surface.get_tile(shipPosition.x, shipPosition.y).name
		
		if tileName ~= "water" and tileName ~= "deepwater" then
			for _,v in pairs(surface.find_entities({{shipPosition.x - 8, shipPosition.y - 4}, {shipPosition.x + 8, shipPosition.y + 4}})) do
				v.destroy()
			end
			
			global.crashedShip = {}
			global.crashedShip[1] = surface.create_entity({name = "big-ship-wreck-1", position = shipPosition, force = game.forces.neutral})
			global.crashedShip[1].get_inventory(1).insert({name = "alien-activator", count = 2})
			global.crashedShip[1].get_inventory(1).insert({name = "crude-oil-collected", count = 2})
			global.crashedShip[2] = 3
			for _,v in pairs(game.players) do
        if v.surface == surface then
          v.print("You can feel the ground shake as an Alien ship crashes to your " .. getDirectionToCrashedShip(v) .. ".")
          v.print("You should investigate and see if there's anything worth looting.")
        end
			end
			global.crashedShipCrashed = true
			
			if global.builders == nil and global.collectors == nil then
				script.on_event(defines.events.on_tick, ticker)
			end
			
			return true
		end
	else
		return false
	end
end

function getDirectionToCrashedShip(player)
	local playerX = player.position.x
	local playerY = player.position.y
	local directionText = ""
	
	-- up = north
	-- down = south
	-- right = east
	-- left = west
	if global.crashedShip ~= nil then
		if global.crashedShip[1].valid and global.crashedShip[1].surface == player.surface then
			if global.crashedShip[1].position.y < playerY then
				directionText = "north"
			elseif global.crashedShip[1].position.y > playerY then
				directionText = "south"
			end
			
			if global.crashedShip[1].position.x < playerX then
				if directionText ~= "" then
					directionText = directionText .. "-"
				end
				
				directionText = directionText .. "west"
			elseif global.crashedShip[1].position.x > playerX then
				if directionText ~= "" then
					directionText = directionText .. "-"
				end
				
				directionText = directionText .. "east"
			end
		end
	else
		if global.crashedShipCrashed == false then
			directionText = "deep (more than 3000 meters from the spawn zone) into the unexplored wilderness"
		else
			directionText = "nowhere! you've already found the ship"
		end
	end
	
	return directionText
end

script.on_event(defines.events.on_built_entity, function(event)
	if event.created_entity.name == "alien-activator" then
		local position
		local player = game.get_player(event.player_index)
		
		player.insert({name="alien-activator", count = 1})
		event.created_entity.destroy()
		
		if game.forces.player.technologies["alien-technology"].researched then
			if player.selected ~= nil then
				if player.selected.name == setupChestName then
					checkSetup(player)
				elseif string.find(player.selected.name, "chest") ~= nil then
					player.print("Activation failure; wrong chest found.")
				else
					player.print("Activation failure; no chest found.")
				end
			else
				player.print("Activation failure; no chest found.")
			end
		else
			player.print("It doesn't seem to do anything. Perhaps research into alien technologies would help.")
		end
	elseif event.created_entity.name == "alien-compass" then
		local player = game.get_player(event.player_index)
		event.created_entity.destroy()
		player.insert({name="alien-compass", count = 1})
		player.print("The compass seems to be pointing ... " .. getDirectionToCrashedShip(player) .. "!")
	end
end)


script.on_event(defines.events.on_entity_died, function(event)
	if global.crashedShip ~= nil then
    local entity = event.entity
		if entity == global.crashedShip[1] then
			local count = global.crashedShip[1].get_inventory(1).get_item_count("alien-activator")
			
			if count ~= 0 then
        local surface = entity.surface
				for n = 1, count do
					surface.create_entity({name = "item-on-ground", position = entity.position, stack = {name = "alien-activator", count = 1}})
				end
			end
			
			global.crashedShip = nil
		end
	end
end)

function tickSetups()
	local detonate = false
	local emitPoison = 0
	
	-- Crashed ship tick
	if global.crashedShip ~= nil then
		if global.crashedShip[1].valid then
			for _,player in pairs(game.players) do
        local surface = global.crashedShip[1].surface
        if player.surface == surface then
          if abs(player.position.x - global.crashedShip[1].position.x) < 150 or abs(player.position.y - global.crashedShip[1].position.y) < 150 then
            for n = 1, 3 do
              if random(6) <= 2 then
                surface.create_entity({name = "alien-standard-smoke", position = {x = global.crashedShip[1].position.x - 3 + random(5) + random(), y = global.crashedShip[1].position.y - 3 + random(5) + random()}})
              end
            end
            
            if global.crashedShip[2] == 0 then
              global.crashedShip[2] = 3
              
              emitAlienPoison(global.crashedShip[1].position, 20, 1, surface)
            else
              global.crashedShip[2] = global.crashedShip[2] - 1
            end
            
            -- The activators where removed from the ship, stop all extra activity.
            if global.crashedShip[1].get_inventory(1).get_item_count("alien-activator") == 0 then
              global.crashedShip = nil
            end
            
            break
          end
        end
			end
		else
			global.crashedShip = nil
		end
	end
	
	-- Collectors tick
	if global.collectors ~= nil then
		for _,setup in pairs(global.collectors) do
			detonate = tickSetupEntities(setup, 1)
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				emitPoison = 2
			end
			
			if setup["damaged"] > 0 then
				emitPoison = emitPoison + floor(setup["damaged"] / 54)
			end
			
			if detonate ~= false or setup["damaged"] >= random(8000) then
				if detonate == false then
					detonate = "structural failure"
				end
				detonateSetup(setup, detonate)
				table.remove(global.collectors, _)
				
				if #global.collectors == 0 then
					global.collectors = nil
				end
			else
				setup["ticks"] = setup["ticks"] + 1
				
				if emitPoison ~= 0 then
					for n = 1, emitPoison do
						if random() >= 0.7 then
							emitAlienPoison(setup["chest"].position, 3, 2, setup["surface"])
						end
					end
					
					if setup["artifacts"] == requiredArtifacts then
						if setup["ticks"] % 25 == 0 then
							if random() >= 0.3 then
								splashAcid(setup["position"], setup["surface"])
							end
						end
					end
				end
				
				if setup["ticks"] == 360 then
					finishCollector(setup)
					table.remove(global.collectors, _)
					
					if #global.collectors == 0 then
						global.collectors = nil
					end
				end
			end
		end
	end
	
	-- Builders tick
	if global.builders ~= nil then
		for _,setup in pairs(global.builders) do
			detonate = tickSetupEntities(setup, 2)
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				emitPoison = 2
			end
			
			if setup["damaged"] > 0 then
				emitPoison = emitPoison + floor(setup["damaged"] / 54)
			end
			
			if detonate ~= false or setup["damaged"] >= random(32000) then
				if detonate == false then
					detonate = "structural failure"
				end
				detonateSetup(setup, detonate)
				table.remove(global.builders, _)
				
				if #global.builders == 0 then
					global.builders = nil
				end
			else
				setup["ticks"] = setup["ticks"] + 1
				
				if emitPoison ~= 0 then
					for n = 1, emitPoison do
						if random() >= 0.3 then
							emitAlienPoison(setup["chest"].position, 3, 2, setup["surface"])
						end
					end
					
					if setup["artifacts"] == requiredArtifacts then
						if setup["ticks"] % 25 == 0 then
							if random() >= 0.1 then
								splashAcid(setup["position"], setup["surface"])
							end
						end
					end
				end
				
				if setup["ticks"] == 360 then
					finishBuilder(setup)
					table.remove(global.builders, _)
					
					if #global.builders == 0 then
						global.builders = nil
					end
				end
			end
		end
	end
end

function emitAlienPoison(position, radius, size, surface)
	local distX
	local distY
	local randomX
	local randomY
	local retry = true
	
	if size == nil then
		size = 1
	end
	
	if size == 1 then
		cloud = "alien-poison-cloud"
	elseif size == 2 then
		cloud = "alien-poison-cloud-tiny"
	end
	
	while retry do
		randomX = position.x - (radius / 2) + random(radius) - 1 + random()
		randomY = position.y - (radius / 2) + random(radius) + random()
		distX = abs(position.x - randomX)
		distY = abs(position.y - randomY)
		
		if math.sqrt((distX * distX) + (distY * distY)) <= radius then
			surface.create_entity({name = cloud, position = {x = randomX, y = randomY}})
			retry = false
		end
	end
end

function splashAcid(position, surface)
	local distX
	local distY
	local randomX
	local randomY
	local distance
	local retry = true
	
	while retry do
		randomX = position.x - 6 + random(12) - 0.5 + random()
		randomY = position.y - 6 + random(12) + random()
		distX = abs(position.x - randomX)
		distY = abs(position.y - randomY)
		distance = math.sqrt((distX * distX) + (distY * distY))
		
		if distance >= 4 and distance <= 6 then
			surface.create_entity({name = "acid-splash-purple", position = {x = randomX, y = randomY}})
			surface.create_entity({name = "alien-poison-cloud-corrosive", position = {x = randomX, y = randomY}})
			retry = false
		end
	end
end

function tickSetupEntities(setup, setupType)
	local detonate = false
  local surface = setup["surface"]
	
	if setup["chest"].valid then
		if setup["chest"].health ~= global.entityMaxHealth[setupChestName] then
			setup["damaged"] = setup["damaged"] + 1
		end
	else
		detonate = "structural failure"
	end
	
	for n = 1, 4 do
		if setup["walls"][n].valid then
			if setup["walls"][n].health ~= global.entityMaxHealth[setupPillarsName] then
				setup["damaged"] = setup["damaged"] + 1
			end
			
			if random() >= 0.2 then
				surface.create_entity({name = "alien-standard-smoke", position = setup["walls"][n].position})
			end
		else
			detonate = "structural failure"
			break
		end
		
		if setup["pipes"][n].valid then
			if setup["pipes"][n].health ~= global.entityMaxHealth[setupPipesName] then
				setup["damaged"] = setup["damaged"] + 1
			end
		else
			detonate = "structural failure"
			break
		end
	end
	
	if setup["chest"].get_inventory(1).get_item_count("alien-artifact") >= 1 then
		if setup["ticks"] % 2 == 0 or setup["artifacts"] == requiredArtifacts * 2 then
			setup["chest"].get_inventory(1).remove({name = "alien-artifact", count = 1})
		end
	else
		detonate = "insufficient Alien artifacts"
	end
	
	if setupType == 1 then
		if pollute then
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				surface.pollute(setup["position"], 27.77)
			end
		end
	else
		if setup["chest"].get_inventory(1).get_item_count("crude-oil-collected") < 1 then
			detonate = "missing crude oil spout"
		end
		
		if pollute then
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				surface.pollute(setup["position"], 55.55)
			end
		end
	end
	
	return detonate
end

function detonateSetup(setup, reason)
	local x = setup["position"].x
	local y = setup["position"].y
	local target
	local distX
	local distY
  local surface = setup["surface"]
	
	for xx = x - 3,x + 3,1.5 do
		for yy = y - 3,y + 3,1.5 do
			distX = abs(x - xx)
			distY = abs(y - yy)
			
			if math.sqrt((distX * distX) + (distY * distY)) <= 3 then
				surface.create_entity({name = "medium-explosion", position = {x = xx, y = yy}})
			end
		end
	end
	
	if setup["chest"].valid then
		target = setup["chest"]
	else
		target = surface.create_entity({name = "alien-activator", position = setup["position"]})
	end
	
	surface.create_entity({name = "alien-setup-detonation", position = setup["position"], target = target, speed = 1})
	surface.create_entity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = setup["position"].x, y = setup["position"].y + 1}})
	
	if destroyOilOnDetonation then
		for _,oil in pairs(surface.find_entities_filtered({area = {{x = x - 3, y = y - 3}, {x = x + 3, y = y + 3}}, name = "crude-oil"})) do
			distX = abs(x - oil.position.x)
			distY = abs(y - oil.position.y)
			
			if math.sqrt((distX * distX) + (distY * distY)) <= 3 then
				surface.create_entity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = oil.position.x, y = oil.position.y + 1}})
				oil.destroy()
			end
		end
	end
	
	if pollute then
		surface.pollute(setup["position"], 40000)
	end
	
	printToAllPlayers("Critical setup failure; " .. reason)
end

function finishCollector(setup)
	local crudeOil
  local surface = setup["surface"]
	local artifactCount = setup["chest"].get_inventory(1).get_item_count("alien-artifact")
	
	if setup["artifacts"] == requiredArtifacts and artifactCount ~= 70 then
		detonateSetup(setup, "insufficient Alien artifacts")
	elseif setup["artifacts"] == requiredArtifacts * 2 and artifactCount ~= 140 then
		detonateSetup(setup, "insufficient Alien artifacts")
	else
		setup["chest"].get_inventory(1).remove({name = "alien-artifact", count = artifactCount})
		
		if setup["chest"].get_inventory(1).can_insert({name = "crude-oil-collected", count = 1}) then
			crudeOil = findEntity(setup["position"], 0, 0, "crude-oil", surface)
			
			if #crudeOil == 1 then
				setup["chest"].get_inventory(1).insert({name = "crude-oil-collected", count = 1})
				surface.create_entity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = setup["position"].x, y = setup["position"].y + 1}})
				crudeOil[1].destroy()
			else
				detonateSetup(setup, "crude oil oddities")
			end
		else
			detonateSetup(setup, "no room in chest for crude oil spout")
		end
	end
end

function finishBuilder(setup)
	local artifactCount = setup["chest"].get_inventory(1).get_item_count("alien-artifact")
  local surface = setup["surface"]
	
	if setup["artifacts"] == requiredArtifacts and artifactCount ~= 70 then
		detonateSetup(setup, "insufficient Alien artifacts")
	elseif setup["artifacts"] == requiredArtifacts * 2 and artifactCount ~= 140 then
		detonateSetup(setup, "insufficient Alien artifacts")
	else
		setup["chest"].get_inventory(1).remove({name = "alien-artifact", count = artifactCount})
		
		if setup["chest"].get_inventory(1).get_item_count("crude-oil-collected") ~= 1 then
			detonateSetup(setup, "wrong number of crude oil spouts")
		else
			setup["chest"].get_inventory(1).remove({name = "crude-oil-collected", count = 1})
			surface.create_entity({name = "crude-oil", position = setup["position"]}).amount = 750 -- 750 = 10% @ 0.1/second
		end
	end
end

function checkSetup(player)
	local newSetup = {}
	local chest
	local pipe
	local wallPositions = {[1] = {-1, -1}, [2] = {1, -1}, [3] = {1, 1}, [4] = {-1, 1}}
	local pipePositions = {[1] = {0, -1}, [2] = {1, 0}, [3] = {0, 1}, [4] = {-1, 0}}
	local pipeDirections = {[1] = 4, [2] = 6, [3] = 0, [4] = 2}
	local walls
	local wall
	local wallCount = 0
	local pipes
	local pipe
	local pipeCount = 0
	local artifactCount
	local crudeOilCollected
	local crudeOil
	local liquid
	local position = player.selected.position
	
	
	chest = findEntity(position, 0, 0, setupChestName, player.surface)
	if #chest == 1 then
		newSetup["chest"] = chest[1]
    newSetup["surface"] = chest[1].surface
		
		-- Check if the setup is already running
		if global.collectors ~= nil then
			for _,setup in pairs(global.collectors) do
				if setup["chest"].valid and setup["chest"] == newSetup["chest"] then
					return
				end
			end
		end
		if global.builders ~= nil then
			for _,setup in pairs(global.builders) do
				if setup["chest"].valid and setup["chest"] == newSetup["chest"] then
					return
				end
			end
		end
		
		-- make sure the chest isn't damaged
		if newSetup["chest"].health ~= global.entityMaxHealth[setupChestName] then
			player.print("Activation failure; chest is damaged.")
			return
		end
		
		walls = {}
		for n = 1, 4 do
			wall = findEntity(position, wallPositions[n][1], wallPositions[n][2], setupPillarsName, newSetup["surface"])
			if #wall == 1 then
				walls[n] = wall[1]
				
				-- make sure the wall isn't damaged
				if walls[n].health ~= global.entityMaxHealth[setupPillarsName] then
					player.print("Activation failure; wall pillar(s) are damaged.")
					return
				end
				wallCount = wallCount + 1
			else
				break
			end
		end
		
		if wallCount == 4 then
			newSetup["walls"] = walls
			
			pipes = {}
			for n = 1, 4 do
				pipe = findEntity(position, pipePositions[n][1], pipePositions[n][2], setupPipesName, newSetup["surface"])
				if #pipe == 1 then
					pipes[n] = pipe[1]
					
					-- make sure the pipe is rotated correctly and throw an error message if they aren't (saying pipes rotated incorrectly)
					if pipes[n].direction ~= pipeDirections[n] then
						player.print("Activation failure; pipe(s) aren't rotated correctly.")
						return
					end
					
					-- make sure the pipe isn't damaged
					if pipes[n].health ~= global.entityMaxHealth[setupPipesName] then
						player.print("Activation failure; pipe(s) are damaged.")
						return
					end
					pipeCount = pipeCount + 1
				else
					break
				end
			end
			
			if pipeCount == 4 then
				newSetup["pipes"] = pipes
				artifactCount = newSetup["chest"].get_inventory(1).get_item_count("alien-artifact")
				
				-- Require exactly the right amount of artifacts
				if artifactCount == requiredArtifacts or artifactCount == requiredArtifacts * 2 then
					crudeOil = findEntity(position, 0, 0, "crude-oil", newSetup["surface"])
					if #crudeOil == 1 then
						if floor(crudeOil[1].position.x) + 0.5 == position.x and floor(crudeOil[1].position.y) + 0.5 == position.y then
							newSetup["position"] = position
							newSetup["artifacts"] = artifactCount
							addCollector(newSetup)
							
							if artifactCount == requiredArtifacts then
								player.print("Basic activation successful.")
							else
								player.print("Advanced activation successful.")
							end
						else
							player.print("Activation failure; crude oil found is not directly below setup.")
						end
					else
						if #crudeOil == 0 then
							crudeOilCollected = newSetup["chest"].get_inventory(1).get_item_count("crude-oil-collected")
							
							if crudeOilCollected > 0 then
								if crudeOilCollected == 1 then
									newSetup["position"] = position
									newSetup["artifacts"] = artifactCount
									addBuilder(newSetup)
									
									if artifactCount == requiredArtifacts then
										player.print("Basic activation successful.")
									else
										player.print("Advanced activation successful.")
									end
								else
									player.print("Activation failure; too many oil spouts in chest.")
								end
							else
								player.print("Activation failure; no crude oil found directly below setup.")
							end
						elseif #crudeOil > 1 then
							player.print("Activation failure; more than one crude oil found directly below setup (overlapping?).")
						end
					end
				else
					if artifactCount < requiredArtifacts then
						player.print("Activation failure; insufficient Alien artifacts in chest.")
					elseif artifactCount > requiredArtifacts then
						player.print("Activation failure; too many Alien artifacts in chest for basic activation.")
					end
				end
			else
				if pipes[1] == nil then
					player.print("Activation failure; north ground pipe not found.")
				elseif pipes[2] == nil then
					player.print("Activation failure; east ground pipe not found.")
				elseif pipes[3] == nil then
					player.print("Activation failure; south ground pipe not found.")
				else
					player.print("Activation failure; west ground pipe not found.")
				end
			end
		else
			if walls[1] == nil then
				player.print("Activation failure; north-west wall pillar not found.")
			elseif walls[2] == nil then
				player.print("Activation failure; north-east wall pillar not found.")
			elseif walls[3] == nil then
				player.print("Activation failure; south-east wall pillar not found.")
			else
				player.print("Activation failure; south-west wall pillar not found.")
			end
		end
	else
		player.print("Activation failure; no storage chest found.")
	end
end

function findEntity(position, offsetX, offsetY, itemName, surface)
	return surface.find_entities_filtered({area = {{position.x - (0.1) + offsetX, position.y - (0.1) + offsetY}, {position.x + (0.1) + offsetX, position.y + (0.1) + offsetY}}, name = itemName})
end

function addCollector(collector)
	if global.collectors == nil then
		global.collectors = {}
		
		if global.builders == nil and global.crashedShip == nil then
			script.on_event(defines.events.on_tick, ticker)
		end
	end
	
	collector["damaged"] = 0
	collector["ticks"] = 0
	table.insert(global.collectors, collector)
end

function addBuilder(builder)
	if global.builders == nil then
		global.builders = {}
		
		if global.collectors == nil and global.crashedShip == nil then
			script.on_event(defines.events.on_tick, ticker)
		end
	end
	
	builder["damaged"] = 0
	builder["ticks"] = 0
	table.insert(global.builders, builder)
end