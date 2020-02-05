local minTimeout = CreateConVar( "sv_mintimeout", 900, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED ):GetInt()
local timeout = GetConVar( "cl_timeout" )
if not timeout or timeout:GetInt() < minTimeout then
    RunConsoleCommand( "cl_timeout", minTimeout )
end
include( "cfc_disconnect_interface/client/cl_detached_timer.lua" )
include( "cfc_disconnect_interface/client/cl_ponger.lua" )
include( "cfc_disconnect_interface/client/cl_interface.lua" )
