include( "cfc_disconnect_interface/client/cl_api.lua" )

local GRACE_TIME = 3.5 -- How many seconds of lag should we have before showing the panel?
local PING_MISS = 2 -- How many pings can we miss on join?

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

local pingLoop = async( function()
    if pingLoopRunning then return end
    pingLoopRunning = true

    -- Randomize the inital delay to avoid a thundering herd problem
    -- (And attempt to take full advantage of CF caching)
    await( NP.timeout( math.Rand( 1, 10 ) ) )

    while pongerStatus do
        -- Randomize followup checks to balance the load out
        local delay = math.Rand( 2, 8 )

        await( NP.timeout( delay ) )
        await( CFCCrashAPI.ping() )
    end

    pingLoopRunning = false
end )

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
    if not LocalPlayer():IsValid() then return end
    dTimer.Remove( "CFC_DisconnectInterface_Startup" )

    net.Start( "CFC_DisconnectInterface_Loaded" )
    net.SendToServer()

    print( "cfc_disconnect_interface loaded." )
    hook.Add( "Tick", "CFC_DisconnectInterface_CrashChecker", checkCrashTick )
end )
