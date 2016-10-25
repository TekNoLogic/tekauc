
local myname, ns = ...


local allscan = CreateFrame("Frame", nil, AuctionFrameBrowse)
allscan:SetSize(605, 305)
allscan:SetPoint("TOPLEFT", 188, -103)


local allscantext = allscan:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
allscantext:SetPoint("CENTER")
allscantext:Hide()

allscan:SetScript("OnShow", function() allscantext:Hide() end)


hooksecurefunc("QueryAuctionItems", function(_, _, _, _, _, _, get_all)
	if get_all then
		allscantext:SetText("Querying auctions...")
		allscantext:Show()
	else
		allscantext:Hide()
	end
end)


local PROGRESS = "Full scan in progess...\n%d%% complete"
local function OnScanProgress(self, message, num, total)
	self:SetFormattedText(PROGRESS, num/total*100)
end


local COMPLETE = "Done scanning\n%d items in %.01f seconds"
local function OnScanComplete(self, message, total, time)
	self:SetFormattedText(COMPLETE, total, time)
end


ns.RegisterCallback(allscantext, "SCAN_PROGRESS", OnScanProgress)
ns.RegisterCallback(allscantext, "SCAN_COMPLETE", OnScanComplete)
