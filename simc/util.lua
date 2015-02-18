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
local loadfile = loadfile
local setfenv = setfenv
local config = require("simc.config")
module("simc.util")

-- Override this if you want another sink for log
print = _G.print

function printf( msg, ... )
	local message = msg:format( ... )
	if __is_console then
		print( message .. string.rep(" ", 119 - message:len()) )
	else
		print( message )
	end
	io.stdout:flush()
	return message
end

function CopyTable(t)
	if type(t) ~= "table" then
		return t
	end
	local copy = {}
	for key, value in pairs(t) do
		copy[CopyTable(key)] = CopyTable(value)
	end
	return copy
end

function ParseJson(json)
	local lua = "return " .. json:gsub("%[", "{"):gsub("%]", "}"):gsub([["(%w-)":]], [[["%1"]=]])--:gsub([[(%w-):]], [[["%1"]=]])
	local func, err = loadstring(lua)
	assert(func, "Error parsing json: " .. tostring(err))
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
		printf("Loading http cache...")
		http_cache = {}
		assert(HttpRequestCached, "HttpRequestCached not defined")
		local func = loadfile(config.HttpCacheFilePath)
		if func then
			setfenv(func, _M)	-- FileAddHttpCache is a member of this module
			local ok = pcall(func, config.HttpCacheFilePath)
			printf("Finished loading cache: %s", tostring(ok))
		end
		http_cache_file = io.open(config.HttpCacheFilePath, "a+")
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
		http_cache_file:flush()	-- MacOS requires flush
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

function PrintTable(table, name)
	DumpTable(io.stdout, table, name)
	io.stdout:flush()
end

function DumpTable(file, table, name)
	local name = name or "value"
	file:write(name, " = {\n")
	WriteTable(file, table)
	file:write("}\n")
	file:flush()
end

function FindInList(list, item)
	for index, value in ipairs(list) do
		if value == item then
			return index
		end
	end
end

local item_cache = {}
function GetItemInfo(item, locale, context)
	local localeSuffix = locale and ("?locale=" .. locale) or ""

	local itemID = item
	local bonusID
	if type(item) == "table" then
		itemID = item.id
		bonusID = item.bonus_id
		-- print("Using bonus_id", bonusID)
	end
	itemID = item_cache[itemID] or itemID
	context = context and "/" .. context or ""
	if not tonumber(itemID) then PrintTable(item) end
	assert(tonumber(itemID), "Error fetching item info: itemID must be a number")

	local queryURL = "http://www.battlenet.com.cn/api/wow/item/" .. itemID .. context .. localeSuffix
	local json = HttpRequestJson(queryURL)
	if not json.name and json.status == "nok" then
		if json.reason:find("unable to get item information") then
			return GetItemInfoWowhead(item)
		end
		printf("Error fetching item info: %s", json.reason)
		http_cache[queryURL] = nil
		return GetItemInfo(item, locale)
	end
	if not json.name and json.availableContexts and #json.availableContexts > 0 then
		local jsonWithContext
		for index, context in ipairs(json.availableContexts) do
			jsonWithContext = GetItemInfo(item, locale, context)
			if FindInList(jsonWithContext.bonusLists, bonusID) then
				return jsonWithContext
			end
		end
		-- print("Error finding info for item: cannot match any context with requested bonus id")
		-- PrintTable(json)
		-- PrintTable(jsonWithContext)
		return jsonWithContext
	end
	if json.name and json.id then
		item_cache[json.name] = json.id
	end
	return json
end

function GetItemInfoWowhead(item)
	printf("Fetching item info from wowhead...")
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
		os.execute("mkdir Sessions")
		file = io.open(fileName, "w")
	end
	assert(file, "Failed saving session: could not open file")
	file:write("session = {\n")
	WriteTable( file, session, "\t" )
	file:write("}\n")
	file:close()
	prevSaveSession = os.time()
end

function GetItemBBCode(id)
	local info = GetItemInfo(id)
	if not info then
		return "[item=id]物品名不可用[/item]"
	end
	if not info.name or not info.icon then
		PrintTable(info)
	end
	return ("[img]http://img.db.178.com/wow/icons/s/%s.jpg[/img][item=%d]%s[/item]"):format(
		info.icon, id, info.name
	)
end

function NewArray()
	return {___isarray = true}
end

function NewRawcode(code)
	return {___israwcode = true, data = code}
end

function WriteJson(file, json)
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
			WriteJson(file, value)
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
			WriteJson(file, key)
			file:write(": ")
			WriteJson(file, value)
			subsequent = true
		end
		file:write("}")
	else
		error("Error parsing json: unknown value " .. tostring(json))
	end
end
