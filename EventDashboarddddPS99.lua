local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local player = Players.LocalPlayer

local StatGUI = {
    Enable = true,
    AutoReconnect = true,
    WebhookUrl = getgenv().WebhookUrl or "YOUR_DISCORD_WEBHOOK_URL_HERE",
    WebhookInterval = 3600,
    WebhookEnabled = true,
    Items = {
        {Class = "Currency", Item = "Diamonds"},
        {Class = "Currency", Item = "FiestaOrbs"},
        {Class = "Currency", Item = "MazeLevel"},
        {Class = "Misc", Item = "Fiesta Key"},
        {Class = "Lootbox", Item = "Fiesta Gift"},
    }
}

if not StatGUI.Enable then return end

local function sendRawWebhook(payload)
    if not StatGUI.WebhookEnabled then return end
    if StatGUI.WebhookUrl and StatGUI.WebhookUrl ~= "" and StatGUI.WebhookUrl ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        pcall(function()
            local encodedData = HttpService:JSONEncode(payload)
            local requestFunc = syn and syn.request or http_request or request or HttpPost
            if requestFunc then
                requestFunc({
                    Url = StatGUI.WebhookUrl,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = encodedData
                })
            end
        end)
    end
end

if getgenv().StatGUI_Connections then
    for _, conn in ipairs(getgenv().StatGUI_Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
end
getgenv().StatGUI_Connections = {}

if getgenv().HasSentDisconnect == nil then
    getgenv().HasSentDisconnect = false
end

local function handleDisconnect(reason)
    if getgenv().HasSentDisconnect then return end
    getgenv().HasSentDisconnect = true
    
    local payload = {
        ["embeds"] = {{
            ["title"] = "⚠️ Disconnect Alert - " .. player.Name,
            ["description"] = "The player has been disconnected from the game.\n**Reason:** " .. tostring(reason) .. (StatGUI.AutoReconnect and "\n\n*Attempting automatic server rejoin...*" or ""),
            ["color"] = 16711680,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }
    sendRawWebhook(payload)
    
    if StatGUI.AutoReconnect then
        task.wait(1)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
        task.wait(5)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if getgenv().HasSentDisconnect then break end
        
        pcall(function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            if robloxGui then
                local promptDialog = robloxGui:FindFirstChild("PromptDialog", true)
                if promptDialog and promptDialog.Visible then
                    handleDisconnect("Network Disconnect / Error Prompt Triggered")
                end
            end
        end)
    end
end)

local conn2 = Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        handleDisconnect("Player left / Client Closed")
    end
end)
table.insert(getgenv().StatGUI_Connections, conn2)

local trackedPetRarities = {
    ["huge"] = true,
    ["titanic"] = true,
    ["gargantuan"] = true
}

local knownPetsInventory = {}
local isFirstInventoryCheck = true

local function sendPetNotification(petName, petRarity)
    local colorMap = {
        ["huge"] = 3447003,
        ["titanic"] = 10181046,
        ["gargantuan"] = 16776960
    }
    
    local payload = {
        ["embeds"] = {{
            ["title"] = "🎉 Rare Pet Obtained! - " .. player.Name,
            ["description"] = string.format("You just hatched or received a **%s** rarity pet!\n\n**Pet Name:** %s", petRarity:upper(), petName),
            ["color"] = colorMap[petRarity:lower()] or 65280,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }
    sendRawWebhook(payload)
end

local function checkInventoryForRarePets(savedata)
    if not savedata or not savedata.Inventory then return end
    
    local currentInventoryPets = {}
    
    pcall(function()
        for _, category in pairs(savedata.Inventory) do
            if type(category) == "table" then
                for _, itemData in pairs(category) do
                    if type(itemData) == "table" then
                        local petName = itemData.id or itemData.Item or itemData.name or "Unknown Pet"
                        local rarity = tostring(itemData.rarity or itemData.Tier or itemData.Class or itemData.type or ""):lower()
                        local isRare = false
                        
                        if trackedPetRarities[rarity] then
                            isRare = true
                        else
                            local nameLower = petName:lower()
                            if nameLower:find("huge") then
                                rarity = "huge"
                                isRare = true
                            elseif nameLower:find("titanic") then
                                rarity = "titanic"
                                isRare = true
                            elseif nameLower:find("gargantuan") then
                                rarity = "gargantuan"
                                isRare = true
                            end
                        end
                        
                        if isRare then
                            local uniqueKey = tostring(itemData.uid or itemData.UUID or (petName "_" tostring(itemData.amount or 1)))
                            currentInventoryPets[uniqueKey] = {Name = petName, Rarity = rarity}
                            
                            if not isFirstInventoryCheck and not knownPetsInventory[uniqueKey] then
                                sendPetNotification(petName, rarity)
                            end
                        end
                    end
                end
            end
        end
    end)
    
    knownPetsInventory = currentInventoryPets
    isFirstInventoryCheck = false
end

local targetParent = player:WaitForChild("PlayerGui")
pcall(function()
    if syn and syn.protect_gui then
        local protected = Instance.new("ScreenGui")
        syn.protect_gui(protected)
        protected.Parent = CoreGui
        targetParent = CoreGui
    elseif gethui then
        targetParent = gethui()
    end
end)

if targetParent:FindFirstChild("CustomStatGUI") then
    targetParent.CustomStatGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomStatGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 2147483647
screenGui.Parent = targetParent

local antiAfkActive = true

local idleConn = player.Idled:Connect(function()
    if antiAfkActive then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0, 0))
        end)
    end
end)
table.insert(getgenv().StatGUI_Connections, idleConn)

