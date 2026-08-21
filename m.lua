local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

pcall(function()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui.Name:match("HennessyLiquidBlueLandscapeUI") or gui.Name:match("HennLiquidBlueLandscapeUI") or gui.Name:match("HennAbsolutePerfection") then
            gui:Destroy()
        end
    end
end)

local function waitForChild(parent, childName, timeout)
    local child = parent and parent:FindFirstChild(childName)
    if child then return child end
    return parent and parent:WaitForChild(childName, timeout or 2) or nil
end

local function findDescendantByName(root, childName)
    if not root then return nil end
    local direct = root:FindFirstChild(childName)
    if direct then return direct end
    for _, child in ipairs(root:GetDescendants()) do
        if child.Name == childName then return child end
    end
    return nil
end

local function safeRequire(module)
    if not (module and module:IsA("ModuleScript")) then return nil end
    local ok, result = pcall(require, module)
    if ok then return result end
    return nil
end

local function requireModuleByPath(path, fallbackName, timeout)
    local current = ReplicatedStorage
    for _, childName in ipairs(path) do
        current = waitForChild(current, childName, timeout or 3)
        if not current then break end
    end
    return safeRequire(current) or safeRequire(findDescendantByName(ReplicatedStorage, fallbackName))
end

local Networking, PlayerStateClient, ItemData, MailboxItemCatalog

task.spawn(function()
    Networking = requireModuleByPath({ "SharedModules", "Networking" }, "Networking", 3)
    PlayerStateClient = requireModuleByPath({ "ClientModules", "PlayerStateClient" }, "PlayerStateClient", 3)
end)

task.spawn(function()
    pcall(function()
        ItemData = requireModuleByPath({ "SharedModules", "ItemData" }, "ItemData", 2) or requireModuleByPath({ "Modules", "ItemData" }, "ItemData", 2)
    end)
    pcall(function()
        local playerScripts = LocalPlayer and LocalPlayer:WaitForChild("PlayerScripts", 3)
        local controllers = playerScripts and playerScripts:WaitForChild("Controllers", 3)
        local mailboxController = controllers and controllers:FindFirstChild("MailboxController")
        MailboxItemCatalog = safeRequire(mailboxController and mailboxController:FindFirstChild("MailboxItemCatalog"))
    end)
end)

local function getFriendlyItemName(category, itemKey, value)
    if category == "Pets" and type(value) == "table" then
        if value.Name and type(value.Name) == "string" and value.Name ~= "" then
            return value.Name
        end
        if value.PetName and type(value.PetName) == "string" and value.PetName ~= "" then
            return value.PetName
        end
        if value.DisplayName and type(value.DisplayName) == "string" and value.DisplayName ~= "" then
            return value.DisplayName
        end
    end

    if ItemData and type(ItemData) == "table" then
        if ItemData.GetDisplayName then
            local ok, res = pcall(ItemData.GetDisplayName, category, itemKey)
            if ok and type(res) == "string" and res ~= "" then return res end
        end
        if ItemData[itemKey] then
            local entry = ItemData[itemKey]
            if type(entry) == "table" and (entry.DisplayName or entry.Name) then
                return tostring(entry.DisplayName or entry.Name)
            elseif type(entry) == "string" then
                return entry
            end
        end
    end

    if category == "Pets" and type(value) == "table" then
        local rawKey = tostring(value.Key or value.Id or itemKey)
        rawKey = rawKey:gsub("^%d+_", "")
        return rawKey
    end

    local clean = tostring(itemKey)
    clean = clean:gsub("^%d+_", "")
    return clean
end

local FALLBACK_CATEGORIES = {
    "Pets", "Sprinklers", "WateringCans", "Mushrooms", "Gnomes", "Raccoons",
    "Crates", "SeedPacks", "Trowels", "Props", "Seeds", "HarvestedFruits", "EmptyPots", "Eggs", "Egg"
}
local EXTRA_GIFTABLE_CATEGORIES = { "Eggs", "Egg" }

local function normalizePayloadCategory(category)
    if category == "Egg" then return "Eggs" end
    return category
end

local function getMailboxCategories()
    if type(MailboxItemCatalog) == "table" and type(MailboxItemCatalog.Categories) == "table" and #MailboxItemCatalog.Categories > 0 then
        local categories = {}
        local seen = {}
        for _, category in ipairs(MailboxItemCatalog.Categories) do
            category = tostring(category)
            if category ~= "" and not seen[category] then
                seen[category] = true
                table.insert(categories, category)
            end
        end
        for _, category in ipairs(EXTRA_GIFTABLE_CATEGORIES) do
            if not seen[category] then
                seen[category] = true
                table.insert(categories, category)
            end
        end
        return categories, false
    end
    return FALLBACK_CATEGORIES, true
end

local function getStackCount(value)
    if type(value) == "number" then return math.floor(value), true end
    if type(value) == "table" then
        local count = tonumber(value.Count or value.count or value.Quantity or value.Amount)
        if count then return math.floor(count), true end
    end
    return nil, false
end

local function isGiftable(category, itemKey, value)
    if category == "HarvestedFruits" then
        return type(value) == "table" and value.Id ~= nil
    end
    if MailboxItemCatalog and MailboxItemCatalog.IsGiftable then
        local ok, result = pcall(MailboxItemCatalog.IsGiftable, category)
        if ok and result ~= true and category ~= "Eggs" and category ~= "Egg" then return false end
    end
    if category == "Pets" then return type(value) == "table" and value.Id ~= nil and value.Equipped ~= true end
    local count = getStackCount(value)
    return count ~= nil and count > 0
end

local function getInventory()
    if not (PlayerStateClient and PlayerStateClient.GetLocalReplica) then return nil, "PlayerStateClient missing" end
    local ok, replica = pcall(function() return PlayerStateClient:GetLocalReplica() end)
    if not ok or not replica then return nil, "Local replica missing" end
    local inventory = replica.Data and replica.Data.Inventory
    if type(inventory) ~= "table" then return nil, "Inventory data missing" end
    return inventory
