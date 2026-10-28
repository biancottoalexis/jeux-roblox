-- Affichage des grands nombres : 1 250 -> "1.25K", 3 400 000 -> "3.4M"

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.Short(n: number): string
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local index = math.min(math.floor(math.log10(n) / 3), #SUFFIXES - 1)
	local value = n / 10 ^ (index * 3)
	local text = if value >= 100 then tostring(math.floor(value)) else string.format("%.3g", value)
	return text .. SUFFIXES[index + 1]
end

-- Durée : 3725 -> "1 h 02 min"
function Format.Duration(seconds: number): string
	seconds = math.floor(seconds)
	local hours = seconds // 3600
	local minutes = (seconds % 3600) // 60
	if hours > 0 then
		return string.format("%d h %02d min", hours, minutes)
	end
	if minutes > 0 then
		return `{minutes} min`
	end
	return `{seconds} s`
end

return Format