task.spawn(function()
    while screenGui.Parent do
        if antiAfkActive then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:Button1Down(Vector2.new(0, 0))
                task.wait(0.1)
                VirtualUser:Button1Up(Vector2.new(0, 0))
                VirtualUser:MoveMouse(Vector2.new(math.random(150, 450), math.random(150, 450)))
            end)
        end
        task.wait(30)
    end
end)

local solidBackground = Instance.new("Frame")
solidBackground.Name = "SolidBackground"
solidBackground.Size = UDim2.new(1, 0, 1, 0)
solidBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
solidBackground.BorderSizePixel = 0
solidBackground.ZIndex = 0
solidBackground.Visible = false
solidBackground.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 520, 0, 365)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local neonStroke = Instance.new("UIStroke")
neonStroke.Color = Color3.fromRGB(70, 130, 255)
neonStroke.Thickness = 2
neonStroke.Parent = mainFrame

local modalOverlay = Instance.new("Frame")
modalOverlay.Size = UDim2.new(1, 0, 1, 0)
modalOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
modalOverlay.BackgroundTransparency = 0.5
modalOverlay.Visible = (StatGUI.WebhookUrl == "" or StatGUI.WebhookUrl == "YOUR_DISCORD_WEBHOOK_URL_HERE")
modalOverlay.ZIndex = 100
modalOverlay.Parent = screenGui

local modalFrame = Instance.new("Frame")
modalFrame.Size = UDim2.new(0, 300, 0, 150)
modalFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
modalFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
modalFrame.ZIndex = 101
modalFrame.Parent = modalOverlay

local modalCorner = Instance.new("UICorner")
modalCorner.CornerRadius = UDim.new(0, 10)
modalCorner.Parent = modalFrame

local modalStroke = Instance.new("UIStroke")
modalStroke.Color = Color3.fromRGB(60, 70, 95)
modalStroke.Thickness = 1.5
modalStroke.Parent = modalFrame

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, 0, 0, 35)
modalTitle.BackgroundTransparency = 1
modalTitle.Font = Enum.Font.GothamBold
modalTitle.Text = "Enter Discord Webhook URL"
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.TextSize = 13
modalTitle.ZIndex = 102
modalTitle.Parent = modalFrame