end

local function create(className, parent, properties)
    local obj = Instance.new(className)
    for prop, val in pairs(properties) do
        obj[prop] = val
    end
    if parent then obj.Parent = parent end
    return obj
end

local function addCorner(parent, radius)
    return create("UICorner", parent, {CornerRadius = radius or UDim.new(0, 8)})
end

local function addStroke(parent, color, thickness, transparency)
    return create("UIStroke", parent, {
        Color = color or Color3.fromRGB(30, 50, 90),
        Thickness = thickness or 1,
        Transparency = transparency or 0
    })
end

local ScreenGui = create("ScreenGui", CoreGui, {
    Name = "HennessyLiquidBlueLandscapeUI_AbsolutePerfection",
    ResetOnSpawn = false
})

local MainWindow = create("Frame", ScreenGui, {
    Size = UDim2.new(0, 624, 0, 330),
    Position = UDim2.new(0.5, -312, 0.5, -165),
    BackgroundColor3 = Color3.fromRGB(8, 14, 28),
    BorderSizePixel = 0
})
addCorner(MainWindow, UDim.new(0, 13))
addStroke(MainWindow, Color3.fromRGB(0, 162, 255), 2, 0.3)

local dragging = false
local resizing = false
local dragInput, dragStart, startPos
local resizeStartPos, resizeStartSize

MainWindow.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not resizing then
        dragging = true
        dragStart = input.Position
        startPos = MainWindow.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainWindow.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging and not resizing then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local ResizeHandle = create("Frame", MainWindow, {
    Name = "ResizeHandle",
    Size = UDim2.new(0, 30, 0, 30),
    Position = UDim2.new(1, -30, 1, -30),
    BackgroundTransparency = 1,
    ZIndex = 10
})

local ResizeTriangle = create("Frame", ResizeHandle, {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(1, -18, 1, -18),
    BackgroundTransparency = 1,
    ZIndex = 11
})

for i = 1, 3 do
    create("Frame", ResizeTriangle, {
        Size = UDim2.new(0, 2, 0, 2),
        Position = UDim2.new(1, - (i * 4), 1, - (i * 4)),
        BackgroundColor3 = Color3.fromRGB(0, 162, 255),
        BorderSizePixel = 0,
        ZIndex = 12
    })
end

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        resizing = true
        resizeStartPos = input.Position
        resizeStartSize = MainWindow.Size
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                resizing = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local minWidth, minHeight = 450, 260
        
        local newWidth = math.max(minWidth, resizeStartSize.X.Offset + delta.X)
        local newHeight = math.max(minHeight, resizeStartSize.Y.Offset + delta.Y)
        MainWindow.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

local HeaderTitle = create("TextLabel", MainWindow, {
    Size = UDim2.new(0, 360, 0, 26),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Hennessy Mailbox (99,990 max items)",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
})

local CloseButton = create("TextButton", MainWindow, {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -31, 0, 5),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ZIndex = 5
})
addCorner(CloseButton, UDim.new(0, 5))
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinimizeButton = create("TextButton", MainWindow, {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -62, 0, 5),
    BackgroundColor3 = Color3.fromRGB(40, 60, 90),
    Text = "-",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    ZIndex = 5
})
addCorner(MinimizeButton, UDim.new(0, 5))

local DateTimeLabel = create("TextLabel", MainWindow, {
    Size = UDim2.new(0, 140, 0, 26),
    Position = UDim2.new(1, -206, 0, 5),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "",
    TextColor3 = Color3.fromRGB(180, 200, 230),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 5
})

task.spawn(function()
    while ScreenGui.Parent do
        DateTimeLabel.Text = os.date("%Y-%m-%d (%I:%M:%S %p)")
        task.wait(1)
    end
end)

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, child in ipairs(MainWindow:GetChildren()) do
        if child:IsA("GuiObject") and child ~= HeaderTitle and child ~= CloseButton and child ~= MinimizeButton and child ~= DateTimeLabel and child ~= ResizeHandle then
            child.Visible = not isMinimized
        end
    end
    local targetSize = isMinimized and UDim2.new(0, MainWindow.AbsoluteSize.X, 0, 36) or UDim2.new(0, MainWindow.AbsoluteSize.X, 0, 330)
    TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end)

local LeftSideContainer = create("Frame", MainWindow, {
    Size = UDim2.new(0.48, 0, 0.86, 0),
    Position = UDim2.new(0.012, 0, 0.11, 0),
    BackgroundTransparency = 1,
    ZIndex = 2
})

local RecipientContainer = create("Frame", LeftSideContainer, {
    Size = UDim2.new(1, 0, 0, 154),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(15, 25, 48),
    ZIndex = 2
})
addCorner(RecipientContainer)

local AvatarIcon = create("ImageLabel", RecipientContainer, {
    Size = UDim2.new(0, 110, 0, 110),
    Position = UDim2.new(1, -114, 0, 2),
    BackgroundColor3 = Color3.fromRGB(10, 18, 35),
    Image = "rbxassetid://0",
    ZIndex = 4
})
addCorner(AvatarIcon, UDim.new(0, 8))
addStroke(AvatarIcon, Color3.fromRGB(55, 75, 110))

local RealTextBox = create("TextBox", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 28),
    Position = UDim2.new(0, 6, 0, 8),
    BackgroundColor3 = Color3.fromRGB(15, 28, 50),
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    PlaceholderText = "Username...",
    PlaceholderColor3 = Color3.fromRGB(170, 170, 170),
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    ClearTextOnFocus = false,
    ZIndex = 4
})
addCorner(RealTextBox, UDim.new(0, 5))
addStroke(RealTextBox, Color3.fromRGB(55, 75, 110))

