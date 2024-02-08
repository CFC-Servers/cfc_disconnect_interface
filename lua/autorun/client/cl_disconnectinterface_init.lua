CreateConVar( "cfc_disconnect_interface_status_endpoint", "https://nanny.cfcservers.org/cfc3-ping", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_restart_time", 180, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_game_url", "https://loading.cfcservers.org/dino.html", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
local minTimeout = CreateConVar( "sv_mintimeout", 900, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED ):GetInt()

local timeout = GetConVar( "cl_timeout" )
if not timeout or timeout:GetInt() < minTimeout then
    RunConsoleCommand( "cl_timeout", minTimeout )
end

require( "cfc_detached_timer" )
include( "cfc_disconnect_interface/client/cl_ponger.lua" )
include( "cfc_disconnect_interface/client/cl_interface.lua" )
