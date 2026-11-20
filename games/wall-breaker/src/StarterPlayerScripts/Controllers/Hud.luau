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
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Panels = require(Controllers:WaitForChild("Panels"))
local Toasts = require(Controllers:WaitForChild("Toasts"))

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
		-- (плитки с референса уже содержат подпись — свою подпись прячем, если символа нет)
		if childName == "Tile" and (IconConfig[key:gsub("Tile$", "Symbol")] or "rbxassetid://0") == "rbxassetid://0" then
			local lbl = holder:FindFirstChild("Label")
			if lbl and lbl:IsA("GuiObject") then
				lbl.Visible = false
			end
		end
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
	setIcon(find("TopRight.AchievementsButton"), "Icon", "Achievements")
	setIcon(find("TopRight.RewardsButton"), "Icon", "Rewards")
	setIcon(find("TopRight.QuestsButton"), "Icon", "Quests")
	setIcon(find("TopRight.SettingsButton"), "Icon", "Settings")
	setIcon(find("Stats.StrengthRow"), "Icon", "Strength")
	setIcon(find("PowerPanel.LevelBar"), "Icon", "LevelSword")
	setIcon(find("PowerPanel.PowerStrikeButton"), "Icon", "PowerSword")
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

local XP_BUTTONS = { XpSmallButton = "xp_small", XpMediumButton = "xp_medium", XpBigButton = "xp_big" }

local function productFactor(key: string): number
	for _, p in ipairs(ShopConfig.Products) do
		if p.Key == key then
			return p.XpFactor or 1
		end
	end
	return 1
end

local function refreshStats()
	local data = State.Data
	if not data then
		return
	end
	local infinite = Players.LocalPlayer:GetAttribute("Infinite") == true
	setText("Stats.WinsRow.Value", infinite and "∞" or Format.Short(data.Wins))
	setText("Stats.StrengthRow.Value", infinite and "∞" or Format.Short(data.Strength))
	setText("Stats.LuckRow.Value", Format.Short(Formulas.LuckPercent(data, State.HasPass("LuckX2"))) .. "%")
	setText("Stats.RebirthRow.Value", tostring(data.Rebirths))
	-- большая надпись силы и полоса уровня
	setText("PowerPanel.StrengthBig", (infinite and "∞" or Format.Short(data.Strength)) .. " Сила")
	local level = data.PlayerLevel or 1
	local need = Formulas.XpForLevel(level)
	setText("PowerPanel.LevelBar.Level", "Уровень " .. tostring(level))
	setText("PowerPanel.LevelBar.Xp", ("%s / %s"):format(Format.Short(data.Xp or 0), Format.Short(need)))
	local fill = find("PowerPanel.LevelBar.Fill")
	if fill and fill:IsA("GuiObject") then
		fill.Size = UDim2.new(math.clamp((data.Xp or 0) / need, 0.02, 1), 0, 1, 0)
	end
	for buttonName, key in pairs(XP_BUTTONS) do
		setText("PowerPanel.XpButtons." .. buttonName, ("+%s очков\nопыта"):format(Format.Short(need * productFactor(key))))
	end
end

local function refreshTimers()
	-- «Мощный удар»: активен / перезарядка / готов
	local strikeText = find("PowerPanel.PowerStrikeButton.Text")
	if strikeText and strikeText:IsA("TextLabel") then
		local active = State.Countdown("PowerStrikeActiveFor")
		local ready = State.Countdown("PowerStrikeReadyIn")
		if active > 0 then
			strikeText.Text = ("Активен\n%d сек"):format(math.ceil(active))
		elseif ready > 0 then
			strikeText.Text = ("Готов через\n%d сек"):format(math.ceil(ready))
		else
			strikeText.Text = "Мощный\nудар"
		end
	end
	-- значок «1» на наградах, когда ежедневная награда готова
	local badge = find("TopRight.RewardsButton.Badge")
	if badge and badge:IsA("GuiObject") then
		badge.Visible = State.Data ~= nil and State.Countdown("DailyReadyIn") <= 0
	end
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
	local small = find("TopRight")
	if small then
		for i, name in ipairs({ "SettingsButton", "QuestsButton", "RewardsButton" }) do
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
		scale.Scale = math.clamp(camera.ViewportSize.Y / 760, 0.75, 1.15)
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
	bindButton("TopRight.AchievementsButton", "AchievementsPanel")
	bindButton("TopRight.RewardsButton", "RewardsPanel")
	bindButton("TopRight.QuestsButton", "QuestsPanel")
	bindButton("TopRight.SettingsButton", "SettingsPanel")

	State.Changed:Connect(function()
		refreshStats()
		refreshTimers()
		updateWheelBadge()
	end)

	-- Кнопки опыта (Robux) и «Мощный удар»
	local function request(action: string, ...)
		local res = State.Request(action, ...)
		if res and res.msg then
			Toasts.Show(res.msg, res.ok and "info" or "error")
		end
	end
	for buttonName, key in pairs(XP_BUTTONS) do
		local b = find("PowerPanel.XpButtons." .. buttonName)
		if b and b:IsA("GuiButton") then
			b.Activated:Connect(function()
				request("BuyProduct", key)
			end)
		end
	end
	local strike = find("PowerPanel.PowerStrikeButton")
	if strike and strike:IsA("GuiButton") then
		strike.Activated:Connect(function()
			request("PowerStrike")
		end)
	end
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
			refreshTimers()
		end
	end)
end

return Hud
