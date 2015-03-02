require "defines"

local destroyOilOnDetonation = true
local pollute = true
local requiredArtifacts = 250

local loaded = false
local ticks = 9
local floor = math.floor
local abs = math.abs
local random = math.random
local setupChestName = "logistic-chest-storage"
local setupPillarsName = "wall"
local setupPipesName = "pipe-to-ground"
local entityMaxHealth = {
	[setupChestName] = 150,
	[setupPillarsName] = 350,
	[setupPipesName] = 50
}

if glob.crashedShipCrashed == nil then
	glob.crashedShipCrashed = false
end

game.forces.player.recipes["alien-compass"].enabled = game.forces.player.technologies["alien-technology"].researched

remote.addinterface("alien-oil", {
	spawnship = function()
		if not spawnCrashedShip(floor((game.player.position.x / 32) - 1), floor((game.player.position.y / 32) - 1)) then
			game.player.print("Crashed ship already exists. Use the ship locator to find it.")
		end
	end,
	resetship = function()
		glob.crashedShip = nil
		glob.crashedShipCrashed = false
		game.player.print("Reset successful.")
	end
})

function ticker()
	if glob.crashedShip ~= nil or glob.collectors ~= nil or glob.builders ~= nil or glob.clouds ~= nil then
		if ticks == 0 then
			ticks = 9
			tickSetups()
		else
			ticks = ticks - 1
		end
	else
		game.onevent(defines.events.ontick, nil)
	end
end

game.onload(function()
	if not loaded then
		loaded = true
		
		if glob.crashedShip ~= nil or glob.collectors ~= nil or glob.builders ~= nil or glob.clouds ~= nil then
			game.onevent(defines.events.ontick, ticker)
		end
	end
end)

game.oninit(function()
	loaded = true
	
	if glob.crashedShip ~= nil or glob.collectors ~= nil or glob.builders ~= nil or glob.clouds ~= nil then
		game.onevent(defines.events.ontick, ticker)
	end
end)

game.onevent(defines.events.onchunkgenerated, function(event)
	local x = floor(event.area.lefttop.x / 32)
	local y = floor(event.area.lefttop.y / 32)
	
	if glob.crashedShipCrashed == false then
		-- y < 200 because f-mod generates the "red planet" at y > 200 and might erase the ship
		if x > 93 or x < -93 or y > 93 or y < -93 and y < 200 then
			if random(100) <= 2 then
				spawnCrashedShip(x, y)
			end
		end
	end
end)

function spawnCrashedShip(x, y)
	local shipPosition
	local tileName
	
	if glob.crashedShip == nil then
		shipPosition = {x = floor((x * 32) + random(5, 25)), y = floor((y * 32) + random(5, 25))}
		tileName = game.gettile(shipPosition.x, shipPosition.y).name
		
		if tileName ~= "water" and tileName ~= "deepwater" then
			for _,v in pairs(game.findentities({{shipPosition.x - 8, shipPosition.y - 4}, {shipPosition.x + 8, shipPosition.y + 4}})) do
				v.destroy()
			end
			
			glob.crashedShip = {}
			glob.crashedShip[1] = game.createentity({name = "big-ship-wreck-1", position = shipPosition})
			glob.crashedShip[1].getinventory(1).insert({name = "alien-activator", count = 2})
			glob.crashedShip[1].getinventory(1).insert({name = "crude-oil-collected", count = 2})
			glob.crashedShip[2] = 3
			game.player.print("You can feel the ground shake as an Alien ship crashes to your " .. getDirectionToCrashedShip() .. ".")
			game.player.print("You should investigate and see if there's anything worth looting.")
			glob.crashedShipCrashed = true
			
			if glob.builders == nil and glob.collectors == nil and glob.clouds == nil then
				game.onevent(defines.events.ontick, ticker)
			end
			
			return true
		end
	else
		return false
	end
end