local webhookBox = Instance.new("TextBox")
webhookBox.Size = UDim2.new(0, 260, 0, 35)
webhookBox.Position = UDim2.new(0.5, -130, 0, 45)
webhookBox.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
webhookBox.Font = Enum.Font.Gotham
webhookBox.PlaceholderText = "Paste Webhook URL here..."
webhookBox.Text = ""
webhookBox.TextColor3 = Color3.fromRGB(220, 225, 240)
webhookBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
webhookBox.TextSize = 11
webhookBox.ClearTextOnFocus = false
webhookBox.ZIndex = 102
webhookBox.Parent = modalFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = webhookBox

local submitButton = Instance.new("TextButton")
submitButton.Size = UDim2.new(0, 260, 0, 35)
submitButton.Position = UDim2.new(0.5, -130, 0, 95)
submitButton.BackgroundColor3 = Color3.fromRGB(60, 130, 246)
submitButton.Font = Enum.Font.GothamBold
submitButton.Text = "Submit & Close"
submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
submitButton.TextSize = 12
submitButton.ZIndex = 102
submitButton.Parent = modalFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = submitButton

submitButton.MouseButton1Click:Connect(function()
    local text = webhookBox.Text
    if text and text ~= "" then
        StatGUI.WebhookUrl = text
        getgenv().WebhookUrl = text
        modalOverlay.Visible = false
    end
end)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 138, 0, 22)
titleLabel.Position = UDim2.new(0, 10, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Hennessy PS99"
titleLabel.TextColor3 = Color3.fromRGB(240, 244, 255)
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.ZIndex = 3
titleLabel.Parent = mainFrame

local avatarImage = Instance.new("ImageLabel")
avatarImage.Size = UDim2.new(0, 44, 0, 44)
avatarImage.Position = UDim2.new(0, 57, 0, 36)
avatarImage.BackgroundTransparency = 1
avatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
avatarImage.ZIndex = 3
avatarImage.Parent = mainFrame

local avatarCorner = Instance.new("UICorner")
avatarCorner.CornerRadius = UDim.new(1, 0)
avatarCorner.Parent = avatarImage

local usernameLabel = Instance.new("TextLabel")
usernameLabel.Size = UDim2.new(0, 138, 0, 18)
usernameLabel.Position = UDim2.new(0, 10, 0, 83)
usernameLabel.BackgroundTransparency = 1
usernameLabel.Font = Enum.Font.GothamMedium
usernameLabel.Text = "@" .. player.Name
usernameLabel.TextColor3 = Color3.fromRGB(160, 180, 210)
usernameLabel.TextSize = 11
usernameLabel.TextXAlignment = Enum.TextXAlignment.Center
usernameLabel.ZIndex = 3
usernameLabel.Parent = mainFrame

local killButton = Instance.new("TextButton")
killButton.Size = UDim2.new(0, 32, 0, 32)
killButton.Position = UDim2.new(1, -40, 0, 9)
killButton.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
killButton.Font = Enum.Font.GothamBold
killButton.Text = "X"
killButton.TextColor3 = Color3.fromRGB(255, 100, 100)
killButton.TextSize = 16
killButton.ZIndex = 3
killButton.Parent = mainFrame

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 6)
killCorner.Parent = killButton

local killStroke = Instance.new("UIStroke")
killStroke.Color = Color3.fromRGB(100, 110, 130)
killStroke.Thickness = 1
killStroke.Parent = killButton

local bgModes = {"None", "Cyan", "White", "Black"}
local bgModeLabels = {"Background: None (default)", "Background: cyan", "Background: white", "Background: black"}
local currentModeIndex = 1

