

local myname, ns = ...


local origs = {}
local OnTooltipSetItem = function(frame, ...)
	assert(frame, "arg 1 is nil, someone isn't hooking correctly")

	local _, link = frame:GetItem()
	if link then
		local id = ns.ids[link]
		local min, max, count = tekauc.mins[id], tekauc.maxes[id], tekauc.counts[id]
		local _, _, _, _, _, _, _, maxStack = GetItemInfo(id)
		if min then frame:AddDoubleLine("AH buyout:", max and max ~= min and (tekauc:GS(min).." - "..tekauc:GS(max)) or tekauc:GS(min)) end
		if min and (maxStack or 0) > 1 then frame:AddDoubleLine("AH stack buyout:", max and max ~= min and (tekauc:GS(min*maxStack).." - "..tekauc:GS(max*maxStack)) or tekauc:GS(min*maxStack)) end
		if count then frame:AddDoubleLine("Number on AH:", count)
		elseif tekauc.manualprices[id] then frame:AddDoubleLine("Manual price:", tekauc:GS(tekauc.manualprices[id])) end

		local owner = frame:GetOwner()
		if frame == GameTooltip and min and owner and owner.hasItem and AuctionFrame:IsVisible() and owner:GetParent():GetID() ~= KEYRING_CONTAINER then
			frame:AddLine("Alt-click to post on AH", 1, 0, 0.5)
		end
	end

	if origs[frame] then return origs[frame](frame, ...) end
end

for i,frame in pairs{GameTooltip, ItemRefTooltip} do
	origs[frame] = frame:GetScript("OnTooltipSetItem")
	frame:SetScript("OnTooltipSetItem", OnTooltipSetItem)
end