function getDirectionToCrashedShip()
	local playerX = game.player.position.x
	local playerY = game.player.position.y
	local directionText = ""
	
	-- up = north
	-- down = south
	-- right = east
	-- left = west
	if glob.crashedShip ~= nil then
		if glob.crashedShip[1].valid then
			if glob.crashedShip[1].position.y < playerY then
				directionText = "north"
			elseif glob.crashedShip[1].position.y > playerY then
				directionText = "south"
			end
			
			if glob.crashedShip[1].position.x < playerX then
				if directionText ~= "" then
					directionText = directionText .. "-"
				end
				
				directionText = directionText .. "west"
			elseif glob.crashedShip[1].position.x > playerX then
				if directionText ~= "" then
					directionText = directionText .. "-"
				end
				
				directionText = directionText .. "east"
			end
		end
	else
		if glob.crashedShipCrashed == false then
			directionText = "deep (more than 3000 meters from the spawn zone) into the unexplored wilderness"
		else
			directionText = "nowhere! you've already found the ship"
		end
	end
	
	return directionText
end

game.onevent(defines.events.onbuiltentity, function(event)
	if event.createdentity.name == "alien-activator" then
		local position
		
		if game.player ~= nil then
			game.player.insert({name="alien-activator", count = 1})
		end
		event.createdentity.destroy()
		
		if game.forces.player.technologies["alien-technology"].researched then
			if game.player.selected ~= nil then
				if game.player.selected.name == setupChestName then
					checkSetup(game.player.selected.position)
				elseif string.find(game.player.selected.name, "chest") ~= nil then
					game.player.print("Activation failure; wrong chest found.")
				else
					game.player.print("Activation failure; no chest found.")
				end
			else
				game.player.print("Activation failure; no chest found.")
			end
		else
			game.player.print("It doesn't seem to do anything. Perhaps research into alien technologies would help.")
		end
	elseif event.createdentity.name == "alien-compass" then
		event.createdentity.destroy()
		if game.player ~= nil then
			game.player.insert({name="alien-compass", count = 1})
		end
		
		game.player.print("The compass seems to be pointing ... " .. getDirectionToCrashedShip() .. "!")
	end
end)


game.onevent(defines.events.onentitydied, function(event)
	if glob.crashedShip ~= nil then
		if event.entity.equals(glob.crashedShip[1]) then
			local count = glob.crashedShip[1].getinventory(1).getitemcount("alien-activator")
			
			if count ~= 0 then
				for n = 1, count do
					game.createentity({name = "item-on-ground", position = event.entity.position, stack = {name = "alien-activator", count = 1}})
				end
			end
			
			glob.crashedShip = nil
		end
	end
end)

function tickSetups()
	local detonate = false
	local emitPoison = 0
	
	-- Crashed ship tick
	if glob.crashedShip ~= nil then
		if glob.crashedShip[1].valid then
			if abs(game.player.position.x - glob.crashedShip[1].position.x) < 150 or abs(game.player.position.y - glob.crashedShip[1].position.y) < 150 then
				for n = 1, 3 do
					if random(6) <= 2 then
						game.createentity({name = "alien-standard-smoke", position = {x = glob.crashedShip[1].position.x - 3 + random(5) + random(), y = glob.crashedShip[1].position.y - 3 + random(5) + random()}})
					end
				end
				
				if glob.crashedShip[2] == 0 then
					glob.crashedShip[2] = 3
					
					emitAlienPoison(glob.crashedShip[1].position, 20)
				else
					glob.crashedShip[2] = glob.crashedShip[2] - 1
				end
				
				-- The activators where removed from the ship, stop all extra activity.
				if glob.crashedShip[1].getinventory(1).getitemcount("alien-activator") == 0 then
					glob.crashedShip = nil
				end
			end
		else
			glob.crashedShip = nil
		end
	end
	
	-- Collectors tick
	if glob.collectors ~= nil then
		for _,setup in pairs(glob.collectors) do
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
				table.remove(glob.collectors, _)
				
				if #glob.collectors == 0 then
					glob.collectors = nil
				end
			else
				setup["ticks"] = setup["ticks"] + 1
				
				if emitPoison ~= 0 then
					for n = 1, emitPoison do
						if random() >= 0.7 then
							emitAlienPoison(setup["chest"].position, 3, 2)
						end
					end
					
					if setup["artifacts"] == requiredArtifacts then
						if setup["ticks"] % 25 == 0 then
							if random() >= 0.3 then
								splashAcid(setup["position"])
							end
						end
					end
				end
				
				if setup["ticks"] == 360 then
					finishCollector(setup)
					table.remove(glob.collectors, _)
					
					if #glob.collectors == 0 then
						glob.collectors = nil
					end
				end
			end
		end
	end
	
	-- Builders tick
	if glob.builders ~= nil then
		for _,setup in pairs(glob.builders) do
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
				table.remove(glob.builders, _)
				
				if #glob.builders == 0 then
					glob.builders = nil
				end
			else
				setup["ticks"] = setup["ticks"] + 1
				
				if emitPoison ~= 0 then
					for n = 1, emitPoison do
						if random() >= 0.3 then
							emitAlienPoison(setup["chest"].position, 3, 2)
						end
					end
					
					if setup["artifacts"] == requiredArtifacts then
						if setup["ticks"] % 25 == 0 then
							if random() >= 0.1 then
								splashAcid(setup["position"])
							end
						end
					end
				end
				
				if setup["ticks"] == 360 then
					finishBuilder(setup)
					table.remove(glob.builders, _)
					
					if #glob.builders == 0 then
						glob.builders = nil
					end
				end
			end
		end
	end
	
	-- Clouds tick
	if glob.clouds ~= nil then
		for _,cloud in pairs(glob.clouds) do
			if cloud[1].valid then
				cloud[1].teleport(cloud[2])
			else
				table.remove(glob.clouds, _)
				
				if #glob.clouds == 0 then
					glob.clouds = nil
				end
			end
		end
	end
