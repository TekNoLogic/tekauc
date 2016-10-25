
local myname, ns = ...


local TICK_LENGTH = 1

ns.block_size = 40


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


ns.RegisterCallback(allscantext, "SCAN_STARTING", function()
	scanning = true
	Tick()
end)


ns.RegisterCallback(allscantext, "SCAN_COMPLETE", function()
	scanning = false
end)
