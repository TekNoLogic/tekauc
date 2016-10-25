
local myname, ns = ...


local DEFAULT_BLOCK_SIZE = 40
local TICK_LENGTH = 1


ns.block_size = DEFAULT_BLOCK_SIZE


local scanning
local function Tick()
	if not scanning then return end

	local fps = GetFramerate()
	if fps < 10 then
		ns.block_size = math.floor(ns.block_size * .75)
	elseif fps > 30 then
		ns.block_size = ns.block_size + 1
	end

	C_Timer.After(TICK_LENGTH, Tick)
end


local C = {}
ns.RegisterCallback(C, "SCAN_STARTING", function()
	ns.block_size = DEFAULT_BLOCK_SIZE
	scanning = true
	Tick()
end)


ns.RegisterCallback(C, "SCAN_COMPLETE", function()
	scanning = false
end)
