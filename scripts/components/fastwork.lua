local OnPlayerRespawn = function(player)
	if player and player.components and player.components.fastwork then
		player:DoTaskInTime(2, function(player)
			player.components.fastwork:Reload()
		end)
	end
end

local FastWork = Class(function(self, player)
	assert(_G.TheNet:GetIsServer() or _G.TheNet:IsDedicated(), "[Fast Work] Component should not exist on client")
	player:ListenForEvent("ms_respawnedfromghost", OnPlayerRespawn)
	self.player = player
	self.speeded_state = {}
end)

function FastWork:SetActionSpeed(action, multi)
	if self.player.prefab ~= "guybrush" then
		return
	end

	if self.player and self.player.sg and self.player.sg.sg and self.player.sg.sg.states[action] then
		if type(multi) ~= "number" or multi < 0 then
			print("[Fast Work] Ungültiger Speed-Multiplikator: " .. tostring(multi))
			return nil
		end

		local old_state = self.player.sg.sg.states[action]
		local new_state = State{ name = action, timeline = {} }
		for k, v in pairs(old_state) do
			if k == "timeline" then
				for k_t, v_t in pairs(v) do
					new_state.timeline[k_t] = TimeEvent(v_t.time * multi, v_t.fn)
				end
			else
				new_state[k] = v
			end
		end
		self.speeded_state[action] = new_state
		return true
	end
end

function FastWork:Reload()
	print("[DEBUG] FastWork:Reload() wird ausgeführt für " .. tostring(self.player.prefab))

	if self.player.prefab ~= "guybrush" then
		print("[DEBUG] Kein Guybrush, daher wird der Buff nicht aktiviert.")
		return
	end

	if not self.player._fastwork_mult then
		print("[DEBUG] Kein aktiver FastWork Buff.")
		return
	end
	
	local old_func = self.player.sg.UpdateState
	self.player.sg.UpdateState = function(...)
		if self.player.sg.currentstate and self.speeded_state[self.player.sg.currentstate.name] then
			self.player.sg.currentstate = self.speeded_state[self.player.sg.currentstate.name]
		end
		old_func(...)
	end
end

return FastWork
