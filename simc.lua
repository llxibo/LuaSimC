local _G = _G
local io = require("io")
local os = require("os")
local table = require("table")
local assert = assert
local pairs = pairs
local ipairs = ipairs
local type = type
local tonumber = tonumber
local config require("simc.config")
local util = require("simc.util")
module("simc")

log = util.printf

local itemKeyList = {
	id = true,
	bonus_id = true,
	-- upgrade = true,
	enchant = true,
}

local charKeyList = {
	head = "item",
	neck = "item",
	shoulder = "item",
	cloak = "item",
	chest = "item",
	wrist = "item",
	hands = "item",
	waist = "item",
	legs = "item",
	feet = "item",
	ring1 = "item",
	ring2 = "item",
	trinket1 = "item",
	trinket2 = "item",

	race = true,
	timeofday = true,
	professions = true,
	talents = true,

	baseChar = false,
	class = false,
}

local globalsKeyList = {
	strict_gcd_queue = true,
	ptr = true,
	default_actions = true,
}

local tokenCache = {}
function ParseItemToken( itemName )
	if tokenCache[itemName] then
		return tokenCache[itemName]
	else
		local name = itemName:lower():gsub("%s", "_"):gsub("[^%a%_]", "")
		if name ~= itemName then
			log("Parsing trinket name %s => %s", itemName, name)
		end
		tokenCache[itemName] = name
		return name
	end
end

function AddProfileKey(profile, key, value)
	assert(type(key) == "string", "Error adding profile key: key is not string")
	assert(type(profile) == "table", "Error adding profile key: invalid profile")
	if type(value) == "boolean" then
		value = value and 1 or 0
	end
	assert(type(value) == "string" or type(value) == "number", "Error adding profile key: invalid value type")
	table.insert(profile, ("%s=%s"):format(key, value))
end

-- Generate a line of item from table
function GenerateItemProfile(item)
	local profile = {}
	-- print(item.enchant)
	assert(item.id, "Error generating item profile: item has no itemID")
	local name = util.GetItemInfo(item, "enUS").name
	assert(name, "Failed fetching name for item " .. item.id)
	local token = ParseItemToken(name)
	table.insert(profile, token)
	for key, value in pairs(item) do
		if itemKeyList[key] then
			AddProfileKey(profile, key, value)
		elseif itemKeyList[key] == nil then
			error("Error generating item profile: Invalid item key " .. key)
		end
	end
	return table.concat(profile, ",")
end

-- Generate character specific profile from table
function GenerateCharProfile(char)
	local profile = {}
	assert(char.baseChar or char.class, "Error generating char profile: No baseChar or class specified")
	if char.baseChar then
		table.insert(profile, ("%s/%s.simc"):format(config.baseProfilePath, char.baseChar))
	elseif char.class then
		AddProfileKey(profile, char.class, "dummy" .. char.class)				-- hunter=dummyhunter
	else
		error("Error generating char profile: No base char or class specified")
	end
	for key, value in pairs(char) do
		assert(charKeyList[key] ~= nil, "Error generating char profile: Unknown char key " .. key)
		if charKeyList[key] == "item" and type(value) == "table" then
			value = GenerateItemProfile(value)
		end
		if charKeyList[key] then
			AddProfileKey(profile, key, value)
		end
	end
	return table.concat(profile, config.simcProfileDelimeter)
end

-- Generate a SimC profile from tables
function GenerateProfile(chars, globals, overrides)
	local profile = {}
	if #chars > 0 then
		for index, char in ipairs(chars) do
			table.insert(profile, GenerateCharProfile(char))
		end
	else
		table.insert(profile, GenerateCharProfile(chars))
	end
	for key, value in pairs(globals) do
		assert(globalsKeyList[key], "Error generating global profile: Unknown option key " .. key)
		AddProfileKey(profile, key, value)
	end
	for key, value in pairs(overrides) do
		AddProfileKey(profile, key, value)
	end
	return table.concat(profile, config.simcProfileDelimeter)
end

-- Count total iterations of a result table
function GetResultIterations(result)
	if not result or not result.iterations then
		return 0
	end
	local total = 0
	for index, iterations in ipairs(result.iterations) do
		total = total + iterations
	end
	return total
end

