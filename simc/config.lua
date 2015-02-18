local os = require("os")
local _VERSION = _VERSION
module("simc.config")

-- OS Detection
local _OS = "Unknown"
if os.getenv("OS") and os.getenv("OS"):lower():find("windows") then
	_OS = "windows"
else
	local osType = os.getenv("OSTYPE")
	if osType and osType:find("darwin") then
		_OS = "MacOS"
	elseif osType then
		_OS = "Linux-" .. osType
	end
end											-- Leave it unknown otherwise

function IsWindows()
	return _OS:find("windows")
end

if IsWindows() then
	simcRootPath = [[E:/simulationcraft]]	-- Default location used by simc dev team
	simcPath = simcRootPath .. [[/simc64]]
	baseProfilePath = simcRootPath .. [[/profiles]]

	os.execute("chcp 65001")				-- Switch to command line codepage to UTF-8
else
	simcRootPath = [[~/Documents/simulationcraft]]
	simcPath = simcRootPath .. [[/engine/simc]]
	baseProfilePath = simcRootPath .. [[/profiles]]

	-- os.clock check for some lua binary on Linux OS: CentOS / RedHat etc.
	-- log("Detecting os.clock() bug ...")
	os.execute("sleep 1")
	if os.clock() == 0 then
		os.clock = os.time
		-- log("Replaced os.clock() as os.time()")
	end
end

-- Delimeter for profile generation. Use "\n" for better readability, yet uncompatitable for execution.
simcProfileDelimeter = " "

-- Lua version detection
_LUA_VERSION = _VERSION:match("Lua ([%d%.]+)")

-- Override this if you want to change cache file location
HttpCacheFilePath = IsWindows() and [[D:/httpCache.lua]] or "httpCache.lua"

-- SimC Output file name
simcOutputFile = "LuaSimC_output.txt"
-- simcOutputHTML = "LuaSimC_output.html"