local bgModeButton = Instance.new("TextButton")
bgModeButton.Size = UDim2.new(0, 185, 0, 32)
bgModeButton.Position = UDim2.new(1, -231, 0, 9)
bgModeButton.BackgroundColor3 = Color3.fromRGB(45, 50, 65)
bgModeButton.Font = Enum.Font.GothamBold
bgModeButton.Text = bgModeLabels[currentModeIndex]
bgModeButton.TextColor3 = Color3.fromRGB(200, 220, 255)
bgModeButton.TextSize = 10
bgModeButton.ZIndex = 3
bgModeButton.Parent = mainFrame

local bgCorner = Instance.new("UICorner")
bgCorner.CornerRadius = UDim.new(0, 6)
bgCorner.Parent = bgModeButton

local bgModeStroke = Instance.new("UIStroke")
bgModeStroke.Color = Color3.fromRGB(100, 110, 130)
bgModeStroke.Thickness = 1
bgModeStroke.Parent = bgModeButton

local leftPanel = Instance.new("Frame")
leftPanel.Size = UDim2.new(0, 138, 1, -112)
leftPanel.Position = UDim2.new(0, 10, 0, 104)
leftPanel.BackgroundTransparency = 1
leftPanel.ZIndex = 2
leftPanel.Parent = mainFrame

local leftList = Instance.new("UIListLayout")
leftList.SortOrder = Enum.SortOrder.LayoutOrder
leftList.Padding = UDim.new(0, 4)
leftList.Parent = leftPanel

local function styleButton(btn)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 70, 95)
    stroke.Thickness = 1.2
    stroke.Parent = btn
end

local antiAfkButton = Instance.new("TextButton")
antiAfkButton.Size = UDim2.new(1, 0, 0, 32)
antiAfkButton.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
antiAfkButton.Font = Enum.Font.GothamBold
antiAfkButton.Text = "Anti AFK: On"
antiAfkButton.TextColor3 = Color3.fromRGB(100, 255, 150)
antiAfkButton.TextSize = 10
antiAfkButton.LayoutOrder = 1
antiAfkButton.ZIndex = 3
antiAfkButton.Parent = leftPanel
styleButton(antiAfkButton)

local autoReconnectButton = Instance.new("TextButton")
autoReconnectButton.Size = UDim2.new(1, 0, 0, 32)
autoReconnectButton.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
autoReconnectButton.Font = Enum.Font.GothamBold
autoReconnectButton.Text = "Auto Recon: On"
autoReconnectButton.TextColor3 = StatGUI.AutoReconnect and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 100, 150)
autoReconnectButton.TextSize = 10
autoReconnectButton.LayoutOrder = 2
autoReconnectButton.ZIndex = 3
autoReconnectButton.Parent = leftPanel
styleButton(autoReconnectButton)

local webhookKillButton = Instance.new("TextButton")
webhookKillButton.Size = UDim2.new(1, 0, 0, 32)
webhookKillButton.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
webhookKillButton.Font = Enum.Font.GothamBold
webhookKillButton.Text = "Webhook: On"
webhookKillButton.TextColor3 = Color3.fromRGB(100, 255, 150)
webhookKillButton.TextSize = 10
webhookKillButton.LayoutOrder = 3
webhookKillButton.ZIndex = 3
webhookKillButton.Parent = leftPanel
styleButton(webhookKillButton)

local testWebhookButton = Instance.new("TextButton")
testWebhookButton.Size = UDim2.new(1, 0, 0, 32)
testWebhookButton.BackgroundColor3 = Color3.fromRGB(25, 55, 45)
testWebhookButton.Font = Enum.Font.GothamBold
testWebhookButton.Text = "Webhook Test"
testWebhookButton.TextColor3 = Color3.fromRGB(100, 255, 200)
testWebhookButton.TextSize = 10
testWebhookButton.LayoutOrder = 4
testWebhookButton.ZIndex = 3
testWebhookButton.Parent = leftPanel
styleButton(testWebhookButton)
testWebhookButton:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(40, 160, 100)

