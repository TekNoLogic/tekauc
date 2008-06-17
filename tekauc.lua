
----------------------
--      Locals      --
----------------------

local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {items = ""}
local items = {}


-----------------------------
--      Event Handler      --
-----------------------------

tekauc = CreateFrame("Button", nil, AuctionFrame)
tekauc:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
tekauc:RegisterEvent("ADDON_LOADED")
tekauc:Hide()


function tekauc:ADDON_LOADED(event, addon)
	if addon ~= "tekauc" then return end

	tekaucDB, tekaucDBPC = setmetatable(tekaucDB or {}, {__index = defaults}), setmetatable(tekaucDBPC or {}, {__index = defaultsPC})
	db, dbpc = tekaucDB, tekaucDBPC

	if dbpc.items ~= "" then
		local function helper(...)
			for i=1,select("#", ...) do items[tonumber((select(i, ...)))] = true end
		end
		helper(string.split(" ", dbpc.items))
	end

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

	self:SetScript("OnReceiveDrag", self.OnReceiveDrag)
	self:SetScript("OnClick", function(self) if CursorHasItem() then self:OnReceiveDrag() end end)

	LibStub("tekKonfig-AboutPanel").new(nil, "tekauc") -- Remove first arg if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	self:RegisterEvent("PLAYER_LOGOUT")
end


function tekauc:PLAYER_LOGOUT()
	local temp = {}
	for item in pairs(items) do table.insert(temp, item) end
	dbpc.items = table.concat(temp, " ")

	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end

	-- Do anything you need to do as the player logs out
end


function tekauc:OnReceiveDrag()
	local infotype, itemid, itemlink = GetCursorInfo()
	if infotype == "item" then items[itemid] = select(8, GetItemInfo(itemid)) end
	return ClearCursor()
end


------------------------------
--      Util Functions      --
------------------------------

function tekauc:Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("tekauc")
function tekauc:Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end

function tekauc:GS(cash)
	if not cash then return end
	cash = cash/100
	local s = floor(cash%100)
	local g = floor(cash/100)
	if g > 0 then return string.format("|cffffd700%d.|cffc7c7cf%02d", g, s)
	else return string.format("|cffc7c7cf%d", s) end
end
