include( "cfc_disconnect_interface/client/cl_api.lua" )

local GRACE_TIME = 3.5 -- How many seconds of lag should we have before showing the panel?
local PING_MISS = 2 -- How many pings can we miss on join?

local API_TIMEOUT = 5 -- How often to call the api

local lastPong

local pongerStatus = false
local pingLoopRunning = false

net.Receive( "cfc_di_ping", function()
    if PING_MISS > 0 then -- Allow some pings before actually starting crash systems. ( Avoid bugs on join stutter. )
        PING_MISS = PING_MISS - 1
    else
        lastPong = SysTime()
    end
end )

local function shutdown()
    dTimer.Remove( "cfc_di_startup" )
    hook.Remove( "Tick", "cfc_di_tick" )
end

net.Receive( "cfc_di_shutdown", shutdown )
hook.Add( "ShutDown", "cfc_di_shutdown", shutdown )

local function _pingLoop()
    if pingLoopRunning then return end
    pingLoopRunning = true

    while pongerStatus do
        await( CFCCrashAPI.ping() )
        await( NP.timeout( API_TIMEOUT ) )
    end

    pingLoopRunning = false
end
pingLoop = async( _pingLoop )

local function checkCrashTick()
    if not lastPong then return end
    if not LocalPlayer():IsValid() then return end -- disconnected or connecting

    local timeout = SysTime() - lastPong

    local inGrace = timeout > GRACE_TIME

    if pongerStatus ~= inGrace then
        pongerStatus = inGrace

        pingLoop()
    end

    hook.Run( "cfc_di_crashTick", pongerStatus, timedown, CFCCrashAPI.state )
end

-- Ping the server when the client is ready.
dTimer.Create( "cfc_di_startup", 0.01, 0, function()
    if LocalPlayer():IsValid() then
        dTimer.Remove( "cfc_di_startup" )

        net.Start( "cfc_di_loaded" )
        net.SendToServer()

        print( "cfc_disconnect_interface loaded." )
        hook.Add( "Tick", "cfc_di_tick", checkCrashTick )
    end
end )
