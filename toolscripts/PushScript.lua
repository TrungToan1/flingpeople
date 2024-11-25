local tool = script.Parent
local hitbox = tool:WaitForChild("Hitbox")
local flingForce = 100 -- Adjust as necessary
local cooldown = 5 -- Adjust the cooldown duration
local canFling = false
local lastActivated = 0
local animation = tool:WaitForChild("Animation")

-- Initial state for hitbox
hitbox.CanTouch = false
hitbox.Transparency = 1

-- Update the tool's name with the remaining cooldown
local function updateCooldownText()
	local remainingTime = cooldown - (tick() - lastActivated)
	if remainingTime > 0 then
		tool.Name = "Push (" .. math.ceil(remainingTime) .. ")" -- Update tool's name to show cooldown
	else
		tool.Name = "Push" -- Show ready status when cooldown ends
	end
end

-- Add a LastHitter tag to the pushed player
local function tagAttacker(targetCharacter, taggerName)
	if not targetCharacter or not targetCharacter:IsA("Model") then return end
	local humanoid = targetCharacter:FindFirstChild("Humanoid")
	if humanoid then
		local lastHitter = targetCharacter:FindFirstChild("LastHitter") or Instance.new("StringValue")
		lastHitter.Name = "LastHitter"
		lastHitter.Value = taggerName
		lastHitter.Parent = targetCharacter

		-- Automatically remove the tag after 10 seconds to prevent stale tags
		game:GetService("Debris"):AddItem(lastHitter, 10)
	end
end

-- Detect when hitbox touches a barrel
hitbox.Touched:Connect(function(hit)
	if hit.Parent.Name == "Barrel" then
		local barrel = hit.Parent
		local barrelPrimaryPart = barrel.PrimaryPart or barrel:FindFirstChild("Barrel") or hit

		if barrelPrimaryPart then
			-- Get the wielder (player using the tool)
			local wielder = tool.Parent
			if not wielder or not wielder:IsA("Model") then return end

			-- Get the wielder's head to determine look direction
			local head = wielder:FindFirstChild("Head")
			if not head then return end

			-- Calculate the direction the player is looking
			local lookDirection = (head.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			local upwardComponent = Vector3.new(0, 0.1, 0) -- Add a slight upward component

			-- Combine the look direction with the upward component
			local pushDirection = (lookDirection + upwardComponent).Unit

			-- Apply impulse to the barrel
			local impulseForce = pushDirection * flingForce * 10
			barrelPrimaryPart:ApplyImpulse(impulseForce)

		end
	end

	-- Detect if the hitbox touches a player and apply force
	local character = hit.Parent
	if not character or not character:IsA("Model") then return end -- Ensure character is valid

	local player = game.Players:GetPlayerFromCharacter(character)
	local wielder = tool.Parent
	if not wielder or not wielder:IsA("Model") then return end -- Ensure wielder is valid

	local wielderPlayer = game.Players:GetPlayerFromCharacter(wielder)

	if canFling and player and wielderPlayer and player ~= wielderPlayer and not tool:GetAttribute("CounterActive") then
		-- Check for the Counter tool
		local counterTool = player.Backpack:FindFirstChild("Counter") or character:FindFirstChild("Counter")
		local counterActive = counterTool and counterTool:GetAttribute("CounterActive") == true

		-- Unequip the player's currently held tool (if any)
		local toolInHand = character:FindFirstChildOfClass("Tool")
		if toolInHand and toolInHand ~= counterTool then
			toolInHand.Parent = player.Backpack -- Temporarily unequip the tool
			task.delay(1, function() -- Re-equip it after 1 second
				if toolInHand.Parent == player.Backpack then
					toolInHand.Parent = character
				end
			end)
		end

		-- Calculate push direction (from wielder's forward direction)
		local wielderRoot = wielder:FindFirstChild("HumanoidRootPart")
		if wielderRoot then
			local pushDirection = wielderRoot.CFrame.LookVector

			if counterActive then
				-- Tag the attacker (wielder) with the player who countered
				tagAttacker(wielder, player.Name)
				print("Tagged by counterer")

				-- Unequip the tool of the wielder (attacker) before fling
				local toolInHandWielder = wielder:FindFirstChildOfClass("Tool")
				if toolInHandWielder then
					toolInHandWielder.Parent = wielderPlayer.Backpack -- Unequip the attacker's tool
				end

				-- Fling the wielder (attacker)
				local wielderRootPart = wielder:FindFirstChild("HumanoidRootPart")
				local wielderHumanoid = wielder:FindFirstChild("Humanoid")
				if wielderRootPart and wielderHumanoid then
					print("Flung attacker with counter")
					script.Parent.Countered:Play()

					wielderHumanoid.PlatformStand = true

					-- Double the fling force
					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.Velocity = -pushDirection * (flingForce * 2)
					bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
					bodyVelocity.Parent = wielderRootPart
					game.Debris:AddItem(bodyVelocity, 0.1)
					wait(1)
					wielderHumanoid.PlatformStand = false
				end
			else
				-- Tag the pushed player (the victim)
				tagAttacker(character, wielderPlayer.Name)

				-- Push the touched player
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChild("Humanoid")
				if rootPart and humanoid then
					humanoid.PlatformStand = true

					local bodyVelocity = Instance.new("BodyVelocity")
					bodyVelocity.Velocity = pushDirection * flingForce
					bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
					bodyVelocity.Parent = rootPart

					-- Clean up and reset
					game.Debris:AddItem(bodyVelocity, 0.1)
					wait(1)
					humanoid.PlatformStand = false
				end
			end
		end
	end
end)

-- Enable fling on tool activation with cooldown
tool.Activated:Connect(function()
	if tick() - lastActivated >= cooldown and not tool:GetAttribute("CounterActive") then
		lastActivated = tick()
		canFling = true
		hitbox.CanTouch = true
		hitbox.Transparency = 0

		-- Perform fling (without dash)
		wait(1) -- Fling window duration
		hitbox.CanTouch = false
		hitbox.Transparency = 1
		canFling = false
	end
end)

-- Store player holding the tool
tool.Equipped:Connect(function()
	canFling = false
	hitbox.CanTouch = false
	updateCooldownText() -- Initial update
end)

tool.Unequipped:Connect(function()
	canFling = false
	hitbox.CanTouch = false
	updateCooldownText() -- Update when unequipped
end)

-- Continuously update the tool's name in the toolbar to show the cooldown
while true do
	updateCooldownText()
	wait(0.1) -- Update the tooltip every 100 milliseconds
end
