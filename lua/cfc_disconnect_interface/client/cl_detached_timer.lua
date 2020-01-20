dTimer = {}

dTimer.timers = {}
dTimer.idCounter = 0

function dTimer.Create(id, delay, reps, f)
	dTimer.timers[id] = {id = id, delay = delay, reps = reps, f = f, lastCall = SysTime()}
end

function dTimer.Adjust(id, delay, reps, f)
	if dTimer.timers[id] then
		dTimer.timers[id].delay = delay or dTimer.timers[id].delay
		dTimer.timers[id].reps = reps or dTimer.timers[id].reps
		dTimer.timers[id].f = f or dTimer.timers[id].f
		return true
	end
	return false
end

function dTimer.Exists(id)
	return not not dTimer.timers[id]
end

function dTimer.Remove(id)
	dTimer.timers[id] = nil
end

function dTimer.RepsLeft(id)
	return dTimer.timers[id] and dTimer.timers[id].reps or -1
end

function dTimer.Simple( delay, f )
	dTimer.Create("SimpleTimer" .. dTimer.idCounter, delay, 1, f)
	dTimer.idCounter = dTimer.idCounter + 1
end


hook.Add("Think", "cfc_di_detatched_timer", function()
	local s = SysTime()
	for k, t in pairs(dTimer.timers) do
		if s - t.lastCall > t.delay then
			t.lastCall = s
			if t.reps > 0 then
				t.reps = t.reps - 1
				if t.reps == 0 then
					dTimer.timers[k] = nil
				end
			end
			t.f()
		end
	end
end)