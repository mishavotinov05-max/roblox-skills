--[[
	PitConfig — ямы прокачки силы в лобби.

	Порядок в списке = номер ямы на карте: 1-я строка — Pit_01, 2-я — Pit_02 …
	(Workspace › Hub › Pits).

	RequiredRebirths — сколько перерождений нужно, чтобы яма открылась.
	Power            — сколько силы даёт один удар в этой яме (до множителей).

	На карте 12 мест. Ямы без строки в этом списке показываются как «Свободное место».
	Чтобы открыть новую яму — допишите строку (она займёт следующий свободный Pit_XX).
]]

return {
	Pits = {
		{ Name = "Землянка", RequiredRebirths = 0, Power = 1 },
		{ Name = "Угольная", RequiredRebirths = 2, Power = 3 },
		{ Name = "Каменная", RequiredRebirths = 5, Power = 8 },
		{ Name = "Железная", RequiredRebirths = 10, Power = 20 },
		{ Name = "Золотая", RequiredRebirths = 20, Power = 50 },
		{ Name = "Алмазная", RequiredRebirths = 40, Power = 120 },
	},
}
