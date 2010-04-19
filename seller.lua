

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc seller|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("tekauc_seller")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


local ids = LibStub("tekIDmemo")


local pendingbag, pendingslot, batchitem, batchprice
local f = CreateFrame("Frame")
f:Hide()
local queue = {}


local function finditem(id, size)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and ids[link] == id then return bag, slot end
		end
	end
end


local time_indexes = { [12*60]=1, [24*60]=2, [48*60]=3}
local function createauction(bag, slot, price, stacksize, time)
	-- local bag, slot = finditem(id)
	local link = GetContainerItemLink(bag, slot)
	if not link then return end

	PickupContainerItem(bag, slot)

	if GetCursorInfo() == "item" then
		ClickAuctionSellItemButton()
		ClearCursor()
	end

	local id = ids[link]
	local _, _, _, _, _, _, _, stack, sellable = GetAuctionSellItemInfo()
	stacksize, time = math.min(stacksize or 1, stack), time_indexes[time or 12*60]
	local numstacks = math.floor(sellable/stacksize)
	Debug("Posting auction", id, bag, slot, price, stacksize, numstacks, time)
	Print("Posting", numstacks, "stacks of", link, "x"..stacksize, "for sale at", price)

	if stacksize == 1 and numstacks == 1 then
		pendingbag, pendingslot, batchitem, batchprice, batchstack = bag, slot, id, price, stack
		f:RegisterEvent("BAG_UPDATE")
	else
		f:RegisterEvent("AUCTION_MULTISELL_UPDATE")
	end

	StartAuction(price, price, time, stacksize, numstacks)
end


local function processqueue()
	Debug("Processing next item in queue")
	local id, price, stack = table.remove(queue, 1), table.remove(queue, 1), table.remove(queue, 1)
	if id and price and stack then
		local bag, slot = finditem(id)
		if bag and slot then createauction(bag, slot, price, stack)
		else return processqueue() end
	else
		Debug("No more items in queue")
	end
end


function tekauc:PostBatch(id, price, stack)
	if price <= 0 then return end
	table.insert(queue, id)
	table.insert(queue, price)
	table.insert(queue, stack)
	if not batchitem then return processqueue() end
end


local elap = 0
f:SetScript("OnShow", function(self) elap = 0 end)
f:SetScript("OnHide", function(self) processqueue() end)
f:SetScript("OnUpdate", function(self, e)
	elap = elap + e
	if elap >= 1 then self:Hide() end
end)
f:SetScript("OnEvent", function(self, event, ...)
	if event == "AUCTION_MULTISELL_UPDATE" then
		local posted, total = ...
		if posted ~= total then return end

		f:UnregisterEvent("AUCTION_MULTISELL_UPDATE")
		f:Show()
	else
		local bag = ...
		if bag ~= pendingbag or GetContainerItemLink(pendingbag, pendingslot) then return end

		local bag, slot = finditem(batchitem, batchstack)
		if (bag and slot) then return createauction(bag, slot, batchprice) end

		pendingbag, pendingslot, batchitem, batchprice = nil
		f:UnregisterEvent("BAG_UPDATE")

		processqueue()
	end
end)


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
		local bag, slot = this:GetParent():GetID(), this:GetID()
		local link = bag and slot and GetContainerItemLink(bag, slot)

		local stacksize = IsShiftKeyDown() and 1 or select(2, GetContainerItemInfo(bag, slot))
		local price = GetPrice(link, stacksize)
		if not price then
			if link then Print("Cannot find price for", link) else Print("Error finding item") end
			return orig(self, button, ...)
		end

		tekauc:PostBatch(ids[link], price, stacksize)
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
]]


local function IsEnchantScroll(link)
	if not link then return end
	local name, _, _, _, _, _, subtype = GetItemInfo(link)
	return subtype == "Item Enhancement" and name:match("^Scroll of Enchant")
end


local butt1 = LibStub("tekKonfig-Button").new(f, "TOPLEFT", 4, -4)
butt1:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt1:SetText("Sell Chants")
butt1.tiptext = "Post all enchant scrolls in your bags as single-item auctions"
butt1:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if IsEnchantScroll(link) then
				local price = GetPrice(link, 1)
				if price then tekauc:PostBatch(ids[link], price, 1) end
			end
		end
	end
end)


local butt2 = LibStub("tekKonfig-Button").new(f, "LEFT", butt1, "RIGHT")
butt2:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt2:SetText("Sell Glyphs")
butt2.tiptext = "Post all glyphs in your bags as single-item auctions"
butt2:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(6, GetItemInfo(link)) == "Glyph" then
				local price = GetPrice(link, 1)
				if price then tekauc:PostBatch(ids[link], price, 1) end
			end
		end
	end
end)


local butt5 = LibStub("tekKonfig-Button").new(f, "LEFT", butt2, "RIGHT")
butt5:SetFrameLevel(AuctionFrame:GetFrameLevel()+1)
butt5:SetText("Sell Gems")
butt5.tiptext = "Post all cut gems in your bags"
butt5:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(6, GetItemInfo(link)) == "Gem" and not blist:match(ids[link]) then
				local price = GetPrice(link, 1)
				if price then tekauc:PostBatch(ids[link], price, 1) end
			end
		end
	end
end)
