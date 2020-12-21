require( "cfc_promises" )

CFCCrashAPI = {}

local endpointDirectory = "cfc/cfc_disconnect_interface/endpoint.txt"

local endpointCFC = file.Read( endpointDirectory ) or "https://nanny.cfcservers.org/cfc3-ping"
local endpointGlobal = "https://www.google.com"

local api = CFCCrashAPI
api.state = api.INACTIVE

api.INACTIVE = 0
api.PINGING_API = 1
api.NO_INTERNET = 2
api.SERVER_DOWN = 3
api.SERVER_UP = 4

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

    local _, data = await( promises.all( api.checkCFCEndpoint(), api.checkGlobalEndpoint() ) )
    local cfcStatus, globalStatus = data[1][1], data[2][1]

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

concommand.Add( "cfc_di_testcrash", function()
    api.stateOverride = api.SERVER_DOWN
end )

concommand.Add( "cfc_di_testnointernet", function()
    api.stateOverride = api.NO_INTERNET
end )

concommand.Add( "cfc_di_testrestart", function()
    api.stateOverride = api.SERVER_UP
end )

concommand.Add( "cfc_di_testrecover", function()
    api.stateOverride = nil
end )
