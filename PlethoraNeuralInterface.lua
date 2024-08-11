-- CONFIGURATION
local mobNames = { "Creeper", "Skeleton", "Zombie" }  -- Mobs to search for with Mob Scanner/Aimbot
local oreNames = { "minecraft:diamond_ore", "minecraft:emerald_ore" }  -- Ores to search for with Ore Scanner
local preferredMethod = "modem"  -- Notification method: "modem", "chatModule", "printOnly"
local modemPort = 1337  -- Modem port
local notificationPosStyle = "relativeDirection"  -- Position format: "relativeXYZ", "relativeDirection"

-- KEY BINDINGS
local launchUpKey = { key = keys.e, keyname = "E" }
local launchDirectionKey = { key = keys.f, keyname = "F" }
local mobScanKey = { key = keys.numPad9, keyname = "NumPad9" }
local useSpamKey = { key = keys.numPad8, keyname = "NumPad8" }
local aimbotKey = { key = keys.numPad7, keyname = "NumPad7" }
local noFallKey = { key = keys.numPad6, keyname = "NumPad6" }
local hoverKey = { key = keys.numPad5, keyname = "NumPad5" }
local oreScanKey = { key = keys.numPad4, keyname = "NumPad4" }

---------------------------------------------------
local modules = peripheral.find("neuralInterface")
if not modules then
	error("A neural interface is required", 0)
end

-- Setup notification method
if preferredMethod == "modem" then
	local modem = peripheral.find("modem")
	if not modem then
		error("A modem is required", 0)
	end
	modem.open(modemPort)
	if not modem.isOpen(modemPort) then
		error("Unable to open the modem port", 0)
	end
elseif preferredMethod == "chatModule" then
	if not modules.hasModule("plethora:chat") then
		error("A chat module is required", 0)
	end
end

-- Check installed modules
local hasSensor = modules.hasModule("plethora:sensor")
local hasKinetic = modules.hasModule("plethora:kinetic")
local hasScanner = modules.hasModule("plethora:scanner")
local hasIntrospection = modules.hasModule("plethora:introspection")

-- FEATURES
local features = {
	mobscan = { enabled = false, name = "Mob Scanner", event = "mobscan" },
	use = { enabled = false, name = "Use Spam", event = "use" },
	aimbot = { enabled = false, name = "Aimbot", event = "aimbot" },
	nofall = { enabled = false, name = "No Fall", event = "nofall" },
	orescan = { enabled = false, name = "Ore Scanner", event = "orescan" },
	hover = { enabled = false, name = "Hover", event = "hover" }
}

-- Lookup tables
local mobLookup = {}
for _, mobName in ipairs(mobNames) do
	mobLookup[mobName] = true
end

local oreLookup = {}
for _, oreName in ipairs(oreNames) do
	oreLookup[oreName] = true
end

-- Helper functions
local function tell(message)
	if message then
		print(message)
		if preferredMethod == "modem" then
			modem.transmit(modemPort, modemPort + 1, message)
			sleep(0.01)
		elseif preferredMethod == "chatModule" then
			modules.tell(message)
		end
	end
end

local function toggle(feature)
	feature.enabled = not feature.enabled
	tell(feature.name .. " was set to " .. tostring(feature.enabled))
	if feature.enabled then 
		os.queueEvent(feature.event)
	end
end

local function getDirection(position)
	local pos = {}
	if notificationPosStyle == "relativeDirection" then
		pos.x = position.x < 0 and "West: " or "East: "
		pos.y = ", Height: "
		pos.z = position.z < 0 and ", North: " or ", South: "
	else
		pos.x, pos.y, pos.z = "X: ", ", Y: ", ", Z: "
	end
	return pos
end

local function getPosition(position)
	local pos = {}
	if notificationPosStyle == "relativeDirection" then
		pos.x = math.abs(position.x)
		pos.y = position.y
		pos.z = math.abs(position.z)
	else
		pos = position
	end
	return pos
end

local function look(entity)
	local x, y, z = entity.x, entity.y, entity.z
	local pitch = -math.atan2(y, math.sqrt(x * x + z * z))
	local yaw = math.atan2(-x, z)
	modules.look(math.deg(yaw), math.deg(pitch))
end

local function distance(mob)
	return math.sqrt(mob.x^2 + mob.y^2 + mob.z^2)
end

local function findNearest(entities)
	local nearest = entities[1]
	for i = 2, #entities do
		if distance(entities[i]) < distance(nearest) then
			nearest = entities[i]
		end
	end
	return nearest
end

local function clearScreen()
	term.setBackgroundColor(colors.black)
	term.clear()
	term.setCursorPos(1,1)
end

