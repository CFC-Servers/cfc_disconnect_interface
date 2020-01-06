local cv = GetConVar( "cl_timeout" )
if not cv or cv:GetInt() < 240 then
    RunConsoleCommand( "cl_timeout", 240 )
end
include( "cfc_disconnect_interface/client/cl_ponger.lua" )
include( "cfc_disconnect_interface/client/cl_interface.lua" )