-- Confirmation Toggle right below username
local ConfirmToggleContainer = create("Frame", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 20),
    Position = UDim2.new(0, 6, 0, 39),
    BackgroundTransparency = 1,
    ZIndex = 4
})

local ConfirmToggleBtn = create("TextButton", ConfirmToggleContainer, {
    Size = UDim2.new(0, 18, 0, 18),
    Position = UDim2.new(0, 0, 0, 1),
    BackgroundColor3 = Color3.fromRGB(30, 45, 75),
    Text = "",
    ZIndex = 5
})
addCorner(ConfirmToggleBtn, UDim.new(0, 4))
addStroke(ConfirmToggleBtn, Color3.fromRGB(55, 75, 110))

local ConfirmToggleCheck = create("TextLabel", ConfirmToggleBtn, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "✓",
    TextColor3 = Color3.fromRGB(0, 220, 255),
    TextSize = 12,
    Visible = true, -- Default ON
    ZIndex = 6
})

local ConfirmToggleLabel = create("TextLabel", ConfirmToggleContainer, {
    Size = UDim2.new(1, -24, 1, 0),
    Position = UDim2.new(0, 24, 0, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "Confirm before sending",
    TextColor3 = Color3.fromRGB(180, 200, 230),
    TextSize = 9.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 5
})

local requireConfirmation = true
ConfirmToggleBtn.MouseButton1Click:Connect(function()
    requireConfirmation = not requireConfirmation
    ConfirmToggleCheck.Visible = requireConfirmation
end)

local MessageLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 14),
    Position = UDim2.new(0, 6, 0, 61),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Message (Optional):",
    TextColor3 = Color3.fromRGB(180, 200, 230),
    TextSize = 9.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local MessageTextBox = create("TextBox", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 24),
    Position = UDim2.new(0, 6, 0, 76),
    BackgroundColor3 = Color3.fromRGB(15, 28, 50),
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    PlaceholderText = "Optional message...",
    PlaceholderColor3 = Color3.fromRGB(170, 170, 170),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    ClearTextOnFocus = false,
    ZIndex = 4
})
addCorner(MessageTextBox, UDim.new(0, 5))
addStroke(MessageTextBox, Color3.fromRGB(55, 75, 110))

local UsernameDisplayLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 15),
    Position = UDim2.new(0, 6, 0, 102),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Username: -",
    TextColor3 = Color3.fromRGB(150, 180, 220),
    TextSize = 9.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local StatusLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 15),
    Position = UDim2.new(0, 6, 0, 117),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "Status: Idle",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextSize = 9.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local SendButton = create("TextButton", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 22),
    Position = UDim2.new(0, 6, 0, 131),
    BackgroundColor3 = Color3.fromRGB(0, 110, 220),
    Font = Enum.Font.GothamBold,
    Text = "Send",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    ZIndex = 4
})
addCorner(SendButton, UDim.new(0, 5))
addStroke(SendButton, Color3.fromRGB(0, 162, 255))

-- Confirmation Overlay Pop-up (Centered)
local ConfirmOverlay = create("Frame", MainWindow, {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.6,
    Visible = false,
    ZIndex = 50
})

local ConfirmDialogBox = create("Frame", ConfirmOverlay, {
    Size = UDim2.new(0, 320, 0, 165),
    Position = UDim2.new(0.5, -160, 0.5, -82.5),
    BackgroundColor3 = Color3.fromRGB(12, 22, 44),
    ZIndex = 51
})
addCorner(ConfirmDialogBox, UDim.new(0, 10))
addStroke(ConfirmDialogBox, Color3.fromRGB(0, 162, 255), 2, 0)

create("TextLabel", ConfirmDialogBox, {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 0, 10),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Are you sure you want to send?",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    ZIndex = 52
})

local ConfirmAvatar = create("ImageLabel", ConfirmDialogBox, {
    Size = UDim2.new(0, 48, 0, 48),
    Position = UDim2.new(0.5, -24, 0, 42),
    BackgroundColor3 = Color3.fromRGB(10, 18, 35),
    Image = "rbxassetid://0",
    ZIndex = 52
})
addCorner(ConfirmAvatar, UDim.new(0, 8))
addStroke(ConfirmAvatar, Color3.fromRGB(55, 75, 110))

local ConfirmTargetUserLabel = create("TextLabel", ConfirmDialogBox, {
    Size = UDim2.new(1, -20, 0, 20),
    Position = UDim2.new(0, 10, 0, 94),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "To: User",
    TextColor3 = Color3.fromRGB(0, 220, 255),
    TextSize = 11,
    ZIndex = 52
})

local ConfirmYesBtn = create("TextButton", ConfirmDialogBox, {
    Size = UDim2.new(0, 130, 0, 28),
    Position = UDim2.new(0.5, -135, 1, -38),
    BackgroundColor3 = Color3.fromRGB(0, 170, 80),
    Font = Enum.Font.GothamBold,
    Text = "Yes",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    ZIndex = 52
})
addCorner(ConfirmYesBtn, UDim.new(0, 6))

local ConfirmNoBtn = create("TextButton", ConfirmDialogBox, {
    Size = UDim2.new(0, 130, 0, 28),
    Position = UDim2.new(0.5, 5, 1, -38),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Font = Enum.Font.GothamBold,
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 12,
    ZIndex = 52
})
addCorner(ConfirmNoBtn, UDim.new(0, 6))

local cachedTargetUserId = nil
local cachedEntries = nil
local cachedSummaryList = nil
local cachedRecipientName = ""
local cachedCustomMsg = ""
local executeSendProcess -- forward declaration

ConfirmNoBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
end)

local currentAvatarUrl = "rbxassetid://0"

