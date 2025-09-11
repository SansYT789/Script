local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not success then
    warn("Failed to load WindUI:", WindUI)
    return
end

local games = {
    -- Arena Of Blox
    ["7832036655"] = "https://raw.githubusercontent.com/Vinreach/MangoHub-Script/refs/heads/main/MangoHub-AOB.lua",
    -- POOP
    ["7932671830"] = "https://raw.githubusercontent.com/Vinreach/MangoHub-Script/refs/heads/main/MangoHub-POOP.lua"
}

local placeId = tostring(game.PlaceId)
local gameId = tostring(game.GameId)

local scriptLink = games[placeId] or games[gameId]

if WindUI and WindUI.Notify then
    WindUI:Notify({
        Title = scriptLink and "Supported Game" or "Not Supported",
        Content = scriptLink and "Detected game!" or "Your current game is not supported.",
        Duration = 5,
        Icon = scriptLink and "check" or "warning"
    })
end

if scriptLink then
    local scriptSuccess, scriptError = pcall(function()
        local scriptCode = game:HttpGet(scriptLink)
        if scriptCode and scriptCode ~= "" then
            loadstring(scriptCode .. "?token=GHSAT0AAAAAADJWTGCZVE2CGFRMLY2VFIEC2GCPIZA")()
        else
            error("Empty or invalid script content")
        end
    end)

    if not scriptSuccess then
        warn("Failed to load game script:", scriptError)
        if WindUI and WindUI.Notify then
            WindUI:Notify({
                Title = "Script Error",
                Content = "Failed to load the game script",
                Duration = 5,
                Icon = "warning"
            })
        end
    end
end