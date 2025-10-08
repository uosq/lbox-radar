local window = {}

local config = require("src/config")
local icons = require("src/icons")
local colors = require("src/colors")
local ui = require("src/ui")

local oldmx, oldmy, lastclicktick = 0, 0, 0
local x, y = 300, 300
local dragging = false

local zoom = 0.1 -- 10% zoom

local white_texture = draw.CreateTextureRGBA(string.rep(string.char(255, 255, 255, 255), 4), 2, 2)

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

local function DrawHealthbar(ent, healthx, healthy, color)
    local height = 3
    local size = config.icon_size * 2.0

    --- draw background
    draw.Color(color.health_bg[1], color.health_bg[2], color.health_bg[3], 255)
    draw.FilledRect(healthx, healthy, healthx + size, healthy + height)

    local health = ent.health
    local maxhealth = ent.maxhealth
    local percent = clamp(health / maxhealth, 0, 1)

    --- drw normal health
    local r, g
    r = (1 - percent) * 255
    g = percent * 255

    draw.Color(r // 1, g // 1, 0, 255)
    draw.FilledRect(healthx, healthy, healthx + (size * percent) // 1, healthy + height)

    if health > maxhealth then
        health = health - maxhealth
        maxhealth = ent.maxbuffhealth - maxhealth
        percent = clamp(health / maxhealth, 0, 1)

        local startX = healthx
        local endX = startX + (size * percent) // 1
        draw.Color(color.blu_team[1], color.blu_team[2], color.blu_team[3], 255)
        draw.FilledRect(startX, healthy, endX, healthy + height)
    end
end

function window.DrawBackground(plocal)
    local size = config.size
    local circular = config.circular
    local sw, sh = draw.GetScreenSize()
    local color = config.light_mode and colors.light or colors.dark
    local team_color = plocal:GetTeamNumber() == 2 and color.red_team or color.blu_team

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

        local starty = y
        local w, h = 100, 25
        local gap = 3
        for name, option in pairs(config) do
            local label = name:gsub("_", " ")

            if type(option) == "boolean" then
                ui.Toggle(plocal, x + size + 3, starty, w, h, label, function()
                    config[name] = not config[name]
                end)
                starty = starty + h + gap
            end
        end

        oldmx, oldmy = mx, my
    end

    if circular == false then
        draw.Color(team_color[1], team_color[2], team_color[3], 255)
        draw.OutlinedRect(x - 1, y - 1, x + size + 1, y + size + 1)

        draw.Color(color.bg[1], color.bg[2], color.bg[3], 250)
        draw.FilledRect(x, y, x + size, y + size)
    else
        local halfSize = size // 2
        local centerX, centerY = x + halfSize, y + halfSize
        draw.Color(team_color[1], team_color[2], team_color[3], 255)
        draw.OutlinedCircle(centerX, centerY, halfSize, 64)
        draw.OutlinedCircle(centerX, centerY, halfSize + 1, 64)

        draw.Color(color.bg[1], color.bg[2], color.bg[3], 250)
        DrawFilledCircle(white_texture, centerX, centerY, halfSize, 64)
    end

    draw.Color(team_color[1], team_color[2], team_color[3], 200)
    draw.Line(x + size // 2, y + 10, x + size // 2, y + size - 10)
    draw.Line(x + 10, y + size // 2, x + size - 10, y + size // 2)
end

function window.DrawPlayers(plocal, players)
    local circular = config.circular
    local world_locked = config.world_locked
    local size = config.size
    local icon_size = config.icon_size
    local icon_outline = config.icon_outline
    local light_mode = config.light_mode
    local healthbar = config.healthbar

    local viewAngles = engine.GetViewAngles()
    local yaw = math.rad(viewAngles.y - 90)
    local plocalPos = plocal:GetAbsOrigin()
    local plocalIndex = plocal:GetIndex()

    local color = light_mode and colors.light or colors.dark
    local team_color = plocal:GetTeamNumber() == 2 and color.red_team or color.blu_team

    for _, player in ipairs(players) do
        if player.index == plocalIndex and plocal:GetPropBool("m_nForceTauntCam") == false then goto skip end

        local class = player.class
        local icon = icons.list[class]
        if icon == nil then goto skip end

        local origin = player.origin

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

        local invis = player.invis

        if icon_outline then
            if player.team == 2 then
                draw.Color(color.red_team[1], color.red_team[2], color.red_team[3], 255)
            else
                draw.Color(color.blu_team[1], color.blu_team[2], color.blu_team[3], 255)
            end

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

        draw.Color(color.height[1], color.height[2], color.height[3], 255)

        if dz > 60 then
            draw.FilledRect(iconX - icon_size, iconY - icon_size - 3, iconX + icon_size, iconY - icon_size - 1)
        elseif dz < -60 then
            draw.FilledRect(iconX - icon_size, iconY + icon_size + 1, iconX + icon_size, iconY + icon_size + 3)
        end

        if healthbar then
            DrawHealthbar(player, iconX - icon_size, iconY + icon_size + 5, color)
        end

        ::skip::
    end
end

function window.cleanup()
    draw.DeleteTexture(white_texture)
end

return window
