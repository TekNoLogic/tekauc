
local myname, ns = ...


SLASH_TEKAUCPRICE1 = "/taprice"
SlashCmdList.TEKAUCPRICE = function(input)
	local id, price = string.match(input, "item:(%d+):.*%|h%|r%s*([%d]+)%s*$")
	if not id or not price then return ns.Print("Usage: /taprice [Item Link] price") end
	local price = tonumber(price)
	if not price or price == 0 then
		tekauc.manualprices[tonumber(id)] = nil
	else
		tekauc.manualprices[tonumber(id)] = tonumber(price)
	end
	ns.Print("Set manual price", GetItemInfo(id), "to", price)
end
