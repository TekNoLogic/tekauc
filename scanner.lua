
local INFLATION_LIMIT = 2.5 -- Maximum markup we'll allow over manually set prices
local ids = LibStub("tekIDmemo")
local mins, maxes, counts, lastseen = {}, {}, {}, {}

tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts


BrowseSearchButton:SetPoint("LEFT", IsUsableCheckButton, "RIGHT", 10, -8)
local butt = LibStub("tekKonfig-Button").new(BrowseSearchButton, "BOTTOM", BrowseSearchButton, "TOP")
butt:SetText("Scan All")

butt:SetScript("OnClick", function()
	if not select(2, CanSendAuctionQuery("list")) then return ChatFrame1:AddMessage("Cannot scan yet") end

	ChatFrame1:AddMessage("Sending all-scan query")
	mins, maxes, counts = {}, {}, {}
	tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts
	QueryAuctionItems(nil, nil, nil, nil, nil, nil, nil, nil, nil, true)
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
end)

butt:SetScript("OnEvent", function(self)
	self:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	for i=1,GetNumAuctionItems("list") do
		local name, texture, count, quality, canUse, level, minBid, minIncrement, buyoutPrice, bidAmount, highBidder, owner = GetAuctionItemInfo("list", i)
		local id = ids[GetAuctionItemLink("list", i)]
		buyoutPrice = buyoutPrice / count
		if buyoutPrice > 0 and (not tekauc.manualprices[id] or (tekauc.manualprices[id] * INFLATION_LIMIT) >= buyoutPrice) then
			if (mins[id] or 9999999999) > buyoutPrice then mins[id] = buyoutPrice end
			if (maxes[id] or 0) < buyoutPrice then maxes[id] = buyoutPrice end
			counts[id] = (counts[id] or 0) + count
		end
	end

	ChatFrame1:AddMessage("Done scanning ".. GetNumAuctionItems("list").. " items")
end)


-- Global API for any addon to query prices
local orig = GetAuctionBuyout
function GetAuctionBuyout(item)
	local id = ids[item]
	if id and mins[id] then return mins[id] end
	if id and tekauc.manualprices[id] then return tekauc.manualprices[id] end
	if orig then return orig(item) end
end
