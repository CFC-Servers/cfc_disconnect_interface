require( "cfc_promises" )

CFCCrashAPI = {}

local endpointCFC = GetConVar( "cfc_disconnect_interface_status_endpoint" ):GetString()
local endpointGlobal = "https://www.google.com"

local api = CFCCrashAPI

api.INACTIVE = 0
api.PINGING_API = 1
api.NO_INTERNET = 2
api.SERVER_DOWN = 3
api.SERVER_UP = 4

api.state = api.INACTIVE
api.stateOverride = nil

api.checkCFCEndpoint = async( function()
    local success, body = await( NP.http.fetch( endpointCFC ) )

    if not success then return false end

    local data = util.JSONToTable( body )
    return tobool( data and data.status == "server-is-up" )
end )

local isOnline = nil
api.checkGlobalEndpoint = async( function()
    if isOnline then return isOnline end

    local success = await( NP.http.fetch( endpointGlobal ) )

    -- Cache a successful google check for 30 seconds
    -- (We don't need to re-check google if we've already confirmed that we have internet)
    -- (A failed check is not cached and is re-checked every interval)
    if success then
        isOnline = true
        timer.Create( "CFC_DisconnectInterface_GlobalEndpointCache", 30, 1, function()
            isOnline = nil
        end )
    end

    return success
end )

api.ping = async( function()
    if api.stateOverride then return api.stateOverride end

    api.state = api.PINGING_API

    local _, data = await( promise.all( { api.checkCFCEndpoint(), api.checkGlobalEndpoint() } ) )
    local cfcStatus, globalStatus = unpack( data )

    if cfcStatus and globalStatus then
        api.state = api.SERVER_UP
    elseif globalStatus then
        api.state = api.SERVER_DOWN
    else
        api.state = api.NO_INTERNET
    end

    return api.state
end )

function api.getState()
    return api.stateOverride or api.state
end

concommand.Add( "cfc_disconnect_interface_test_crash", function()
    api.stateOverride = api.SERVER_DOWN
end )

concommand.Add( "cfc_disconnect_interface_test_nointernet", function()
    api.stateOverride = api.NO_INTERNET
end )

concommand.Add( "cfc_disconnect_interface_test_restart", function()
    api.stateOverride = api.SERVER_UP
end )

concommand.Add( "cfc_disconnect_interface_test_recover", function()
    api.stateOverride = nil
end )
