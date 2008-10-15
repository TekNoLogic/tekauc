

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
			local price = link and GetAuctionBuyout(link)
			if not price then
				if link then Print("Cannot find price for", link) else Print("Error finding item") end
				return orig(button, ...)
			end

			price = math.floor((price*stack - 1)/500) * 500 -- Rounds down to the next multiple of 5s
			Print("Queueing ", link, "for sale at ", price)
			tekauc:PostBatch(ids[link], price, stack)
		end
	else return orig(self, button, ...) end
end

