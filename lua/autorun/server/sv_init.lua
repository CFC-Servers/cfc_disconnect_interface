util.AddNetworkString( "cfc_di_ping" )
util.AddNetworkString( "cfc_di_loaded" )
util.AddNetworkString( "cfc_di_shutdown" )

AddCSLuaFile( "cfc_disconnect_interface/client/cl_ponger.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_api.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_interface.lua" )

resource.AddSingleFile( "materials/icons/cross.png" )

include( "cfc_disconnect_interface/server/sv_pinger.lua" )