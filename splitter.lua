
local myname, ns = ...


local function findempty()
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			if not GetContainerItemLink(bag, slot) then return bag, slot end
		end
	end
end


local f = CreateFrame("Frame")
local idqueue, sizequeue = {}, {}
local pendingbag, pendingslot, lastbag, lastslot
local function teksplit()
	local id, size = idqueue[1], sizequeue[1]
	for bag=0,4 do
		for slot=1,GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and ns.ids[link] == id then
				local _, qty = GetContainerItemInfo(bag, slot)
				if qty > size then
					local ebag, eslot = findempty()
					if not (ebag and eslot) then
						pendingbag, pendingslot, lastbag, lastslot = nil
						idqueue, sizequeue = {}, {}
						f:UnregisterEvent("BAG_UPDATE")
						return
					end

					if lastbag ~= ebag or lastslot ~= eslot then
						lastbag, lastslot = ebag, eslot
						pendingbag, pendingslot = bag, slot, id, size
						f:RegisterEvent("BAG_UPDATE")
						SplitContainerItem(bag, slot, size)
						PickupContainerItem(ebag, eslot)
					end
					return
				end
			end
		end
	end
	table.remove(idqueue, 1)
	table.remove(sizequeue, 1)
	if #idqueue == 0 then
		pendingbag, pendingslot, lastbag, lastslot = nil
		f:UnregisterEvent("BAG_UPDATE")
	else return teksplit() end
end


f:SetScript("OnEvent", function(self, event, bag)
	if not pendingbag or pendingbag ~= bag or select(3, GetContainerItemInfo(pendingbag, pendingslot)) then return end
	teksplit()
end)


SLASH_TEKSPLITTER1 = "/split"
SlashCmdList.TEKSPLITTER = function(input)
	local id, size = string.match(input, "item:(%d+):.*%|h%|r%s*([%d]+)%s*$")
	if not id or not size then return ns.Print("Usage: /split [Item Link] size") end
	table.insert(idqueue, tonumber(id))
	table.insert(sizequeue, tonumber(size))
	if #idqueue == 1 then teksplit() end
end