local fpsButton = Instance.new("TextButton")
fpsButton.Size = UDim2.new(1, 0, 0, 32)
fpsButton.BackgroundColor3 = Color3.fromRGB(55, 40, 20)
fpsButton.Font = Enum.Font.GothamBold
fpsButton.Text = "FPS Booster"
fpsButton.TextColor3 = Color3.fromRGB(255, 200, 100)
fpsButton.TextSize = 11
fpsButton.LayoutOrder = 5
fpsButton.ZIndex = 3
fpsButton.Parent = leftPanel
styleButton(fpsButton)
fpsButton:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(180, 120, 40)

local statsBox = Instance.new("Frame")
statsBox.Size = UDim2.new(1, -165, 1, -55)
statsBox.Position = UDim2.new(0, 158, 0, 48)
statsBox.BackgroundColor3 = Color3.fromRGB(16, 19, 27)
statsBox.BorderSizePixel = 0
statsBox.ZIndex = 2
statsBox.Parent = mainFrame

local statsBoxCorner = Instance.new("UICorner")
statsBoxCorner.CornerRadius = UDim.new(0, 8)
statsBoxCorner.Parent = statsBox

local statsBoxStroke = Instance.new("UIStroke")
statsBoxStroke.Color = Color3.fromRGB(45, 55, 80)
statsBoxStroke.Thickness = 1.2
statsBoxStroke.Parent = statsBox

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, -12, 1, -12)
contentHolder.Position = UDim2.new(0, 6, 0, 6)
contentHolder.BackgroundTransparency = 1
contentHolder.ZIndex = 3
contentHolder.Parent = statsBox

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 3)
uiList.Parent = contentHolder

local function showWebhookSentNotification()
    pcall(function()
        local notif = Instance.new("TextLabel")
        notif.Size = UDim2.new(0, 180, 0, 30)
        notif.AnchorPoint = Vector2.new(0.5, 0)
        notif.Position = UDim2.new(0.5, 0, 0, 15)
        notif.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
        notif.TextColor3 = Color3.fromRGB(100, 255, 150)
        notif.Font = Enum.Font.GothamBold
        notif.TextSize = 12
        notif.Text = "webhook sent"
        notif.ZIndex = 10
        notif.Parent = mainFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = notif

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(50, 200, 100)
        stroke.Thickness = 1
        stroke.Parent = notif

        task.delay(2, function()
            if notif and notif.Parent then
                notif:Destroy()
            end
        end)
    end)
end

local valueLabels = {}
local function sendWebhookNotification(isTest)
    if not StatGUI.WebhookEnabled then return end
    if StatGUI.WebhookUrl and StatGUI.WebhookUrl ~= "" and StatGUI.WebhookUrl ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        pcall(function()
            local fields = {}
            for _, pair in ipairs(valueLabels or {}) do
                local nameLower = pair.ItemName:lower()
                if nameLower ~= "fiestacoins" and nameLower ~= "fiesta coins" and nameLower ~= "fiesta candy" then
                    table.insert(fields, {
                        name = pair.ItemName,
                        value = pair.Label.Text,
                        inline = true
                    })
                end
            end
            
            local titlePrefix = isTest and "🧪 TEST Webhook Report - " or "📊 Hourly Stat Report - "
            local data = {
                ["embeds"] = {{
                    ["title"] = titlePrefix .. player.Name,
                    ["color"] = isTest and 65280 or 3066993, 
                    ["fields"] = fields,
                    ["footer"] = {
                        ["text"] = os.date("%Y-%m-%d %H:%M:%S")
                    }
                }}
            }
            sendRawWebhook(data)
        end)
    end
end

