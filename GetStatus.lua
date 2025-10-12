local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local player = Players.LocalPlayer
local char, hum, hrp

local GameInfo = {
    Name = MarketplaceService:GetProductInfo(game.PlaceId).Name or "Unknown Game",
    PlaceId = tostring(game.PlaceId),
    GameId = tostring(game.GameId),
    JobId = tostring(game.JobId)
}

local FPSCounter = {value = 0, lastUpdate = 0}
local PlayerCache = {}

local Window = WindUI:CreateWindow({
    Title = "MangoHub — " .. GameInfo.Name,
    Icon = "zap",
    Author = "Vinreach Group",
    Folder = "MangoHub",
    Size = UDim2.fromOffset(400, 500),
    Theme = "Dark"
})

local function Notify(title, desc, duration, icon)
    WindUI:Notify({
        Title = title,
        Content = desc,
        Icon = icon or "zap",
        Duration = duration or 3
    })
end

local function Copy(text)
    if setclipboard then
        setclipboard(tostring(text))
        Notify("Copied!", "Text copied to clipboard", 2, "clipboard")
    else
        Notify("Error", "Clipboard not supported", 3, "x")
    end
end

local function SendChat(msg)
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if channel and channel.SendAsync then
        pcall(function() channel:SendAsync(msg) end)
    elseif ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        pcall(function() ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end)
    end
end

local function SetupCharacter(newChar)
    char = newChar
    hum = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
end

if player.Character then SetupCharacter(player.Character) end
player.CharacterAdded:Connect(SetupCharacter)

local function UpdateFPS()
    local now = tick()
    if now - FPSCounter.lastUpdate > 1 then
        FPSCounter.value = math.floor(1 / RunService.Heartbeat:Wait())
        FPSCounter.lastUpdate = now
    end
    return FPSCounter.value
end

local function GetPlayerData()
    return {
        count = #Players:GetPlayers(),
        max = Players.MaxPlayers,
        list = PlayerCache
    }
end

local function UpdatePlayerCache()
    PlayerCache = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(PlayerCache, p.Name)
    end
end

local function GetPosition()
    if hrp then
        local pos = hrp.Position
        return string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)
    end
    return "Unavailable"
end

local function GetNearbyPlayers(radius)
    if not hrp then return {} end
    local nearby = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
            if dist <= radius then
                table.insert(nearby, {name = p.Name, dist = math.floor(dist)})
            end
        end
    end
    table.sort(nearby, function(a, b) return a.dist < b.dist end)
    return nearby
end

local function GetSpawns()
    local spawns = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawns, {name = obj.Name, pos = obj.Position})
        end
    end
    return spawns
end

local function CountObjects()
    local counts = {parts = 0, models = 0, scripts = 0}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then counts.parts = counts.parts + 1
        elseif obj:IsA("Model") then counts.models = counts.models + 1
        elseif obj:IsA("BaseScript") then counts.scripts = counts.scripts + 1 end
    end
    return counts
end

local function GetNetworkInfo()
    return {
        ping = math.floor(player:GetNetworkPing() * 1000),
        region = game:GetService("LocalizationService").RobloxLocaleId or "Unknown"
    }
end

local function GetSystemStats()
    return {
        memory = math.floor(Stats:GetTotalMemoryUsageMb()),
        fps = UpdateFPS(),
        dataRecv = math.floor(Stats.DataReceiveKbps),
        dataSent = math.floor(Stats.DataSendKbps)
    }
end

local MainTab = Window:Tab({Title = "Main", Icon = "house"})
local PlayerTab = Window:Tab({Title = "Players", Icon = "users"})
local MapTab = Window:Tab({Title = "Map", Icon = "map"})
local SystemTab = Window:Tab({Title = "System", Icon = "cpu"})
local UtilityTab = Window:Tab({Title = "Utility", Icon = "tool"})

MainTab:Button({Title = "Copy Game Name", Icon = "type", Callback = function() Copy(GameInfo.Name) end})
MainTab:Button({Title = "Copy Game ID", Icon = "hash", Callback = function() Copy(GameInfo.GameId) end})
MainTab:Button({Title = "Copy Place ID", Icon = "map-pin", Callback = function() Copy(GameInfo.PlaceId) end})
MainTab:Button({Title = "Copy Job ID", Icon = "server", Callback = function() Copy(GameInfo.JobId) end})
MainTab:Button({Title = "Copy Position", Icon = "crosshair", Callback = function() Copy(GetPosition()) end})
MainTab:Divider({Text = "Actions"})
MainTab:Button({Title = "Rejoin Server", Icon = "refresh-cw", Callback = function() 
    TeleportService:Teleport(game.PlaceId, player) 
end})
MainTab:Button({Title = "Server Hop", Icon = "shuffle", Callback = function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    if servers.data[1] then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers.data[1].id, player)
    else
        Notify("Error", "No servers available", 3, "x")
    end
end})

PlayerTab:Button({Title = "Player Count", Icon = "users", Callback = function()
    local data = GetPlayerData()
    Notify("Players", data.count .. "/" .. data.max .. " online", 3, "users")
    Copy(data.count .. "/" .. data.max)
end})

