if getgenv().AuraFarmEnabled then
loadstring(game:HttpGet("https://raw.githubusercontent.com/SansYT789/Library/refs/heads/main/AuraFarming.lua"))()
return
end

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RepStorage = game:GetService("ReplicatedStorage")
local TxtChat = game:GetService("TextChatService")
local Teleport = game:GetService("TeleportService")
local Light = game:GetService("Lighting")
local Work = game:GetService("Workspace")
local Market = game:GetService("MarketplaceService")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInput = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local char, hum, hrp

-- Cache
local gameInfo = {
    name = Market:GetProductInfo(game.PlaceId).Name or "Unknown",
    placeId = game.PlaceId,
    gameId = game.GameId,
    jobId = game.JobId
}

local cache = {
    fps = 0,
    lastFps = tick(),
    players = {},
    spawns = nil,
    npcs = nil,
    lastNpcScan = 0
}

-- Optimized Window
local win = WindUI:CreateWindow({
    Title = "MangoHub • " .. gameInfo.name,
    Icon = "zap",
    Author = "Vinreach",
    Folder = "MangoHub",
    Size = UDim2.fromOffset(340, 360),
    Theme = "Dark"
})

-- Utilities
local function notify(title, desc, dur, icon)
    WindUI:Notify({
        Title = title,
        Content = desc,
        Icon = icon or "zap",
        Duration = dur or 2.5
    })
end

local function copy(text)
    if setclipboard then
        setclipboard(tostring(text))
        notify("Copied", "To clipboard", 1.5, "clipboard")
        return true
    end
    notify("Error", "Clipboard unavailable", 2, "x")
    return false
end

local function chat(msg)
    local channel = TxtChat.TextChannels:FindFirstChild("RBXGeneral")
    if channel and channel.SendAsync then
        pcall(function() channel:SendAsync(msg) end)
    elseif RepStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        pcall(function() RepStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end)
    end
end

local function setupChar(newChar)
    char = newChar
    hum = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
end

if plr.Character then setupChar(plr.Character) end
plr.CharacterAdded:Connect(setupChar)

-- Performance optimized functions
local function getFPS()
    local now = tick()
    if now - cache.lastFps > 0.5 then
        cache.fps = math.floor(1 / Run.RenderStepped:Wait())
        cache.lastFps = now
    end
    return cache.fps
end

local function updatePlayerCache()
    table.clear(cache.players)
    for _, p in ipairs(Players:GetPlayers()) do
        cache.players[#cache.players + 1] = p.Name
    end
end

local function getPos()
    if hrp then
        local p = hrp.Position
        return string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z), p
    end
    return "N/A", nil
end

