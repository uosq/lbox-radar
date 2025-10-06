local base64 = require("src/base64")
local frameLoadLimit = 3

local icons = {
    list = {},
    pending = {},
    loaded = 0,
    is_loading = true,
    folder = "tf/radar/icons/",
    urls = {
        scout    = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/scout.lua",
        sniper   = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/sniper.lua",
        soldier  = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/soldier.lua",
        demo     = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/demo.lua",
        medic    = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/medic.lua",
        heavy    = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/heavy.lua",
        pyro     = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/pyro.lua",
        spy      = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/spy.lua",
        engineer = "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/engineer.lua",
    }
}

-- Prepare file list
for name, url in pairs(icons.urls) do
    table.insert(icons.pending, { name = name, url = url })
end

filesystem.CreateDirectory("tf/radar")
filesystem.CreateDirectory("tf/radar/icons")

local function fileExists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

function icons.load()
    if not icons.is_loading then return end
    if #icons.pending == 0 then
        icons.is_loading = false
        print(string.format("Radar - Loaded %d icons.", icons.loaded))
        return
    end

    local count = 0
    while #icons.pending > 0 and count < frameLoadLimit do
        local entry = table.remove(icons.pending, 1)
        local filepath = icons.folder .. entry.name .. ".lua"

        local content

        if fileExists(filepath) then
            -- Load from disk
            local f = io.open(filepath, "r")
            if f then
                content = f:read("a")
                f:close()
            end
        else
            -- Download and save for future use
            local ok, result = pcall(http.Get, entry.url)
            if ok and result then
                content = result
                local f = io.open(filepath, "w")
                if f then
                    f:flush()
                    f:write(result)
                    f:close()
                else
                    print("Radar - Failed to write icon: " .. filepath)
                end
            else
                print("Radar - Failed to download: " .. entry.url)
            end
        end

        if content then
            local success, texture = pcall(base64.createTextureFromRGBA, content)
            if success and texture then
                icons.loaded = icons.loaded + 1
                icons.list[icons.loaded] = texture
            else
                print("Radar - Failed to create texture for: " .. entry.name)
            end
        end

        count = count + 1
    end
end

function icons.cleanup()
    for _, tex in ipairs(icons.list) do
        draw.DeleteTexture(tex)
    end
end

return icons