fpsButton.MouseButton1Click:Connect(function()
    pcall(function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("BloomEffect") or v:IsA("SunRaysEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("Clouds") then
                v:Destroy()
            end
        end
        
        local greyEffect = Instance.new("ColorCorrectionEffect")
        greyEffect.Saturation = -1
        greyEffect.Brightness = 0.05
        greyEffect.Contrast = 0.1
        greyEffect.Parent = Lighting

        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 1.5
        Lighting.ClockTime = 14
        Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
        Lighting.Ambient = Color3.fromRGB(120, 120, 120)

        if Terrain then
            pcall(function()
                Terrain.WaterWaveSize = 0
                Terrain.WaterWaveSpeed = 0
                Terrain.WaterTransparency = 1
                Terrain.WaterReflectance = 0
                Terrain.Decoration = false
            end)
        end

        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SpecialMesh") then
                    obj:Destroy()
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                    obj:Destroy()
                elseif obj:IsA("Explosion") then
                    obj:Destroy()
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Color = Color3.fromRGB(140, 140, 140)
                    obj.Reflectance = 0
                    obj.CastShadow = false
                elseif obj:IsA("Light") then
                    obj.Enabled = false
                end
            end)
        end

        Workspace.DescendantAdded:Connect(function(obj)
            pcall(function()
                if obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SpecialMesh") or obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Trail") or obj:IsA("Beam") then
                    task.defer(function() obj:Destroy() end)
                elseif obj:IsA("BasePart") then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Color = Color3.fromRGB(140, 140, 140)
                    obj.Reflectance = 0
                    obj.CastShadow = false
                elseif obj:IsA("Light") then
                    obj.Enabled = false
                end
            end)
        end)

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            UserSettings().GameSettings.SavedQualityLevel = Enum.SavedQualityLevel.Level1
        end)

        fpsButton.TextColor3 = Color3.fromRGB(100, 255, 150)
        fpsButton.Text = "optimized"
    end)
end)

webhookKillButton.MouseButton1Click:Connect(function()
    StatGUI.WebhookEnabled = not StatGUI.WebhookEnabled
    if StatGUI.WebhookEnabled then
        webhookKillButton.Text = "Webhook: On"
        webhookKillButton.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        webhookKillButton.Text = "Webhook: Off"
        webhookKillButton.TextColor3 = Color3.fromRGB(255, 100, 150)
    end
end)

testWebhookButton.MouseButton1Click:Connect(function()
    if not StatGUI.WebhookEnabled then return end
    sendWebhookNotification(true)
    showWebhookSentNotification()
end)

antiAfkButton.MouseButton1Click:Connect(function()
    antiAfkActive = not antiAfkActive
    if antiAfkActive then
        antiAfkButton.Text = "Anti AFK: On"
        antiAfkButton.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        antiAfkButton.Text = "Anti AFK: Off"
        antiAfkButton.TextColor3 = Color3.fromRGB(255, 100, 150)
    end
end)

autoReconnectButton.MouseButton1Click:Connect(function()
    StatGUI.AutoReconnect = not StatGUI.AutoReconnect
    if StatGUI.AutoReconnect then
        autoReconnectButton.Text = "Auto Recon: On"
        autoReconnectButton.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        autoReconnectButton.Text = "Auto Recon: Off"
        autoReconnectButton.TextColor3 = Color3.fromRGB(255, 100, 150)
    end
end)

bgModeButton.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex + 1
    if currentModeIndex > #bgModes then
        currentModeIndex = 1
    end
    
    local mode = bgModes[currentModeIndex]
    bgModeButton.Text = bgModeLabels[currentModeIndex]
    
    if mode == "None" then
        solidBackground.Visible = false
    elseif mode == "Cyan" then
        solidBackground.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
        solidBackground.Visible = true
    elseif mode == "White" then
        solidBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        solidBackground.Visible = true
    elseif mode == "Black" then
        solidBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        solidBackground.Visible = true
    end
end)

killButton.MouseButton1Click:Connect(function()
    antiAfkActive = false
    screenGui:Destroy()
end)

