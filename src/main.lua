--- made by navet
--- radar

local icons = require("src/icons")
local radar = require("src/radar")

local function Draw()
	icons.load()
	if icons.is_loading then
		return
	end

	local plocal = entities.GetLocalPlayer()
	if plocal == nil then
		return
	end

	radar.DrawBackground(plocal)

	local players = entities.FindByClass("CTFPlayer")
	local list = {}

	local plocalPos = plocal:GetAbsOrigin()

	for _, player in pairs(players) do
		if player:IsAlive() == false or player:IsDormant() then
      goto continue
		end

		local origin = player:GetAbsOrigin()
		list[#list + 1] = {
			origin = origin,
			class = player:GetPropInt("m_iClass"),
			dist = (origin - plocalPos):LengthSqr(),
			index = player:GetIndex(),
			invis = player:InCond(E_TFCOND.TFCond_Cloaked),
			maxhealth = player:GetMaxHealth(),
			maxbuffhealth = player:GetMaxBuffedHealth(),
			health = player:GetHealth(),
			team = player:GetTeamNumber(),
		}

		::continue::
	end

	table.sort(list, function(a, b)
		return a.dist > b.dist
	end)

	radar.DrawPlayers(plocal, list)
end

local function Unload()
	icons.cleanup()
	radar.cleanup()

	radar = nil
	icons = nil
end

callbacks.Register("Draw", Draw)
callbacks.Register("Unload", Unload)