local function CheckUser(usernameInput)
    usernameInput = usernameInput:match("^%s*(.-)%s*$")
    if usernameInput == "" or #usernameInput < 3 then
        UsernameDisplayLabel.Text = "Username: -"
        StatusLabel.Text = "Status: Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        AvatarIcon.Image = "rbxassetid://0"
        currentAvatarUrl = "rbxassetid://0"
        return
    end

    UsernameDisplayLabel.Text = "Username: Searching..."
    StatusLabel.Text = "Status: searching..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)

    task.spawn(function()
        local success, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(usernameInput)
        end)
        if success and userId then
            local okName, actualUsername = pcall(function()
                return Players:GetNameFromUserIdAsync(userId)
            end)
            if okName and actualUsername then
                UsernameDisplayLabel.Text = "Username: " .. actualUsername
            else
                UsernameDisplayLabel.Text = "Username: " .. usernameInput
            end

            StatusLabel.Text = "Status: player found"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)

            local okThumb, thumbUrl = pcall(function()
                return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            if okThumb and thumbUrl then
                AvatarIcon.Image = thumbUrl
                currentAvatarUrl = thumbUrl
            else
                AvatarIcon.Image = "rbxassetid://0"
                currentAvatarUrl = "rbxassetid://0"
            end
        else
            UsernameDisplayLabel.Text = "Username: Not Found"
            StatusLabel.Text = "Status: player not found"
            StatusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            AvatarIcon.Image = "rbxassetid://0"
            currentAvatarUrl = "rbxassetid://0"
        end
    end)
end

RealTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    CheckUser(RealTextBox.Text)
end)

local HistoryContainer = create("Frame", LeftSideContainer, {
    Size = UDim2.new(1, 0, 1, -162),
    Position = UDim2.new(0, 0, 0, 162),
    BackgroundColor3 = Color3.fromRGB(12, 22, 44),
    ZIndex = 2
})
addCorner(HistoryContainer)

