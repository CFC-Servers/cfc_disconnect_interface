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

function api._checkCFCEndpoint()
    local success, body = await( NP.http.fetch( endpointCFC ) )

    if not success then return false end

    local data = util.JSONToTable( body )
    return tobool( data and data.status == "server-is-up" )
end
api.checkCFCEndpoint = async( api._checkCFCEndpoint )

function api._checkGlobalEndpoint()
    local success = await( NP.http.fetch( endpointGlobal ) )
    return success
end
api.checkGlobalEndpoint = async( api._checkGlobalEndpoint )

function api._ping()
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
end
api.ping = async( api._ping )

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
