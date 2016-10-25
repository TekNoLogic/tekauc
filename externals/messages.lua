
local myname, ns = ...


local callbacks = {}
function ns.RegisterCallback(context, message, func)
	assert(context, "`context` must not be nil")
	assert(message, "`message` must not be nil")
	if not callbacks[message] then callbacks[message] = {} end
	callbacks[message][context] = func
end


function ns.SendMessage(message, ...)
	assert(message, "`message` must not be nil")
	if not callbacks[message] then return end

	for context,func in pairs(callbacks[message]) do
		func(context, message, ...)
	end
end
