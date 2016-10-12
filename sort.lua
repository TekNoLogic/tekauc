
--~ AuctionSort["list_bid"] = {
--~ 	{column = "duration",	reverse = false},
--~ 	{column = "quantity",	reverse = true},
--~ 	{column = "name",     reverse = false},
--~ 	{column = "level",    reverse = true},
--~ 	{column = "quality",  reverse = false},
--~ 	{column = "buyoutthenbid", reverse = false},
--~ }

SortAuctionClearSort("list") -- clear the existing sort.
SortAuctionSetSort("list", "duration", true)
SortAuctionSetSort("list", "buyoutthenbid", true)
SortAuctionSetSort("list", "name", true)
SortAuctionSetSort("list", "level", false)
SortAuctionSetSort("list", "quality", true)
SortAuctionSetSort("list", "quantity", true)
