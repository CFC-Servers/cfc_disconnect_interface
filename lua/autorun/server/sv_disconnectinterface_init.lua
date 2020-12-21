util.AddNetworkString( "CFC_DisconnectInterface_Ping" )
util.AddNetworkString( "CFC_DisconnectInterface_Loaded" )
util.AddNetworkString( "CFC_DisconnectInterface_Shutdown" )

CreateConVar( "cfc_disconnect_interface_status_endpoint", "https://nanny.cfcservers.org/cfc3-ping", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_restart_time", 180, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_game_url", "https://cdn.cfcservers.org/media/dinosaur/index.html", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "sv_mintimeout", 900, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )

AddCSLuaFile( "cfc_disconnect_interface/client/cl_ponger.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_api.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_interface.lua" )
AddCSLuaFile( "cfc_disconnect_interface/client/cl_detached_timer.lua" )

resource.AddSingleFile( "materials/icons/cross.png" )

include( "cfc_disconnect_interface/server/sv_pinger.lua" )
