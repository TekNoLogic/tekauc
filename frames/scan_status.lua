
local myname, ns = ...


local allscan = CreateFrame("Frame", nil, AuctionFrameBrowse)
allscan:SetSize(605, 305)
allscan:SetPoint("TOPLEFT", 188, -103)


local allscantext = allscan:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
allscantext:SetPoint("CENTER")
allscantext:Hide()

allscan:SetScript("OnShow", function() allscantext:Hide() end)


local query_time
hooksecurefunc("QueryAuctionItems", function(_, _, _, _, _, _, get_all)
	if get_all then
		query_time = GetTime()
		allscantext:SetText("Querying auctions...")
		allscantext:Show()
	else
		allscantext:Hide()
	end
end)


local PROGRESS = "Full scan in progess...\n%d%% complete"
local function OnScanProgress(self, message, num, total)
	if query_time then
		start_time = GetTime()
		ns.Printf("Server response %.01f seconds", start_time - query_time)
		query_time = nil
	end

	self:SetFormattedText(PROGRESS, num/total*100)
end


local COMPLETE = "Done scanning\n%d items in %.01f seconds"
local function OnScanComplete(self, message, total)
	local time = GetTime() - start_time
	self:SetFormattedText(COMPLETE, total, time)
end


ns.RegisterCallback(allscantext, "SCAN_PROGRESS", OnScanProgress)
ns.RegisterCallback(allscantext, "SCAN_COMPLETE", OnScanComplete)
