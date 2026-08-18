local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local ESP_NAME = "MutationESP"
local ESP_WIDTH = 140
local ESP_HEIGHT = 35
local ESP_TEXT_SIZE = 13
local ESP_OFFSET = Vector3.new(0, 2.8, 0)
local ESP_MAX_DISTANCE = 2000

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MutationESPUI"
screenGui.ResetOnSpawn = false

pcall(function()
    screenGui.Parent = CoreGui
end)

if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 130, 0, 122)
mainFrame.Position = UDim2.new(1, -160, 0, -30)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainFrame

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0, 114, 0, 32)
espButton.Position = UDim2.new(0.5, -57, 0, 8)
espButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
espButton.TextColor3 = Color3.fromRGB(0, 255, 0)
espButton.TextScaled = false
espButton.TextSize = 15
espButton.Font = Enum.Font.FredokaOne
espButton.Text = "ESP: ON"
espButton.Parent = mainFrame

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 6)
espCorner.Parent = espButton

local killButton = Instance.new("TextButton")
killButton.Size = UDim2.new(0, 114, 0, 32)
killButton.Position = UDim2.new(0.5, -57, 0, 45)
killButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
killButton.TextColor3 = Color3.fromRGB(255, 60, 60)
killButton.TextScaled = false
killButton.TextSize = 15
killButton.Font = Enum.Font.FredokaOne
killButton.Text = "Kill Switch"
killButton.Parent = mainFrame

local killCorner = Instance.new("UICorner")
killCorner.CornerRadius = UDim.new(0, 6)
killCorner.Parent = killButton

local rejoinButton = Instance.new("TextButton")
rejoinButton.Size = UDim2.new(0, 114, 0, 32)
rejoinButton.Position = UDim2.new(0.5, -57, 0, 82)
rejoinButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
rejoinButton.TextColor3 = Color3.fromRGB(255, 170, 0)
rejoinButton.TextScaled = false
rejoinButton.TextSize = 15
rejoinButton.Font = Enum.Font.FredokaOne
rejoinButton.Text = "Rejoin"
rejoinButton.Parent = mainFrame

local rejoinCorner = Instance.new("UICorner")
rejoinCorner.CornerRadius = UDim.new(0, 6)
rejoinCorner.Parent = rejoinButton

local espEnabled = true
local scriptAlive = true

local function removeAllESP()
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BillboardGui") and descendant.Name == ESP_NAME then
            descendant:Destroy()
        end
    end
end

local function isReadyToHatch(item)
    if item:FindFirstChild("ReadyEggPulseHighlight") then
        return true
    end

    for _, desc in ipairs(item:GetDescendants()) do
        if desc.Name == "ReadyEggPulseHighlight" then
            return true
        end
    end

    return false
end

local function getActualMutation(targetInstance)
    local realMutation

    local function scan(obj)
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("ValueBase") or child:IsA("StringValue") then
                local name = child.Name:lower()
                local val = tostring(child.Value)
                if val ~= "" and val ~= "nil" then
                    if (name:find("mutation") or name:find("mutated")) and not realMutation then
                        realMutation = val
                    end
                end
            end
        end
    end

    scan(targetInstance)
    if targetInstance.Parent then
        scan(targetInstance.Parent)
    end

    for _, attrName in ipairs(targetInstance:GetAttributes()) do
        local val = tostring(targetInstance:GetAttribute(attrName))
        local lowerName = attrName:lower()
        if (lowerName:find("mutation") or lowerName:find("mutated")) and not realMutation then
            realMutation = val
        end
    end

    return realMutation
end

local function getTargetPart(obj)
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part end
    end
    return nil
end

local function applyESP(part, mutationText)
    if not part then return end

    local displayString = "Mut: " .. tostring(mutationText)

    local existing = part:FindFirstChild(ESP_NAME)
    if not existing then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = ESP_NAME
        billboard.Size = UDim2.new(0, ESP_WIDTH, 0, ESP_HEIGHT)
        billboard.StudsOffset = ESP_OFFSET
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = ESP_MAX_DISTANCE
        billboard.LightInfluence = 0
        billboard.Adornee = part
        billboard.Parent = part

        local label = Instance.new("TextLabel")
        label.Name = "MutationLabel"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(0, 255, 255)
        label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.TextStrokeTransparency = 0.1
        label.TextScaled = false
        label.TextSize = ESP_TEXT_SIZE
        label.Font = Enum.Font.FredokaOne
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.Text = displayString
        label.Parent = billboard
    else
        existing.Enabled = espEnabled
        local label = existing:FindFirstChild("MutationLabel")
        if label then
            label.Text = displayString
        end
    end
end

local function scanReadyEggs()
    if not scriptAlive or not espEnabled then return end

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if not scriptAlive then break end

        if descendant:IsA("Model") and not Players:GetPlayerFromCharacter(descendant) then
            if isReadyToHatch(descendant) then
                pcall(function()
                    local targetPart = getTargetPart(descendant)
                    if targetPart then
                        local mutation = getActualMutation(descendant)
                        applyESP(targetPart, mutation or "None")
                    end
                end)
            end
        end
    end
end

task.spawn(function()
    while scriptAlive do
        if espEnabled then
            pcall(function()
                scanReadyEggs()
            end)
        else
            removeAllESP()
        end
        task.wait(0.05)
    end
end)

espButton.MouseButton1Click:Connect(function()
    if not scriptAlive then return end
    espEnabled = not espEnabled

    if espEnabled then
        espButton.Text = "ESP: ON"
        espButton.TextColor3 = Color3.fromRGB(0, 255, 0)
        scanReadyEggs()
    else
        espButton.Text = "ESP: OFF"
        espButton.TextColor3 = Color3.fromRGB(255, 0, 0)
        removeAllESP()
    end
end)

killButton.MouseButton1Click:Connect(function()
    scriptAlive = false
    espEnabled = false
    removeAllESP()
    if screenGui then
        screenGui:Destroy()
    end
end)

rejoinButton.MouseButton1Click:Connect(function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
