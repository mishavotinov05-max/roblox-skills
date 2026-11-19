--[[
	Panels — окна магазина, питомцев, аур, перерождения, колеса, наград, заданий, достижений, настроек.

	Каждое окно лежит в StarterGui › MainHud › Panels. Внутри окна есть скрытая карточка "Template":
	её можно перекрасить и передвинуть элементы — все карточки в списке будут такими же.
]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local PickaxeConfig = require(Config:WaitForChild("PickaxeConfig"))
local AuraConfig = require(Config:WaitForChild("AuraConfig"))
local ShopConfig = require(Config:WaitForChild("ShopConfig"))
local WheelConfig = require(Config:WaitForChild("WheelConfig"))
local RewardsConfig = require(Config:WaitForChild("RewardsConfig"))
local RebirthConfig = require(Config:WaitForChild("RebirthConfig"))
local PetConfig = require(Config:WaitForChild("PetConfig"))
local IconConfig = require(Config:WaitForChild("IconConfig"))
local Settings = require(Config:WaitForChild("GameSettings"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared:WaitForChild("Format"))
local Formulas = require(Shared:WaitForChild("Formulas"))
local Catalog = require(Shared:WaitForChild("Catalog"))

local Controllers = script.Parent
local State = require(Controllers:WaitForChild("State"))
local Toasts = require(Controllers:WaitForChild("Toasts"))

local Panels = {}
local root: Frame
local openName: string? = nil
local shopTab = "Luck"
local spinning = false
local traderMult = 1
local traderSelected: { [string]: boolean } = {}

local COLOR_BUY = Color3.fromRGB(61, 200, 110)
local COLOR_EQUIP = Color3.fromRGB(63, 140, 255)
local COLOR_DONE = Color3.fromRGB(120, 120, 145)
local COLOR_SPECIAL = Color3.fromRGB(166, 91, 255)

local function panel(name: string): Frame?
	return root and root:FindFirstChild(name) :: Frame?
end

local function act(action: string, ...)
	local res = State.Request(action, ...)
	if res and res.msg then
		Toasts.Show(res.msg, res.ok and "info" or "error")
	end
	return res
end

local function clearList(p: Instance)
	local content = p:FindFirstChild("Content")
	if not content then
		return
	end
	for _, child in ipairs(content:GetChildren()) do
		if child.Name == "Item" then
			child:Destroy()
		end
	end
end

type CardOptions = {
	name: string,
	info: string?,
	fallback: string?,
	image: string?,
	color: Color3?,
	button: string?,
	buttonColor: Color3?,
	onClick: (() -> ())?,
	order: number?,
	highlight: boolean?,
}

local function addCard(p: Instance, o: CardOptions): Frame?
	local template = p:FindFirstChild("Template")
	local content = p:FindFirstChild("Content")
	if not template or not content then
		return nil
	end
	local card = template:Clone() :: Frame
	card.Name = "Item"
	card.Visible = true
	card.LayoutOrder = o.order or 0
	local function text(name: string, value: string?)
		local l = card:FindFirstChild(name)
		if l and l:IsA("TextLabel") then
			l.Text = value or ""
		end
	end
	text("NameLabel", o.name)
	text("InfoLabel", o.info)
	local fallback = card:FindFirstChild("Fallback")
	if fallback and fallback:IsA("TextLabel") then
		fallback.Text = o.fallback or ""
		if o.color then
			fallback.TextColor3 = o.color
		end
	end
	local icon = card:FindFirstChild("Icon")
	if icon and icon:IsA("ImageLabel") and o.image and o.image ~= "rbxassetid://0" then
		icon.Image = o.image
		icon.Visible = true
		if fallback and fallback:IsA("GuiObject") then
			fallback.Visible = false
		end
	end
	if o.highlight then
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = Color3.fromRGB(255, 225, 77)
		end
	end
	local button = card:FindFirstChild("ActionButton")
	if button and button:IsA("TextButton") then
		if o.button then
			button.Text = o.button
			button.BackgroundColor3 = o.buttonColor or COLOR_BUY
			if o.onClick then
				button.Activated:Connect(o.onClick)
			end
		else
			button.Visible = false
		end
	end
	card.Parent = content
	return card
end

local function setLabel(p: Instance, name: string, value: string)
	local l = p:FindFirstChild(name, true)
	if l and (l:IsA("TextLabel") or l:IsA("TextButton")) then
		l.Text = value
	end
end

-- ===== Магазин =====
local function fillShop(p: Frame)
	local data = State.Data
	for _, tab in ipairs({ "Luck", "Donate" }) do
		local tabs = p:FindFirstChild("Tabs")
		local b = tabs and tabs:FindFirstChild(tab .. "Tab")
		if b and b:IsA("TextButton") then
			b.BackgroundColor3 = tab == shopTab and Color3.fromRGB(255, 196, 61) or Color3.fromRGB(90, 70, 160)
		end
	end
	if shopTab == "Luck" then
		local maxed = data.LuckPercent >= ShopConfig.Luck.MaxPercent
		for i, offer in ipairs(ShopConfig.Luck.Offers) do
			local cost = Formulas.LuckOfferCost(offer, data.LuckBought[offer.Id] or 0)
			addCard(p, {
				name = offer.Name,
				info = ("+%d%% удачи · сейчас %s%%"):format(offer.Percent, Format.Short(Formulas.LuckPercent(data, State.HasPass("LuckX2")))),
				fallback = offer.Emoji or "🍀",
				image = i == 1 and IconConfig.Luck or nil,
				button = maxed and "Максимум" or ("🏆 " .. Format.Short(cost)),
				buttonColor = maxed and COLOR_DONE or (data.Wins >= cost and COLOR_BUY or COLOR_DONE),
				onClick = function()
					act("BuyLuck", offer.Id)
				end,
				order = i,
			})
		end
	else
		for i, key in ipairs(ShopConfig.GamePassOrder) do
			local pass = ShopConfig.GamePasses[key]
			local has = State.HasPass(key)
			addCard(p, {
				name = pass.Name,
				info = pass.Description,
				fallback = "⭐",
				image = IconConfig[pass.Icon],
				button = has and "Куплено" or "Купить",
				buttonColor = has and COLOR_DONE or COLOR_SPECIAL,
				onClick = function()
					if not has then
						act("BuyPass", key)
					end
				end,
				order = i,
			})
		end
		for i, product in ipairs(ShopConfig.Products) do
			if product.Hidden then
				continue
			end
			addCard(p, {
				name = product.Name,
				info = "Можно покупать много раз",
				fallback = product.Spins and "🎡" or "🏆",
				button = "Купить",
				buttonColor = COLOR_SPECIAL,
				onClick = function()
					act("BuyProduct", product.Key)
				end,
				order = 100 + i,
			})
		end
	end
end

-- ===== Питомцы =====
local function fillPets(p: Frame)
	local data = State.Data
	setLabel(p, "Info", ("Надето %d/%d · множитель силы ×%s · яйца стоят в лобби у южной стены"):format(
		#data.EquippedPets,
		Settings.MaxEquippedPets,
		Format.Short(Formulas.PetMultiplier(data))
	))
	local pets = table.clone(data.Pets)
	table.sort(pets, function(a, b)
		local da, db = Catalog.Pets[a.Id], Catalog.Pets[b.Id]
		return (da and da.Bonus or 0) > (db and db.Bonus or 0)
	end)
	if #pets == 0 then
		addCard(p, { name = "Пока нет питомцев", info = "Открой яйцо в лобби!", fallback = "🥚" })
	end
	for i, pet in ipairs(pets) do
		local def = PetConfig.Pets[pet.Id]
		if def then
			local equipped = table.find(data.EquippedPets, pet.Uid) ~= nil
			local card = addCard(p, {
				name = def.Name,
				info = ("%s · +%s к силе"):format(def.Rarity, tostring(def.Bonus)),
				fallback = "🐾",
				color = def.Color,
				button = equipped and "Снять" or "Надеть",
				buttonColor = equipped and COLOR_DONE or COLOR_EQUIP,
				onClick = function()
					act(equipped and "UnequipPet" or "EquipPet", pet.Uid)
				end,
				order = i,
				highlight = equipped,
			})
			local del = card and card:FindFirstChild("DeleteButton")
			if del and del:IsA("TextButton") then
				del.Activated:Connect(function()
					act("DeletePet", pet.Uid)
				end)
			end
		end
	end
end

-- ===== Ауры =====
local function fillAuras(p: Frame)
	local data = State.Data
	for i, aura in ipairs(AuraConfig.Auras) do
		local owned = data.Auras[aura.Id]
		local equipped = data.EquippedAura == aura.Id
		local label
		if equipped then
			label = "Снять"
		elseif owned then
			label = "Надеть"
		elseif aura.Price > 0 then
			label = "Купить"
		else
			label = "Колесо"
		end
		addCard(p, {
			name = aura.Name,
			info = ("Сила ×%s · %s"):format(tostring(aura.Multiplier), owned and "есть" or (aura.Price > 0 and (Format.Short(aura.Price) .. " побед") or "только из колеса")),
			fallback = "✨",
			color = aura.Color,
			button = label,
			buttonColor = equipped and COLOR_DONE or (owned and COLOR_EQUIP or (aura.Price > 0 and COLOR_BUY or COLOR_SPECIAL)),
			onClick = function()
				if equipped then
					act("EquipAura", "")
				elseif owned then
					act("EquipAura", aura.Id)
				elseif aura.Price > 0 then
					act("BuyAura", aura.Id)
				else
					Panels.Open("WheelPanel")
				end
			end,
			order = i,
			highlight = equipped,
		})
	end
end

-- ===== Перерождение =====
local function fillRebirth(p: Frame)
	local data = State.Data
	local cost = State.Snapshot.RebirthCost or Formulas.RebirthCost(data.Rebirths)
	local needLevel = State.Snapshot.RebirthLevel or Formulas.RebirthLevel(data.Rebirths)
	setLabel(p, "Info", ("Перерождений: %d\n\nНужен уровень: %d (сейчас %d)%s\nНаграда: +%d%% силы навсегда (сейчас ×%s) и новые ямы\n\nСбросится: сила, уровень, кирки и стены.\nОстанутся: питомцы, ауры, удача и победы."):format(
		data.Rebirths,
		needLevel,
		data.PlayerLevel or 1,
		cost > 0 and ("\nЦена: " .. Format.Short(cost) .. " побед") or "",
		math.floor(RebirthConfig.StrengthBonusPerRebirth * 100),
		tostring(Formulas.RebirthMultiplier(data))
	))
	setLabel(p, "RebirthButton", (data.PlayerLevel or 1) >= needLevel and "Переродиться!" or ("Нужен уровень " .. needLevel))
end

-- ===== Колесо =====
local wheelBuilt = false
local function buildWheel(p: Frame)
	if wheelBuilt then
		return
	end
	local disc = p:FindFirstChild("Disc", true)
	if not disc then
		return
	end
	wheelBuilt = true
	local discImage = disc:FindFirstChild("DiscImage")
	if discImage and discImage:IsA("ImageLabel") and IconConfig.WheelDisc ~= "rbxassetid://0" then
		discImage.Image = IconConfig.WheelDisc
	end
	local n = #WheelConfig.Prizes
	for i, prize in ipairs(WheelConfig.Prizes) do
		local a = math.rad((i - 0.5) * 360 / n)
		local label = Instance.new("TextLabel")
		label.Name = "Prize" .. i
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Size = UDim2.fromScale(0.3, 0.12)
		label.Position = UDim2.fromScale(0.5 + 0.33 * math.sin(a), 0.5 - 0.33 * math.cos(a))
		label.Rotation = math.deg(a)
		label.BackgroundColor3 = prize.Color
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = prize.Text
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.4, 0)
		corner.Parent = label
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Color = Color3.fromRGB(26, 16, 51)
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = label
		label.Parent = disc
	end
	local buy = p:FindFirstChild("BuySpinButton", true)
	if buy and buy:IsA("GuiButton") then
		buy.Activated:Connect(function()
			act("BuyProduct", "spin")
		end)
	end
	local spin = p:FindFirstChild("SpinButton", true)
	if spin and spin:IsA("TextButton") then
		spin.Activated:Connect(function()
			if spinning then
				return
			end
			spinning = true
			local res = State.Request("SpinWheel")
			if not res or not res.ok then
				spinning = false
				if res and res.msg then
					Toasts.Show(res.msg, "error")
				end
				return
			end
			local d = disc :: GuiObject
			local center = (res.index - 0.5) * 360 / n
			local current = d.Rotation % 360
			local target = d.Rotation - current + 360 * 5 + (360 - center)
			local tween = TweenService:Create(d, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = target })
			tween:Play()
			tween.Completed:Wait()
			Toasts.Show("Выигрыш: " .. res.text, "wins")
			spinning = false
		end)
	end
