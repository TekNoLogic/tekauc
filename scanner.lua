
local myname, ns = ...

local INFLATION_LIMIT = 2.5 -- Maximum markup we'll allow over manually set prices
local maxes, counts, lastseen = {}, {}, {}
local allscaninprogress, touched
local mins = tekauc_data and tekauc_data.GetTable() or {}

tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts


local butt = LibStub("tekKonfig-Button").new(BrowseSearchButton, "RIGHT", BrowseSearchButton, "LEFT", -10, 0)
butt:SetText("Scan All")


local function IsValidPrice(id, price)
	if not tekauc.manualprices[id] then return true end
	if (tekauc.manualprices[id] * INFLATION_LIMIT) >= price then return true end
end


local function ScanBlock(startindex, endindex)
	for i=startindex,endindex do
		local name, texture, count, quality, canUse, level, levelColHeader, minBid,
			minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, owner,
			ownerFullName, saleStatus, id, hasAllInfo = GetAuctionItemInfo("list", i)

		if not allscaninprogress and not touched[id] then
			-- Wipe these results if it's a short scan
			touched[id], mins[id], maxes[id], counts[id] = true
		end
		buyoutPrice = buyoutPrice / count
		if buyoutPrice > 0 and IsValidPrice(id, buyoutPrice) then
			if (mins[id] or 9999999999) > buyoutPrice then mins[id] = buyoutPrice end
			if (maxes[id] or 0) < buyoutPrice then maxes[id] = buyoutPrice end
			counts[id] = (counts[id] or 0) + count
		end
	end
end


local enabled = true
local TICKLENGTH = 0.1
local totalresults, nextblock, nexttick, throttle
local default_ui_was_registered
butt:SetScript("OnUpdate", function(self, elap)
	-- check if we need to process a block of results
	if allscaninprogress and nexttick <= GetTime() then
		local endindex = nextblock + ns.block_size
		if endindex > totalresults then endindex = totalresults end

		ns.SendMessage("SCAN_PROGRESS", nextblock, totalresults)
		local t = GetTime()
		ScanBlock(nextblock, endindex)

		if endindex == totalresults then
			for _,sellbutt in pairs(ns.sellbutts) do sellbutt:Enable() end
			ns.SendMessage("SCAN_COMPLETE", totalresults)

			ns.scannedall = true
			allscaninprogress = false
			totalresults, nextblock = nil
			if default_ui_was_registered then
				AuctionFrameBrowse:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
			end
		else
			nextblock = endindex + 1
			nexttick = GetTime() + TICKLENGTH
		end
	end

	local _, scanable = CanSendAuctionQuery("list")
	if allscaninprogress or (enabled and not scanable) then self:Disable()
	elseif not enabled and scanable then
		self:Enable()
		for _,sellbutt in pairs(ns.sellbutts) do sellbutt:Disable() end
	end
	enabled = scanable
end)

local allscanpending
butt:SetScript("OnClick", function(self)
	mins, maxes, counts = {}, {}, {}
	tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts
	if tekauc_data then tekauc_data.SetTable(mins) end
	allscanpending = true
	default_ui_was_registered = AuctionFrameBrowse:IsEventRegistered("AUCTION_ITEM_LIST_UPDATE")
	AuctionFrameBrowse:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	SortAuctionClearSort("list")
	QueryAuctionItems(nil, nil, nil, nil, nil, nil, true)
end)


local function ShouldAllScan()
	local num, total = GetNumAuctionItems("list")
	if allscanpending and num == total then return true end
end


local function ShouldPartialScan()
	if allscanpending or allscaninprogress then return false end
	if GetNumAuctionItems("list") > 5000 then return false end
	if AuctionFrameBrowse.page ~= 0 then return false end

	local column, reverse = GetAuctionSort("list", 1)
	if column == "unitprice" and not reverse then return true end
end


local function BeginAllScan()
	allscanpending = false
	allscaninprogress = true
	touched = {}
	totalresults = GetNumAuctionItems("list")
	nextblock = 1
	nexttick = GetTime()
	ns.SendMessage("SCAN_STARTING")
end


local function BeginPartialScan()
	local num = GetNumAuctionItems("list")
	touched = {}
	ScanBlock(1, num)
end


butt:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
butt:SetScript("OnEvent", function(self)
	if ShouldAllScan() then return BeginAllScan() end
	if ShouldPartialScan() then BeginPartialScan() end
end)


-- Global API for any addon to query prices
local orig = GetAuctionBuyout
function GetAuctionBuyout(item)
	local id = ns.ids[item]
	if id and mins[id] then return mins[id] end
	if id and tekauc.manualprices[id] then return tekauc.manualprices[id] end
	if orig then return orig(item) end
end

tekauc.GetAuctionBuyout = GetAuctionBuyout
