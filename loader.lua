
-- FLY + NOCLIP COMBINED LOADER
-- Loads both scripts from your GitHub repository

local scripts = {
    "https://raw.githubusercontent.com/thegamerkid2440-cell/doo-ovan/main/fly.lua",
    "https://raw.githubusercontent.com/thegamerkid2440-cell/doo-ovan/main/noclip.lua"
}

for _, url in ipairs(scripts) do
    local success, source = pcall(function()
        return game:HttpGet(url)
    end)

    if success then
        local scriptFunction, errorMessage =
            loadstring(source)

        if scriptFunction then
            local ran, err = pcall(scriptFunction)

            if ran then
                print("LOADED: " .. url)
            else
                warn("SCRIPT ERROR: " .. tostring(err))
            end
        else
            warn("COMPILATION ERROR: " .. tostring(errorMessage))
        end
    else
        warn("DOWNLOAD FAILED: " .. tostring(source))
    end
end
