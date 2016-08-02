
local myname, ns = ...

local TIME = 1 -- Which duration to post for.  1 == 12hr
local searched = {}

local debugf = tekDebug and tekDebug:GetFrame("tekauc_seller")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


local pendingbag, pendingslot, batchitem, batchprice
local f = CreateFrame("Frame")
f:Hide()
local queue = {}


local function finditem(id, size)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and ns.ids[link] == id then return bag, slot end
		end
	end
end

local processing = {}
local function ClearProcessing()
	wipe(processing)
end

function tekauc:PostBatch(id, price, stacksize)
	if price <= 0 then return end
	local bag, slot = finditem(id)
	if not bag or not slot then return end

	local link = GetContainerItemLink(bag, slot)
	if not link then return end

	PickupContainerItem(bag, slot)

	if GetCursorInfo() == "item" then
		AuctionFrameAuctions.duration = TIME -- Just so the default auction UI doesn't throw a stupid error
		ClickAuctionSellItemButton()
		ClearCursor()
	end

	local id = ns.ids[link]
	local _, _, _, _, _, _, _, stack, sellable = GetAuctionSellItemInfo()
	stacksize = math.min(stacksize or 1, stack)
	local numstacks = math.floor(sellable/stacksize)
	Debug("Posting auction", id, bag, slot, price, stacksize, numstacks, TIME)
	ns.Print("Posting", numstacks, "stacks of", link, "x"..stacksize, "for sale at", ns.GS(price))

	StartAuction(price, price, TIME, stacksize, numstacks)

	if not next(processing) then C_Timer.After(4, ClearProcessing) end
	if numstacks == 1 then
		processing[id] = true
	else
		processing.batch = true
	end
end


local function GetPrice(link, stack)
	local price = link and tekauc.GetAuctionBuyout(link)
	if not price then return end
	local stackprice = price*stack
	if stackprice > 10000 then stackprice = math.floor((stackprice - 1)/500) * 500 end -- Rounds down to the next multiple of 5s if > 1g
	return stackprice
end


local orig = ContainerFrameItemButton_OnModifiedClick
ContainerFrameItemButton_OnModifiedClick = function(self, button, ...)
	if AuctionFrame:IsShown() and IsAltKeyDown() then
		local bag, slot = self:GetParent():GetID(), self:GetID()
		local link = bag and slot and GetContainerItemLink(bag, slot)
		local id = link and ns.ids[link]

		local stacksize = IsShiftKeyDown() and 1 or select(2, GetContainerItemInfo(bag, slot))
		local price = GetPrice(link, stacksize)
		if id and not ns.scannedall and not searched[id] then
			searched[id] = true
			local name = GetItemInfo(id)
			BrowseName:SetText(name)
			AuctionFrameBrowse.page = 0
			QueryAuctionItems(name)
			return
		end

		if not price then
			if link then ns.Print("Cannot find price for", link) else ns.Print("Error finding item") end
			return orig(self, button, ...)
		end

		tekauc:PostBatch(ns.ids[link], price, stacksize)
	else return orig(self, button, ...) end
end


local PADDING = 4
local bgFrame = {bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", insets = {left = PADDING, right = PADDING, top = PADDING, bottom = PADDING},
	tile = true, tileSize = 16, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16}

local f = CreateFrame("Frame", nil, AuctionFrame)
f:SetPoint("TOP", 0, 13)
f:SetPoint("RIGHT", -25, 0)
f:SetWidth(248)
f:SetHeight(53)
f:SetFrameLevel(AuctionFrame:GetFrameLevel()-1)

f:SetBackdrop(bgFrame)
f:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b)
f:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b)


local blist = [[
  818   774  1206  1210  1529  1705
 3864  7909  7910 12361 12364 12799 12800
23077 21929 23112 23079 23117 23107
23436 23439 23440 23437 23438 23441
32227 32231 32229 32249 32228 32230
36917 36929 36920 36932 36923 36926
36918 36930 36921 36933 36924 36927
 5498  5500  7971 13926 24478 36783 24479
25867 25868 36784 41266 41334 42225
11382 12363 19774
36919 36931 36922 36934 36925 36928
52190 52193 52195 52192 52191 52194
52177 52181 52179 52182 52178 52180
76136 76130 76134 76137 76133 76135
76131 76140 76142 76139 76138 76141
76734
]]


local function IsEnchantScroll(link)
	if not link then return end
	local name, _, _, _, _, _, subtype = GetItemInfo(link)
	return subtype == "Item Enhancement" and name:match("^Scroll of Enchant")
end


local butt1 = LibStub("tekKonfig-Button").new(f, "TOPLEFT", 4, -4)
butt1:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt1:SetText("Sell Chants")
butt1:Disable()
butt1.tiptext = "Post all enchant scrolls in your bags as single-item auctions"
butt1:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if IsEnchantScroll(link) then
				local price = GetPrice(link, 1)
				if price then return tekauc:PostBatch(ns.ids[link], price, 1) end
			end
		end
	end
end)


local butt2 = LibStub("tekKonfig-Button").new(f, "LEFT", butt1, "RIGHT")
butt2:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt2:SetText("Sell Glyphs")
butt2:Disable()
butt2.tiptext = "Post all glyphs in your bags as single-item auctions"
butt2:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local id = ns.ids[link]
				local skip = processing[id] or processing.batch
				if not skip and select(6, GetItemInfo(link)) == "Glyph" then
					local price = GetPrice(link, 1)
					if price then return tekauc:PostBatch(ns.ids[link], price, 1) end
				end
			end
		end
	end
end)


local WEAPON = GetItemClassInfo(2)
local ARMOR = GetItemClassInfo(4)
local butt3 = LibStub("tekKonfig-Button").new(f, "LEFT", butt2, "RIGHT")
butt3:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt3:SetText("Sell BoEs")
butt3:Disable()
butt3.tiptext = "Post all Bind on Equip equipment in your bags"
butt3:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link then
				local id = ns.ids[link]
				local skip = processing[id] or processing.batch
				skip = skip or not ns.IsBindOnEquip(bag, slot)
				local _, _, _, _, _, itemtype = GetItemInfo(link)
				if not skip and (itemtype == ARMOR or itemtype == WEAPON) then
					local price = GetPrice(link, 1)
					if price then return tekauc:PostBatch(ns.ids[link], price, 1) end
				end
			end
		end
	end
end)

ns.sellbutts = {butt1, butt2, butt3}