create("TextLabel", HistoryContainer, {
    Size = UDim2.new(1, -10, 0, 20),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "📜 HISTORY",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local TotalSentLabel = create("TextLabel", HistoryContainer, {
    Size = UDim2.new(1, -5, 0, 20),
    Position = UDim2.new(0, 0, 0, 5),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Sent: 0",
    TextColor3 = Color3.fromRGB(0, 200, 255),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 3
})

local HistoryScroll = create("ScrollingFrame", HistoryContainer, {
    Size = UDim2.new(1, -10, 1, -32),
    Position = UDim2.new(0, 5, 0, 26),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ZIndex = 3
})

local HistList = create("UIListLayout", HistoryScroll, {Padding = UDim.new(0, 5)})

local function UpdateHistoryTotal()
    local total = 0
    for _, v in ipairs(HistoryScroll:GetChildren()) do
        if v:IsA("Frame") then total = total + 1 end
    end
    TotalSentLabel.Text = "Sent: " .. total
end

HistList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    HistoryScroll.CanvasSize = UDim2.fromOffset(0, HistList.AbsoluteContentSize.Y + 5)
    UpdateHistoryTotal()
end)

local function AddHistoryCard(username, itemsText, timeStr)
    local Card = create("Frame", HistoryScroll, {
        Size = UDim2.new(1, -2, 0, 65),
        BackgroundColor3 = Color3.fromRGB(15, 28, 55),
        ZIndex = 4
    })
    addCorner(Card, UDim.new(0, 5))
    
    create("TextLabel", Card, {
        Size = UDim2.new(0, 110, 0, 15),
        Position = UDim2.new(0, 6, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = username,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })
    
    create("TextLabel", Card, {
        Size = UDim2.new(1, -12, 0, 38),
        Position = UDim2.new(0, 6, 0, 20),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = itemsText,
        TextColor3 = Color3.fromRGB(0, 220, 255),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None,
        ZIndex = 5
    })
    
    create("TextLabel", Card, {
        Size = UDim2.new(0, 70, 0, 15),
        Position = UDim2.new(1, -74, 0, 4),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = timeStr,
        TextColor3 = Color3.fromRGB(180, 190, 210),
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 5
    })
    
    UpdateHistoryTotal()
end

local InventoryContainer = create("Frame", MainWindow, {
    Size = UDim2.new(0.50, 0, 0.86, 0),
    Position = UDim2.new(0.488, 0, 0.11, 0),
    BackgroundColor3 = Color3.fromRGB(12, 20, 40),
    ZIndex = 2
})
addCorner(InventoryContainer)

local RunScanInventory

local TopBarHolder = create("Frame", InventoryContainer, {
    Size = UDim2.new(1, -10, 0, 26),
    Position = UDim2.new(0, 5, 0, 5),
    BackgroundTransparency = 1,
    ZIndex = 4
})

local SearchBox = create("TextBox", TopBarHolder, {
    Size = UDim2.new(1, -32, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(18, 28, 50),
    PlaceholderText = "🔍 Search Item, Weight or Mutation...",
    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    Text = "",
    TextSize = 10,
    ZIndex = 4
})
addCorner(SearchBox, UDim.new(0, 5))
addStroke(SearchBox, Color3.fromRGB(35, 55, 85))

local RefreshButton = create("TextButton", TopBarHolder, {
    Size = UDim2.new(0, 26, 1, 0),
    Position = UDim2.new(1, -26, 0, 0),
    BackgroundColor3 = Color3.fromRGB(18, 28, 50),
    Font = Enum.Font.GothamBold,
    Text = "🔄",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    ZIndex = 4
})
addCorner(RefreshButton, UDim.new(0, 5))
addStroke(RefreshButton, Color3.fromRGB(35, 55, 85))

RefreshButton.MouseButton1Click:Connect(function()
    RunScanInventory()
end)

local FilterContainer = create("Frame", InventoryContainer, {
    Size = UDim2.new(1, -10, 0, 26),
    Position = UDim2.new(0, 5, 0, 35),
    BackgroundTransparency = 1,
    ZIndex = 4
})

local FilterLayout = create("UIListLayout", FilterContainer, {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 3)
})

local activeFilter = ""
local filterButtons = {}

local function createFilterButton(name, filterText, order)
    local btn = create("TextButton", FilterContainer, {
        Size = UDim2.new(0.166, -3, 1, 0),
        BackgroundColor3 = Color3.fromRGB(15, 25, 48),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(180, 190, 210),
        TextSize = 8.5,
        LayoutOrder = order,
        ZIndex = 5
    })
    addCorner(btn, UDim.new(0, 4))
    addStroke(btn, Color3.fromRGB(35, 55, 85))
    
    filterButtons[filterText] = btn
    return btn
end

local function setFilter(filterText)
    activeFilter = filterText
    
    for text, btn in pairs(filterButtons) do
        if text == activeFilter then
            btn.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.BackgroundColor3 = Color3.fromRGB(15, 25, 48)
            btn.TextColor3 = Color3.fromRGB(180, 190, 210)
        end
    end
    
    RunScanInventory()
end

local btnAll = createFilterButton("All", "", 1)
local btnSeeds = createFilterButton("Seeds", "seeds", 2)
local btnGears = createFilterButton("Gears", "gears", 3)
local btnPets = createFilterButton("Pets", "pets", 4)
local btnProps = createFilterButton("Props", "props", 5)
local btnFruit = createFilterButton("Fruit", "fruit", 6)

btnAll.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
btnAll.TextColor3 = Color3.fromRGB(255, 255, 255)

btnAll.MouseButton1Click:Connect(function() setFilter("") end)
btnSeeds.MouseButton1Click:Connect(function() setFilter("seeds") end)
btnGears.MouseButton1Click:Connect(function() setFilter("gears") end)
btnPets.MouseButton1Click:Connect(function() setFilter("pets") end)
btnProps.MouseButton1Click:Connect(function() setFilter("props") end)
btnFruit.MouseButton1Click:Connect(function() setFilter("fruit") end)

local ScrollingFrame = create("ScrollingFrame", InventoryContainer, {
    Size = UDim2.new(1, -10, 1, -68),
    Position = UDim2.new(0, 5, 0, 65),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ZIndex = 3
})

local ScanListLayout = create("UIListLayout", ScrollingFrame, {
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local ALLOWED_SEEDS = {
    ["Eclipse Bloom"] = true, ["Star Fruit"] = true, ["Dragon's Breath"] = true, ["Hypno Bloom"] = true, 
    ["Amber Cranberry"] = true, ["Sun Bloom"] = true, ["Moon Bloom"] = true, ["Conifer Cone"] = true, 
    ["Venom Spitter"] = true, ["Maple Venom Spitter"] = true, ["Poison Apple"] = true, ["Maple Poison Apple"] = true, 
    ["Pomegranate"] = true, ["Maple Pomegranate"] = true, ["Venus Fly Trap"] = true, ["Maple Venus Fly Trap"] = true, 
    ["Ghost Pepper"] = true, ["Mega Seed"] = true, ["Rainbow Seed"] = true, ["Briar Rose"] = true, 
    ["Romanesco"] = true, ["Conifer Cone Sapling"] = true, ["Fire Fern"] = true, ["Sunflower"] = true, 
    ["Maple Sunflower"] = true, ["Cherry"] = true, ["Maple Cherry"] = true, ["Acorn"] = true, 
    ["Maple Acorn"] = true, ["Atlantic Giant Pumpkin"] = true, ["Dragon Fruit"] = true, ["Maple Dragon Fruit"] = true, 
    ["Rocket Pop"] = true, ["Gold Seed"] = true, ["Poison Ivy"] = true, ["Plum"] = true, 
    ["Honeysuckle"] = true, ["Mango"] = true, ["Maple Mango"] = true, ["Coconut"] = true, 
    ["Maple Coconut"] = true, ["Grape"] = true, ["Maple Grape"] = true, ["Banana"] = true, 
    ["Maple Banana"] = true, ["Green Bean"] = true, ["Maple Green Bean"] = true, ["Mushroom"] = true, 
    ["Maple Mushroom"] = true, ["Glow Mushroom"] = true, ["Cinnamon Stick"] = true, ["Pineapple"] = true, 
    ["Maple Pineapple"] = true, ["Cactus"] = true, ["Maple Cactus"] = true, ["Corn"] = true, 
    ["Maple Corn"] = true, ["Bamboo"] = true, ["Maple Bamboo"] = true, ["Baby Cactus"] = true, 
    ["Horned Melon"] = true, ["Potato"] = true, ["Apple"] = true, ["Maple Apple"] = true, 
    ["Tomato"] = true, ["Maple Tomato"] = true, ["Tulip"] = true, ["Maple Tulip"] = true, 
    ["Blueberry"] = true, ["Maple Blueberry"] = true, ["Strawberry"] = true, ["Maple Strawberry"] = true, 
    ["Carrot"] = true, ["Maple Carrot"] = true
}

local ALLOWED_GEARS = {
    ["Super Magic Mail"] = true, ["Super Syrup Sprinkler"] = true, ["Super Watering Can"] = true, ["Super Syrup Watering Can"] = true, 
    ["Super Sprinkler"] = true, ["Strawberry Sniper"] = true, ["Player Magnet"] = true, ["Legendary Magic Mail"] = true, 
    ["Legendary Sprinkler"] = true, ["Wheelbarrow"] = true, ["Teleporter"] = true, ["Invisibility Mushroom"] = true, 
    ["Wind Staff"] = true, ["Basic Pot"] = true, ["Gnome"] = true, ["Flashbang"] = true, 
    ["Supersize Mushroom"] = true, ["Shrink Mushroom"] = true, ["Bull Horn"] = true, ["Rare Magic Mail"] = true, 
    ["Harp"] = true, ["Rare Sprinkler"] = true, ["Lantern"] = true, ["Megaphone"] = true, 
    ["Jump Mushroom"] = true, ["Speed Mushroom"] = true, ["Trowel"] = true, ["Uncommon Sprinkler"] = true, 
    ["Sign"] = true, ["Common Sprinkler"] = true, ["Syrup Sprinkler"] = true, ["Common Watering Can"] = true, 
    ["Syrup Watering Can"] = true
}

local ALLOWED_PETS = {
    ["Kitsune"] = true, ["Shadow Dragon"] = true, ["Raccoon"] = true, ["Black Dragon"] = true, 
    ["Ice Serpent"] = true, ["Red Panda"] = true, ["Unicorn"] = true, ["Fox"] = true, 
    ["Golden Dragonfly"] = true, ["Wolf"] = true, ["Bald Eagle"] = true, ["Bear"] = true, 
    ["Monkey"] = true, ["Firefly"] = true, ["Jandel Monkey"] = true, ["Scarecrow"] = true, 
    ["Swan"] = true, ["Squirrel"] = true, ["Bee"] = true, ["Butterfly"] = true, 
    ["Robin"] = true, ["Jackalope"] = true, ["Hedgehog"] = true, ["Turkey"] = true, 
    ["Turtle"] = true, ["Deer"] = true, ["Dog"] = true, ["Owl"] = true, 
    ["Bunny"] = true, ["Frog"] = true
}

local ALLOWED_PROPS = {
    ["American Flag"] = true, ["Patriotic Archway"] = true, ["Patriotic Balloons"] = true, ["Patriotic Drums"] = true, 
    ["Patriotic Pinwheel"] = true, ["Patriotic Rope Lights"] = true, ["Patriotic Stars"] = true, ["Boombox"] = true, 
    ["Big Boombox"] = true, ["Mega Boombox"] = true, ["Candle Cluster"] = true, ["Hanging Lamp Post"] = true, 
    ["Warm Lamp Post"] = true, ["Black Street Lamp"] = true, ["Fire Pit"] = true, ["Wood Barrel"] = true, 
    ["Wood Crate"] = true, ["Hay Bale"] = true, ["Haystack"] = true, ["Picnic Table"] = true, 
    ["Wood Pile"] = true, ["Scarecrow"] = true, ["Wood Wagon"] = true, ["Windmill"] = true, 
    ["Cobblestone Wall"] = true, ["Cobblestone Pillar"] = true, ["Mossy Cobblestone Wall"] = true, ["Cobblestone Stepping Stones"] = true, 
    ["Cobblestone Wolf Statue"] = true, ["Cobblestone Hero Statue"] = true, ["Small Spruce Floor"] = true, ["Spruce Window"] = true, 
    ["Medium Spruce Floor"] = true, ["Large Spruce Floor"] = true, ["Pergola Arch"] = true, ["Fall Bridge"] = true, 
    ["Fall Arch"] = true, ["Rake"] = true, ["Big Rake"] = true, ["Mega Rake"] = true, 
    ["Swimming Pool"] = true, ["Teleporter Pad Crate"] = true, ["Fence Crate"] = true, ["Boombox Crate"] = true, 
    ["Owner Door Crate"] = true, ["Bear Trap Crate"] = true, ["Rake Crate"] = true, ["Seesaw Crate"] = true, 
    ["Spring Crate"] = true, ["Bridge Crate"] = true, ["Conveyor Crate"] = true, ["Fourth Of July Crate"] = true, 
    ["Picture Frame Crate"] = true, ["Roleplay Crate"] = true, ["Fall Structure Crate"] = true, ["Arch Crate"] = true, 
    ["Cobblestone Crate"] = true, ["Sign Crate"] = true, ["Fall Cosmetic Crate"] = true, ["Light Crate"] = true, 
    ["Bench Crate"] = true, ["Lantern Crate"] = true, ["Ladder Crate"] = true
}

local selectedItemsData = {}
local totalItemsCount = 0

local isScanning = false
RunScanInventory = function()
    if isScanning then return end
    isScanning = true

    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    
    selectedItemsData = {}
    local inventory = getInventory()
    local categories = getMailboxCategories()
    local displayList = {}
    local petGroups = {}
    local searchText = (SearchBox.Text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

    if inventory then
        for _, category in ipairs(categories) do
            local items = inventory[category]
            if type(items) == "table" then
                for itemKey, value in pairs(items) do
                    if isGiftable(category, itemKey, value) then
                        local friendlyName = getFriendlyItemName(category, itemKey, value)
                        
                        local isSeed = ALLOWED_SEEDS[friendlyName] == true
                        local isFruit = (category == "HarvestedFruits")
                        local isGear = ALLOWED_GEARS[friendlyName] == true
                        local isPet = ALLOWED_PETS[friendlyName] == true
                        local isProp = ALLOWED_PROPS[friendlyName] == true
                        
                        if isSeed or isFruit or isGear or isPet or isProp then
                            local nameLower = tostring(friendlyName):lower()

                            if isPet then
                                if not petGroups[friendlyName] then
                                    petGroups[friendlyName] = {
                                        Category = "Pets",
                                        ItemKey = itemKey,
                                        DisplayName = friendlyName,
                                        Quantity = 0,
                                        SendFullCount = false,
                                        IsFruit = false,
                                        FruitValue = 0,
                                        FruitWeight = 0,
                                        FruitMutation = "None",
                                        UniqueIds = {}
                                    }
                                end
                                petGroups[friendlyName].Quantity = petGroups[friendlyName].Quantity + 1
                                table.insert(petGroups[friendlyName].UniqueIds, itemKey)
                            else
                                local count, sendFullCount = getStackCount(value)
                                count = count or 0

                                local fruitMutation = "None"
                                local fruitWeight = 0
                                local fruitValue = 0
                                if isFruit and type(value) == "table" then
                                    fruitMutation = tostring(value.Mutation or value.mutation or "None")
                                    fruitWeight = tonumber(value.Weight or value.weight) or 0
                                    fruitValue = tonumber(value.Value or value.value) or 0
                                end

                                local weightStr = tostring(fruitWeight)
                                local matchesSearch = (searchText == "") or 
                                    (friendlyName and friendlyName:lower():match(searchText)) or 
                                    tostring(itemKey):lower():match(searchText) or 
                                    fruitMutation:lower():match(searchText) or 
                                    weightStr:match(searchText)
                                
                                local matchesFilter = true
                                if activeFilter == "seeds" then
                                    matchesFilter = isSeed
                                elseif activeFilter == "fruit" then
                                    matchesFilter = isFruit
                                elseif activeFilter == "gears" then
                                    matchesFilter = isGear
                                elseif activeFilter == "pets" then
                                    matchesFilter = isPet
                                elseif activeFilter == "props" then
                                    matchesFilter = isProp
                                else
                                    matchesFilter = true
                                end

                                if matchesSearch and matchesFilter and count > 0 then
                                    table.insert(displayList, {
                                        Category = normalizePayloadCategory(category),
                                        ItemKey = itemKey,
                                        DisplayName = friendlyName,
                                        Quantity = count,
                                        SendFullCount = sendFullCount,
                                        IsFruit = isFruit,
                                        FruitValue = fruitValue,
                                        FruitWeight = fruitWeight,
                                        FruitMutation = fruitMutation
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end

        for _, petData in pairs(petGroups) do
            local matchesSearch = (searchText == "") or petData.DisplayName:lower():match(searchText)
            local matchesFilter = (activeFilter == "" or activeFilter == "pets")
            if matchesSearch and matchesFilter and petData.Quantity > 0 then
                table.insert(displayList, petData)
            end
        end
    end

    totalItemsCount = #displayList
    
    if totalItemsCount == 0 then
        create("TextLabel", ScrollingFrame, {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = "No items found.",
            TextColor3 = Color3.fromRGB(150, 170, 200),
            TextSize = 10,
            ZIndex = 4
        })
        isScanning = false
        return
    end
    
    for _, data in ipairs(displayList) do
        local chosenQty = 0
        local uniqueKey = data.Category .. "_" .. tostring(data.ItemKey)
        selectedItemsData[uniqueKey] = {
            Category = data.Category,
            ItemKey = data.ItemKey,
            FriendlyName = data.DisplayName,
            Count = 0,
            SendFullCount = data.SendFullCount,
            IsFruit = data.IsFruit,
            FruitValue = data.FruitValue,
            FruitWeight = data.FruitWeight,
            FruitMutation = data.FruitMutation,
            UniqueIds = data.UniqueIds
        }

        local ItemCard = create("Frame", ScrollingFrame, {
            Size = UDim2.new(1, -2, 0, 36),
            BackgroundColor3 = Color3.fromRGB(15, 25, 48),
            ZIndex = 4
        })
        addCorner(ItemCard, UDim.new(0, 5))
        
        local labelText = data.DisplayName .. " (" .. data.Quantity .. ")"
        if data.IsFruit then
            local mutText = (data.FruitMutation and data.FruitMutation ~= "None") and (" [" .. data.FruitMutation .. "]") or ""
            labelText = data.DisplayName .. mutText .. " (Wt: " .. string.format("%.1f", data.FruitWeight) .. ") (" .. data.Quantity .. ")"
        end

        create("TextLabel", ItemCard, {
            Size = UDim2.new(1, -145, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = labelText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 9,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5
        })

        local QtyControlHolder = create("Frame", ItemCard, {
            Size = UDim2.new(0, 140, 0, 26),
            Position = UDim2.new(1, -143, 0, 5),
            BackgroundTransparency = 1,
            ZIndex = 5
        })

        local MinusBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 22, 0, 24),
            Position = UDim2.new(0, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(30, 45, 75),
            Font = Enum.Font.GothamBold,
            Text = "-",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            ZIndex = 6
        })
        addCorner(MinusBtn, UDim.new(0, 4))

        local QtyBox = create("TextBox", QtyControlHolder, {
            Size = UDim2.new(0, 52, 0, 24),
            Position = UDim2.new(0, 24, 0, 1),
            BackgroundColor3 = Color3.fromRGB(10, 18, 35),
            Font = Enum.Font.GothamBold,
            Text = "0",
            TextColor3 = Color3.fromRGB(0, 220, 255),
            TextSize = 9.5,
            ClearTextOnFocus = false,
            ZIndex = 6
        })
        addCorner(QtyBox, UDim.new(0, 4))
        addStroke(QtyBox, Color3.fromRGB(40, 65, 100))

        local PlusBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 22, 0, 24),
            Position = UDim2.new(0, 78, 0, 1),
            BackgroundColor3 = Color3.fromRGB(30, 45, 75),
            Font = Enum.Font.GothamBold,
            Text = "+",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12,
            ZIndex = 6
        })
        addCorner(PlusBtn, UDim.new(0, 4))

        local MaxBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 36, 0, 24),
            Position = UDim2.new(0, 102, 0, 1),
            BackgroundColor3 = Color3.fromRGB(0, 110, 220),
            Font = Enum.Font.GothamBold,
            Text = "MAX",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 8,
            ZIndex = 6
        })
        addCorner(MaxBtn, UDim.new(0, 4))

        local function updateQtyDisplay(val)
            chosenQty = math.max(0, math.floor(val))
            QtyBox.Text = tostring(chosenQty)
            selectedItemsData[uniqueKey].Count = chosenQty
            ItemCard.BackgroundColor3 = chosenQty > 0 and Color3.fromRGB(18, 35, 65) or Color3.fromRGB(15, 25, 48)
        end

        PlusBtn.MouseButton1Click:Connect(function() updateQtyDisplay(chosenQty + 1) end)
        MinusBtn.MouseButton1Click:Connect(function() updateQtyDisplay(chosenQty - 1) end)
        MaxBtn.MouseButton1Click:Connect(function() updateQtyDisplay(data.Quantity) end)
        QtyBox.FocusLost:Connect(function() updateQtyDisplay(tonumber(QtyBox.Text) or 0) end)
    end
    isScanning = false