end

function emitAlienPoison(position, radius, size)
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
			game.createentity({name = cloud, position = {x = randomX, y = randomY}})
			retry = false
		end
	end
end

function splashAcid(position)
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
			game.createentity({name = "acid-splash-purple", position = {x = randomX, y = randomY}})
			game.createentity({name = "alien-poison-cloud-corrosive", position = {x = randomX, y = randomY}})
			retry = false
		end
	end
end

function tickSetupEntities(setup, setupType)
	local detonate = false
	
	if setup["chest"].valid then
		if setup["chest"].health ~= entityMaxHealth[setupChestName] then
			setup["damaged"] = setup["damaged"] + 1
		end
	else
		detonate = "structural failure"
	end
	
	for n = 1, 4 do
		if setup["walls"][n].valid then
			if setup["walls"][n].health ~= entityMaxHealth[setupPillarsName] then
				setup["damaged"] = setup["damaged"] + 1
			end
			
			if random() >= 0.2 then
				game.createentity({name = "alien-standard-smoke", position = setup["walls"][n].position})
			end
		else
			detonate = "structural failure"
			break
		end
		
		if setup["pipes"][n].valid then
			if setup["pipes"][n].health ~= entityMaxHealth[setupPipesName] then
				setup["damaged"] = setup["damaged"] + 1
			end
		else
			detonate = "structural failure"
			break
		end
	end
	
	if setup["chest"].getinventory(1).getitemcount("alien-artifact") >= 1 then
		if setup["ticks"] % 2 == 0 or setup["artifacts"] == requiredArtifacts * 2 then
			setup["chest"].getinventory(1).remove({name = "alien-artifact", count = 1})
		end
	else
		detonate = "insufficient Alien artifacts"
	end
	
	if setupType == 1 then
		if pollute then
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				game.pollute(setup["position"], 27.77)
			end
		end
	else
		if setup["chest"].getinventory(1).getitemcount("crude-oil-collected") < 1 then
			detonate = "missing crude oil spout"
		end
		
		if pollute then
			if setup["artifacts"] ~= requiredArtifacts * 2 then
				game.pollute(setup["position"], 55.55)
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
	
	for xx = x - 3,x + 3,1.5 do
		for yy = y - 3,y + 3,1.5 do
			distX = abs(x - xx)
			distY = abs(y - yy)
			
			if math.sqrt((distX * distX) + (distY * distY)) <= 3 then
				game.createentity({name = "huge-explosion", position = {x = xx, y = yy}})
			end
		end
	end
	
	if setup["chest"].valid then
		target = setup["chest"]
	else
		target = game.createentity({name = "alien-activator", position = setup["position"]})
	end
	
	game.createentity({name = "alien-setup-detonation", position = setup["position"], target = target, speed = 1})
	lockCloudToPosition(game.createentity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = setup["position"].x, y = setup["position"].y + 1}}))
	
	if destroyOilOnDetonation then
		for _,oil in pairs(game.findentitiesfiltered({area = {{x = x - 3, y = y - 3}, {x = x + 3, y = y + 3}}, name = "crude-oil"})) do
			distX = abs(x - oil.position.x)
			distY = abs(y - oil.position.y)
			
			if math.sqrt((distX * distX) + (distY * distY)) <= 3 then
				lockCloudToPosition(game.createentity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = oil.position.x, y = oil.position.y + 1}}))
				oil.destroy()
			end
		end
	end
	
	if pollute then
		game.pollute(setup["position"], 40000)
	end
	
	game.player.print("Critical setup failure; " .. reason)
