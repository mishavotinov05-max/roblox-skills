--[[
	Swing — удар киркой: клик / тап, пока кирка в руках. Автоклик для владельцев геймпасса.
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("GameSettings"))
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))

local Swing = {}
local player = Players.LocalPlayer
local lastSwing = 0
local currentTool: Tool? = nil

local function swing()
	local now = os.clock()
	if now - lastSwing < Settings.SwingCooldown then
		return
	end
	lastSwing = now
	Remotes.Event("Swing"):FireServer()
end

local function watchCharacter(character: Model)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child.Name == "Pickaxe" then
			currentTool = child
			child.Activated:Connect(swing)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child == currentTool then
			currentTool = nil
		end
	end)
	local existing = character:FindFirstChild("Pickaxe")
	if existing and existing:IsA("Tool") then
		currentTool = existing
		existing.Activated:Connect(swing)
	end
end

function Swing.Init()
	player.CharacterAdded:Connect(watchCharacter)
	if player.Character then
		watchCharacter(player.Character)
	end
	-- Автоклик
	task.spawn(function()
		while true do
			task.wait(Settings.AutoClickInterval)
			local data = State.Data
			if currentTool and currentTool.Parent == player.Character and data and data.Settings.AutoClick and State.HasPass("AutoClick") then
				swing()
			end
		end
	end)
end

return Swing
