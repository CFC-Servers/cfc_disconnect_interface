local PING_TIME = 1

local players = {}

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

hook.Add( "PlayerDisconnected", "crashsys", function( ply )
    ping( ply ) -- Stop menu popping up while they are leaving
    table.RemoveByValue( players, ply )
end )

timer.Create( "cfc_di_pingTimer", PING_TIME, 0, ping )

hook.Add( "ShutDown", "cfc_di", function()
    net.Start( "cfc_di_shutdown" )
    net.Send( players )
end )