local function getNearby(radius)
    if not hrp then return {} end
    local nearby = {}
    local myPos = hrp.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr and p.Character then
            local theirHRP = p.Character:FindFirstChild("HumanoidRootPart")
            if theirHRP then
                local dist = (myPos - theirHRP.Position).Magnitude
                if dist <= radius then
                    nearby[#nearby + 1] = {name = p.Name, dist = math.floor(dist)}
                end
            end
        end
    end
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    return nearby
end

local function getSpawns()
    if not cache.spawns then
        cache.spawns = {}
        for _, obj in ipairs(Work:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                cache.spawns[#cache.spawns + 1] = {name = obj.Name, pos = obj.Position}
            end
        end
    end
    return cache.spawns
end

local function countObjs()
    local parts, models = 0, 0
    for _, obj in ipairs(Work:GetDescendants()) do
        if obj:IsA("BasePart") then 
            parts = parts + 1
        elseif obj:IsA("Model") then 
            models = models + 1
        end
    end
    return parts, models
end

local function getNPCs()
    local now = tick()
    if not cache.npcs or now - cache.lastNpcScan > 10 then
        cache.npcs = {}
        for _, model in ipairs(Work:GetDescendants()) do
            if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
                if not Players:GetPlayerFromCharacter(model) then
                    cache.npcs[#cache.npcs + 1] = model.Name
                end
            end
        end
        cache.lastNpcScan = now
    end
    return cache.npcs
end

local function getNet()
    return {
        ping = math.floor(plr:GetNetworkPing() * 1000),
        region = game:GetService("LocalizationService").RobloxLocaleId
    }
end

local function getStats()
    return {
        mem = math.floor(Stats:GetTotalMemoryUsageMb()),
        fps = getFPS(),
        recv = math.floor(Stats.DataReceiveKbps),
        send = math.floor(Stats.DataSendKbps),
        physFps = math.floor(Work:GetRealPhysicsFPS())
    }
end

-- Enhanced server hop with better server selection
local function serverHop(findLow)
    notify("Hopping", "Finding server...", 2, "shuffle")
    local cursor = ""
    local bestServer = nil
    
    for i = 1, 3 do
        local url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100%s", 
            gameInfo.placeId, findLow and "Asc" or "Desc", cursor ~= "" and "&cursor=" .. cursor or "")
        local success, result = pcall(function()
            return Http:JSONDecode(game:HttpGet(url))
        end)
        
        if success and result.data then
            for _, server in ipairs(result.data) do
                if server.id ~= gameInfo.jobId and server.playing < server.maxPlayers then
                    if not bestServer or (findLow and server.playing < bestServer.playing) or (not findLow and server.playing > bestServer.playing) then
                        bestServer = server
                    end
                end
            end
            if bestServer then break end
            cursor = result.nextPageCursor or ""
        end
    end
    
    if bestServer then
        Teleport:TeleportToPlaceInstance(gameInfo.placeId, bestServer.id, plr)
    else
        notify("Error", "No servers found", 3, "x")
    end
end

-- Tabs
local main = win:Tab({Title = "Main", Icon = "home"})
local ply = win:Tab({Title = "Players", Icon = "users"})
local map = win:Tab({Title = "World", Icon = "globe"})
local sys = win:Tab({Title = "Stats", Icon = "bar-chart"})
local util = win:Tab({Title = "Tools", Icon = "wrench"})

-- Main Tab
main:Button({Title = "Copy Game", Icon = "type", Callback = function() copy(gameInfo.name) end})
main:Button({Title = "Copy Game ID", Icon = "hash", Callback = function() copy(gameInfo.gameId) end})
main:Button({Title = "Copy Place ID", Icon = "map-pin", Callback = function() copy(gameInfo.placeId) end})
main:Button({Title = "Copy Job ID", Icon = "server", Callback = function() copy(gameInfo.jobId) end})
main:Button({Title = "Copy Position", Icon = "crosshair", Callback = function() copy(getPos()) end})

main:Divider({Text = "Travel"})
main:Button({Title = "Rejoin", Icon = "refresh-cw", Callback = function() 
    Teleport:Teleport(gameInfo.placeId, plr) 
end})
main:Button({Title = "Hop (High Pop)", Icon = "trending-up", Callback = function()
    serverHop(false)
end})
main:Button({Title = "Hop (Low Pop)", Icon = "trending-down", Callback = function()
    serverHop(true)
end})

-- Player Tab
ply:Button({Title = "Player Count", Icon = "users", Callback = function()
    local count = #Players:GetPlayers()
    local max = Players.MaxPlayers
    notify("Players", count .. "/" .. max .. " online", 2, "users")
    copy(count .. "/" .. max)
end})

ply:Button({Title = "List Players", Icon = "list", Callback = function()
    updatePlayerCache()
    copy(table.concat(cache.players, ", "))
    notify("Players", #cache.players .. " names copied", 2, "list")
end})

ply:Button({Title = "Nearby (25m)", Icon = "radio", Callback = function()
    local nearby = getNearby(25)
    if #nearby > 0 then
        local txt = {}
        for _, p in ipairs(nearby) do
            txt[#txt + 1] = p.name .. " (" .. p.dist .. "m)"
        end
        copy(table.concat(txt, ", "))
        notify("Nearby", #nearby .. " players", 2, "radio")
    else
        notify("Nearby", "None found", 2, "radio")
    end
end})

ply:Button({Title = "Nearby (100m)", Icon = "radar", Callback = function()
    local nearby = getNearby(100)
    if #nearby > 0 then
        local txt = {}
        for _, p in ipairs(nearby) do
            txt[#txt + 1] = p.name .. " (" .. p.dist .. "m)"
        end
        copy(table.concat(txt, ", "))
        notify("Nearby", #nearby .. " players", 2, "radar")
    else
        notify("Nearby", "None found", 2, "radar")
    end
end})

ply:Button({Title = "Spectate Random", Icon = "eye", Callback = function()
    local players = Players:GetPlayers()
    if #players > 1 then
        local target = players[math.random(#players)]
        if target ~= plr and target.Character and target.Character:FindFirstChildOfClass("Humanoid") then
            Work.CurrentCamera.CameraSubject = target.Character.Humanoid
            notify("Spectating", target.Name, 2, "eye")
            return
        end
    end
    notify("Error", "No valid targets", 2, "x")
end})

ply:Button({Title = "Reset Camera", Icon = "camera", Callback = function()
    if hum then
        Work.CurrentCamera.CameraSubject = hum
        notify("Camera", "Reset", 1.5, "camera")
    end
end})

-- Map Tab
map:Button({Title = "Spawns", Icon = "flag", Callback = function()
    local spawns = getSpawns()
    if #spawns > 0 then
        local txt = {}
        for _, s in ipairs(spawns) do
            txt[#txt + 1] = s.name
        end
        copy(table.concat(txt, ", "))
        notify("Spawns", #spawns .. " found", 2, "flag")
    else
        notify("Spawns", "None found", 2, "flag")
    end
end})

map:Button({Title = "Teleport to Spawn", Icon = "zap", Callback = function()
    local spawns = getSpawns()
    if #spawns > 0 and hrp then
        local spawn = spawns[math.random(#spawns)]
        hrp.CFrame = CFrame.new(spawn.pos + Vector3.new(0, 5, 0))
        notify("Teleported", spawn.name, 2, "zap")
    else
        notify("Error", "No spawns", 2, "x")
    end
end})

map:Button({Title = "Lighting", Icon = "sun", Callback = function()
    local info = string.format("Time: %s | Bright: %.1f", Light.TimeOfDay, Light.Brightness)
    copy(info)
    notify("Lighting", "Data copied", 2, "sun")
end})

map:Button({Title = "Count Objects", Icon = "box", Callback = function()
    local parts, models = countObjs()
    local info = string.format("Parts: %d | Models: %d", parts, models)
    copy(info)
    notify("Objects", info, 3, "box")
end})

map:Button({Title = "Find NPCs", Icon = "bot", Callback = function()
    local npcs = getNPCs()
    if #npcs > 0 then
        copy(table.concat(npcs, ", "))
        notify("NPCs", #npcs .. " found", 2, "bot")
    else
        notify("NPCs", "None found", 2, "bot")
    end
end})

map:Button({Title = "Refresh Cache", Icon = "refresh-ccw", Callback = function()
    cache.spawns = nil
    cache.npcs = nil
    cache.lastNpcScan = 0
    notify("Cache", "Cleared", 1.5, "refresh-ccw")
end})

-- Stats Tab
sys:Button({Title = "Network", Icon = "wifi", Callback = function()
    local net = getNet()
    local info = string.format("Ping: %dms | Region: %s", net.ping, net.region)
    copy(info)
    notify("Network", info, 2, "wifi")
end})

sys:Button({Title = "Performance", Icon = "activity", Callback = function()
    local st = getStats()
    local info = string.format("Mem: %dMB | FPS: %d | Physics: %d", st.mem, st.fps, st.physFps)
    copy(info)
    notify("Stats", info, 3, "activity")
end})

sys:Button({Title = "Bandwidth", Icon = "trending-up", Callback = function()
    local st = getStats()
    local info = string.format("↓ %d Kbps | ↑ %d Kbps", st.recv, st.send)
    copy(info)
    notify("Bandwidth", info, 2, "trending-up")
end})

sys:Button({Title = "Export All", Icon = "download", Callback = function()
    local st = getStats()
    local net = getNet()
    local posStr = getPos()
    local data = string.format([[MangoHub Data Export
━━━━━━━━━━━━━━━━━━━━
Game: %s
Game ID: %s | Place: %s
Job ID: %s
Players: %d/%d
Position: %s
Ping: %dms | Region: %s
Memory: %dMB | FPS: %d | Physics: %d
Network: ↓%d ↑%d Kbps
Time: %s]], 
        gameInfo.name, gameInfo.gameId, gameInfo.placeId, gameInfo.jobId,
        #Players:GetPlayers(), Players.MaxPlayers, posStr,
        net.ping, net.region, st.mem, st.fps, st.physFps, st.recv, st.send, Light.TimeOfDay)
    copy(data)
    notify("Export", "Complete", 2, "download")
end})

-- Utility Tab
util:Button({Title = "Reset", Icon = "rotate-ccw", Callback = function()
    if char then char:BreakJoints() end
end})

util:Button({Title = "Clear Chat", Icon = "message-square", Callback = function()
    chat(string.rep("\n", 50))
    notify("Chat", "Cleared", 1.5, "message-square")
end})

util:Button({Title = "Join Link", Icon = "link", Callback = function()
    local link = string.format("https://www.roblox.com/games/%s?jobId=%s", gameInfo.placeId, gameInfo.jobId)
    copy(link)
    notify("Link", "Copied", 2, "link")
end})

util:Button({Title = "Fullscreen", Icon = "maximize", Callback = function()
    game:GetService("GuiService"):ToggleFullscreen()
end})

util:Button({Title = "Zoom Out", Icon = "zoom-out", Callback = function()
    if plr.CameraMaxZoomDistance < 500 then
        plr.CameraMaxZoomDistance = 500
        notify("Zoom", "Extended", 1.5, "zoom-out")
    end
end})

local autoUpdate = false
util:Toggle({
    Title = "Auto Stats",
    Default = false,
    Callback = function(v)
        autoUpdate = v
        if v then
            notify("Auto Stats", "Enabled", 2, "refresh-cw")
            task.spawn(function()
                while autoUpdate do
                    getFPS()
                    task.wait(3)
                end
            end)
        end
    end
})

local noClip = false
util:Toggle({
    Title = "Noclip",
    Default = false,
    Callback = function(v)
        noClip = v
        notify("Noclip", v and "On" or "Off", 1.5, "ghost")
    end
})

Run.Stepped:Connect(function()
    if noClip and char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Event handlers
updatePlayerCache()

Players.PlayerAdded:Connect(function(p)
    cache.players[#cache.players + 1] = p.Name
    notify("Joined", p.Name, 1.5, "user-plus")
end)

Players.PlayerRemoving:Connect(function(p)
    for i, name in ipairs(cache.players) do
        if name == p.Name then
            table.remove(cache.players, i)
            notify("Left", p.Name, 1.5, "user-minus")
            break
        end
    end
end)

notify("MangoHub", "Ready!", 2, "check")