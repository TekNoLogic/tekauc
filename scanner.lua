
local myname, ns = ...

local INFLATION_LIMIT = 2.5 -- Maximum markup we'll allow over manually set prices
local ids = LibStub("tekIDmemo")
local mins, maxes, counts, lastseen, allscan = {}, {}, {}, {}

tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts


local butt = LibStub("tekKonfig-Button").new(BrowseSearchButton, "RIGHT", BrowseSearchButton, "LEFT", -10, 0)
butt:SetText("Scan All")

local enabled = true
butt:SetScript("OnUpdate", function(self)
	local _, scanable = CanSendAuctionQuery("list")
	if enabled and not scanable then self:Disable()
	elseif not enabled and scanable then
		self:Enable()
		for _,sellbutt in pairs(ns.sellbutts) do sellbutt:Disable() end
	end
	enabled = scanable
end)

butt:SetScript("OnClick", function(self)
	ChatFrame1:AddMessage("Sending all-scan query")
	mins, maxes, counts = {}, {}, {}
	tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts
	allscan = true
	QueryAuctionItems(nil, nil, nil, nil, nil, nil, nil, nil, nil, true)
end)

butt:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
butt:SetScript("OnEvent", function(self)
	local num, total = GetNumAuctionItems("list")
	if num ~= total then return end

	local touched = {}

	for i=1,num do
		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)
		local id = ids[GetAuctionItemLink("list", i)]

		if not allscan and not touched[id] then touched[id], mins[id], maxes[id], counts[id] = true end -- Wipe these results if it's a short scan
		buyoutPrice = buyoutPrice / count
		if buyoutPrice > 0 and (not tekauc.manualprices[id] or (tekauc.manualprices[id] * INFLATION_LIMIT) >= buyoutPrice) then
			if (mins[id] or 9999999999) > buyoutPrice then mins[id] = buyoutPrice end
			if (maxes[id] or 0) < buyoutPrice then maxes[id] = buyoutPrice end
			counts[id] = (counts[id] or 0) + count
		end
	end

	for _,sellbutt in pairs(ns.sellbutts) do sellbutt:Enable() end
	if allscan then ChatFrame1:AddMessage("Done scanning ".. num.. " items") end
	allscan = false
end)


-- Global API for any addon to query prices
local orig = GetAuctionBuyout
function GetAuctionBuyout(item)
	local id = ids[item]
	if id and mins[id] then return mins[id] end
	if id and tekauc.manualprices[id] then return tekauc.manualprices[id] end
	if orig then return orig(item) end
end

tekauc.GetAuctionBuyout = GetAuctionBuyout
