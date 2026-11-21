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
		-- значки справа сверху уже с подписью — свою подпись прячем
		if (childName == "Icon" or childName == "Disc") and holder.Parent and holder.Parent.Name == "TopRight" then
			local lbl = holder:FindFirstChild("Label")
			if lbl and lbl:IsA("GuiObject") then
				lbl.Visible = false
			end
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

-- Картинка-скин вместо простой цветной плашки: фон и обводку прячем, лишние подписи тоже
local function setSkin(holder: Instance?, key: string, hide: { string })
	if not holder then
		return false
	end
	local id = IconConfig[key]
	local img = holder:FindFirstChild("Skin")
	if not img or not img:IsA("ImageLabel") or not id or id == "" or id == "rbxassetid://0" then
		return false
	end
	img.Image = id
	img.Visible = true
	if holder:IsA("GuiObject") then
		holder.BackgroundTransparency = 1
	end
	local stroke = holder:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Enabled = false
	end
	for _, n in ipairs(hide) do
		local o = holder:FindFirstChild(n)
		if o and o:IsA("GuiObject") then
			o.Visible = false
		end
	end
	-- Новые карточки без напечатанных чисел: заплатка ValueBg больше не нужна
	local patch = holder:FindFirstChild("ValueBg")
	if patch and patch:IsA("GuiObject") then
		patch.Visible = false
	end
	return true
end

local levelSkin = false
local powerSkin = false
local LEVEL_START = 0.122 -- где на картинке полосы кончается меч (из art/ui_ref/skins.json)

local function applySkins()
	setSkin(find("Stats.WinsRow"), "WinsCard", { "Icon", "Fallback", "Title" })
	setSkin(find("Stats.StrengthRow"), "StrengthCard", { "Icon", "Fallback", "Title" })
	setSkin(find("Stats.LuckRow"), "LuckCard", { "Icon", "Fallback", "Title" })
	setSkin(find("Stats.RebirthRow"), "RebirthCard", { "Icon", "Fallback", "Title" })
	powerSkin = setSkin(find("PowerPanel.PowerStrikeButton"), "PowerButton", { "Icon", "Fallback" })
	if setSkin(find("PowerPanel.LevelBar"), "LevelBarEmpty", { "Icon", "Fallback" }) then
		levelSkin = setSkin(find("PowerPanel.LevelBar.Fill"), "LevelBarFull", {})
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
		local pct = math.clamp((data.Xp or 0) / need, 0.02, 1)
		if levelSkin then
			-- жёлтая картинка начинается под мечом и растягивается до процента; внутри — на всю длину полосы
			local w = LEVEL_START + pct * (1 - LEVEL_START)
			fill.Size = UDim2.new(w, 0, 1, 0)
			local inner = fill:FindFirstChild("Skin")
			if inner and inner:IsA("GuiObject") then
				inner.Size = UDim2.new(1 / w, 0, inner.Size.Y.Scale, 0)
			end
		else
			fill.Size = UDim2.new(pct, 0, 1, 0)
		end
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
		-- на картинке уже написано «Мощный удар» — свой текст показываем только для таймера
		if powerSkin then
			strikeText.Visible = active > 0 or ready > 0
		end
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
		-- вращаем только эмодзи-заглушку; картинка с подписью покачивается
		local disc = wheel:FindFirstChild("Disc")
		if disc and disc:IsA("GuiObject") then
			disc.Rotation = 6 * math.sin(t * 2)
		end
		for _, child in ipairs({ "Fallback" }) do
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

-- имя файла картинки → строка IconConfig
local NAME_TO_KEY = {
	ref_shop = "ShopTile", ref_pets = "PetsTile", ref_auras = "AurasTile", ref_rebirth = "RebirthTile",
	ref_settings = "Settings", ref_quests = "Quests", ref_wheel = "WheelDisc", ref_rewards = "Rewards",
	ref_wins = "Wins", ref_strength = "Strength", ref_luck = "Luck",
	ref_level_sword = "LevelSword", ref_power_sword = "PowerSword",
	card_wins = "WinsCard", card_strength = "StrengthCard", card_luck = "LuckCard", card_rebirth = "RebirthCard",
	levelbar_empty = "LevelBarEmpty", levelbar_full = "LevelBarFull", power_button = "PowerButton",
}

