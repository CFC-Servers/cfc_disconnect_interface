util.AddNetworkString( "cfc_di_ping" )
util.AddNetworkString( "cfc_di_loaded" )
util.AddNetworkString( "cfc_di_shutdown" )

CreateConVar( "sv_mintimeout", 900, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )

AddCSLuaFile( "cfc_disconnect_interface/client/cl_ponger.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_api.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_interface.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_detached_timer.lua" )

resource.AddSingleFile( "materials/icons/cross.png" )

include( "cfc_disconnect_interface/server/sv_pinger.lua" )