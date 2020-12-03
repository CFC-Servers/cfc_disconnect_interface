local PING_TIME = 1

local players = {}
local table = table

local function getStatusEndpoint()
    local endpoint = file.Read( "cfc/cfc_di_status_endpoint.txt", "DATA" )

    if not endpoint then
        error( "No status endpoint is set, disconnect interface will not function properly!" )
        return
    end

    endpoint = string.Replace( "\n", "" )
    endpoint = string.Replace( "\r", "" )

    return endpoint
end

local statusEndpoint = getStatusEndpoint()


local function ping( ply )
    net.Start( "cfc_di_ping" )
    net.Send( ply or players )
end

net.Receive( "cfc_di_loaded", function( len, ply )
    if not IsValid( ply ) then return end
    if not table.HasValue( players, ply ) then
        table.insert( players, ply )
    end
end )

    net.Start( "CFC_DisconnectInterface_GetStatusEndpoint" )
        net.WriteString( statusEndpoint )
    net.Send( ply )

hook.Add( "PlayerDisconnected", "crashsys", function( ply )
    ping( ply ) -- Stop menu popping up while they are leaving
    table.RemoveByValue( players, ply )
end )

timer.Create( "cfc_di_pingTimer", PING_TIME, 0, function()
    ping()
end )

hook.Add( "ShutDown", "cfc_di", function()
    net.Start( "cfc_di_shutdown" )
    net.Send( players )
end )