-- Extract DPS and error from a plain text report generated by SimC
function GetReportDPS(report)
	local name, dps, err = report:match([[Player: (%S+) %S+ %S+ %S+ %S+
  DPS: ([%d%.]+)  DPS%-Error=([%d%.]+)]])
	dps = tonumber(dps)
	assert(dps, "Error calculating result DPS: Failed fetching DPS from result")
	err = tonumber(err)
	assert(err, "Error calculating result DPS: Failed fetching Error from result")
	return dps, err
end

-- Extract DPS and error from a result table
function GetResultDPS(result)
	assert(result, "Error calculating result DPS: No result specified")
	assert(result.outputs and #result.outputs > 0, "Error calculating result DPS: No data")

	if #result.outputs == 1 then
		return GetReportDPS(result.outputs[1])
	end

	local totalIterations = 0
	local totalDPS = 0
	local totalErrSquare = 0
	for index, output in ipairs(outputs) do
		local iterations = result.iterations[index]
		assert(iterations and iterations > 0, "Error calculating result DPS: Iterations not match")
		totalIterations = totalIterations + iterations

		local dps, err = GetReportDPS(output)

		totalDPS = totalDPS + (dps * iterations)
		totalErrSquare = totalErrSquare + (err * iterations) ^ 2
	end
	if totalIterations <= 0 then
		return nil, nil
	else
		return totalDPS / totalIterations, math.sqrt(totalErrSquare) / totalIterations
	end
end

-- Update result for a specific character, ensuring enough iterations
function SimulateChar(char, globals, iterations, result)
	log("Simulating char...")
	local result = result or {}
	local prevIterations = GetResultIterations(result)
	local requiredIterations = iterations - prevIterations
	if requiredIterations <= 0 then
		log("Skipping simulation: expecting %d, got %d", iterations, prevIterations)
		-- print_table(char)
		-- print(GetResultDPS(result))
		-- error("Stopping")
		return result
	end

	local overrides = {
		name = util.GetRandomName(),
		output = "Trinket_gen_output.txt",
		html = "Trinket_gen_output.html",
		iterations = requiredIterations,
	}
	local profile = GenerateProfile(char, globals, overrides)

	result.iterations = result.iterations or {}
	result.outputs = result.outputs or {}
	-- The output of simc could be read by io.popen("simc.exe")
	-- However, it requires extra logic to handle progress bar
	local simcStartTime = os.clock()
	log("Executing %s", profile)
	os.execute(config.simcPath .. " " .. profile)
	local simcElapsed = os.clock() - simcStartTime


	-- So we dump output into file and then process
	local report = util.ReadFile(overrides.output)
	local name, dps, err = report:match("Player: (%S+) %S+ %S+ %S+ %S+\n%s+DPS: ([%d%.]+)  DPS%-Error=([%d%.]+)")
	-- Check if we get correct char name
	if name and tonumber(dps) > 0 then
		if name ~= overrides.name then
			log("Output char name mismatch: %s expected, got %s", tostring(overrides.name), tostring(name))
			return
		end
		log("Sim complete for %s: %.1f - %.1f", name, dps, err)
	else
		log("Failed fetching dps from report. Dumping output file")
		log("")
		log(report)
		log("")
		error()
	end

	-- Potential error - item name inconsistency
	local customName, formalName, id = report:match([[inconsistency between name '(%S+)' and '(%S+)' for id (%d+)]])
	if customName then
		log("Name inconsistency: %s => %s #%d", formalName, customName, id)
	end

	table.insert(result.iterations, requiredIterations)
	table.insert(result.outputs, report)
	return result
end

function GetSimCVersion(isPTR)
	local report = {}
	local profile = isPTR and "ptr=1" or ""
	local simcOutput = util.ReadExecute(([[%s %s]]):format(config.simcPath, profile))
	report.version, report.major, report.minor,
		report.clientDesc, report.clientVer, report.clientType, report.clientBuild = simcOutput:match(
			"SimulationCraft ((%d+)%-(%d+)) for World of Warcraft (([%d%.]+) (.-) %(build level (%d+)%))"
		)
	report.hash, report.date = util.ReadExecute(
		([[git -C %s log -1 --format="%%h,%%cd"]]):format(config.simcRootPath)):match("^(%x+),([^\n]+)")
	report.versionFull = report.version .. "-" .. report.hash
	assert(report.clientDesc)
	return report
end
