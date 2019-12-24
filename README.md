# cfc_disconnect_interface
Custom interface to display when the server crashes or the client loses connection  
You get to play the dinosaur game from Google Chrome!

## Debugging
- First set `DEV_MODE` in `lua/cfc_disconnect_interface/client/cl_api.lua` to `true`
- Then run any of the follow console commands:
  - `cfc_di_testcrash` - This imitates the server crashing
  - `cfc_di_testnointernet` - This imitates the client losing internet connection
  - `cfc_di_testrestart` - This imitates the server rebooting (but not recovering)
  - `cfc_di_testrecover` - This imitates the server recovering without crashing (basically a big lag spike)
- You should run `cfc_di_testrecover` if you want behaviour to return to normal, or before opening another menu
