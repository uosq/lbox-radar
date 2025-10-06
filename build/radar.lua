-- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
--- made by navet
--- radar

local icons = require("src/icons")
local config = require("src/config")
local radar = require("src/radar")

local function Draw()
    icons.load()
    if icons.is_loading then return end

    local plocal = entities.GetLocalPlayer()
    if plocal == nil then return end

    radar.DrawBackground()

    if config.healthbar then
        radar.DrawHealthbar(plocal)
    end

    local players = entities.FindByClass("CTFPlayer")
    radar.DrawPlayers(plocal, players)
end

local function Unload()
    icons.cleanup()
    radar.cleanup()
end

callbacks.Register("Draw", Draw)
callbacks.Register("Unload", Unload)

end)
__bundle_register("src/radar", function(require, _LOADED, __bundle_register, __bundle_modules)
local window = {}

local config = require("src/config")
local icons = require("src/icons")

local oldmx, oldmy, lastclicktick = 0, 0, 0
local x, y = 300, 300
local dragging = false

local white_texture = draw.CreateTextureRGBA(string.rep(string.char(255, 255, 255, 255), 4), 2, 2)
local red, blu = { 191, 97, 106 }, { 136, 192, 208 }

local cos, sin, sqrt = math.cos, math.sin, math.sqrt

---@param texture TextureID
---@param centerX integer
---@param centerY integer
---@param radius integer
---@param segments integer
local function DrawFilledCircle(texture, centerX, centerY, radius, segments)
    local vertices = {}

    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2

        --- fuck you lsp
        ---@diagnostic disable-next-line: redefined-local
        local x = centerX + cos(angle) * radius

        --- fuck you lsp
        ---@diagnostic disable-next-line: redefined-local
        local y = centerY + sin(angle) * radius
        vertices[i + 1] = { x, y, 0, 0 }
    end

    draw.TexturedPolygon(texture, vertices, false)
end

local function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end

function window.DrawBackground()
    local size = config.size
    local circular = config.circular
    local sw, sh = draw.GetScreenSize()
    local background_transparency = config.background_transparency
    local light_mode = config.light_mode

    if gui.IsMenuOpen() then
        local mouse = input.GetMousePos()
        local mx, my = mouse[1], mouse[2]
        local dx, dy = mx - oldmx, my - oldmy

        local state, tick = input.IsButtonPressed(E_ButtonCode.MOUSE_LEFT)
        if state and tick > lastclicktick then
            if mx >= x and mx <= x + size and my >= y and my <= y + size then
                dragging = true
            end
        end

        if input.IsButtonReleased(E_ButtonCode.MOUSE_LEFT) then
            dragging = false
        end

        if dragging then
            if (x + dx) > 0 and (x + dx) < sw - size then
                x = x + dx
            end

            if (y + dy) > 0 and (y + dy) < sh - size then
                y = y + dy
            end
        end

        draw.Color(192, 192, 192, 255)
        draw.OutlinedRect(x, y, x + size, y + size)

        oldmx, oldmy = mx, my
    end

    if circular == false then
        draw.Color(blu[1], blu[2], blu[3], 255)
        draw.OutlinedRect(x - 1, y - 1, x + size + 1, y + size + 1)

        if light_mode then
            draw.Color(236, 239, 244, background_transparency)
        else
            draw.Color(46, 52, 64, background_transparency)
        end
        draw.FilledRect(x, y, x + size, y + size)
    else
        local halfSize = size // 2
        local centerX, centerY = x + halfSize, y + halfSize
        draw.Color(blu[1], blu[2], blu[3], 255)
        draw.OutlinedCircle(centerX, centerY, halfSize, 64)
        draw.OutlinedCircle(centerX, centerY, halfSize + 1, 64)

        if light_mode then
            draw.Color(236, 239, 244, background_transparency)
        else
            draw.Color(46, 52, 64, background_transparency)
        end
        DrawFilledCircle(white_texture, centerX, centerY, halfSize, 64)
    end
end

function window.DrawPlayers(plocal, players)
    local circular = config.circular
    local world_locked = config.world_locked
    local size = config.size
    local zoom = config.zoom
    local icon_size = config.icon_size
    local icon_outline = config.icon_outline
    local light_mode = config.light_mode

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local plocalPos = plocal:GetAbsOrigin()
    local plocalIndex = plocal:GetIndex()

    for _, player in pairs(players) do
        if player:IsDormant() or player:IsAlive() == false then goto skip end
        if player:GetIndex() == plocalIndex and plocal:GetPropBool("m_nForceTauntCam") == false then goto skip end


        local class = player:GetPropInt("m_iClass")
        local icon = icons.list[class]
        if icon == nil then goto skip end

        local origin = player:GetAbsOrigin()

        --- get relative position to local player
        local dx = origin.x - plocalPos.x
        local dy = origin.y - plocalPos.y
        local dz = origin.z - plocalPos.z

        --- rotate relative to local player's view
        local rx, ry = dx, dy

        if world_locked == false then
            rx = dx * cos(-yaw) - dy * sin(-yaw)
            ry = dx * sin(-yaw) + dy * cos(-yaw)
        end

        --- apply zoom and translate to radar
        local iconX, iconY
        if circular then
            local halfSize = size / 2
            local centerX, centerY = x + halfSize, y + halfSize

            -- compute distance from center
            local dist = sqrt(rx * rx + ry * ry)

            -- clamp to radar radius
            local maxDist = halfSize / zoom
            if dist > maxDist then
                local scale = maxDist / dist
                rx = rx * scale
                ry = ry * scale
            end

            iconX = (centerX + rx * zoom) // 1
            iconY = (centerY - ry * zoom) // 1
        else
            iconX = clamp((x + size / 2 + rx * zoom) // 1, x, x + size)
            iconY = clamp((y + size / 2 - ry * zoom) // 1, y, y + size) -- invert y to match screen coordinates
        end

        if player:GetTeamNumber() == 2 then
            draw.Color(red[1], red[2], red[3], 255)
        else
            draw.Color(blu[1], blu[2], blu[3], 255)
        end

        local invis = player:InCond(E_TFCOND.TFCond_Cloaked)

        if icon_outline then
            local thickness = icon_size + 2
            DrawFilledCircle(white_texture, iconX, iconY, thickness, 32)

            if invis then
                draw.Color(0, 0, 0, 200)
                DrawFilledCircle(white_texture, iconX, iconY, thickness, 32)
            end
        end

        draw.Color(255, 255, 255, 255)
        draw.TexturedRect(icon, iconX - icon_size, iconY - icon_size, iconX + icon_size, iconY + icon_size)

        if invis then
            draw.Color(0, 0, 0, 200)
            draw.TexturedRect(icon, iconX - icon_size, iconY - icon_size, iconX + icon_size, iconY + icon_size)
        end

        if light_mode then
            draw.Color(46, 52, 64, 255)
        else
            draw.Color(255, 255, 255, 250)
        end

        if dz > 60 then
            draw.FilledRect(iconX - icon_size, iconY - icon_size - 3, iconX + icon_size, iconY - icon_size - 1)
        elseif dz < -60 then
            draw.FilledRect(iconX - icon_size, iconY + icon_size + 1, iconX + icon_size, iconY + icon_size + 3)
        end

        ::skip::
    end
end

function window.DrawHealthbar(plocal)
    local size = config.size
    local circular = config.circular

    draw.Color(blu[1], blu[2], blu[3], 255)
    draw.Line(x + size // 2, y, x + size // 2, y + size)
    draw.Line(x, y + size // 2, x + size, y + size // 2)

    local healthBarX, healthBarY, healthBarW, healthBarH
    if circular then
        healthBarX = x
        healthBarY = y + size + 5
        healthBarW = size
        healthBarH = 10

        --- draw background
        draw.Color(40, 40, 40, 255)
        draw.FilledRect(healthBarX, healthBarY, healthBarX + healthBarW, healthBarY + healthBarH)

        local health = plocal:GetHealth()
        local maxhealth = plocal:GetMaxHealth()
        local percent = clamp(health / maxhealth, 0, 1)

        --- drw normal health
        draw.Color(216, 222, 233, 255)
        draw.FilledRect(healthBarX, healthBarY, healthBarX + (healthBarW * percent) // 1, healthBarY + healthBarH)

        if health > maxhealth then
            health = health - maxhealth
            maxhealth = plocal:GetMaxBuffedHealth() - maxhealth
            percent = clamp(health / maxhealth, 0, 1)

            local startX = healthBarX
            local endX = startX + (healthBarW * percent) // 1
            draw.Color(blu[1], blu[2], blu[3], 255)
            draw.FilledRect(startX, healthBarY, endX, healthBarY + healthBarH)
        end

        draw.Color(blu[1], blu[2], blu[3], 255)
        draw.OutlinedRect(healthBarX - 1, healthBarY - 1, healthBarX + healthBarW + 1, healthBarY + healthBarH + 1)
    else
        healthBarX = x - 15
        healthBarY = y
        healthBarW, healthBarH = 10, size
        draw.Color(90, 90, 90, 255)
        draw.FilledRect(healthBarX - 1, healthBarY - 1, healthBarX + healthBarW + 1, healthBarY + healthBarH + 1)

        draw.Color(40, 40, 40, 255)
        draw.FilledRect(healthBarX, healthBarY, healthBarX + healthBarW, healthBarY + healthBarH)

        local health = plocal:GetHealth()
        local maxhealth = plocal:GetMaxHealth()
        local percent = clamp(health / maxhealth, 0, 1)

        draw.Color(216, 222, 233, 255)
        draw.FilledRect(healthBarX, healthBarY + (healthBarH * (1 - percent)) // 1, healthBarX + healthBarW,
            healthBarY + healthBarH)

        if health > maxhealth then
            health = health - maxhealth
            maxhealth = plocal:GetMaxBuffedHealth() - maxhealth
            percent = clamp(health / maxhealth, 0, 1)

            draw.Color(blu[1], blu[2], blu[3], 255)
            draw.FilledRect(healthBarX, healthBarY + (healthBarH * (1 - percent)) // 1, healthBarX + healthBarW,
                healthBarY + healthBarH)
        end
    end
end

function window.cleanup()
    draw.DeleteTexture(white_texture)
end

return window

end)
__bundle_register("src/icons", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("src/base64", function(require, _LOADED, __bundle_register, __bundle_modules)
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

end)
__bundle_register("src/config", function(require, _LOADED, __bundle_register, __bundle_modules)
local config = {
    size = 200,
    icon_size = 12,
    zoom = 0.1, -- 10% zoom
    circular = false,
    healthbar = true,
    background_transparency = 250,
    light_mode = false,
    world_locked = false,
    icon_outline = true,
}

return config

end)
return __bundle_require("__root")