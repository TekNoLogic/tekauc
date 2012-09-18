
local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc manual pricer|r:", ...)) end


SLASH_TEKAUCPRICE1 = "/taprice"
SlashCmdList.TEKAUCPRICE = function(input)
	local id, price = string.match(input, "item:(%d+):.*%|h%|r%s*([%d]+)%s*$")
	if not id or not price then return Print("Usage: /taprice [Item Link] price") end
	local price = tonumber(price)
	if not price or price == 0 then
		tekauc.manualprices[tonumber(id)] = nil
	else
		tekauc.manualprices[tonumber(id)] = tonumber(price)
	end
	Print("Set manual price", GetItemInfo(id), "to", price)
end

