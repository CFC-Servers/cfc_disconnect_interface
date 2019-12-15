crashApi = {}

local cfc_endpoint = "https://scripting.cfcservers.org/cfc3-ping"
local global_endpoint = "https://www.google.com"

local api = crashApi

api.INACTIVE = 0
api.PINGING_API = 1
api.NO_INTERNET = 2
api.SERVER_DOWN = 3
api.SERVER_UP = 4

local responses = {cfc = nil, global = nil} -- Does nothing but helps with clarity

local state = api.INACTIVE

local pingCancelled = false

local function getState()
	return state
end

local function handleResponses()
	if pingCancelled then -- Ignore responses if ping was cancelled
		return
	end
	if responses.cfc == nil or responses.global == nil then -- Not all responses arrived yet
		return
	end
	if responses.cfc then
		-- Server is up
		state = api.SERVER_UP
	elseif not responses.cfc and responses.global then
		-- Server is down
		state = api.SERVER_DOWN
	else
		-- Internet is down
		state = api.NO_INTERNET
	end
end

local function triggerPing()
	pingCancelled = false
	state = api.PINGING_API
	responses = {cfc = nil, global = nil}

	http.Fetch(cfc_endpoint, 
		function(body, size, headers, code)
			local data = util.JSONToTable( body )
			if not data or data["server-is-up"] == nil then -- Can't use dot notation cuz api field has dashes >:(
				responses.cfc = false
				handleResponses()
			else
				responses.cfc = data["server-is-up"]
				handleResponses()
			end
		end, 
		function(err)
			responses.cfc = false
			handleResponses()
		end
	)

	http.Fetch(global_endpoint, 
		function(body, size, headers, code) 
			responses.global = true
			handleResponses()
		end, 
		function(err)
			responses.global = false
			handleResponses()
		end
	)

end

local function cancelPing()
	state = api.INACTIVE
	pingCancelled = true
end


api.getState = getState
api.triggerPing = triggerPing
api.cancelPing = cancelPing
