-- Format — красивый вывод чисел: 1250 → "1.25K", 3190 → "3,190"
local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Short(n: number): string
	n = tonumber(n) or 0
	if math.abs(n) < 1000 then
		return tostring(math.floor(n))
	end
	local i = 0
	while math.abs(n) >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local s = string.format(n >= 100 and "%.0f" or (n >= 10 and "%.1f" or "%.2f"), n)
	if s:find("%.") then
		s = s:gsub("0+$", ""):gsub("%.$", "")
	end
	return s .. SUFFIXES[i]
end

-- С разделителями тысяч (до миллиона), дальше — короткий вид
function Format.Comma(n: number): string
	n = math.floor(tonumber(n) or 0)
	if math.abs(n) >= 1e6 then
		return Format.Short(n)
	end
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return (n < 0 and "-" or "") .. out
end

function Format.Time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return Format
