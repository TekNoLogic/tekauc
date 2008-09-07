

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc seller|r:", ...)) end

local debugf = tekDebug and tekDebug:GetFrame("tekauc_seller")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", ...)) end end


local ids = LibStub("tekIDmemo")


local defaults = {
	[24027] = 700000, [24028] = 700000, [24029] = 700000, [24030] = 700000, [24031] = 700000, [24032] = 700000, [24036] = 700000, -- Living Rubies
	[24058] = 500000, [24059] = 500000, [24060] = 500000, [24061] = 500000, [31867] = 500000, [31868] = 500000, [35316] = 500000, -- Noble Topaz
	[24047] = 550000, [24048] = 550000, [24050] = 550000, [24051] = 550000, [24052] = 550000, [24053] = 550000, [31861] = 550000, -- Dawnstone
	[24033] = 250000, [24035] = 250000, [24037] = 250000, [24039] = 250000, -- Star of Elune

	[23077] = 50000, [21939] = 13000, [23112] = 20000, [23079] = 12500, [23117] = 10000, [23107] = 40000, -- Raw greens
	[23094] = 70000, [23095] = 70000, [23097] = 70000, [23096] = 70000, [28595] = 70000, -- Blood Garnet
	[23098] = 25000, [23099] = 25000, [23100] = 25000, [23101] = 25000, [31866] = 70000, [31869] = 70000, -- Flame Spessarite
	[23113] = 25000, [23114] = 25000, [23115] = 25000, [23116] = 25000, [28290] = 25000, [31860] = 25000, -- Golden Draenite
	[32833] = 20000, [32836] = 600000, -- Pearls
}

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
ContainerFrameItemButton_OnModifiedClick = function(button, ...)
	if AuctionFrame:IsShown() and IsAltKeyDown() then
		local bag, slot = this:GetParent():GetID(), this:GetID()
		local link = bag and slot and GetContainerItemLink(bag, slot)
		local _, stack = GetContainerItemInfo(bag, slot)
		local price = link and GetAuctionBuyout(link)
		if not price then
			if link then Print("Cannot find price for", link) else Print("Error finding item") end
			return orig(button, ...)
		end

		price = math.floor((price*stack - 1)/500) * 500 -- Rounds down to the next multiple of 5s
		Print("Queueing ", link, "for sale at ", price)
		tekauc:PostBatch(ids[link], price, stack)
	else return orig(button, ...) end
end

