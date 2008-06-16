
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

local f = CreateFrame("frame", nil, AuctionFrame)
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")
f:Hide()


function f:ADDON_LOADED(event, addon)
	if addon ~= "tekauc" then return end

	tekaucDB, tekaucDBPC = setmetatable(tekaucDB or {}, {__index = defaults}), setmetatable(tekaucDBPC or {}, {__index = defaultsPC})
	db, dbpc = tekaucDB, tekaucDBPC

	local n = AuctionFrame.numTabs+1
	self.tabindex = n
	local framename = "AuctionFrameTab"..n
	local frame = CreateFrame("Button", framename, AuctionFrame, "CharacterFrameTabButtonTemplate")
	frame:SetID(n)
	frame:SetText("tekauc")
	frame:SetPoint("LEFT", getglobal("AuctionFrameTab"..n-1), "RIGHT", -8, 0)
	PanelTemplates_SetNumTabs(AuctionFrame, n)
	PanelTemplates_EnableTab(AuctionFrame, n)

	frame:SetScript("OnClick", function()
		PanelTemplates_SetTab(AuctionFrame, n)
		AuctionFrameAuctions:Hide()
		AuctionFrameBrowse:Hide()
		AuctionFrameBid:Hide()
		PlaySound("igCharacterInfoTab")

		AuctionFrameTopLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
		AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Top")
		AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopRight")
		AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
		AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-Bot")
		AuctionFrameBotRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")
		self:Show()
	end)

	local function Hider() self:Hide() end
	for _,frame in pairs({AuctionFrameAuctions, AuctionFrameBrowse, AuctionFrameBid}) do CreateFrame("Frame", nil, frame):SetScript("OnShow", Hider) end

	self:SetPoint("TOPLEFT", 20, -71)
	self:SetPoint("BOTTOMRIGHT", -10, 37)

	LibStub("tekKonfig-AboutPanel").new(nil, "tekauc") -- Remove first arg if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self:RegisterEvent("PLAYER_LOGOUT")
end


function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end

