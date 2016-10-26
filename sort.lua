
local myname, ns = ...


-- Default to sort by cheapest unit price
SortAuctionSetSort("list", "unitprice")

-- Restore after a scan
ns.RegisterCallback({}, "SCAN_COMPLETE", function()
  SortAuctionSetSort("list", "unitprice")
end)
