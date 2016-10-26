
local myname, ns = ...


local allscan = CreateFrame("Frame", nil, AuctionFrameBrowse)
allscan:SetSize(605, 305)
allscan:SetPoint("TOPLEFT", 188, -103)


local allscantext = allscan:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
allscantext:SetPoint("CENTER")
allscantext:Hide()

allscan:SetScript("OnShow", function() allscantext:Hide() end)


local query_time, response_time, start_time
hooksecurefunc("QueryAuctionItems", function(_, _, _, _, _, _, get_all)
	if get_all then
		query_time = GetTime()
		allscantext:SetText("Querying auctions...")
		allscantext:Show()
	else
		allscantext:Hide()
	end
end)


local function OnScanStarting(self, message, num, total)
	start_time = GetTime()
	response_time = start_time - query_time
	query_time = nil
end


local PROGRESS = "Full scan in progess...\n%d%% complete"
local function OnScanProgress(self, message, num, total)
	self:SetFormattedText(PROGRESS, num/total*100)
end


local COMPLETE = "%s records scanned\n%.01fs server response\n%.01fs scanning"
local function OnScanComplete(self, message, total)
	local time = GetTime() - start_time
	self:SetFormattedText(COMPLETE, BreakUpLargeNumbers(total), response_time, time)
end


ns.RegisterCallback(allscantext, "SCAN_STARTING", OnScanStarting)
ns.RegisterCallback(allscantext, "SCAN_PROGRESS", OnScanProgress)
ns.RegisterCallback(allscantext, "SCAN_COMPLETE", OnScanComplete)
