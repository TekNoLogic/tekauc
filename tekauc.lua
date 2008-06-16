
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}


------------------------------
--      Util Functions      --
------------------------------

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("tekauc")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


-----------------------------
--      Event Handler      --
-----------------------------

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")


function f:ADDON_LOADED(event, addon)
	if addon ~= "tekauc" then return end

	tekaucDB, tekaucDBPC = setmetatable(tekaucDB or {}, {__index = defaults}), setmetatable(tekaucDBPC or {}, {__index = defaultsPC})
	db, dbpc = tekaucDB, tekaucDBPC

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new("tekauc", "tekauc") -- Remove first arg if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self:RegisterEvent("PLAYER_LOGOUT")
end


function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end