-- Узнаём имена картинок из IconConfig.Unsorted и раскладываем их по местам
local function resolveUnsorted(): boolean
	local list = IconConfig.Unsorted
	if type(list) ~= "table" or #list == 0 then
		return false
	end
	local MarketplaceService = game:GetService("MarketplaceService")
	local changed = false
	local unknown = {}
	for _, id in ipairs(list) do
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id)
		end)
		local name = ok and info and tostring(info.Name):lower():gsub("%.png$", ""):gsub("%s+", "") or nil
		local key = name and NAME_TO_KEY[name]
		if key then
			local cur = IconConfig[key]
			if cur == nil or cur == "" or cur == "rbxassetid://0" then
				IconConfig[key] = "rbxassetid://" .. tostring(id)
				changed = true
			end
			print(("[Иконки] %s = \"rbxassetid://%d\""):format(key, id))
		else
			print(("[Иконки] %d — имя «%s» не узнано"):format(id, tostring(ok and info and info.Name)))
			table.insert(unknown, { id = id, name = ok and info and info.Name or "?" })
		end
	end
	-- В Studio показываем нераспознанные картинки с номерами — сделайте скриншот и пришлите
	if #unknown > 0 and game:GetService("RunService"):IsStudio() then
		local panel = Instance.new("Frame")
		panel.Name = "UnknownIcons"
		panel.AnchorPoint = Vector2.new(0.5, 0.5)
		panel.Position = UDim2.fromScale(0.5, 0.5)
		panel.Size = UDim2.fromOffset(760, 140 + math.ceil(#unknown / 6) * 130)
		panel.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
		panel.ZIndex = 100
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0, 40)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextScaled = true
		title.Font = Enum.Font.GothamBold
		title.Text = "Сделайте скриншот и пришлите (это видно только в Studio)"
		title.ZIndex = 101
		title.Parent = panel
		for i, u in ipairs(unknown) do
			local cell = Instance.new("Frame")
			cell.Size = UDim2.fromOffset(120, 125)
			cell.Position = UDim2.fromOffset(10 + ((i - 1) % 6) * 125, 50 + math.floor((i - 1) / 6) * 130)
			cell.BackgroundColor3 = Color3.fromRGB(70, 140, 70)
			cell.ZIndex = 101
			local img = Instance.new("ImageLabel")
			img.Size = UDim2.fromOffset(100, 100)
			img.Position = UDim2.fromOffset(10, 0)
			img.BackgroundTransparency = 1
			img.ScaleType = Enum.ScaleType.Fit
			img.Image = "rbxassetid://" .. tostring(u.id)
			img.ZIndex = 102
			img.Parent = cell
			local lbl = Instance.new("TextLabel")
			lbl.Size = UDim2.new(1, 0, 0, 22)
			lbl.Position = UDim2.fromOffset(0, 102)
			lbl.BackgroundTransparency = 1
			lbl.TextColor3 = Color3.new(1, 1, 1)
			lbl.TextScaled = true
			lbl.Text = tostring(u.id)
			lbl.ZIndex = 102
			lbl.Parent = cell
			cell.Parent = panel
		end
		local close = Instance.new("TextButton")
		close.Size = UDim2.fromOffset(40, 40)
		close.Position = UDim2.new(1, -45, 0, 0)
		close.Text = "X"
		close.ZIndex = 103
		close.Parent = panel
		close.Activated:Connect(function()
			panel:Destroy()
		end)
		panel.Parent = gui
	end
	return changed
end

-- Шрифт как на нарисованных счётчиках: круглый жирный (FredokaOne)
local COUNTER_FONT = Enum.Font.FredokaOne
local function applyCounterFont()
	for _, path in ipairs({
		"Stats.WinsRow.Value", "Stats.StrengthRow.Value", "Stats.LuckRow.Value", "Stats.RebirthRow.Value",
		"Stats.WinsRow.Title", "Stats.StrengthRow.Title", "Stats.LuckRow.Title", "Stats.RebirthRow.Title",
		"PowerPanel.StrengthBig", "PowerPanel.LevelBar.Level", "PowerPanel.LevelBar.Xp",
		"PowerPanel.XpButtons.XpSmallButton", "PowerPanel.XpButtons.XpMediumButton", "PowerPanel.XpButtons.XpBigButton",
		"PowerPanel.PowerStrikeButton.Text",
	}) do
		local l = find(path)
		if l and (l:IsA("TextLabel") or l:IsA("TextButton")) then
			l.Font = COUNTER_FONT
		end
	end
end

-- Свои кнопки: любой кнопке или картинке в StarterGui добавьте атрибут OpenPanel
-- (Properties › Attributes › + › имя OpenPanel, тип string) со значением, например, Shop.
-- Игра сама откроет нужное окно по нажатию — скрипт в кнопку вставлять не нужно.
local PANEL_ALIASES = {
	shop = "ShopPanel", ["магазин"] = "ShopPanel",
	pets = "PetsPanel", ["питомцы"] = "PetsPanel",
	auras = "AurasPanel", ["ауры"] = "AurasPanel",
	rebirth = "RebirthPanel", ["перерождение"] = "RebirthPanel",
	wheel = "WheelPanel", ["колесо"] = "WheelPanel",
	rewards = "RewardsPanel", ["подарки"] = "RewardsPanel", ["подарок"] = "RewardsPanel",
	quests = "QuestsPanel", ["задания"] = "QuestsPanel",
	settings = "SettingsPanel", ["настройки"] = "SettingsPanel",
	achievements = "AchievementsPanel", ["достижения"] = "AchievementsPanel",
}

local function panelFromAttribute(value: any): string?
	if typeof(value) ~= "string" or value == "" then
		return nil
	end
	local key = string.lower(value)
	return PANEL_ALIASES[key] or (string.sub(value, -5) == "Panel" and value) or (value .. "Panel")
end

local bound = setmetatable({}, { __mode = "k" })
local function bindCustom(obj: Instance)
	if bound[obj] or not obj:IsA("GuiObject") then
		return
	end
	if obj:GetAttribute("OpenPanel") == nil then
		return
	end
	bound[obj] = true
	local function open()
		local name = panelFromAttribute(obj:GetAttribute("OpenPanel"))
		if name then
			Panels.Toggle(name)
		else
			warn("[OpenPanel] у", obj:GetFullName(), "пустой атрибут OpenPanel")
		end
	end
	if obj:IsA("GuiButton") then
		obj.Activated:Connect(open)
	else
		obj.Active = true
		obj.InputBegan:Connect(function(input)
			local t = input.UserInputType
			if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
				open()
			end
		end)
	end
end

local function watchCustomButtons(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		bindCustom(d)
	end
	root.DescendantAdded:Connect(function(d)
		task.defer(bindCustom, d)
	end)
end

function Hud.Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = (pg:WaitForChild("MainHud", 5) or Instance.new("ScreenGui", pg)) :: ScreenGui
	applyIcons()
	applySkins()
	applyCounterFont()
	task.spawn(function()
		if resolveUnsorted() then
			applyIcons()
			applySkins()
			refreshStats()
		end
	end)
	bindButton("LeftMenu.ShopButton", "ShopPanel")
	bindButton("LeftMenu.PetsButton", "PetsPanel")
	bindButton("LeftMenu.AurasButton", "AurasPanel")
	bindButton("LeftMenu.RebirthButton", "RebirthPanel")
	bindButton("TopRight.WheelButton", "WheelPanel")
	bindButton("TopRight.AchievementsButton", "AchievementsPanel")
	bindButton("TopRight.RewardsButton", "RewardsPanel")
	bindButton("TopRight.QuestsButton", "QuestsPanel")
	bindButton("TopRight.SettingsButton", "SettingsPanel")
	watchCustomButtons(Players.LocalPlayer:WaitForChild("PlayerGui"))

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
