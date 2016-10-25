
local myname, ns = ...


local debugf = tekDebug and tekDebug:GetFrame(myname)
function ns.Debug(...)
  if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end
end
