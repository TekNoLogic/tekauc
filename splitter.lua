
local ids = LibStub("tekIDmemo")

local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc splitter|r:", ...)) end


local function findempty()
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			if not GetContainerItemLink(bag, slot) then return bag, slot end
		end
	end
end


local f = CreateFrame("Frame")
local pendingbag, pendingslot, pendingid, pendingsize, lastbag, lastslot
function teksplit(id, size)
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and ids[link] == id then
				local _, qty = GetContainerItemInfo(bag, slot)
				if qty > size then
					local ebag, eslot = findempty()
					if not (ebag and eslot) then
						pendingbag, pendingslot, pendingid, pendingsize, lastbag, lastslot = nil
						return
					end

					if lastbag ~= ebag or lastslot ~= eslot then
						lastbag, lastslot = ebag, eslot
						pendingbag, pendingslot, pendingid, pendingsize = bag, slot, id, size
						f:RegisterEvent("BAG_UPDATE")
						SplitContainerItem(bag, slot, size)
						PickupContainerItem(ebag, eslot)
					end
					return
				end
			end
		end
	end
	pendingbag, pendingslot, pendingid, pendingsize, lastbag, lastslot = nil
	f:UnregisterEvent("BAG_UPDATE")
end


f:SetScript("OnEvent", function(self, event, bag)
	if not pendingbag or pendingbag ~= bag or select(3, GetContainerItemInfo(pendingbag, pendingslot)) then return end
	teksplit(pendingid, pendingsize)
end)

SLASH_TEKSPLITTER1 = "/split"
SlashCmdList.TEKSPLITTER = function(input)
	local id, size = string.match(input, "item:(%d+):.*%|h%|r%s*([%d]+)%s*$")
	if not id or not size then return Print("Usage: /split [Item Link] size") end
	teksplit(tonumber(id), tonumber(size))
end

