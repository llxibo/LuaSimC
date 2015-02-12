local _G = _G
local require = require
local os = require("os")
local io = require("io")
local string = require("string")
local math = require("math")
local table = require("table")
local assert = assert
local error = error
local pairs = pairs
local ipairs = ipairs
local loadstring = loadstring
local type = type
local tonumber = tonumber
local tostring = tostring
local pcall = pcall
local dofile = dofile
module("simc.util")

log = _G.print

local _isWindows = os.getenv("OS") and os.getenv("OS"):find("Windows")
function IsWindows()
	return _isWindows
end

-- Override this if you want to change cache
HttpCacheFilePath = IsWindows() and [[D:/httpCache.lua]] or "httpCache.lua"

function printf( msg, ... )
	local message = msg:format( ... )
	if __is_console then
		log( message .. string.rep(" ", 119 - message:len()) )
	else
		log( message )
	end
	io.stdout:flush()
	return message
end

function printf_t( t, msg, ... )
	local message = printf(msg, ...)
	table.insert(t, message)
end

function ParseJson( json )
	local lua = "return " .. json:gsub("%[", "{"):gsub("%]", "}"):gsub([["(%w-)":]], [[["%1"]=]])--:gsub([[(%w-):]], [[["%1"]=]])
	local func, err = loadstring(lua)
	if not func then
		print(lua)
		return error(err)
	end
	return func()
end

function HttpRequest(url, retry)
	local http = require("socket.http")
	local retry = retry or 10
	while retry > 0 do
		local data = http.request(url)
		if data then
			return data
		end
		retry = retry - 1
	end
end

local http_cache
local http_cache_file
function HttpRequestCached(url, retry)
	if not http_cache then
		log("Loading http cache...")
		http_cache = {}
		pcall(dofile, HttpCacheFilePath)
		http_cache_file = io.open(HttpCacheFilePath, "a+")
		log("Finished loading cache.")
	end
	if http_cache[url] then
		return http_cache[url]
	end
	printf("HttpRequestCached %s", url)
	local data = HttpRequest(url, retry)
	AddHttpCache(url, data)
	return data
end

function HttpRequestJson(url)
	local json_str = HttpRequestCached(url, 5)
	if not json_str then
		return {}
	end
	return ParseJson(json_str) or {}
end

function AddHttpCache(url, data)
	http_cache[url] = data
	if http_cache_file then
		http_cache_file:write("FileAddHttpCache(", string.format("%q", url), ", ", string.format("%q", data), ")", "\n")
	end
end

function FileAddHttpCache(url, data)
	http_cache[url] = data
end

function WriteTable( file, table, indent )
	local indent = indent or ""
	for key, value in pairs(table) do
		file:write(indent)
		if type(key) == "number" then
			file:write("[", key, "]")
		elseif type(key) == "string" then
			file:write("[", string.format("%q", key), "]")
		end
		file:write(" = ")
		if type(value) == "number" then
			file:write(value)
		elseif type(value) == "string" then
			file:write(string.format("%q", value))
		elseif type(value) == "table" then
			file:write("{\n")
			WriteTable(file, value, indent .. "\t")
			file:write(indent)
			file:write("}")
		elseif type(value) == "boolean" then
			file:write(tostring(value))
		else
			file:write("nil")
		end
		file:write(",\n")
	end
end

function print_table(table, name)
	dump_table(io.stdout, table, name)
	io.stdout:flush()
end

function dump_table(file, table, name)
	local name = name or "value"
	file:write(name, " = {\n")
	WriteTable(file, table)
	file:write("}\n")
	file:flush()
end

function find_in_list(list, item)
	for index, value in ipairs(list) do
		if value == item then
			return index
		end
	end
end

local item_cache = {}
function get_item_info(item, locale, context)
	local locale_query = locale and ("?locale=" .. locale) or ""

	local itemID = item
	local bonusID
	if type(item) == "table" then
		itemID = item.id
		bonusID = item.bonus_id
		-- print("Using bonus_id", bonusID)
	end
	itemID = item_cache[itemID] or itemID
	context = context and "/" .. context or ""
	if not tonumber(itemID) then print_table(item) end
	assert(tonumber(itemID), "Error fetching item info: itemID must be a number")

	local queryURL = "http://www.battlenet.com.cn/api/wow/item/" .. itemID .. context .. locale_query
	local json = HttpRequestJson(queryURL)
	if not json.name and json.status == "nok" then
		if json.reason:find("unable to get item information") then
			return get_item_info_wowhead(item)
		end
		printf("Error fetching item info: %s", json.reason)
		http_cache[queryURL] = nil
		return get_item_info(item, locale)
	end
	if not json.name and json.availableContexts and #json.availableContexts > 0 then
		local jsonWithContext
		for index, context in ipairs(json.availableContexts) do
			jsonWithContext = get_item_info(item, locale, context)
			if find_in_list(jsonWithContext.bonusLists, bonusID) then
				return jsonWithContext
			end
		end
		-- print("Error finding info for item: cannot match any context with requested bonus id")
		-- print_table(json)
		-- print_table(jsonWithContext)
		return jsonWithContext
	end
	if json.name and json.id then
		item_cache[json.name] = json.id
	end
	return json
end

