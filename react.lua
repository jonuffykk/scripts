local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
if not player then return end

local PingRemote = ReplicatedStorage:WaitForChild("Events", 30):WaitForChild("UpdatePing", 30)
if not PingRemote then return end

local Config = {
    Active = false,
    MinPing = 70,
    MaxPing = 90,
    UpdateTime = 2,
    DynamicMode = false,
    DynamicReduction = 60,
    MaxFails = 3,
    Timeout = 10,
    CheckInterval = 0.1,
    FailCount = 0,
    MossHelper = false,
    ShowHitbox = false,
    HeadSize = Vector3.new(2, 2, 2),
    HeadOffset = Vector3.new(0, 0, 0),
    HeadTransparency = 0.5
}

local Window = Rayfield:CreateWindow({
    Name = "React Plus",
    LoadingTitle = "React Plus",
    LoadingSubtitle = "by Jonuffy",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "ReactPlus"
    },
    KeySystem = true,
    KeySettings = {
        Title = "React Plus",
        Subtitle = "Key System",
        Note = "Você pode pegar essa key no meu discord (jonuffykk).",
        FileName = "ReactPlusKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"dilton"}
    }
})

local ReactTab = Window:CreateTab("React", 4483362458)
local PingTab = Window:CreateTab("Ping", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

local statusLabel = PingTab:CreateLabel("Status: Disabled")
local pingLabel = PingTab:CreateLabel("Your Ping: 0ms")

local function getRealPing()
    local success, ping = pcall(function()
        return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return success and ping or 0
end

local function safeUpdateHeadSize()
    if not player.Character or not player.Character:FindFirstChild("Head") then return end
    local head = player.Character.Head

    if Config.MossHelper then
        head.Size = Config.HeadSize
        head.Position = head.Position + Config.HeadOffset
        head.Transparency = Config.HeadTransparency
    else
        head.Size = Vector3.new(2, 2, 2)
        head.Position = head.Position - Config.HeadOffset
        head.Transparency = 0
    end
end

local function createHitboxVisualizer()
    if not player.Character or not player.Character:FindFirstChild("Head") then return end

    local existingHitbox = player.Character:FindFirstChild("HitboxVisualizer")
    if existingHitbox then existingHitbox:Destroy() end

    if Config.ShowHitbox then
        local hitboxPart = Instance.new("Part")
        hitboxPart.Name = "HitboxVisualizer"
        hitboxPart.Anchored = false
        hitboxPart.CanCollide = false
        hitboxPart.Transparency = 0.6
        hitboxPart.BrickColor = BrickColor.new("Really red")
        hitboxPart.Material = Enum.Material.Neon
        hitboxPart.Size = player.Character.Head.Size

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = hitboxPart
        weld.Part1 = player.Character.Head
        weld.Parent = hitboxPart

        hitboxPart.CFrame = player.Character.Head.CFrame
        hitboxPart.Parent = player.Character
    end
end

ReactTab:CreateSection("Main Controls")

ReactTab:CreateToggle({
    Name = "Moss Helper",
    Info = {
        Title = "Moss Helper",
        Description = "Modifies head size and position"
    },
    CurrentValue = Config.MossHelper,
    Flag = "MossHelper",
    Callback = function(Value)
        Config.MossHelper = Value
        safeUpdateHeadSize()
        createHitboxVisualizer()
    end
})

ReactTab:CreateToggle({
    Name = "Show Hitbox",
    Info = {
        Title = "Show Hitbox",
        Description = "Displays head hitbox visualization"
    },
    CurrentValue = Config.ShowHitbox,
    Flag = "ShowHitbox",
    Callback = function(Value)
        Config.ShowHitbox = Value
        createHitboxVisualizer()
    end
})

ReactTab:CreateInput({
    Name = "Head Size (X,Y,Z)",
    PlaceholderText = "2,2,2",
    NumbersOnly = true,
    RemoveTextAfterFocusLost = false,
    Flag = "HeadSize",
    Callback = function(Text)
        local x, y, z = Text:match("([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)")
        x, y, z = tonumber(x), tonumber(y), tonumber(z)

        if x and y and z then
            Config.HeadSize = Vector3.new(x, y, z)
            if Config.MossHelper then
                safeUpdateHeadSize()
                createHitboxVisualizer()
            end
            return true
        end
        return false
    end
})

ReactTab:CreateInput({
    Name = "Head Offset (X,Y,Z)",
    PlaceholderText = "0,0,0",
    NumbersOnly = true,
    RemoveTextAfterFocusLost = false,
    Flag = "HeadOffset",
    Callback = function(Text)
        local x, y, z = Text:match("([^,]+)%s*,%s*([^,]+)%s*,%s*([^,]+)")
        x, y, z = tonumber(x), tonumber(y), tonumber(z)

        if x and y and z then
            Config.HeadOffset = Vector3.new(x, y, z)
            if Config.MossHelper then
                safeUpdateHeadSize()
                createHitboxVisualizer()
            end
            return true
        end
        return false
    end
})

ReactTab:CreateSlider({
    Name = "Head Transparency",
    Info = {
        Title = "Head Transparency",
        Description = "Adjust head visibility"
    },
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = Config.HeadTransparency,
    Flag = "HeadTransparency",
    Callback = function(Value)
        Config.HeadTransparency = Value
        safeUpdateHeadSize()
    end
})

PingTab:CreateSection("Controls")

local function updatePing()
    if not Config.Active then return end

    local clientPing = player.PlayerScripts:FindFirstChild("ClientPing")
    if clientPing then clientPing.Enabled = not Config.Active end

    local currentPing = getRealPing()
    local pingToSend = Config.DynamicMode and
        math.random(Config.MinPing, Config.MaxPing) or
        math.max(1, currentPing - Config.DynamicReduction)

    local success = pcall(function()
        PingRemote:FireServer(pingToSend)
        statusLabel:Set("Status: " .. (Config.DynamicMode and
            string.format("Range: %d-%d ms", Config.MinPing, Config.MaxPing) or
            string.format("Reducing %d ms", Config.DynamicReduction)))
    end)

    if not success then
        Config.FailCount = Config.FailCount + 1
        if Config.FailCount >= Config.MaxFails then
            Config.Active = false
            if clientPing then clientPing.Enabled = true end
            statusLabel:Set("Status: Error - Too many fails")
            Rayfield:Notify({
                Title = "Error",
                Content = "System disabled due to failures",
                Duration = 3
            })
        end
    else
        Config.FailCount = 0
    end
end

local function startPingLoop()
    local startTime = tick()
    while not player:FindFirstChild('leaderstats') and tick() - startTime <= Config.Timeout do
        task.wait(Config.CheckInterval)
    end

    if not player:FindFirstChild('leaderstats') then
        Config.Active = false
        statusLabel:Set("Status: Error - Timeout")
        Rayfield:Notify({
            Title = "Error",
            Content = "System timeout - leaderstats not found",
            Duration = 3
        })
        return
    end

    task.spawn(function()
        while Config.Active do
            updatePing()
            task.wait(Config.UpdateTime)
        end
    end)
end

local function autoUpdateSystem()
    RunService.Heartbeat:Connect(function()
        if Config.Active then
            pingLabel:Set("Your Ping: " .. getRealPing() .. "ms")

            local clientPing = player.PlayerScripts:FindFirstChild("ClientPing")
            if clientPing and clientPing.Enabled ~= not Config.Active then
                clientPing.Enabled = not Config.Active
            end
        end
    end)
end

local function initializeSystem()
    loadSettings()
    task.wait(0.5)

    pcall(function()
        if Config.MossHelper then
            safeUpdateHeadSize()
        end
        if Config.ShowHitbox then
            createHitboxVisualizer()
        end
        autoUpdateSystem()
    end)
end

PingTab:CreateToggle({
    Name = "Enable React Plus",
    Info = {
        Title = "React Plus",
        Description = "Toggles the ping modification system"
    },
    CurrentValue = Config.Active,
    Flag = "ReactEnabled",
    Callback = function(Value)
        Config.Active = Value
        Config.FailCount = 0

        local clientPing = player.PlayerScripts:FindFirstChild("ClientPing")
        if clientPing then
            clientPing.Enabled = not Value
        end

        if Value then
            startPingLoop()
        else
            statusLabel:Set("Status: Disabled")
        end
    end
})

local dynamicToggle = PingTab:CreateToggle({
    Name = "Dynamic Mode",
    Info = "Toggle between dynamic and reduction mode",
    CurrentValue = Config.DynamicMode,
    Flag = "ToggleDynamic",
    Callback = function(Value)
        Config.DynamicMode = Value
    end
})

PingTab:CreateSection("Adjustments")

local sliderReduction = PingTab:CreateSlider({
    Name = "Reduction",
    Info = "Value to reduce from current ping",
    Range = {1, 200},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = Config.DynamicReduction,
    Flag = "SliderReduction",
    Callback = function(Value)
        Config.DynamicReduction = Value
    end
})

local sliderMin = PingTab:CreateSlider({
    Name = "Minimum",
    Info = "Minimum ping (dynamic mode)",
    Range = {1, 200},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = Config.MinPing,
    Flag = "SliderMinPing",
    Callback = function(Value)
        Config.MinPing = Value
        if Config.MinPing > Config.MaxPing then
            Config.MaxPing = Value
            if sliderMax then sliderMax:Set(Value) end
        end
    end
})

local sliderMax = PingTab:CreateSlider({
    Name = "Maximum",
    Info = "Maximum ping (dynamic mode)",
    Range = {1, 200},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = Config.MaxPing,
    Flag = "SliderMaxPing",
    Callback = function(Value)
        Config.MaxPing = Value
        if Config.MaxPing < Config.MinPing then
            Config.MinPing = Value
            if sliderMin then sliderMin:Set(Value) end
        end
    end
})

SettingsTab:CreateSection("System")

local function saveSettings()
    local savedData = {
        MinPing = Config.MinPing,
        MaxPing = Config.MaxPing,
        UpdateTime = Config.UpdateTime,
        DynamicMode = Config.DynamicMode,
        DynamicReduction = Config.DynamicReduction,
        MaxFails = Config.MaxFails,
        Timeout = Config.Timeout,
        CheckInterval = Config.CheckInterval,
        MossHelper = Config.MossHelper,
        ShowHitbox = Config.ShowHitbox,
        HeadSize = {Config.HeadSize.X, Config.HeadSize.Y, Config.HeadSize.Z},
        HeadOffset = {Config.HeadOffset.X, Config.HeadOffset.Y, Config.HeadOffset.Z},
        HeadTransparency = Config.HeadTransparency
    }
    writefile("ReactPlus.json", HttpService:JSONEncode(savedData))
end

local function loadSettings()
    if isfile("ReactPlus.json") then
        local success, savedData = pcall(function()
            return HttpService:JSONDecode(readfile("ReactPlus.json"))
        end)

        if success and savedData then
            for key, value in pairs(savedData) do
                if key == "HeadSize" or key == "HeadOffset" then
                    Config[key] = Vector3.new(value[1], value[2], value[3])
                else
                    Config[key] = value
                end
            end
        end
    end
end

SettingsTab:CreateSlider({
    Name = "Update Time",
    Info = "Interval between updates",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = Config.UpdateTime,
    Flag = "UpdateTime",
    Callback = function(Value)
        Config.UpdateTime = Value
    end
})

SettingsTab:CreateSlider({
    Name = "Max Fails",
    Info = "Maximum fails before disable",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = Config.MaxFails,
    Flag = "MaxFails",
    Callback = function(Value)
        Config.MaxFails = Value
    end
})

RunService.Heartbeat:Connect(function()
    if Config.Active then
        pingLabel:Set("Your Ping: " .. getRealPing() .. "ms")
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.End and not gameProcessed then
        Rayfield:Toggle()
    end
end)

local function loadSavedConfig()
    pcall(function()
        if Config.MossHelper then
            safeUpdateHeadSize()
        end
        if Config.ShowHitbox then
            createHitboxVisualizer()
        end
    end)
end

loadSettings()
task.wait(0.5)
pcall(function()
    if Config.MossHelper then
        safeUpdateHeadSize()
    end
    if Config.ShowHitbox then
        createHitboxVisualizer()
    end
end)

player.CharacterAdded:Connect(function(char)
    local head = char:WaitForChild("Head", 10)
    if head then
        task.wait(0.1)
        if Config.MossHelper then safeUpdateHeadSize() end
        if Config.ShowHitbox then createHitboxVisualizer() end
    end
end)

player.CharacterRemoving:Connect(function()
    local hitboxPart = player.Character and player.Character:FindFirstChild("HitboxVisualizer")
    if hitboxPart then hitboxPart:Destroy() end
end)

RunService.Heartbeat:Connect(function()
    if Config.MossHelper and player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head
        pcall(function()
            if head.Size ~= Config.HeadSize then
                safeUpdateHeadSize()
            end

            if Config.ShowHitbox then
                createHitboxVisualizer()
            end
        end)
    end
end)
