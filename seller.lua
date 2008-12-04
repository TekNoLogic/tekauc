

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc seller|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("tekauc_seller")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


local ids = LibStub("tekIDmemo")


local pendingbag, pendingslot, batchitem, batchprice
local f = CreateFrame("Frame")
local queue = {}


local function finditem(id, size)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			local _, stack = GetContainerItemInfo(bag, slot)
			if link and ids[link] == id and stack == size then return bag, slot end
		end
	end
end


local function createauction(bag, slot, price, time)
	local link = GetContainerItemLink(bag, slot)
	if not link then return end

	Debug("Posting auction", link, bag, slot, price, time or 12*60)

	local _, stack = GetContainerItemInfo(bag, slot)

	PickupContainerItem(bag, slot)

	if GetCursorInfo() == "item" then
		ClickAuctionSellItemButton()
		ClearCursor()
	end

	pendingbag, pendingslot, batchitem, batchprice, batchstack = bag, slot, ids[link], price, stack
	f:RegisterEvent("BAG_UPDATE")
	StartAuction(price, price, time or 12*60)
end


local function processqueue()
	Debug("Processing next item in queue")
	local id, price, stack = table.remove(queue, 1), table.remove(queue, 1), table.remove(queue, 1)
	if id and price and stack then
		local bag, slot = finditem(id, stack)
		if bag and slot then
			createauction(bag, slot, price)
		else return processqueue() end
	else
		Debug("No more items in queue")
		pendingbag, pendingslot, batchitem, batchprice = nil
		f:UnregisterEvent("BAG_UPDATE")
	end
end


function tekauc:PostBatch(id, price, stack)
	if price <= 0 then return end
	table.insert(queue, id)
	table.insert(queue, price)
	table.insert(queue, stack)
	if not batchitem then return processqueue() end
end


f:SetScript("OnEvent", function(self, event, bag)
	if bag ~= pendingbag or GetContainerItemLink(pendingbag, pendingslot) then return end

	local bag, slot = finditem(batchitem, batchstack)
	if not (bag and slot) then processqueue()
	else createauction(bag, slot, batchprice) end
end)


local function GetPrice(link, stack)
	local price = link and GetAuctionBuyout(link)
	if not price then return end
	return math.floor((price*stack - 1)/500) * 500 -- Rounds down to the next multiple of 5s
end


local orig = ContainerFrameItemButton_OnModifiedClick
ContainerFrameItemButton_OnModifiedClick = function(self, button, ...)
	if AuctionFrame:IsShown() and IsAltKeyDown() then
		local bag, slot = this:GetParent():GetID(), this:GetID()
		local link = bag and slot and GetContainerItemLink(bag, slot)
		if IsShiftKeyDown() then
			-- Split into singles!
			SlashCmdList.TEKSPLITTER(link.." 1")
		else
			local _, stack = GetContainerItemInfo(bag, slot)
			local price = GetPrice(link, stack)
			if not price then
				if link then Print("Cannot find price for", link) else Print("Error finding item") end
				return orig(button, ...)
			end

			Print("Queueing ", link, "for sale at ", price)
			tekauc:PostBatch(ids[link], price, stack)
		end
	else return orig(self, button, ...) end
end


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
]]
local butt = LibStub("tekKonfig-Button").new(AuctionFrameAuctions, "TOPRIGHT", 20, -13)
butt:SetText("Sell Gems")
butt.tiptext = "Post all cut gems in your bags"
butt:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(6, GetItemInfo(link)) == "Gem" and not blist:match(ids[link]) and select(2, GetContainerItemInfo(bag, slot)) == 1 then
				local price = GetPrice(link, 1)
				if price then tekauc:PostBatch(ids[link], price, 1) end
			end
		end
	end
end)


local butt2 = LibStub("tekKonfig-Button").new(butt, "RIGHT", butt, "LEFT", -20, 0)
butt2:SetText("Sell Glyphs")
butt2.tiptext = "Post all single-stack glyphs in your bags"
butt2:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(6, GetItemInfo(link)) == "Glyph" and select(2, GetContainerItemInfo(bag, slot)) == 1 then
				local price = GetPrice(link, 1)
				if price then tekauc:PostBatch(ids[link], price, 1) end
			end
		end
	end
end)


local butt3 = LibStub("tekKonfig-Button").new(butt, "RIGHT", butt2, "LEFT")
butt3:SetText("Split Glyphs")
butt3.tiptext = "Split glyph stacks into singles"
butt3:SetScript("OnClick", function(self)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(6, GetItemInfo(link)) == "Glyph" and select(2, GetContainerItemInfo(bag, slot)) ~= 1 then
				SlashCmdList.TEKSPLITTER(link.." 1")
			end
		end
	end
end)