end

ScanListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.fromOffset(0, ScanListLayout.AbsoluteContentSize.Y + 5)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(RunScanInventory)

local isSending = false

executeSendProcess = function()
    isSending = true
    SendButton.Text = "SENDING..."

    local batches = {}
    local currentBatch = {}
    for _, entry in ipairs(cachedEntries) do
        table.insert(currentBatch, entry)
        if #currentBatch >= 25 then
            table.insert(batches, currentBatch)
            currentBatch = {}
        end
    end
    if #currentBatch > 0 then
        table.insert(batches, currentBatch)
    end

    task.spawn(function()
        local mailboxRemote = Networking and Networking.Mailbox
        if mailboxRemote then
            if mailboxRemote.SendBatch then
                for _, batch in ipairs(batches) do
                    pcall(function()
                        if mailboxRemote.SendBatch.Fire then
                            mailboxRemote.SendBatch:Fire(cachedTargetUserId, batch, cachedCustomMsg)
                        elseif mailboxRemote.SendBatch.InvokeServer then
                            mailboxRemote.SendBatch:InvokeServer(cachedTargetUserId, batch, cachedCustomMsg)
                        end
                    end)
                end
            else
                for _, entry in ipairs(cachedEntries) do
                    pcall(function()
                        if mailboxRemote.Send then
                            if mailboxRemote.Send.Fire then
                                mailboxRemote.Send.Fire(cachedTargetUserId, entry.Category, entry.ItemKey, entry.Count, cachedCustomMsg)
                            elseif mailboxRemote.Send.InvokeServer then
                                mailboxRemote.Send.InvokeServer(cachedTargetUserId, entry.Category, entry.ItemKey, entry.Count, cachedCustomMsg)
                            end
                        end
                    end)
                end
            end
        end

        AddHistoryCard(cachedRecipientName, table.concat(cachedSummaryList, ", "), os.date("%I:%M %p"))
        RunScanInventory()
        
        SendButton.Text = "SENT!"
        
        for i = 3, 1, -1 do
            SendButton.Text = "COOLDOWN (" .. i .. ")"
            task.wait(1)
        end
        
        SendButton.Text = "Send"
        isSending = false
    end)
