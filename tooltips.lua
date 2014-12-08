

local myname, ns = ...


local origs = {}
local OnTooltipSetItem = function(frame, ...)
	assert(frame, "arg 1 is nil, someone isn't hooking correctly")

	local _, link = frame:GetItem()
	if link then
		local id = ns.ids[link]
		local min, max, count = tekauc.mins[id], tekauc.maxes[id], tekauc.counts[id]
		local _, _, _, _, _, _, _, maxStack = GetItemInfo(id)

		if min then
			local buyout = ns.GS(min)
			if max and max ~= min then buyout = buyout.." - "..ns.GS(max) end
			frame:AddDoubleLine("AH buyout:", buyout)

			if (maxStack or 0) > 1 then
				local stackbuyout = ns.GS(min*maxStack)
				if max and max ~= min then
					stackbuyout = stackbuyout.." - "..ns.GS(max*maxStack)
				end
				frame:AddDoubleLine("AH stack buyout:", stackbuyout)
			end
		end

		if count then
			frame:AddDoubleLine("Number on AH:", count)
		elseif tekauc.manualprices[id] then
			frame:AddDoubleLine("Manual price:", ns.GS(tekauc.manualprices[id]))
		end

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
