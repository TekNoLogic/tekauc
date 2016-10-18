
local myname, ns = ...


local allscan = CreateFrame("Frame", nil, AuctionFrameBrowse)
allscan:SetSize(605, 305)
allscan:SetPoint("TOPLEFT", 188, -103)


local allscantext = allscan:CreateFontString(nil, "OVERLAY", "GameFontHighlightHuge")
allscantext:SetPoint("CENTER")
allscantext:SetText("Full scan in progess...")
allscantext:Hide()

allscan:SetScript("OnShow", function() allscantext:Hide() end)


hooksecurefunc("QueryAuctionItems", function(_, _, _, _, _, _, get_all)
	if get_all then
		allscantext:Show()
	else
		allscantext:Hide()
	end
end)


function ns.AllScanComplete()
	allscantext:Hide()
end
