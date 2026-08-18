local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local StatGUI = {
    Enable = true,
    Items = {
        {Class = "Currency", Item = "Diamonds"},
        {Class = "Currency", Item = "FiestaCoins"},
        {Class = "Currency", Item = "FiestaOrbs"},
        {Class = "Misc", Item = "Fiesta Candy"},
        {Class = "Misc", Item = "Fiesta Key"},
        {Class = "Lootbox", Item = "Fiesta Gift"},
    }
}

if not StatGUI.Enable then return end

if playerGui:FindFirstChild("CustomStatGUI") then
    playerGui.CustomStatGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CustomStatGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 999999
screenGui.Parent = playerGui

local solidBackground = Instance.new("Frame")
solidBackground.Name = "SolidBackground"
solidBackground.Size = UDim2.new(1, 0, 1, 0)
solidBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
solidBackground.BorderSizePixel = 0
solidBackground.ZIndex = 0
solidBackground.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 440, 0, 70 + (#StatGUI.Items * 50))
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(5, 12, 35)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

local neonStroke = Instance.new("UIStroke")
neonStroke.Color = Color3.fromRGB(0, 150, 255)
neonStroke.Thickness = 2.5
neonStroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -128, 0, 70)
titleLabel.Position = UDim2.new(0, 26, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "Stat Tracker"
titleLabel.TextColor3 = Color3.fromRGB(200, 230, 255)
titleLabel.TextSize = 32
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 3
titleLabel.Parent = mainFrame

local bgModeButton = Instance.new("TextButton")
bgModeButton.Size = UDim2.new(0, 50, 0, 50)
bgModeButton.Position = UDim2.new(1, -115, 0, 10)
bgModeButton.BackgroundColor3 = Color3.fromRGB(10, 25, 60)
bgModeButton.Font = Enum.Font.GothamBold
bgModeButton.Text = "W"
bgModeButton.TextColor3 = Color3.fromRGB(150, 200, 255)
bgModeButton.TextSize = 24
bgModeButton.ZIndex = 3
bgModeButton.Parent = mainFrame

local bgModeStroke = Instance.new("UIStroke")
bgModeStroke.Color = Color3.fromRGB(0, 150, 255)
bgModeStroke.Thickness = 1.5
bgModeStroke.Parent = bgModeButton

local killButton = Instance.new("TextButton")
killButton.Size = UDim2.new(0, 50, 0, 50)
killButton.Position = UDim2.new(1, -60, 0, 10)
killButton.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
killButton.Font = Enum.Font.GothamBold
killButton.Text = "X"
killButton.TextColor3 = Color3.fromRGB(255, 100, 100)
killButton.TextSize = 28
killButton.ZIndex = 3
killButton.Parent = mainFrame

local killStroke = Instance.new("UIStroke")
killStroke.Color = Color3.fromRGB(255, 50, 50)
killStroke.Thickness = 1.5
killStroke.Parent = killButton

local contentHolder = Instance.new("Frame")
contentHolder.Size = UDim2.new(1, 0, 1, -70)
contentHolder.Position = UDim2.new(0, 0, 0, 70)
contentHolder.BackgroundTransparency = 1
contentHolder.ZIndex = 2
contentHolder.Parent = mainFrame

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 8)
uiList.Parent = contentHolder

local bgModes = {"White", "Black", "None"}
local currentModeIndex = 1

bgModeButton.MouseButton1Click:Connect(function()
    currentModeIndex = currentModeIndex + 1
    if currentModeIndex > #bgModes then
        currentModeIndex = 1
    end
    
    local mode = bgModes[currentModeIndex]
    if mode == "White" then
        solidBackground.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        solidBackground.Visible = true
        bgModeButton.Text = "W"
        bgModeButton.TextColor3 = Color3.fromRGB(150, 200, 255)
    elseif mode == "Black" then
        solidBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        solidBackground.Visible = true
        bgModeButton.Text = "B"
        bgModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    elseif mode == "None" then
        solidBackground.Visible = false
        bgModeButton.Text = "N"
        bgModeButton.TextColor3 = Color3.fromRGB(100, 100, 100)
    end
end)

killButton.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

local valueLabels = {}

for index, entry in ipairs(StatGUI.Items) do
    local itemRow = Instance.new("Frame")
    itemRow.Size = UDim2.new(1, -36, 0, 44)
    itemRow.Position = UDim2.new(0, 26, 0, 0)
    itemRow.BackgroundTransparency = 1
    itemRow.LayoutOrder = index
    itemRow.ZIndex = 2
    itemRow.Parent = contentHolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.Gotham
    nameLabel.Text = entry.Item .. ":"
    nameLabel.TextColor3 = Color3.fromRGB(170, 200, 240)
    nameLabel.TextSize = 26
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.ZIndex = 3
    nameLabel.Parent = itemRow

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.4, -20, 1, 0)
    valueLabel.Position = UDim2.new(0.58, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.Text = "0"
    valueLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    valueLabel.TextSize = 26
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 3
    valueLabel.Parent = itemRow
    
    table.insert(valueLabels, {Label = valueLabel, ItemName = entry.Item, Class = entry.Class})
end

local function formatWithCommas(number)
    local formatted = tostring(number)
    while true do
        local formattedResult, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        formatted = formattedResult
        if k == 0 then break end
    end
    return formatted
end

local function getStatValue(itemName)
    local val = 0
    pcall(function()
        local success, Save = pcall(function()
            return require(game:GetService("ReplicatedStorage"):WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Save"))
        end)
        
        if success and Save then
            local savedata = Save.Get()
            if savedata then
                if itemName == "Diamonds" and savedata.Diamonds then
                    val = savedata.Diamonds
                    return
                end
                
                if savedata.Currencies and savedata.Currencies[itemName] then
                    val = savedata.Currencies[itemName]
                    return
                end

                if savedata.Inventory then
                    for _, category in pairs(savedata.Inventory) do
                        if type(category) == "table" then
                            for _, itemData in pairs(category) do
                                if type(itemData) == "table" then
                                    local id = itemData.id or itemData.Item
                                    if id == itemName then
                                        val = itemData.amount or itemData.Amt or itemData._am or 1
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    return val
end

task.spawn(function()
    while screenGui.Parent and task.wait(0.5) do
        for _, pair in ipairs(valueLabels) do
            local currentVal = getStatValue(pair.ItemName)
            pair.Label.Text = formatWithCommas(currentVal)
        end
    end
end)