end

function finishCollector(setup)
	local crudeOil
	local artifactCount = setup["chest"].getinventory(1).getitemcount("alien-artifact")
	
	if setup["artifacts"] == requiredArtifacts and artifactCount ~= 70 then
		detonateSetup(setup, "insufficient Alien artifacts")
	elseif setup["artifacts"] == requiredArtifacts * 2 and artifactCount ~= 140 then
		detonateSetup(setup, "insufficient Alien artifacts")
	else
		setup["chest"].getinventory(1).remove({name = "alien-artifact", count = artifactCount})
		
		if setup["chest"].getinventory(1).caninsert({name = "crude-oil-collected", count = 1}) then
			crudeOil = findEntity(setup["position"], 0, 0, "crude-oil")
			
			if #crudeOil == 1 then
				setup["chest"].getinventory(1).insert({name = "crude-oil-collected", count = 1})
				lockCloudToPosition(game.createentity({name = "alien-destroyed-crude-oil-poison-cloud", position = {x = setup["position"].x, y = setup["position"].y + 1}}))
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
	local artifactCount = setup["chest"].getinventory(1).getitemcount("alien-artifact")
	
	if setup["artifacts"] == requiredArtifacts and artifactCount ~= 70 then
		detonateSetup(setup, "insufficient Alien artifacts")
	elseif setup["artifacts"] == requiredArtifacts * 2 and artifactCount ~= 140 then
		detonateSetup(setup, "insufficient Alien artifacts")
	else
		setup["chest"].getinventory(1).remove({name = "alien-artifact", count = artifactCount})
		
		if setup["chest"].getinventory(1).getitemcount("crude-oil-collected") ~= 1 then
			detonateSetup(setup, "wrong number of crude oil spouts")
		else
			setup["chest"].getinventory(1).remove({name = "crude-oil-collected", count = 1})
			game.createentity({name = "crude-oil", position = setup["position"]}).amount = 750 -- 750 = 10% @ 0.1/second
		end
	end
end

