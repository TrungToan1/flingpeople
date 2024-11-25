local tool = script.Parent
local throwForce = 80 -- Adjust throw force as needed
local cooldown = 8
local lastActivated = 0
local brickmodel = script.Parent.brick
local debris = game:GetService("Debris")
local serverstorage = game:GetService("ServerStorage")

-- RemoteEvent for communication
local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "ThrowEvent"
remoteEvent.Parent = tool

-- Function to update tool name with cooldown
local function updateToolName(timeLeft)
	if timeLeft > 0 then
		tool.Name = string.format("Throw (%d)", math.ceil(timeLeft))
	else
		tool.Name = "Throw"
	end
end

-- Function to start the cooldown
local function startCooldown()
	local startTime = tick()
	while tick() - startTime < cooldown do
		local timeLeft = cooldown - (tick() - startTime)
		updateToolName(timeLeft)
		task.wait(0.1)
	end
	updateToolName(0)
	for _, child in pairs(brickmodel:GetChildren()) do
		if child:IsA("UnionOperation") or child:IsA("Part") then
			child.Transparency = 0
		end
	end
end

-- Add a LastHitter tag to the player
local function tagPlayer(player, attackerName)
	if not player or not attackerName then return end
	local character = player.Character
	if character then
		local lastHitter = character:FindFirstChild("LastHitter") or Instance.new("StringValue")
		lastHitter.Name = "LastHitter"
		lastHitter.Value = attackerName
		lastHitter.Parent = character
		-- Automatically remove the tag after 10 seconds
		debris:AddItem(lastHitter, 10)
	end
end

-- Handle collisions for the brick
local function onCollision(brick, direction, throwerCharacter, throwerPlayer)
	local hitAlready = false -- Track if the brick has hit a player already

	brick.Touched:Connect(function(hit)
		if hitAlready then return end

		local character = hit.Parent
		local player = game.Players:GetPlayerFromCharacter(character)

		if not character or not player or character == throwerCharacter then
			return
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.PlatformStand = true
			local backpack = player:FindFirstChild("Backpack")
			local toolsToRemove = {}

			for _, tool in ipairs(character:GetChildren()) do
				if tool:IsA("Tool") then
					tool.Parent = backpack
					table.insert(toolsToRemove, tool)
				end
			end

			-- Play the bell sound from the brickmodel if it exists
			local bellSound = brick:FindFirstChild("bell")
			if bellSound and bellSound:IsA("Sound") then
				print("Playing bell sound!")  -- Debugging line
				bellSound:Play() -- Play the sound from the brick
			else
				print("No bell sound found!")  -- Debugging line
			end
			brick.Left.CanCollide = true
			brick.Middle.CanCollide = true
			brick.Right.CanCollide = true
			brick:BreakJoints()

			task.delay(3, function()
				if humanoid.Parent then
					humanoid.PlatformStand = false
					for _, tool in ipairs(toolsToRemove) do
						tool.Parent = character
					end
				end
			end)

			-- Tag the player with the attacker's name
			tagPlayer(player, throwerPlayer.Name)
		end

		hitAlready = true
	end)
end

-- Throw the brick
local function throwBrick(playerCharacter, direction, throwerPlayer)
	local rootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local brick = serverstorage.Brick:Clone()
		brick.Parent = workspace
		tool.ThrowV2:Play()
		local randomRotation = CFrame.Angles(
			math.rad(math.random(0, 360)),
			math.rad(math.random(0, 360)),
			math.rad(math.random(0, 360))
		)

		brick.CFrame = CFrame.new(rootPart.Position + direction.Unit * 2, rootPart.Position + direction.Unit * 4) * randomRotation

		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = direction.Unit * throwForce
		bodyVelocity.MaxForce = Vector3.new(10000, 10000, 10000)
		bodyVelocity.Parent = brick

		task.delay(0.1, function()
			if bodyVelocity.Parent then
				bodyVelocity:Destroy()
			end
		end)

		onCollision(brick, direction, playerCharacter, throwerPlayer)

		debris:AddItem(brick, 5)
	end
end

-- Listen for remote event
remoteEvent.OnServerEvent:Connect(function(player, targetPosition)
	local character = player.Character
	if character and tick() - lastActivated >= cooldown then
		lastActivated = tick()

		for _, child in pairs(brickmodel:GetChildren()) do
			if child:IsA("UnionOperation") or child:IsA("Part") then
				child.Transparency = 0.5
			end
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local direction = (targetPosition - rootPart.Position).Unit
			throwBrick(character, direction, player)
		end

		task.spawn(startCooldown)
	end
end)