for index, entry in ipairs(StatGUI.Items) do
    local itemRow = Instance.new("Frame")
    itemRow.Size = UDim2.new(1, 0, 0, 32)
    itemRow.Position = UDim2.new(0, 0, 0, 0)
    itemRow.BackgroundTransparency = 1
    itemRow.LayoutOrder = index
    itemRow.ZIndex = 4
    itemRow.Parent = contentHolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.48, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 4, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.Text = entry.Item .. ":"
    nameLabel.TextColor3 = Color3.fromRGB(210, 220, 240)
    nameLabel.TextSize = 13
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 5
    nameLabel.Parent = itemRow

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.52, -8, 1, 0)
    valueLabel.Position = UDim2.new(0.48, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "0"
    valueLabel.TextColor3 = Color3.fromRGB(50, 255, 200)
    valueLabel.TextSize = 13
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 5
    valueLabel.Parent = itemRow
    
    table.insert(valueLabels, {Label = valueLabel, ItemName = entry.Item, Class = entry.Class})
end

local function formatWithCommas(number)
    local formatted = tostring(number)
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function getStatValue(itemName)
    local val = 0
    pcall(function()
        local targetLower = itemName:lower():gsub("%s+", "")

        if targetLower == "mazelevel" then
            local successFiesta, FiestaLevelCmds = pcall(function()
                return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("FiestaLevelCmds"))
            end)
            if successFiesta and FiestaLevelCmds and type(FiestaLevelCmds.Get) == "function" then
                val = FiestaLevelCmds.Get() or 0
                if val > 0 then return end
            end
        end

        if targetLower == "diamonds" then
            local leaderstats = player:FindFirstChild("leaderstats")
            if leaderstats then
                for _, stat in ipairs(leaderstats:GetChildren()) do
                    if stat.Name:lower():find("diamond") or stat.Name:lower():find("gem") then
                        val = tonumber(stat.Value) or 0
                        if val > 0 then return end
                    end
                end
            end
            if player:GetAttribute("Diamonds") then
                val = player:GetAttribute("Diamonds")
                if val > 0 then return end
            end
        end

        local success, Save = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save"))
        end)
        
        if success and Save then
            val = 0
            local savedata = nil
            if type(Save.Get) == "function" then
                savedata = Save.Get()
            elseif type(Save.GetStore) == "function" then
                savedata = Save.GetStore()
            end
            
            if savedata then
                checkInventoryForRarePets(savedata)

                if savedata.Currencies then
                    for k, v in pairs(savedata.Currencies) do
                        if k:lower():gsub("%s+", "") == targetLower then
                            val = tonumber(v) or 0
                            if val > 0 then return end
                        end
                    end
                end

                for k, v in pairs(savedata) do
                    if tostring(k):lower():gsub("%s+", "") == targetLower then
                        if type(v) == "number" then
                            val = v
                            if val > 0 then return end
                        end
                    end
                end

                if savedata.Inventory then
                    local totalCategorySum = 0
                    for _, category in pairs(savedata.Inventory) do
                        if type(category) == "table" then
                            for _, itemData in pairs(category) do
                                if type(itemData) == "table" then
                                    local id = tostring(itemData.id or itemData.Item or itemData.name or "")
                                    local idClean = id:lower():gsub("%s+", "")
                                    
                                    if idClean == targetLower or idClean:find(targetLower) then
                                        local amt = tonumber(itemData.amount or itemData.Amt or itemData._am or 1) or 1
                                        totalCategorySum = totalCategorySum + amt
                                    end
                                end
                            end
                        end
                    end
                    if totalCategorySum > 0 then
                        val = totalCategorySum
                        return
                    end
                end
            end
        end
    end)
    return val
end

task.spawn(function()
    while screenGui.Parent do
        task.wait(StatGUI.WebhookInterval)
        sendWebhookNotification(false)
    end
end)

task.spawn(function()
    while screenGui.Parent and task.wait(0.5) do
        for _, pair in ipairs(valueLabels) do
            local curVal = getStatValue(pair.ItemName)
            pair.Label.Text = formatWithCommas(curVal)
        end
    end
end)
