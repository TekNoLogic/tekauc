

local ids = LibStub("tekIDmemo")


local origs = {}
local OnTooltipSetItem = function(frame, ...)
	assert(frame, "arg 1 is nil, someone isn't hooking correctly")

	local _, link = frame:GetItem()
	if link then
		local id = ids[link]
		local val = tekauc.mins[id]
		local _, _, _, _, _, _, _, maxStack = GetItemInfo(id)
		if val and (maxStack or 0) > 1 then
			frame:AddDoubleLine("Lowest AH buyout:", tekauc:GS(val).." ("..tekauc:GS(val*maxStack)..")")
			frame:AddDoubleLine("Highest AH buyout:", tekauc:GS(tekauc.maxes[id]).." ("..tekauc:GS(tekauc.maxes[id]*maxStack)..")")
			frame:AddDoubleLine("Number on AH:", tekauc.counts[id])
		elseif val then
			frame:AddDoubleLine("Lowest AH buyout:", tekauc:GS(val))
			frame:AddDoubleLine("Highest AH buyout:", tekauc:GS(tekauc.maxes[id]))
			frame:AddDoubleLine("Number on AH:", tekauc.counts[id])
		end
	end
	if origs[frame] then return origs[frame](frame, ...) end
end

for i,frame in pairs{GameTooltip, ItemRefTooltip} do
	origs[frame] = frame:GetScript("OnTooltipSetItem")
	frame:SetScript("OnTooltipSetItem", OnTooltipSetItem)
end


