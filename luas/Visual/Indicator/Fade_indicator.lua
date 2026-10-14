local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
	local output = ''
	local len = #text-1
	local rinc = (r2 - r1) / len
	local ginc = (g2 - g1) / len
	local binc = (b2 - b1) / len
	local ainc = (a2 - a1) / len
	for i=1, len+1 do
		output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
		r1 = r1 + rinc
		g1 = g1 + ginc
		b1 = b1 + binc
		a1 = a1 + ainc
	end
	return output
end

client.set_event_callback('paint', function()
	renderer.indicator(255, 255, 255, 255, gradient_text(255,255,255,255,129,114,135,255,"(T^T)"))
end)