-- Counter Script
local tool = script.Parent
local cooldownActive = false
local activeDuration = 1 -- Time counter is active
local cooldownDuration = 5 -- Cooldown duration

tool.Shield.Transparency = 1 -- Initial state: fully transparent
tool.Handle.BrickColor = BrickColor.new("Bright red") -- Initial state of the tool

-- Set initial counter state to false
tool:SetAttribute("CounterActive", false)

-- Function to deactivate the counter
local function deactivateCounter()
	tool:SetAttribute("CounterActive", false)
	tool.Shield.Transparency = 1 -- Make the shield transparent
	tool.Handle.BrickColor = BrickColor.new("Bright red") -- Indicates counter is inactive
	print("Counter Deactivated!")
end

-- Function to activate the counter
local function activateCounter(player)
	if not cooldownActive then
		-- Activate the counter
		tool:SetAttribute("CounterActive", true)
		tool.Shield.Transparency = 0 -- Make the shield opaque
		tool.Handle.BrickColor = BrickColor.new("Bright blue") -- Indicates counter is active
		cooldownActive = true
		print("Counter Activated!")

		-- Deactivate the counter after the active duration
		task.delay(activeDuration, function()
			deactivateCounter()
		end)

		-- Return the tool after cooldown
		task.delay(cooldownDuration, function()
			cooldownActive = false
			print("Counter Ready!")
		end)
	end
end

-- Trigger counter activation when the tool is activated
tool.Activated:Connect(function()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if player then
		activateCounter(player)
	end
end)

-- Reset the counter when the tool is unequipped
tool.Unequipped:Connect(function()
	deactivateCounter()
end)
