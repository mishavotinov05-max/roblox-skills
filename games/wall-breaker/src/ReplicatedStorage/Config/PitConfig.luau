--[[
	PitConfig — ямы прокачки силы в лобби (как на картинке-референсе).

	Порядок в списке = номер ямы на карте: 1-я строка — Pit_01, 2-я — Pit_02 …
	(Workspace › Map › Hub › Pits).

	RequiredRebirths — сколько перерождений нужно, чтобы яма открылась.
	Power            — сколько силы даёт один удар в этой яме (до множителей).
	                   Удар по воздуху даёт GameSettings.AirSwingPower (1), в ямах — больше.
	В открытой яме кирка бьёт сама (GameSettings.PitAutoInterval), клики добавляют удары.
	Опыт (уровень) тоже качается только в ямах.

	Чтобы добавить яму: допишите строку и скопируйте модель Pit_07 → Pit_08.
]]

return {
	Pits = {
		{ Name = "Обычная яма", RequiredRebirths = 0, Power = 2 },
		{ Name = "Угольная яма", RequiredRebirths = 3, Power = 6 },
		{ Name = "Каменная яма", RequiredRebirths = 9, Power = 16 },
		{ Name = "Железная яма", RequiredRebirths = 18, Power = 40 },
		{ Name = "Золотая яма", RequiredRebirths = 36, Power = 100 },
		{ Name = "Алмазная яма", RequiredRebirths = 50, Power = 240 },
		{ Name = "Мифическая яма", RequiredRebirths = 65, Power = 600 },
	},
}