function checkSetup(position)
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
	
	
	chest = findEntity(position, 0, 0, setupChestName)
	if #chest == 1 then
		newSetup["chest"] = chest[1]
		
		-- Check if the setup is already running
		if glob.collectors ~= nil then
			for _,setup in pairs(glob.collectors) do
				if setup["chest"].valid and setup["chest"].equals(newSetup["chest"]) then
					return
				end
			end
		end
		if glob.builders ~= nil then
			for _,setup in pairs(glob.builders) do
				if setup["chest"].valid and setup["chest"].equals(newSetup["chest"]) then
					return
				end
			end
		end
		
		-- make sure the chest isn't damaged
		if newSetup["chest"].health ~= entityMaxHealth[setupChestName] then
			game.player.print("Activation failure; chest is damaged.")
			return
		end
		
		walls = {}
		for n = 1, 4 do
			wall = findEntity(position, wallPositions[n][1], wallPositions[n][2], setupPillarsName)
			if #wall == 1 then
				walls[n] = wall[1]
				
				-- make sure the wall isn't damaged
				if walls[n].health ~= entityMaxHealth[setupPillarsName] then
					game.player.print("Activation failure; wall pillar(s) are damaged.")
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
				pipe = findEntity(position, pipePositions[n][1], pipePositions[n][2], setupPipesName)
				if #pipe == 1 then
					pipes[n] = pipe[1]
					
					-- make sure the pipe is rotated correctly and throw an error message if they aren't (saying pipes rotated incorrectly)
					if pipes[n].direction ~= pipeDirections[n] then
						game.player.print("Activation failure; pipe(s) aren't rotated correctly.")
						return
					end
					
					-- make sure the pipe doesn't have liquid in it (other than crude oil)
					liquid = pipes[n].getliquid()
					if liquid ~= nil then
						game.player.print("Activation failure; pipe(s) contain liquids.")
						return
					end
					
					-- make sure the pipe isn't damaged
					if pipes[n].health ~= entityMaxHealth[setupPipesName] then
						game.player.print("Activation failure; pipe(s) are damaged.")
						return
					end
					pipeCount = pipeCount + 1
				else
					break
				end
			end
			
			if pipeCount == 4 then
				newSetup["pipes"] = pipes
				artifactCount = newSetup["chest"].getinventory(1).getitemcount("alien-artifact")
				
				-- Require exactly the right amount of artifacts
				if artifactCount == requiredArtifacts or artifactCount == requiredArtifacts * 2 then
					crudeOil = findEntity(position, 0, 0, "crude-oil")
					if #crudeOil == 1 then
						if floor(crudeOil[1].position.x) + 0.5 == position.x and floor(crudeOil[1].position.y) + 0.5 == position.y then
							newSetup["position"] = position
							newSetup["artifacts"] = artifactCount
							addCollector(newSetup)
							
							if artifactCount == requiredArtifacts then
								game.player.print("Basic activation successful.")
							else
								game.player.print("Advanced activation successful.")
							end
						else
							game.player.print("Activation failure; crude oil found is not directly below setup.")
						end
					else
						if #crudeOil == 0 then
							crudeOilCollected = newSetup["chest"].getinventory(1).getitemcount("crude-oil-collected")
							
							if crudeOilCollected > 0 then
								if crudeOilCollected == 1 then
									newSetup["position"] = position
									newSetup["artifacts"] = artifactCount
									addBuilder(newSetup)
									
									if artifactCount == requiredArtifacts then
										game.player.print("Basic activation successful.")
									else
										game.player.print("Advanced activation successful.")
									end
								else
									game.player.print("Activation failure; too many oil spouts in chest.")
								end
							else
								game.player.print("Activation failure; no crude oil found directly below setup.")
							end
						elseif #crudeOil > 1 then
							game.player.print("Activation failure; more than one crude oil found directly below setup (overlapping?).")
						end
					end
				else
					if artifactCount < requiredArtifacts then
						game.player.print("Activation failure; insufficient Alien artifacts in chest.")
					elseif artifactCount > requiredArtifacts then
						game.player.print("Activation failure; too many Alien artifacts in chest for basic activation.")
					end
				end
			else
				if pipes[1] == nil then
					game.player.print("Activation failure; north ground pipe not found.")
				elseif pipes[2] == nil then
					game.player.print("Activation failure; east ground pipe not found.")
				elseif pipes[3] == nil then
					game.player.print("Activation failure; south ground pipe not found.")
				else
					game.player.print("Activation failure; west ground pipe not found.")
				end
			end
		else
			if walls[1] == nil then
				game.player.print("Activation failure; north-west wall pillar not found.")
			elseif walls[2] == nil then
				game.player.print("Activation failure; north-east wall pillar not found.")
			elseif walls[3] == nil then
				game.player.print("Activation failure; south-east wall pillar not found.")
			else
				game.player.print("Activation failure; south-west wall pillar not found.")
			end
		end
	else
		game.player.print("Activation failure; no storage chest found.")
	end
end

function findEntity(position, offsetX, offsetY, itemName)
	return game.findentitiesfiltered({area = {{position.x - (0.1) + offsetX, position.y - (0.1) + offsetY}, {position.x + (0.1) + offsetX, position.y + (0.1) + offsetY}}, name = itemName})
end

function addCollector(collector)
	if glob.collectors == nil then
		glob.collectors = {}
		
		if glob.builders == nil and glob.crashedShip == nil and glob.clouds == nil then
			game.onevent(defines.events.ontick, ticker)
		end
	end
	
	collector["damaged"] = 0
	collector["ticks"] = 0
	table.insert(glob.collectors, collector)
end

function addBuilder(builder)
	if glob.builders == nil then
		glob.builders = {}
		
		if glob.collectors == nil and glob.crashedShip == nil and glob.clouds == nil then
			game.onevent(defines.events.ontick, ticker)
		end
	end
	
	builder["damaged"] = 0
	builder["ticks"] = 0
	table.insert(glob.builders, builder)
end

function lockCloudToPosition(cloud)
	if glob.clouds == nil then
		glob.clouds = {}
		
		if glob.builders == nil and glob.collectors == nil and glob.crashedShip == nil then
			game.onevent(defines.events.ontick, ticker)
		end
	end
	
	table.insert(glob.clouds, {[1] = cloud, [2] = cloud.position})
end