
local function Print(...) ChatFrame1:AddMessage(string.join(" ", "|cFF33FF99tekauc manual pricer|r:", ...)) end


SLASH_TEKAUCPRICE1 = "/taprice"
SlashCmdList.TEKAUCPRICE = function(input)
	local id, price = string.match(input, "item:(%d+):.*%|h%|r%s*([%d]+)%s*$")
	if not id or not price then return Print("Usage: /taprice [Item Link] price") end
	tekauc.manualprices[tonumber(id)] = tonumber(price)
	Print("Set manual price", GetItemInfo(id), "to", price)
end

