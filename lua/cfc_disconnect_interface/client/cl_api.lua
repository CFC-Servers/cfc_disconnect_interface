crashApi = {}

-- local references
local http, concommand = http, concommand

local serverStatusEndpoint
local connectivityTestEndpoint = "https://www.google.com"

local api = crashApi

api.INACTIVE = 0
api.PINGING_API = 1
api.NO_INTERNET = 2
api.SERVER_DOWN = 3
api.SERVER_UP = 4

local DEV_MODE = false

api.inDebug = false
api.debugMode = api.INACTIVE

if DEV_MODE then
    -- Testing
    local function testServerCrash()
        api.inDebug = true
        api.debugMode = api.SERVER_DOWN
    end
    concommand.Add( "cfc_di_testcrash", testServerCrash )

    local function testNoInternet()
        api.inDebug = true
        api.debugMode = api.NO_INTERNET
    end
    concommand.Add( "cfc_di_testnointernet", testNoInternet )

    local function serverRestarted()
        api.inDebug = true
        api.debugMode = api.SERVER_UP
    end
    concommand.Add( "cfc_di_testrestart", serverRestarted )

    local function serverRecovered()
        api.inDebug = false
    end
    concommand.Add( "cfc_di_testrecover", serverRecovered )
end


local responses = {cfc = nil, global = nil} -- Does nothing but helps with clarity

local state = api.INACTIVE

local pingCancelled = false

local function getState()
    return state
end

-- Check both websites responded, set state accordingly
local function handleResponses()
    if pingCancelled then -- Ignore responses if ping was cancelled
        return
    end
    if responses.cfc == nil or responses.global == nil then -- Not all responses arrived yet
        return
    end

    -- If in debug mode, set state to debug state
    if api.inDebug then state = api.debugMode return end

    if responses.cfc then
        -- Server is up
        state = api.SERVER_UP
    elseif not responses.cfc and responses.global then
        -- Server is down
        state = api.SERVER_DOWN
    else
        -- Internet is down
        state = api.NO_INTERNET
    end
end

-- Fetch cfc and global end points
local function triggerPing()
    pingCancelled = false
    state = api.PINGING_API
    responses = {cfc = nil, global = nil}

    http.Fetch( serverStatusEndpoint,
        function( body, size, headers, code )
            local data = util.JSONToTable( body )
            -- If response is malformed, or empty, set cfc false
            if not data or data["server-is-up"] == nil then -- Can't use dot notation cuz api field has dashes >:(
                responses.cfc = false
                handleResponses()
            else
                responses.cfc = data["server-is-up"]
                handleResponses()
            end
        end,
        function( err )
            -- If cfc doesn't respond, set cfc false, might want to do something special here, as this means cfcservers had a heart attack
            responses.cfc = false
            handleResponses()
        end
    )

    http.Fetch( connectivityTestEndpoint,
        function( body, size, headers, code )
            responses.global = true
            handleResponses()
        end,
        function( err )
            responses.global = false
            handleResponses()
        end
    )

end

net.Receive( "CFC_DisconnectInterface_GetStatusEndpoint", function( _, ply )
    if not IsValid( ply ) then return end
    net.Start( "CFC_DisconnectInterface_GetStatusEndpoint" )
        net.WriteString( statusEndpoint )
    net.Send( ply )
end )

local function cancelPing()
    state = api.INACTIVE
    pingCancelled = true
end


api.getState = getState
api.triggerPing = triggerPing
api.cancelPing = cancelPing
