--[[
    CREDITS: titaniummachine1 "Terminator"
    - https://github.com/titaniummachine1/lua-image-embeding
]]

local base64 = {}
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local lookup = {}
for i = 1, #chars do lookup[chars:sub(i, i)] = i - 1 end

function base64.decode(data)
    data = data:gsub("%s+", ""):gsub("=+$", "")
    local decoded = {}
    for i = 1, #data, 4 do
        local chunk, n = data:sub(i, i + 3), 0
        for j = 1, #chunk do n = n * 64 + lookup[chunk:sub(j, j)] end
        if #chunk >= 2 then decoded[#decoded + 1] = string.char((n >> 16) & 0xFF) end
        if #chunk >= 3 then decoded[#decoded + 1] = string.char((n >> 8) & 0xFF) end
        if #chunk >= 4 then decoded[#decoded + 1] = string.char(n & 0xFF) end
    end
    return table.concat(decoded)
end

function base64.createTextureFromRGBA(data)
    local raw = base64.decode(data)
    local width = (raw:byte(1) << 24) + (raw:byte(2) << 16) + (raw:byte(3) << 8) + raw:byte(4)
    local height = (raw:byte(5) << 24) + (raw:byte(6) << 16) + (raw:byte(7) << 8) + raw:byte(8)
    local rgba = raw:sub(9)
    assert(#rgba == width * height * 4, "Invalid RGBA data length")
    return draw.CreateTextureRGBA(rgba, width, height)
end

return base64
