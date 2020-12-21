include( "cfc_disconnect_interface/client/cl_api.lua" )

local GRACE_TIME = 3.5 -- How many seconds of lag should we have before showing the panel?
local PING_MISS = 2 -- How many pings can we miss on join?

local API_TIMEOUT = 5 -- How often to call the api

local lastPong

local pongerStatus = false
local pingLoopRunning = false

net.Receive( "CFC_DisconnectInterface_Ping", function()
    if CFCCrashAPI.stateOverride then return end

    if PING_MISS > 0 then -- Allow some pings before actually starting crash systems. ( Avoid bugs on join stutter. )
        PING_MISS = PING_MISS - 1
    else
        lastPong = SysTime()
    end
end )

local function shutdown()
    dTimer.Remove( "CFC_DisconnectInterface_Startup" )
    hook.Remove( "Tick", "CFC_DisconnectInterface_CrashChecker" )
end

net.Receive( "CFC_DisconnectInterface_Shutdown", shutdown )
hook.Add( "ShutDown", "CFC_DisconnectInterface_Cleanup", shutdown )

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

    local timedown = SysTime() - lastPong

    local inGrace = timedown > GRACE_TIME

    if pongerStatus ~= inGrace then
        pongerStatus = inGrace

        pingLoop()
    end

    hook.Run( "CFC_CrashTick", pongerStatus, timedown, CFCCrashAPI.getState() )
end

-- Ping the server when the client is ready.
dTimer.Create( "CFC_DisconnectInterface_Startup", 0.01, 0, function()
    if LocalPlayer():IsValid() then
        dTimer.Remove( "CFC_DisconnectInterface_Startup" )

        net.Start( "CFC_DisconnectInterface_Loaded" )
        net.SendToServer()

        print( "cfc_disconnect_interface loaded." )
        hook.Add( "Tick", "CFC_DisconnectInterface_CrashChecker", checkCrashTick )
    end
end )
