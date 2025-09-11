local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

-- // Player
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
local hum = nil
local hrp = nil

-- // Game Information
local GameName = MarketplaceService:GetProductInfo(game.PlaceId).Name or "Unknown Game"
local PlaceId = tostring(game.PlaceId)
local GameId = tostring(game.GameId)
local JobId = tostring(game.JobId)

-- =========================
-- UI Window
-- =========================
local Window = WindUI:CreateWindow({
    Title = "MangoHub — Get Status [" .. GameName .. "]",
    Icon = "zap",
    Author = "Vinreach Group",
    Folder = "MangoHub",
    Size = UDim2.fromOffset(380, 480),
    Theme = "Dark"
})

-- =========================
-- Utilities
-- =========================
local function SendMessage(msg)
    local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
    if channel and channel.SendAsync then
        pcall(function() channel:SendAsync(msg) end)
    elseif ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        pcall(function() ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, "All") end)
    end
end

local function Notify(title, desc, duration, icon)
    WindUI:Notify({
        Title = title or "MangoHub — Get Status",
        Content = desc or "No details provided",
        Icon = icon or "zap",
        Duration = duration or 3,
    })
end

local function CopyToClipboard(text)
    if setclipboard then
        setclipboard(tostring(text))
        Notify("Copied!", "Text copied to clipboard", 2, "clipboard")
    else
        Notify("Error", "Clipboard not supported", 3, "x")
    end
end

-- =========================
-- Character Setup
-- =========================
local function setupChar(characters)
    char = characters
    character = characters
    hum = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end

if player.Character then
    setupChar(player.Character)
end
player.CharacterAdded:Connect(setupChar)

-- =========================
-- Information Functions
-- =========================
local function GetPlayerCount()
    return #Players:GetPlayers()
end

local function GetMaxPlayers()
    return Players.MaxPlayers
end

local function GetServerRegion()
    return game:GetService("LocalizationService").RobloxLocaleId or "Unknown"
end

local function GetPing()
    return math.floor(player:GetNetworkPing() * 1000) .. " ms"
end

local function GetFPS()
    local fps = 0
    local heartbeat = game:GetService("RunService").Heartbeat
    local lastTick = tick()
    
    heartbeat:Connect(function()
        fps = math.floor(1 / (tick() - lastTick))
        lastTick = tick()
    end)
    
    return fps
end

local function GetCurrentPosition()
    if hrp then
        local pos = hrp.Position
        return string.format("X: %.2f, Y: %.2f, Z: %.2f", pos.X, pos.Y, pos.Z)
    end
    return "Position unavailable"
end

local function GetNearbyPlayers(radius)
    radius = radius or 50
    local nearbyPlayers = {}
    
    if hrp then
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local distance = (hrp.Position - otherPlayer.Character.HumanoidRootPart.Position).Magnitude
                if distance <= radius then
                    table.insert(nearbyPlayers, {
                        name = otherPlayer.Name,
                        distance = math.floor(distance)
                    })
                end
            end
        end
    end
    
    return nearbyPlayers
end

local function GetSpawnLocations()
    local spawns = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            table.insert(spawns, {
                name = obj.Name,
                position = obj.Position
            })
        end
    end
    return spawns
end

-- =========================
-- Tabs
-- =========================
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
local PlayerTab = Window:Tab({ Title = "Players", Icon = "users" })
local MapTab = Window:Tab({ Title = "Map Info", Icon = "map" })
local SystemTab = Window:Tab({ Title = "System", Icon = "settings" })

-- =========================
-- Main Tab
-- =========================
MainTab:Button({
    Title = "Copy Game Name",
    Icon = "bell",
    Callback = function()
        CopyToClipboard(GameName)
    end
})

MainTab:Button({
    Title = "Copy Game Id",
    Icon = "hash",
    Callback = function()
        CopyToClipboard(GameId)
    end
})

MainTab:Button({
    Title = "Copy Place Id",
    Icon = "map-pin",
    Callback = function()
        CopyToClipboard(PlaceId)
    end
})

MainTab:Button({
    Title = "Copy Job Id",
    Icon = "server",
    Callback = function()
        CopyToClipboard(JobId)
    end
})

MainTab:Button({
    Title = "Copy Current Position",
    Icon = "crosshair",
    Callback = function()
        CopyToClipboard(GetCurrentPosition())
    end
})

MainTab:Button({
    Title = "Rejoin Server",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, player)
    end
})

-- =========================
-- Player Tab
-- =========================
PlayerTab:Button({
    Title = "Get Player Count",
    Icon = "users",
    Callback = function()
        local count = GetPlayerCount()
        local max = GetMaxPlayers()
        Notify("Player Count", count .. "/" .. max .. " players online", 4, "users")
        CopyToClipboard(count .. "/" .. max)
    end
})

