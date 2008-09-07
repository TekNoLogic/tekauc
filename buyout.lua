
local orig = BrowseButton8:GetScript("OnClick")
local function OnClick(self, button, ...)
	if IsAltKeyDown() then
		local id = self:GetID() + FauxScrollFrame_GetOffset(BrowseScrollFrame)
		if not GetAuctionItemLink("list", id) then return end
		SetSelectedAuctionItem("list", id)
    PlaceAuctionBid("list", id, (select(9, GetAuctionItemInfo("list", id))))
    CloseAuctionStaticPopups()
		return
	end

	return orig(self, button, ...)
end
for i=1,8 do _G["BrowseButton"..i]:SetScript("OnClick", OnClick) end
