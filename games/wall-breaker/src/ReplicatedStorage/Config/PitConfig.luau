--[[
	PitConfig — ямы прокачки силы в лобби.

	Порядок в списке = номер ямы на карте: 1-я строка — Pit_01, 2-я — Pit_02 …
	(Workspace › Hub › Pits).

	RequiredRebirths — сколько перерождений нужно, чтобы яма открылась.
	Power            — сколько силы даёт один удар в этой яме (до множителей).
	                   Удар по воздуху даёт GameSettings.AirSwingPower (1), поэтому в яме всегда ×2 и больше.
	В открытой яме кирка бьёт сама (GameSettings.PitAutoInterval), клики добавляют удары.

	На карте 6 мест (Pit_01…Pit_06). Чтобы добавить яму — допишите строку и скопируйте модель Pit_06 → Pit_07.
]]

return {
	Pits = {
		{ Name = "Землянка", RequiredRebirths = 0, Power = 2 },
		{ Name = "Угольная", RequiredRebirths = 2, Power = 6 },
		{ Name = "Каменная", RequiredRebirths = 5, Power = 16 },
		{ Name = "Железная", RequiredRebirths = 10, Power = 40 },
		{ Name = "Золотая", RequiredRebirths = 20, Power = 100 },
		{ Name = "Алмазная", RequiredRebirths = 40, Power = 240 },
	},
}