PlayerTab:Button({Title = "List All Players", Icon = "list", Callback = function()
    UpdatePlayerCache()
    Copy(table.concat(PlayerCache, ", "))
    Notify("Player List", "Copied " .. #PlayerCache .. " names", 3, "list")
end})

PlayerTab:Button({Title = "Nearby Players (50 studs)", Icon = "radar", Callback = function()
    local nearby = GetNearbyPlayers(50)
    if #nearby > 0 then
        local text = {}
        for _, p in ipairs(nearby) do
            table.insert(text, p.name .. " (" .. p.dist .. "m)")
        end
        Copy(table.concat(text, ", "))
        Notify("Nearby", "Found " .. #nearby .. " players", 3, "radar")
    else
        Notify("Nearby", "No players nearby", 3, "radar")
    end
end})

PlayerTab:Button({Title = "Spectate Random Player", Icon = "eye", Callback = function()
    local players = Players:GetPlayers()
    local target = players[math.random(#players)]
    if target and target ~= player and target.Character then
        Workspace.CurrentCamera.CameraSubject = target.Character.Humanoid
        Notify("Spectating", target.Name, 3, "eye")
    end
end})

PlayerTab:Button({Title = "Reset Camera", Icon = "camera-off", Callback = function()
    if char and hum then
        Workspace.CurrentCamera.CameraSubject = hum
        Notify("Camera", "Reset to self", 2, "camera")
    end
end})

MapTab:Button({Title = "Get Spawn Locations", Icon = "flag", Callback = function()
    local spawns = GetSpawns()
    if #spawns > 0 then
        local text = {}
        for _, s in ipairs(spawns) do
            table.insert(text, s.name)
        end
        Copy(table.concat(text, ", "))
        Notify("Spawns", "Found " .. #spawns .. " locations", 3, "flag")
    else
        Notify("Spawns", "None found", 3, "flag")
    end
end})

MapTab:Button({Title = "Lighting Info", Icon = "sun", Callback = function()
    local info = string.format("Time: %s | Brightness: %.1f | Ambient: %s", 
        Lighting.TimeOfDay, Lighting.Brightness, tostring(Lighting.Ambient))
    Copy(info)
    Notify("Lighting", "Data copied", 3, "sun")
end})

MapTab:Button({Title = "Count Map Objects", Icon = "box", Callback = function()
    local counts = CountObjects()
    local info = string.format("Parts: %d | Models: %d | Scripts: %d", counts.parts, counts.models, counts.scripts)
    Copy(info)
    Notify("Objects", info, 4, "box")
end})

MapTab:Button({Title = "Find All NPCs", Icon = "bot", Callback = function()
    local npcs = {}
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(model) then
            table.insert(npcs, model.Name)
        end
    end
    if #npcs > 0 then
        Copy(table.concat(npcs, ", "))
        Notify("NPCs", "Found " .. #npcs .. " NPCs", 3, "bot")
    else
        Notify("NPCs", "None found", 3, "bot")
    end
end})

SystemTab:Button({Title = "Network Info", Icon = "wifi", Callback = function()
    local net = GetNetworkInfo()
    local info = string.format("Ping: %dms | Region: %s", net.ping, net.region)
    Copy(info)
    Notify("Network", info, 3, "wifi")
end})

SystemTab:Button({Title = "System Stats", Icon = "activity", Callback = function()
    local stats = GetSystemStats()
    local info = string.format("Memory: %dMB | FPS: %d | Recv: %dKbps | Send: %dKbps", 
        stats.memory, stats.fps, stats.dataRecv, stats.dataSent)
    Copy(info)
    Notify("System", info, 4, "activity")
end})

SystemTab:Button({Title = "Export All Data", Icon = "download", Callback = function()
    local sys = GetSystemStats()
    local net = GetNetworkInfo()
    local data = string.format([[
Game: %s
Game ID: %s | Place ID: %s
Job ID: %s
Players: %d/%d
Position: %s
Ping: %dms | Region: %s
Memory: %dMB | FPS: %d
Time: %s
]], GameInfo.Name, GameInfo.GameId, GameInfo.PlaceId, GameInfo.JobId, 
    GetPlayerData().count, GetPlayerData().max, GetPosition(), 
    net.ping, net.region, sys.memory, sys.fps, Lighting.TimeOfDay)
    Copy(data)
    Notify("Export", "All data exported", 4, "download")
end})

UtilityTab:Button({Title = "Reset Character", Icon = "rotate-ccw", Callback = function()
    if char then char:BreakJoints() end
end})

UtilityTab:Button({Title = "Clear Chat", Icon = "message-square", Callback = function()
    SendChat(string.rep("\n", 100))
    Notify("Chat", "Cleared", 2, "message-square")
end})

UtilityTab:Button({Title = "Get Coordinates Link", Icon = "link", Callback = function()
    local pos = GetPosition()
    local link = string.format("https://www.roblox.com/games/%s?privateServerLinkCode=%s", 
        GameInfo.PlaceId, GameInfo.JobId)
    Copy(link)
    Notify("Link", "Join link copied", 3, "link")
end})

UtilityTab:Button({Title = "Toggle Fullscreen", Icon = "maximize", Callback = function()
    game:GetService("GuiService"):ToggleFullscreen()
end})

local autoUpdateEnabled = false
UtilityTab:Toggle({
    Title = "Auto-Update Stats",
    Default = false,
    Callback = function(v)
        autoUpdateEnabled = v
        if v then
            Notify("Auto-Update", "Enabled", 2, "refresh-cw")
            spawn(function()
                while autoUpdateEnabled do
                    UpdateFPS()
                    wait(5)
                end
            end)
        end
    end
})

UpdatePlayerCache()

Players.PlayerAdded:Connect(function(p)
    table.insert(PlayerCache, p.Name)
    Notify("Player Joined", p.Name, 2, "user-plus")
end)

Players.PlayerRemoving:Connect(function(p)
    for i, name in ipairs(PlayerCache) do
        if name == p.Name then
            table.remove(PlayerCache, i)
            break
        end
    end
    Notify("Player Left", p.Name, 2, "user-minus")
end)

Notify("MangoHub", "Loaded successfully!", 3, "zap")