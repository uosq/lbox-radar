local base64 = require("src/base64")

local icons = {
	list = {},
	loaded = 0,
	is_loading = true,
	folder = "tf/radar/icons/",
	urls = {
		{ "scout", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/scout.lua" },
		{ "sniper", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/sniper.lua" },
		{ "soldier", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/soldier.lua" },
		{ "demo", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/demo.lua" },
		{ "medic", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/medic.lua" },
		{ "heavy", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/heavy.lua" },
		{ "pyro", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/pyro.lua" },
		{ "spy", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/spy.lua" },
		{ "engineer", "https://raw.githubusercontent.com/uosq/lbox-icons/refs/heads/main/engineer.lua" },
	},
}

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
	if not icons.is_loading then
		return
	end

	for index, url in ipairs(icons.urls) do
		local name = url[1]
		local filepath = icons.folder .. name
		local content

		-- Try loading from disk first
		if fileExists(filepath) then
			local f = io.open(filepath, "r")
			if f then
				content = f:read("a")
				f:close()
			end
		else
			-- Download and save for future use
			local ok, result = pcall(http.Get, url[2])
			if ok and result then
				content = result
				local f = io.open(filepath, "w")
				if f then
					f:write(result)
					f:close()
				else
					print("Radar - Failed to write icon: " .. filepath)
				end
			else
				print("Radar - Failed to download: " .. url[2])
			end
		end

		-- Create texture
		if content then
			local success, texture = pcall(base64.createTextureFromRGBA, content)
			if success and texture then
				icons.loaded = icons.loaded + 1
				icons.list[icons.loaded] = texture
			else
				print("Radar - Failed to create texture for: " .. name)
			end
		end
	end

	icons.is_loading = false
	print(string.format("Radar - Loaded %d icons.", icons.loaded))
end

function icons.cleanup()
	for _, tex in ipairs(icons.list) do
		draw.DeleteTexture(tex)
	end
end

return icons
