include( "cfc_disconnect_interface/client/cl_api.lua" )

local net, hook, timer = net, hook, timer

local GRACE_TIME = 3.5 -- How many seconds of lag should we have before showing the panel?
local PING_MISS = 2 -- How many pings can we miss on join?

local API_TIMEOUT = 5 -- How often to call the api

local lastPing
local lastApiCall

net.Receive( "cfc_di_ping", function()
    if PING_MISS > 0 then -- Allow some pings before actually starting crash systems. ( Avoid bugs on join stutter. )
        PING_MISS = PING_MISS - 1
    else
        lastPong = RealTime()
    end
end )

local function shutdown()
    timer.Remove( "cfc_di_startup" )
    hook.Remove( "Tick", "cfc_di_tick" )
end

net.Receive( "cfc_di_shutdown", shutdown )
hook.Add( "ShutDown", "crashsys", shutdown )

local function crashTick( timedown )
    local apiState = crashApi.getState();
    if ( apiState == crashApi.INACTIVE ) or -- No ping sent
       ( apiState ~= crashApi.SERVER_UP and RealTime() - lastApiCall > API_TIMEOUT ) then -- Previous ping failed, and API_TIMEOUT has passed
        crashApi.triggerPing();
        lastApiCall = RealTime();

        apiState = crashApi.getState();
    end
    hook.Run( "cfc_di_crashTick", true, timedown, apiState );
end

local function checkCrashTick()
    if not lastPong then return end
    if not LocalPlayer():IsValid() then return end -- disconnected or connecting

    local timeout = RealTime() - lastPong

    if timeout > GRACE_TIME then
        crashTick( timeout )
    else
        -- Server recovered while crashApi was running, cancel the request
        if crashApi.getState() ~= crashApi.INACTIVE then
            crashApi.cancelPing();
        end
        hook.Run( "cfc_di_crashTick", false );
    end
end

-- Ping the server when the client is ready.
timer.Create( "cfc_di_startup", 0.01, 0, function()
    local ply = LocalPlayer()
    if ply:IsValid() then
        net.Start( "cfc_di_loaded" )
        net.SendToServer()
        timer.Remove( "cfc_di_startup" )
        print( "cfc_disconnect_interface loaded." )
        hook.Add( "Tick", "cfc_di_tick", checkCrashTick )
    end
end )
