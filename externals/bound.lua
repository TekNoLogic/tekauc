
local myname, ns = ...


assert(ns.scantip, "Tooltip scanner external not loaded")


local function Scan(phrase)
	for i=1,4 do
		if ns.scantip.L[i] == phrase then return true end
	end

	return false
end


function ns.IsSoulbound(bag, slot)
	ns.scantip:SetBagItem(bag, slot)
	return Scan(ITEM_SOULBOUND)
end


function ns.IsAccountBound(bag, slot)
	ns.scantip:SetBagItem(bag, slot)
	return Scan(ITEM_BNETACCOUNTBOUND) or Scan(ITEM_ACCOUNTBOUND)
end


function ns.IsBindOnEquip(bag, slot)
	ns.scantip:SetBagItem(bag, slot)
	return Scan(ITEM_BIND_ON_EQUIP)
end