function get_item_info_wowhead(item)
--$.extend(g_items[122601], {"armor":0,"classs":4,"flags2":8192,"id":122601,"level":640,"name":"3Stone of Wind","namedesc":"Stage 1 of 4","reqlevel":91,"slot":12,"slotbak":12,"source":[1],"sourcemore":[{"c":11,"icon":"achievement_dungeon_utgardekeep","n":"Stone of Wind","s":171,"t":6,"ti":181647}],"subclass":-4,"jsonequip":{"quality":4,"armor":0,"classs":4,"flags2":8192,"id":122601,"level":640,"name":"3Stone of Wind","namedesc":"Stage 1 of 4","reqlevel":91,"slot":12,"slotbak":12,"source":[1],"sourcemore":[{"c":11,"icon":"achievement_dungeon_utgardekeep","n":"Stone of Wind","s":171,"t":6,"ti":181647}],"subclass":-4,"reqlevel":91,"reqskill":171,"reqskillrank":1,"sellprice":178494,"slotbak":12,"versatility":175,"statsInfo":[]}});
	log("Fetching item info from wowhead...")
	local itemID = item
	local bonusID
	if type(item) == "table" then
		itemID = item.id
		bonusID = item.bonus_id
	end
	local bonusStr = bonusID and "&bonus=" .. bonusID or ""
	local page = HttpRequestCached(string.format("http://www.wowhead.com/item=%d%s", itemID, bonusStr))
	local info = page:match("%$%.extend%(g_items%[" .. itemID .. "%], (.-)%);")
	-- error(info)
	local itemJson = ParseJson(info)
	itemJson.name = itemJson.sourcemore[1].n	-- Wowhead returns name like: "3Stone of Earth"
	itemJson.icon = itemJson.sourcemore[1].icon
	return itemJson
end

function ReadStream(path, pattern, streamOpen)
	local file = streamOpen(path, "r")
	if not file then
		return
	end
	local str = file:read(pattern or "*all")
	file:close()
	return str
end

function ReadFile(path, pattern)
	return ReadStream(path, pattern, io.open)
end

function ReadExecute(command, pattern)
	return ReadStream(command, pattern, io.popen)
end

function GetRandomName()
	local dict = "0123456789ABCDEF"
	local name = ""
	for index = 1, 8 do
		local index = math.random(1, #dict)
		name = name .. dict:sub(index, index)
	end
	return name
end

function WriteTable( file, table, indent )
	local indent = indent or ""
	for key, value in pairs(table) do
		file:write(indent)
		if type(key) == "number" then
			file:write("[", key, "]")
		elseif type(key) == "string" then
			file:write("[", string.format("%q", key), "]")
		end
		file:write(" = ")
		if type(value) == "number" then
			file:write(value)
		elseif type(value) == "string" then
			file:write(string.format("%q", value))
		elseif type(value) == "table" then
			file:write("{\n")
			WriteTable(file, value, indent .. "\t")
			file:write(indent)
			file:write("}")
		elseif type(value) == "boolean" then
			file:write(tostring(value))
		else
			file:write("nil")
		end
		file:write(",\n")
	end
end

function SaveSession(session, forceSave)
	if (not forceSave) and (prevSaveSession and os.time() - prevSaveSession < 10) then
		return
	end
	local fileName = "Sessions/" .. session.name .. ".lua"
	local file = io.open(fileName, "w")
	if not file then
		os.execute("md Sessions")
		file = io.open(fileName, "w")
	end
	assert(file, "Failed saving session: could not open file")
	file:write("session = {\n")
	WriteTable( file, session, "\t" )
	file:write("}\n")
	file:close()
	prevSaveSession = os.time()
end

function get_item_bbcode(id)
	local info = get_item_info(id)
	if not info then
		return "[item=id]物品名不可用[/item]"
	end
	if not info.name or not info.icon then
		print_table(info)
	end
	return ("[img]http://img.db.178.com/wow/icons/s/%s.jpg[/img][item=%d]%s[/item]"):format(
		info.icon, id, info.name
	)
end

function new_array()
	return {___isarray = true}
end

function new_rawcode(code)
	return {___israwcode = true, data = code}
end

function write_json(file, json)
	local subsequent = false
	if type(json) == "string" then
		file:write(string.format("%q", json))
	elseif type(json) == "number" then
		file:write(tostring(json))
	elseif type(json) == "boolean" then
		file:write(tostring(json))
	elseif type(json) == "table" and json.___israwcode then
		assert(json.code, "Error parsing json: node marked as raw code without data")
		file:write(json.data)
	elseif type(json) == "table" and json.___isarray then
		file:write("[")
		for index, value in ipairs(json) do
			if subsequent then
				file:write(", ")
			end
			write_json(file, value)
			subsequent = true
		end
		file:write("]")
	elseif type(json) == "table" and not json.___isarray then
		file:write("{")
		for key, value in pairs(json) do
			if subsequent then
				file:write(", ")
			end
			if type(key) ~= "string" then
				error("Error parsing json: invalid key " .. tostring(key))
			end
			write_json(file, key)
			file:write(": ")
			write_json(file, value)
			subsequent = true
		end
		file:write("}")
	else
		error("Error parsing json: unknown value " .. tostring(json))
	end
end