-- Main Loop
parallel.waitForAny(
	function() -- Handle user input
		while true do
			local event, key = os.pullEvent("key")
			if key == launchUpKey.key and hasKinetic then
				modules.launch(0, -90, 3)
			elseif key == launchDirectionKey.key and hasKinetic then
				modules.launch(meta.yaw, meta.pitch, 3)
			elseif key == mobScanKey.key and hasSensor then
				toggle(features.mobscan)
			elseif key == useSpamKey.key and hasKinetic then
				toggle(features.use)
			elseif key == aimbotKey.key and hasSensor and hasKinetic then
				toggle(features.aimbot)
			elseif key == noFallKey.key and hasKinetic and hasScanner and hasIntrospection then
				toggle(features.nofall)
			elseif key == hoverKey.key and hasKinetic and hasIntrospection then
				toggle(features.hover)
			elseif key == oreScanKey.key and hasScanner then
				toggle(features.orescan)
			else
				tell("Feature not available or missing required modules.")
			end
		end
	end,
	function() -- Update meta data
		while true do
			if hasIntrospection then
				meta = modules.getMetaOwner()
			end
		end
	end,
	function() -- Mob Scanner
		while true do
			if features.mobscan.enabled then
				local mobs = modules.sense()
				local candidates = {}
				for _, mob in ipairs(mobs) do
					if mobLookup[mob.name] then
						table.insert(candidates, mob)
					end
				end
				if #candidates > 0 then
					for i, mob in ipairs(candidates) do
						if math.abs(mob.y) < 5 then
							local pos = getDirection(mob)
							local mobpos = getPosition(mob)
							tell("Mob Scanner | " .. i .. ": " .. mob.name .. " found at " .. pos.x .. mobpos.x .. pos.y .. mobpos.y .. pos.z .. mobpos.z)
						end
					end
				end
				sleep(2)
			else
				os.pullEvent(features.mobscan.event)
			end
		end
	end,
	function() -- Use Spam
		while true do
			if features.use.enabled then
				if not modules.use(1, "main") then
					tell("No block to use")
					features.use.enabled = false
					tell(features.use.name .. " was set to " .. tostring(features.use.enabled))
				end
				sleep(0.5)
			else
				os.pullEvent(features.use.event)
			end
		end
	end,
	function() -- Aimbot
		while true do
			if features.aimbot.enabled then
				local mobs = modules.sense()
				local candidates = {}
				for _, mob in ipairs(mobs) do
					if mobLookup[mob.name] then
						table.insert(candidates, mob)
					end
				end
				if #candidates > 0 then
					local nearestMob = findNearest(candidates)
					look(nearestMob)
					sleep(0.2)
				end
			else
				os.pullEvent(features.aimbot.event)
			end
		end
	end,
	function() -- No Fall
		while true do
			if features.nofall.enabled then
				local blocks = modules.scan()
				for y = 0, -8, -1 do
					local block = blocks[1 + (8 + (8 + y) * 17 + 8 * 17^2)]
					if block.name ~= "minecraft:air" then
						if meta.motionY < -0.3 then
							modules.launch(0, -90, math.min(4, meta.motionY / -0.5))
						end
						break
					end
				end
			else
				os.pullEvent(features.nofall.event)
			end
		end
	end,
	function() -- Hover
		while true do
			if features.hover.enabled then
				local mY = (meta.motionY - 0.138) / 0.8
				if mY > 0.5 or mY < 0 then
					local sign = mY < 0 and -1 or 1
					modules.launch(0, 90 * sign, math.min(4, math.abs(mY)))
				else
					sleep(0)
				end
			else
				os.pullEvent(features.hover.event)
			end
		end
	end,
	function() -- Ore Scanner
		while true do
			if features.orescan.enabled then
				local ores = modules.scan()
				local candidates = {}
				for _, ore in ipairs(ores) do
					if oreLookup[ore.name] then
						table.insert(candidates, ore)
					end
				end
				if #candidates > 0 then
					for i, ore in ipairs(candidates) do
						local pos = getDirection(ore)
						local orepos = getPosition(ore)
						tell("Ore Scanner | " .. i .. ": " .. ore.name .. " found at " .. pos.x .. orepos.x .. pos.y .. orepos.y .. pos.z .. orepos.z)
					end
				else
					tell("Ore Scanner | No ores found")
				end
				features.orescan.enabled = false
			else
				os.pullEvent(features.orescan.event)
			end
		end
	end,
	function() -- Display Help Text
		while true do
			clearScreen()
			local textColor = {
				[true] = colors.green,
				[false] = colors.red
			}

			local function printFeatureStatus(featureName, keyName, condition, featureDescription)
				term.setTextColor(textColor[condition])
				print(featureDescription .. ": Press " .. keyName .. ".")
			end

			printFeatureStatus("Launch Upwards", launchUpKey.keyname, hasKinetic, "Launch Upwards")
			printFeatureStatus("Launch Direction", launchDirectionKey.keyname, hasKinetic, "Launch in Direction")
			printFeatureStatus("Mob Scanner", mobScanKey.keyname, hasSensor, "Toggle Mob Scanner")
			printFeatureStatus("Use Spam", useSpamKey.keyname, hasKinetic, "Toggle Use Spam")
			printFeatureStatus("Aimbot", aimbotKey.keyname, hasSensor and hasKinetic, "Toggle Aimbot")
			printFeatureStatus("No Fall", noFallKey.keyname, hasKinetic and hasScanner and hasIntrospection, "Toggle No Fall Damage")
			printFeatureStatus("Hover", hoverKey.keyname, hasKinetic and hasIntrospection, "Toggle Hover")
			printFeatureStatus("Ore Scan", oreScanKey.keyname, hasScanner, "Activate Ore Scan")

			sleep(5)
		end
	end
)
