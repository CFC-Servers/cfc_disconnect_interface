local PING_TIME = 1

local players = {}
local unreliable = true

local function ping( ply )
    net.Start( "CFC_DisconnectInterface_Ping", unreliable )
    net.Send( ply or players )
end

net.Receive( "CFC_DisconnectInterface_Loaded", function( _, ply )
    if not IsValid( ply ) then return end
    if not table.HasValue( players, ply ) then
        table.insert( players, ply )
    end
end )

hook.Add( "PlayerDisconnected", "CFC_DisconnectInterface_UnregisterPlayer", function( ply )
    ping( ply ) -- Stop menu popping up while they are leaving
    table.RemoveByValue( players, ply )
end )

timer.Create( "CFC_DisconnectInterface_PingTimer", PING_TIME, 0, ping )

hook.Add( "ShutDown", "CFC_DisconnectInterface_ForwardShutdown", function()
    net.Start( "CFC_DisconnectInterface_Shutdown" )
    net.Send( players )
end )