PlayerTab:Button({
    Title = "List All Players",
    Icon = "list",
    Callback = function()
        local playerList = {}
        for _, p in pairs(Players:GetPlayers()) do
            table.insert(playerList, p.Name)
        end
        local playerString = table.concat(playerList, ", ")
        CopyToClipboard(playerString)
        Notify("Player List", "Copied " .. #playerList .. " player names", 3, "list")
    end
})

PlayerTab:Button({
    Title = "Find Nearby Players",
    Icon = "radar",
    Callback = function()
        local nearby = GetNearbyPlayers(50)
        if #nearby > 0 then
            local nearbyText = {}
            for _, p in pairs(nearby) do
                table.insert(nearbyText, p.name .. " (" .. p.distance .. " studs)")
            end
            local nearbyString = table.concat(nearbyText, ", ")
            CopyToClipboard(nearbyString)
            Notify("Nearby Players", "Found " .. #nearby .. " players within 50 studs", 4, "radar")
        else
            Notify("Nearby Players", "No players found within 50 studs", 3, "radar")
        end
    end
})

-- =========================
-- Map Tab
-- =========================
MapTab:Button({
    Title = "Get Spawn Locations",
    Icon = "flag",
    Callback = function()
        local spawns = GetSpawnLocations()
        if #spawns > 0 then
            local spawnText = {}
            for _, spawn in pairs(spawns) do
                table.insert(spawnText, spawn.name .. " (" .. tostring(spawn.position) .. ")")
            end
            local spawnString = table.concat(spawnText, "\n")
            CopyToClipboard(spawnString)
            Notify("Spawn Locations", "Found " .. #spawns .. " spawn points", 3, "flag")
        else
            Notify("Spawn Locations", "No spawn locations found", 3, "flag")
        end
    end
})

MapTab:Button({
    Title = "Get Lighting Info",
    Icon = "sun",
    Callback = function()
        local lightingInfo = string.format(
            "Time: %s, Brightness: %.2f, Ambient: %s, ColorShift: %s",
            Lighting.TimeOfDay,
            Lighting.Brightness,
            tostring(Lighting.Ambient),
            tostring(Lighting.ColorShift_Top)
        )
        CopyToClipboard(lightingInfo)
        Notify("Lighting Info", "Lighting data copied", 3, "sun")
    end
})

MapTab:Button({
    Title = "Count Map Objects",
    Icon = "box",
    Callback = function()
        local partCount = 0
        local modelCount = 0
        local scriptCount = 0
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                partCount = partCount + 1
            elseif obj:IsA("Model") then
                modelCount = modelCount + 1
            elseif obj:IsA("BaseScript") then
                scriptCount = scriptCount + 1
            end
        end
        
        local objectInfo = string.format("Parts: %d, Models: %d, Scripts: %d", partCount, modelCount, scriptCount)
        CopyToClipboard(objectInfo)
        Notify("Object Count", objectInfo, 4, "box")
    end
})

-- =========================
-- System Tab
-- =========================
SystemTab:Button({
    Title = "Get Network Info",
    Icon = "wifi",
    Callback = function()
        local networkInfo = string.format("Ping: %s, Region: %s", GetPing(), GetServerRegion())
        CopyToClipboard(networkInfo)
        Notify("Network Info", networkInfo, 3, "wifi")
    end
})

SystemTab:Button({
    Title = "Get System Stats",
    Icon = "activity",
    Callback = function()
        local stats = game:GetService("Stats")
        local memory = math.floor(stats:GetTotalMemoryUsageMb())
        local systemInfo = string.format("Memory Usage: %d MB, FPS: %d", memory, GetFPS())
        CopyToClipboard(systemInfo)
        Notify("System Stats", systemInfo, 3, "activity")
    end
})

SystemTab:Button({
    Title = "Export All Info",
    Icon = "download",
    Callback = function()
        local allInfo = {
            ["Game Name"] = GameName,
            ["Game ID"] = GameId,
            ["Place ID"] = PlaceId,
            ["Job ID"] = JobId,
            ["Player Count"] = GetPlayerCount() .. "/" .. GetMaxPlayers(),
            ["Current Position"] = GetCurrentPosition(),
            ["Network Ping"] = GetPing(),
            ["Server Region"] = GetServerRegion(),
            ["Time of Day"] = Lighting.TimeOfDay,
            ["Memory Usage"] = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb()) .. " MB"
        }
        
        local infoString = ""
        for key, value in pairs(allInfo) do
            infoString = infoString .. key .. ": " .. value .. "\n"
        end
        
        CopyToClipboard(infoString)
        Notify("Export Complete", "All information exported to clipboard", 4, "download")
    end
})

-- =========================
-- Auto-refresh player list
-- =========================
Players.PlayerAdded:Connect(function(newPlayer)
    Notify("Player Joined", newPlayer.Name .. " joined the server", 2, "user-plus")
end)

Players.PlayerRemoving:Connect(function(leftPlayer)
    Notify("Player Left", leftPlayer.Name .. " left the server", 2, "user-minus")
end)

-- =========================
-- Initial notification
-- =========================
Notify("MangoHub Loaded", "Welcome to " .. GameName, 3, "zap")