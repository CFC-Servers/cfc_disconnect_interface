# cfc_disconnect_interface
Custom interface to display when the server crashes or the client loses connection  
You get to play the Dinosaur Game from Google Chrome!

## Requirements
- [cfc_network_promises](https://github.com/CFC-Servers/cfc_network_promises)

## Convars (Server-side)
- `cfc_disconnect_interface_status_endpoint` - (String) The url that will be pinged to check server status.  
	Defaults to `https://nanny.cfcservers.org/cfc3-ping`.  
	Is expected to return a JSON table containing a `status` key, which will be `server-is-up` when the server is running.
	```
	{
		"status": "server-is-up"
	}
	```
- `cfc_disconnect_interface_restart_time` - (Int) The number of seconds that will be displayed as the average restart time for the server.  
	Defaults to `180`
## Commands (Client-side)
- `cfc_disconnect_interface_test_crash` - Mimics the server crashing, showing the interface.
- `cfc_disconnect_interface_test_nointernet` - Mimics your internet disconnecting, showing the interface.
- `cfc_disconnect_interface_test_restart` - Mimics the server restarting, allowing you to reconnect.
- `cfc_disconnect_interface_test_recover` - Mimics the server fully recovering, closing the interface.