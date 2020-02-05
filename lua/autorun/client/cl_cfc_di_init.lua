local cv = GetConVar( "cl_timeout" )
if not cv or cv:GetInt() < 900 then
    RunConsoleCommand( "cl_timeout", 900 )
end
include( "cfc_disconnect_interface/client/cl_detached_timer.lua" )
include( "cfc_disconnect_interface/client/cl_ponger.lua" )
include( "cfc_disconnect_interface/client/cl_interface.lua" )