end

ConfirmYesBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
    executeSendProcess()
end)

SendButton.MouseButton1Click:Connect(function()
    if isSending then return end
    
    local recipientName = RealTextBox.Text:match("^%s*(.-)%s*$")
    if recipientName == "" then 
        SendButton.Text = "NO USER"
        task.delay(1.5, function() SendButton.Text = "Send" end)
        return 
    end
    
    local customMessage = MessageTextBox.Text or ""
    
    local targetUserId = nil
    pcall(function()
        local mailbox = Networking and Networking.Mailbox
        if mailbox and mailbox.LookupPlayer then
            targetUserId = mailbox.LookupPlayer:Fire(recipientName)
        end
    end)
    if not targetUserId or type(targetUserId) ~= "number" then
        pcall(function()
            targetUserId = Players:GetUserIdFromNameAsync(recipientName)
        end)
    end
    
    if not targetUserId or type(targetUserId) ~= "number" then
        SendButton.Text = "INVALID"
        task.delay(1.5, function() SendButton.Text = "Send" end)
        return
    end

    local entries = {}
    local sentSummaryList = {}

    for _, data in pairs(selectedItemsData) do
        if type(data) == "table" and data.Count > 0 then
            table.insert(sentSummaryList, data.FriendlyName .. " (x" .. data.Count .. ")")
            
            if data.Category == "Pets" and data.UniqueIds then
                for i = 1, math.min(data.Count, #data.UniqueIds) do
                    table.insert(entries, {
                        Category = data.Category,
                        ItemKey = data.UniqueIds[i],
                        Count = 1,
                        SendFullCount = false
                    })
                end
            elseif data.IsFruit then
                table.insert(entries, {
                    Category = data.Category,
                    ItemKey = data.ItemKey,
                    Count = data.Count,
                    SendFullCount = data.SendFullCount,
                    IsFruit = true,
                    Value = data.FruitValue,
                    Weight = data.FruitWeight,
                    Mutation = data.FruitMutation
                })
            else
                local remainingCount = data.Count
                while remainingCount > 0 do
                    local sendAmount = math.min(remainingCount, 9999)
                    table.insert(entries, {
                        Category = data.Category,
                        ItemKey = data.ItemKey,
                        Count = sendAmount,
                        SendFullCount = data.SendFullCount
                    })
                    remainingCount = remainingCount - sendAmount
                end
            end
        end
    end

    if #entries == 0 then
        SendButton.Text = "NO ITEMS"
        task.delay(1.5, function() SendButton.Text = "Send" end)
        return
    end

    cachedTargetUserId = targetUserId
    cachedEntries = entries
    cachedSummaryList = sentSummaryList
    cachedRecipientName = recipientName
    cachedCustomMsg = customMessage

    if requireConfirmation then
        ConfirmTargetUserLabel.Text = "To: " .. recipientName
        ConfirmAvatar.Image = currentAvatarUrl
        ConfirmOverlay.Visible = true
    else
        executeSendProcess()
    end
end)

task.spawn(RunScanInventory)