end

local function fillWheel(p: Frame)
	buildWheel(p)
	local data = State.Data
	local remaining = State.Countdown("WheelReadyIn")
	local text
	if remaining <= 0 then
		text = "Бесплатное вращение готово!"
	else
		text = "Бесплатно через " .. Format.Time(remaining)
	end
	if data.Wheel.ExtraSpins > 0 then
		text ..= ("  ·  доп. вращений: %d"):format(data.Wheel.ExtraSpins)
	end
	setLabel(p, "Timer", text)
	-- если бесплатное вращение ещё не готово — показываем кнопку покупки за Robux
	local free = remaining <= 0 or data.Wheel.ExtraSpins > 0
	local spin = p:FindFirstChild("SpinButton", true)
	local buy = p:FindFirstChild("BuySpinButton", true)
	if spin and spin:IsA("TextButton") then
		spin.Text = free and "Крутить!" or Format.Time(remaining)
		spin.BackgroundColor3 = free and Color3.fromRGB(255, 160, 40) or COLOR_DONE
	end
	if buy and buy:IsA("GuiObject") then
		buy.Visible = not free
	end
end

-- ===== Ежедневные награды =====
local function fillRewards(p: Frame)
	local data = State.Data
	local remaining = State.Countdown("DailyReadyIn")
	local list = RewardsConfig.DailyRewards
	local nextDay = ((data.Daily.Streak) % #list) + 1
	for i, reward in ipairs(list) do
		addCard(p, {
			name = "День " .. i,
			info = "+" .. Format.Short(reward) .. " побед",
			fallback = "🎁",
			order = i,
			highlight = i == nextDay,
		})
	end
	setLabel(p, "Info", remaining <= 0 and "Награда готова!" or ("Следующая награда через " .. Format.Time(remaining)))
	setLabel(p, "ClaimButton", remaining <= 0 and "Забрать" or Format.Time(remaining))
end

-- ===== Задания и достижения =====
local function fillQuests(p: Frame)
	local data = State.Data
	local progress = State.Snapshot.QuestProgress or {}
	for i, quest in ipairs(RewardsConfig.DailyQuests) do
		local value = math.min(progress[quest.Id] or 0, quest.Goal)
		local claimed = data.Quests.Claimed[quest.Id]
		local done = value >= quest.Goal
		addCard(p, {
			name = quest.Text,
			info = ("%s / %s · награда %s побед"):format(Format.Short(value), Format.Short(quest.Goal), Format.Short(quest.Reward)),
			fallback = "📅",
			button = claimed and "Получено" or (done and "Забрать" or "В процессе"),
			buttonColor = claimed and COLOR_DONE or (done and COLOR_BUY or COLOR_DONE),
			onClick = function()
				if done and not claimed then
					act("ClaimQuest", quest.Id)
				end
			end,
			order = i,
		})
	end
	setLabel(p, "Info", "Новые задания через " .. Format.Time(State.Countdown("QuestResetIn")))
end

local function fillAchievements(p: Frame)
	local data = State.Data
	for i, ach in ipairs(RewardsConfig.Achievements) do
		local value = math.min(data.Stats[ach.Stat] or 0, ach.Goal)
		local claimed = data.Achievements[ach.Id]
		local done = value >= ach.Goal
		addCard(p, {
			name = ach.Text,
			info = ("%s / %s · награда %s побед"):format(Format.Short(value), Format.Short(ach.Goal), Format.Short(ach.Reward)),
			fallback = "🏆",
			button = claimed and "Получено" or (done and "Забрать" or "В процессе"),
			buttonColor = claimed and COLOR_DONE or (done and COLOR_BUY or COLOR_DONE),
			onClick = function()
				if done and not claimed then
					act("ClaimAchievement", ach.Id)
				end
			end,
			order = (claimed and 1000 or 0) + i,
		})
	end
end

local function fillSettings(p: Frame)
	local data = State.Data
	local hasAuto = State.HasPass("AutoClick")
	addCard(p, {
		name = "Автоклик",
		info = hasAuto and "Кирка бьёт сама, пока она в руках" or "Нужен геймпасс «Автоклик» (Магазин › Донат)",
		fallback = "🤖",
		button = hasAuto and (data.Settings.AutoClick and "Вкл" or "Выкл") or "Магазин",
		buttonColor = (hasAuto and data.Settings.AutoClick) and COLOR_BUY or COLOR_DONE,
		onClick = function()
			if hasAuto then
				act("SetSetting", "AutoClick", not data.Settings.AutoClick)
			else
				shopTab = "Donate"
				Panels.Open("ShopPanel")
			end
		end,
		order = 1,
	})
	addCard(p, {
		name = "Показывать питомцев",
		info = "Питомцы других игроков",
		fallback = "🐾",
		button = data.Settings.ShowPets and "Вкл" or "Выкл",
		buttonColor = data.Settings.ShowPets and COLOR_BUY or COLOR_DONE,
		onClick = function()
			act("SetSetting", "ShowPets", not data.Settings.ShowPets)
		end,
		order = 2,
	})
	addCard(p, {
		name = "Вернуться в лобби",
		info = "Телепорт к яйцам и ямам",
		fallback = "🏠",
		button = "В лобби",
		buttonColor = COLOR_EQUIP,
		onClick = function()
			act("GoToLobby")
			Panels.Close()
		end,
		order = 3,
	})
end

-- ===== Торговец рудами =====
local function fillTrader(p: Frame)
	local data = State.Data
	local OreConfig = require(Config:WaitForChild("OreConfig"))
	local total, selectedTotal, any = 0, 0, false
	for i, ore in ipairs(OreConfig.Ores) do
		local n = data.Ores[ore.Id] or 0
		if n > 0 then
			any = true
			local price = ore.Price * traderMult
			total += price * n
			local selected = traderSelected[ore.Id] == true
			if selected then
				selectedTotal += price * n
			end
			addCard(p, {
				name = ("%s ×%d"):format(ore.Name, n),
				info = ("%s 🏆 за штуку · всего %s 🏆"):format(Format.Short(price), Format.Short(price * n)),
				fallback = "⬤",
				color = ore.Color,
				button = selected and "✓ Выбрано" or "Выбрать",
				buttonColor = selected and COLOR_BUY or COLOR_DONE,
				onClick = function()
					traderSelected[ore.Id] = not selected or nil
					Panels.Refresh()
				end,
				order = i,
				highlight = selected,
			})
		end
	end
	if not any then
		addCard(p, { name = "Нет руд", info = "Ломай стены — руды выпадают из слоёв", fallback = "⛏" })
	end
	setLabel(p, "Total", ("Выбрано: %s 🏆  ·  Всё: %s 🏆%s"):format(
		Format.Short(selectedTotal),
		Format.Short(total),
		traderMult > 1 and ("  (цены ×" .. tostring(traderMult) .. ")") or ""
	))
end

local FILLERS = {
	TraderPanel = fillTrader,
	ShopPanel = fillShop,
	PetsPanel = fillPets,
	AurasPanel = fillAuras,
	RebirthPanel = fillRebirth,
	WheelPanel = fillWheel,
	RewardsPanel = fillRewards,
	QuestsPanel = fillQuests,
	AchievementsPanel = fillAchievements,
	SettingsPanel = fillSettings,
}

function Panels.Refresh()
	if not openName or not State.Data then
		return
	end
	local p = panel(openName)
	local filler = FILLERS[openName]
	if p and filler then
		clearList(p)
		filler(p)
	end
end

function Panels.Open(name: string)
	if not root then
		return
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = child.Name == name
		end
	end
	openName = name
	local p = panel(name)
	if p then
		local scale = p:FindFirstChildOfClass("UIScale")
		if scale then
			scale.Scale = 0.85
			TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	Panels.Refresh()
end

function Panels.Close()
	if not root then
		return
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = false
		end
	end
	openName = nil
end

function Panels.Toggle(name: string)
	if openName == name then
		Panels.Close()
	else
		Panels.Open(name)
	end
end

function Panels.Init()
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainHud")
	root = gui:WaitForChild("Panels") :: Frame
	for _, p in ipairs(root:GetChildren()) do
		local close = p:FindFirstChild("CloseButton", true)
		if close and close:IsA("GuiButton") then
			close.Activated:Connect(Panels.Close)
		end
		local template = p:FindFirstChild("Template")
		if template and template:IsA("GuiObject") then
			template.Visible = false
		end
	end
	-- Вкладки магазина
	local shop = panel("ShopPanel")
	local tabs = shop and shop:FindFirstChild("Tabs")
	if tabs then
		for _, tab in ipairs({ "Luck", "Donate" }) do
			local b = tabs:FindFirstChild(tab .. "Tab")
			if b and b:IsA("GuiButton") then
				b.Activated:Connect(function()
					shopTab = tab
					Panels.Refresh()
				end)
			end
		end
	end
	-- Кнопки окон
	local pets = panel("PetsPanel")
	local best = pets and pets:FindFirstChild("EquipBestButton", true)
	if best and best:IsA("GuiButton") then
		best.Activated:Connect(function()
			act("EquipBestPets")
		end)
	end
	local rebirth = panel("RebirthPanel")
	local rb = rebirth and rebirth:FindFirstChild("RebirthButton", true)
	if rb and rb:IsA("GuiButton") then
		rb.Activated:Connect(function()
			act("Rebirth")
		end)
	end
	-- Торговец: выделить все / продать выбранное / продать все
	local trader = panel("TraderPanel")
	if trader then
		local function bindT(name: string, fn)
			local b = trader:FindFirstChild(name, true)
			if b and b:IsA("GuiButton") then
				b.Activated:Connect(fn)
			end
		end
		bindT("SelectAllButton", function()
			local OreConfig = require(Config:WaitForChild("OreConfig"))
			local all = true
			for _, ore in ipairs(OreConfig.Ores) do
				if (State.Data.Ores[ore.Id] or 0) > 0 and not traderSelected[ore.Id] then
					all = false
				end
			end
			for _, ore in ipairs(OreConfig.Ores) do
				traderSelected[ore.Id] = (not all) or nil
			end
			Panels.Refresh()
		end)
		bindT("SellSelectedButton", function()
			local ids = {}
			for id in pairs(traderSelected) do
				table.insert(ids, id)
			end
			if #ids == 0 then
				Toasts.Show("Сначала выбери руды", "error")
				return
			end
			act("SellOres", ids)
			traderSelected = {}
		end)
		bindT("SellAllButton", function()
			act("SellOres", nil)
			traderSelected = {}
		end)
	end
	game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Effect").OnClientEvent:Connect(function(kind, a)
		if kind == "OpenTrader" then
			traderMult = a or 1
			traderSelected = {}
			Panels.Open("TraderPanel")
		end
	end)

	local rewards = panel("RewardsPanel")
	local claim = rewards and rewards:FindFirstChild("ClaimButton", true)
	if claim and claim:IsA("GuiButton") then
		claim.Activated:Connect(function()
			act("ClaimDaily")
		end)
	end

	Panels.Close()
	State.Changed:Connect(function()
		if openName ~= "WheelPanel" or not spinning then
			Panels.Refresh()
		end
	end)
	-- Таймеры обновляются раз в секунду
	task.spawn(function()
		while true do
			task.wait(1)
			if openName == "WheelPanel" or openName == "RewardsPanel" or openName == "QuestsPanel" then
				if not spinning then
					Panels.Refresh()
				end
			end
		end
	end)
end

return Panels
