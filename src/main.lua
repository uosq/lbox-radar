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
