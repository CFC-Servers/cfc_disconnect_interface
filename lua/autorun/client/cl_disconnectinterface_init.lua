CreateConVar( "cfc_disconnect_interface_status_endpoint", "https://nanny.cfcservers.org/cfc3-ping", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_restart_time", 180, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
CreateConVar( "cfc_disconnect_interface_game_url", "https://cdn.cfcservers.org/media/dinosaur/index.html", FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
local minTimeout = CreateConVar( "sv_mintimeout", 900, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED ):GetInt()

local timeout = GetConVar( "cl_timeout" )
if not timeout or timeout:GetInt() < minTimeout then
    RunConsoleCommand( "cl_timeout", minTimeout )
end

include( "cfc_disconnect_interface/client/cl_detached_timer.lua" )
include( "cfc_disconnect_interface/client/cl_ponger.lua" )
include( "cfc_disconnect_interface/client/cl_interface.lua" )
