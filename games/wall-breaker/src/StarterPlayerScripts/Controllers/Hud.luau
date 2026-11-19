--[[
	Hud — главный интерфейс: кнопки, показатели, колесо, панель уровня, анимации иконок.
	Сами кнопки лежат в StarterGui › MainHud — их можно двигать и перекрашивать в Studio.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Config")
local IconConfig = require(Config:WaitForChild("IconConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Panels = require(Controllers:WaitForChild("Panels"))

local Hud = {}
local gui: ScreenGui

local function find(path: string): Instance?
	local node: Instance? = gui
	for part in path:gmatch("[^%.]+") do
		node = node and node:FindFirstChild(part)
	end
	return node
end

local function setIcon(holder: Instance?, childName: string, key: string)
	if not holder then
		return
	end
	local image = holder:FindFirstChild(childName)
	local id = IconConfig[key]
	if image and image:IsA("ImageLabel") and id and id ~= "" and id ~= "rbxassetid://0" then
		image.Image = id
		image.Visible = true
		local fallback = holder:FindFirstChild("Fallback")
		if fallback and fallback:IsA("GuiObject") then
			fallback.Visible = false
		end
		-- если загружена картинка-плитка, убираем цветной фон кнопки
		if childName == "Tile" and holder:IsA("GuiObject") then
			holder.BackgroundTransparency = 1
			local stroke = holder:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Enabled = false
			end
		end
	end
end

local function applyIcons()
	setIcon(find("LeftMenu.ShopButton"), "Tile", "ShopTile")
	setIcon(find("LeftMenu.ShopButton"), "Symbol", "ShopSymbol")
	setIcon(find("LeftMenu.PetsButton"), "Tile", "PetsTile")
	setIcon(find("LeftMenu.PetsButton"), "Symbol", "PetsSymbol")
	setIcon(find("LeftMenu.AurasButton"), "Tile", "AurasTile")
	setIcon(find("LeftMenu.AurasButton"), "Symbol", "AurasSymbol")
	setIcon(find("LeftMenu.RebirthButton"), "Tile", "RebirthTile")
	setIcon(find("LeftMenu.RebirthButton"), "Symbol", "RebirthSymbol")
	setIcon(find("TopRight.WheelButton"), "Base", "WheelBase")
	setIcon(find("TopRight.WheelButton"), "Disc", "WheelDisc")
	setIcon(find("TopRight.WheelButton"), "Top", "WheelTop")
	setIcon(find("TopRight.SmallButtons.AchievementsButton"), "Icon", "Achievements")
	setIcon(find("TopRight.SmallButtons.RewardsButton"), "Icon", "Rewards")
	setIcon(find("TopRight.SmallButtons.QuestsButton"), "Icon", "Quests")
	setIcon(find("TopRight.SmallButtons.SettingsButton"), "Icon", "Settings")
	setIcon(find("Stats.StrengthRow"), "Icon", "Strength")
	setIcon(find("Stats.LuckRow"), "Icon", "Luck")
	setIcon(find("Stats.WinsRow"), "Icon", "Wins")
end

local function bindButton(path: string, panelName: string)
	local button = find(path)
	if button and button:IsA("GuiButton") then
		button.Activated:Connect(function()
			Panels.Toggle(panelName)
		end)
	end
end

local function setText(path: string, text: string)
	local label = find(path)
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function refreshStats()
	local data = State.Data
	if not data then
		return
	end
	setText("Stats.StrengthRow.Value", "Сила: " .. Format.Comma(data.Strength))
	setText("Stats.LuckRow.Value", ("Удача: %s%%"):format(Format.Short(Formulas.LuckPercent(data, State.HasPass("LuckX2")))))
	setText("Stats.WinsRow.Value", "Победы: " .. Format.Comma(data.Wins))
end

-- Анимации иконок (покачивание, прыжки, пульсация, вращение)
local baseState = {}
local function remember(obj: GuiObject?)
	if obj and not baseState[obj] then
		baseState[obj] = { Position = obj.Position, Size = obj.Size, Rotation = obj.Rotation }
	end
	return obj
end

local function animate(t: number)
	local function sym(button: string, child: string): GuiObject?
		local holder = find("LeftMenu." .. button)
		local obj = holder and (holder:FindFirstChild(child) :: GuiObject?)
		return remember(obj)
	end
	for i, name in ipairs({ "ShopButton", "PetsButton", "AurasButton", "RebirthButton" }) do
		local btn = find("LeftMenu." .. name) :: GuiObject?
		local scale = btn and btn:FindFirstChild("Pulse")
		if scale and scale:IsA("UIScale") then
			scale.Scale = 1 + 0.035 * math.sin(t * 3 + i * 1.3)
		end
		-- символ и запасной эмодзи анимируются одинаково
		for _, child in ipairs({ "Symbol", "Fallback" }) do
			local obj = sym(name, child)
			if obj and baseState[obj] then
				local base = baseState[obj]
				if name == "ShopButton" then
					obj.Rotation = 7 * math.sin(t * 2.6)
				elseif name == "PetsButton" then
					obj.Position = base.Position + UDim2.fromOffset(0, -8 * math.abs(math.sin(t * 3.2)))
				elseif name == "AurasButton" then
					local k = 1 + 0.08 * math.sin(t * 7)
					obj.Size = UDim2.new(base.Size.X.Scale * k, base.Size.X.Offset * k, base.Size.Y.Scale * k, base.Size.Y.Offset * k)
				elseif name == "RebirthButton" then
					obj.Rotation = (t * 90) % 360
				end
			end
		end
	end
	-- колесо фортуны и значок «!»
	local wheel = find("TopRight.WheelButton")
	if wheel then
		for _, child in ipairs({ "Disc", "Fallback" }) do
			local d = wheel:FindFirstChild(child)
			if d and d:IsA("GuiObject") then
				d.Rotation = (t * 50) % 360
			end
		end
		local badge = wheel:FindFirstChild("Badge")
		local bScale = badge and badge:FindFirstChildOfClass("UIScale")
		if bScale then
			bScale.Scale = 1 + 0.22 * math.max(0, math.sin(t * 6))
		end
	end
	-- маленькие кнопки справа сверху покачиваются
	local small = find("TopRight.SmallButtons")
	if small then
		for i, name in ipairs({ "AchievementsButton", "RewardsButton", "QuestsButton", "SettingsButton" }) do
			local btn = small:FindFirstChild(name)
			if btn then
				for _, child in ipairs({ "Icon", "Fallback" }) do
					local obj = remember(btn:FindFirstChild(child) :: GuiObject?)
					if obj and baseState[obj] then
						obj.Position = baseState[obj].Position + UDim2.fromOffset(0, -3 * math.sin(t * 2.6 + i * 0.9))
						if name == "SettingsButton" then
							obj.Rotation = (t * 40) % 360
						elseif name == "RewardsButton" then
							obj.Rotation = (t % 2.4) < 0.6 and 12 * math.sin(t * 28) or 0
						end
					end
				end
			end
		end
	end
	-- иконка силы «замахивается»
	local strengthIcon = find("Stats.StrengthRow.Icon")
	if strengthIcon and strengthIcon:IsA("GuiObject") then
		strengthIcon.Rotation = -14 * math.max(0, math.sin(t * 5))
	end
end

local function updateWheelBadge()
	local badge = find("TopRight.WheelButton.Badge")
	if badge and badge:IsA("GuiObject") and State.Data then
		badge.Visible = State.Countdown("WheelReadyIn") <= 0 or State.Data.Wheel.ExtraSpins > 0
	end
end

local function onLevelState(info)
	local panel = find("LevelPanel")
	if not panel or not panel:IsA("GuiObject") then
		return
	end
	if not info then
		panel.Visible = false
		return
	end
	panel.Visible = true
	setText("LevelPanel.Title", ("Уровень %d · %s"):format(info.Level, info.Name))
	setText("LevelPanel.Sub", "Рекомендуемая сила: " .. Format.Short(info.Recommended))
	local fill = find("LevelPanel.Bar.Fill")
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.new(math.clamp(info.Layer / info.Layers, 0, 1), 0, 1, 0)
	end
	if info.Layer >= info.Layers then
		setText("LevelPanel.Bar.BarText", "Стена пройдена! Награда — в нише справа")
	else
		setText("LevelPanel.Bar.BarText", ("Слой %d / %d · прочность %s / %s"):format(info.Layer + 1, info.Layers, Format.Short(info.HP), Format.Short(info.MaxHP)))
	end
end

local function fitScale()
	local scale = gui:FindFirstChild("Scale")
	local camera = Workspace.CurrentCamera
	if scale and scale:IsA("UIScale") and camera then
		scale.Scale = math.clamp(camera.ViewportSize.Y / 760, 0.55, 1.2)
	end
end

function Hud.Init()
	gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainHud") :: ScreenGui
	applyIcons()
	bindButton("LeftMenu.ShopButton", "ShopPanel")
	bindButton("LeftMenu.PetsButton", "PetsPanel")
	bindButton("LeftMenu.AurasButton", "AurasPanel")
	bindButton("LeftMenu.RebirthButton", "RebirthPanel")
	bindButton("TopRight.WheelButton", "WheelPanel")
	bindButton("TopRight.SmallButtons.AchievementsButton", "AchievementsPanel")
	bindButton("TopRight.SmallButtons.RewardsButton", "RewardsPanel")
	bindButton("TopRight.SmallButtons.QuestsButton", "QuestsPanel")
	bindButton("TopRight.SmallButtons.SettingsButton", "SettingsPanel")

	State.Changed:Connect(function()
		refreshStats()
		updateWheelBadge()
	end)
	Remotes.Event("LevelState").OnClientEvent:Connect(onLevelState)

	fitScale()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScale)
	end

	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		animate(os.clock())
		acc += dt
		if acc > 1 then
			acc = 0
			updateWheelBadge()
		end
	end)
end

return Hud
