
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
local BLOCKSIZE = 40
local TICKLENGTH = 0.1
local totalresults, nextblock, starttime, nexttick, throttle
local default_ui_was_registered
butt:SetScript("OnUpdate", function(self, elap)
	-- Once per second we check our framerate and adjust or scan speed
	if allscaninprogress then
		throttle = (throttle or 1) - elap
		if throttle < 0 then
			throttle = 1
			local fps = GetFramerate()
			if fps < 10 then
				BLOCKSIZE = math.floor(BLOCKSIZE * .75)
			elseif fps > 30 then
				BLOCKSIZE = BLOCKSIZE + 1
			end
		end
	end

	-- check if we need to process a block of results
	if allscaninprogress and nexttick <= GetTime() then
		local endindex = nextblock + BLOCKSIZE
		if endindex > totalresults then endindex = totalresults end

		self:SetText(string.format("%d%% done", 100.0 * nextblock / totalresults))
		local t = GetTime()
		ScanBlock(nextblock, endindex)

		if endindex == totalresults then
			for _,sellbutt in pairs(ns.sellbutts) do sellbutt:Enable() end
			local elap = GetTime() - starttime
			ns.Printf("Done scanning: %d items in %.01f seconds", totalresults, elap)
			self:SetText("Scan All")

			ns.scannedall = true
			allscaninprogress = false
			totalresults, nextblock, starttime = nil
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

local allscanpending, querytime
butt:SetScript("OnClick", function(self)
	querytime = GetTime()
	ns.Print("Sending all-scan query")
	self:SetText("Querying...")
	mins, maxes, counts = {}, {}, {}
	tekauc.mins, tekauc.maxes, tekauc.counts = mins, maxes, counts
	if tekauc_data then tekauc_data.SetTable(mins) end
	allscanpending = true
	default_ui_was_registered = AuctionFrameBrowse:IsEventRegistered("AUCTION_ITEM_LIST_UPDATE")
	AuctionFrameBrowse:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	SortAuctionClearSort("list")
	QueryAuctionItems(nil, nil, nil, nil, nil, nil, true)
end)

butt:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
butt:SetScript("OnEvent", function(self)
	local num, total = GetNumAuctionItems("list")
	if total < 10000000 and num ~= total then return end


	if allscanpending then
		allscanpending = false
	 	allscaninprogress = true
		starttime = GetTime()
		touched, totalresults, nextblock = {}, num, 1
		nexttick = starttime
		ns.Printf("Server response %.01f seconds", starttime - querytime)
		ns.Print("Starting scan")
	elseif not allscaninprogress and num < 5000 then
		touched = {}
		ScanBlock(1, num)
	end
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
