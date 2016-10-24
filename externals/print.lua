local myname, ns = ...


local title = "|cFF33FF99".. GetAddOnMetadata(myname, "Title").. "|r:"
function ns.Print(...) print(title, ...) end
function ns.Printf(...) ns.Print(string.format(...)) end


local function PrintToFrame(cf, event, ...)
	if not cf:IsEventRegistered(event) then return end

	local info = ChatTypeInfo["SYSTEM"]
	if strsub(event, 1, 8) == "CHAT_MSG" then
		local type = string.sub(event, 10)
		info = ChatTypeInfo[type]
	end

	cf:AddMessage(strjoin(" ", tostringall(...)), info.r, info.g, info.b, info.id)
end


function ns.ChatFramePrint(event, ...)
	for i=1,7 do PrintToFrame(_G["ChatFrame"..i], event, ...) end
end


function ns.ChatFramePrintf(event, ...)
	ns.ChatFramePrint(event, string.format(...))
end
