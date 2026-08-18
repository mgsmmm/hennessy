-- Hennessy Mailbox (99,990 max per items)
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
    Size = UDim2.new(0, 624, 0, 351),
    Position = UDim2.new(0.5, -312, 0.5, -175.5),
    BackgroundColor3 = Color3.fromRGB(8, 14, 28),
    BorderSizePixel = 0
})
addCorner(MainWindow, UDim.new(0, 13))
addStroke(MainWindow, Color3.fromRGB(0, 162, 255), 2, 0.3)

local dragging, dragInput, dragStart, startPos
MainWindow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainWindow.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local resizing = false
local resizeEdge = nil
local resizeStartPos, resizeStartSize

local function createResizeHandle(name, size, position)
    local handle = create("Frame", MainWindow, {
        Name = name,
        Size = size,
        Position = position,
        BackgroundTransparency = 1,
        ZIndex = 10
    })
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeEdge = name
            resizeStartPos = input.Position
            resizeStartSize = MainWindow.Size
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    resizeEdge = nil
                end
            end)
        end
    end)
    
    return handle
end

createResizeHandle("RightEdge", UDim2.new(0, 10, 1, 0), UDim2.new(1, -5, 0, 0))
createResizeHandle("BottomEdge", UDim2.new(1, 0, 0, 10), UDim2.new(0, 0, 1, -5))
createResizeHandle("CornerEdge", UDim2.new(0, 20, 0, 20), UDim2.new(1, -15, 1, -15))

UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local minWidth, minHeight = 450, 260
        
        if resizeEdge == "RightEdge" then
            local newWidth = math.max(minWidth, resizeStartSize.X.Offset + delta.X)
            MainWindow.Size = UDim2.new(0, newWidth, 0, MainWindow.AbsoluteSize.Y)
        elseif resizeEdge == "BottomEdge" then
            local newHeight = math.max(minHeight, resizeStartSize.Y.Offset + delta.Y)
            MainWindow.Size = UDim2.new(0, MainWindow.AbsoluteSize.X, 0, newHeight)
        elseif resizeEdge == "CornerEdge" then
            local newWidth = math.max(minWidth, resizeStartSize.X.Offset + delta.X)
            local newHeight = math.max(minHeight, resizeStartSize.Y.Offset + delta.Y)
            MainWindow.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
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

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, child in ipairs(MainWindow:GetChildren()) do
        if child:IsA("GuiObject") and child ~= HeaderTitle and child ~= CloseButton and child ~= MinimizeButton and child.Name ~= "RightEdge" and child.Name ~= "BottomEdge" and child.Name ~= "CornerEdge" then
            child.Visible = not isMinimized
        end
    end
    local targetSize = isMinimized and UDim2.new(0, MainWindow.AbsoluteSize.X, 0, 36) or UDim2.new(0, MainWindow.AbsoluteSize.X, 0, 351)
    TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end)

-- ==========================================
-- LEFT SIDE (Recipient Search + Send Button + History)
-- ==========================================
local LeftSideContainer = create("Frame", MainWindow, {
    Size = UDim2.new(0.48, 0, 0.86, 0),
    Position = UDim2.new(0.012, 0, 0.11, 0),
    BackgroundTransparency = 1,
    ZIndex = 2
})

local RecipientContainer = create("Frame", LeftSideContainer, {
    Size = UDim2.new(1, 0, 0, 114),
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

local UsernameDisplayLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 18),
    Position = UDim2.new(0, 6, 0, 40),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Username: -",
    TextColor3 = Color3.fromRGB(150, 180, 220),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local StatusLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 18),
    Position = UDim2.new(0, 6, 0, 58),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "Status: Idle",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local SendButton = create("TextButton", RecipientContainer, {
    Size = UDim2.new(1, -124, 0, 26),
    Position = UDim2.new(0, 6, 0, 80),
    BackgroundColor3 = Color3.fromRGB(0, 110, 220),
    Font = Enum.Font.GothamBold,
    Text = "Send",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    ZIndex = 4
})
addCorner(SendButton, UDim.new(0, 5))
addStroke(SendButton, Color3.fromRGB(0, 162, 255))

local function CheckUser(usernameInput)
    usernameInput = usernameInput:match("^%s*(.-)%s*$")
    if usernameInput == "" or #usernameInput < 3 then
        UsernameDisplayLabel.Text = "Username: -"
        StatusLabel.Text = "Status: Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        AvatarIcon.Image = "rbxassetid://0"
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
            else
                AvatarIcon.Image = "rbxassetid://0"
            end
        else
            UsernameDisplayLabel.Text = "Username: Not Found"
            StatusLabel.Text = "Status: player not found"
            StatusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            AvatarIcon.Image = "rbxassetid://0"
        end
    end)
end

RealTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    CheckUser(RealTextBox.Text)
end)

local HistoryContainer = create("Frame", LeftSideContainer, {
    Size = UDim2.new(1, 0, 1, -122),
    Position = UDim2.new(0, 0, 0, 122),
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

-- ==========================================
-- RIGHT SIDE (Inventory with Search & Items)
-- ==========================================
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
    PlaceholderText = "🔍 Search Item in Inventory...",
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
    Padding = UDim.new(0, 4)
})

local activeFilter = ""
local filterButtons = {}

local function createFilterButton(name, filterText, order)
    local btn = create("TextButton", FilterContainer, {
        Size = UDim2.new(0.158, -4, 1, 0),
        BackgroundColor3 = Color3.fromRGB(15, 25, 48),
        Font = Enum.Font.GothamBold,
        Text = name,
        TextColor3 = Color3.fromRGB(180, 190, 210),
        TextSize = 9,
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
local btnFruits = createFilterButton("Fruits", "fruits", 6)

btnAll.BackgroundColor3 = Color3.fromRGB(0, 110, 220)
btnAll.TextColor3 = Color3.fromRGB(255, 255, 255)

btnAll.MouseButton1Click:Connect(function() setFilter("") end)
btnSeeds.MouseButton1Click:Connect(function() setFilter("seeds") end)
btnGears.MouseButton1Click:Connect(function() setFilter("gears") end)
btnPets.MouseButton1Click:Connect(function() setFilter("pets") end)
btnProps.MouseButton1Click:Connect(function() setFilter("props") end)
btnFruits.MouseButton1Click:Connect(function() setFilter("fruits") end)

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
    local searchText = SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if inventory then
        for _, category in ipairs(categories) do
            local items = inventory[category]
            if type(items) == "table" then
                for itemKey, value in pairs(items) do
                    if isGiftable(category, itemKey, value) then
                        local friendlyName = getFriendlyItemName(category, itemKey, value)
                        local isFruitCategory = (category == "HarvestedFruits" or category:lower():match("fruit"))

                        if category == "Pets" then
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

                            local matchesSearch = (searchText == "") or friendlyName:lower():match(searchText) or tostring(itemKey):lower():match(searchText)

                            local catLower = category:lower()
                            local nameLower = friendlyName:lower()
                            
                            local isCrate = catLower:match("crate") or nameLower:match("crate")
                            local isPot = catLower:match("pot") or nameLower:match("pot")
                            local isSeedShop = catLower:match("seed") or nameLower:match("seed") or catLower:match("seedpack")
                            local isGearShop = (catLower:match("sprinkler") or catLower:match("wateringcan") or catLower:match("trowel") or nameLower:match("sprinkler") or nameLower:match("wateringcan") or nameLower:match("trowel")) and not isPot
                            local isPetShop = catLower:match("pet") or nameLower:match("pet") or catLower:match("egg")
                            local isPropShop = catLower:match("prop") or catLower:match("gnome") or catLower:match("mushroom") or catLower:match("raccoon") or nameLower:match("prop") or nameLower:match("gnome") or nameLower:match("mushroom") or nameLower:match("raccoon")
                            local isFruitCategoryCheck = (category == "HarvestedFruits" or catLower:match("fruit"))

                            local matchesFilter = true
                            if isPot then
                                matchesFilter = false
                            else
                                if activeFilter == "fruits" then
                                    matchesFilter = isFruitCategoryCheck
                                else
                                    if isFruitCategoryCheck then
                                        matchesFilter = false
                                    elseif activeFilter ~= "" then
                                        if activeFilter == "seeds" then
                                            matchesFilter = isSeedShop
                                        elseif activeFilter == "gears" then
                                            matchesFilter = isGearShop
                                        elseif activeFilter == "pets" then
                                            matchesFilter = isPetShop
                                        elseif activeFilter == "props" then
                                            matchesFilter = isPropShop or isCrate
                                        end
                                    else
                                        -- When "All" is active, crates are included, pots are excluded
                                        matchesFilter = true
                                    end
                                end
                            end

                            if matchesSearch and matchesFilter and count > 0 then
                                local fruitValue, fruitWeight, fruitMutation = 0, 0, "None"
                                if category == "HarvestedFruits" and type(value) == "table" then
                                    fruitValue = tonumber(value.Value or value.value or value.SellValue) or 0
                                    fruitWeight = tonumber(value.Weight or value.weight) or 0
                                    fruitMutation = tostring(value.Mutation or value.mutation or value.Mut or "None")
                                end

                                table.insert(displayList, {
                                    Category = normalizePayloadCategory(category),
                                    ItemKey = itemKey,
                                    DisplayName = friendlyName,
                                    Quantity = count,
                                    SendFullCount = sendFullCount,
                                    IsFruit = isFruitCategoryCheck,
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
            UniqueIds = data.UniqueIds
        }

        local ItemCard = create("Frame", ScrollingFrame, {
            Size = UDim2.new(1, -2, 0, data.IsFruit and 52 or 36),
            BackgroundColor3 = Color3.fromRGB(15, 25, 48),
            ZIndex = 4
        })
        addCorner(ItemCard, UDim.new(0, 5))
        
        local labelText = data.DisplayName .. (data.IsFruit and "" or " (" .. data.Quantity .. ")")
        if data.IsFruit then
            labelText = data.DisplayName .. "\nVal: " .. data.FruitValue + 0 .. " | Wt: " .. data.FruitWeight + 0 .. " | Mut: " .. data.FruitMutation
        end

        create("TextLabel", ItemCard, {
            Size = UDim2.new(1, -145, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = labelText,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = data.IsFruit and 8.5 or 9.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5
        })

        local QtyControlHolder = create("Frame", ItemCard, {
            Size = UDim2.new(0, 140, 0, 26),
            Position = UDim2.new(1, -143, 0, data.IsFruit and 13 or 5),
            BackgroundTransparency = 1,
            ZIndex = 5
        })

        if data.IsFruit then
            local TargetValueBox = create("TextBox", QtyControlHolder, {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(10, 18, 35),
                Font = Enum.Font.GothamBold,
                PlaceholderText = "Target Value...",
                PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                Text = "",
                TextColor3 = Color3.fromRGB(0, 220, 255),
                TextSize = 9,
                ClearTextOnFocus = false,
                ZIndex = 6
            })
            addCorner(TargetValueBox, UDim.new(0, 4))
            addStroke(TargetValueBox, Color3.fromRGB(40, 65, 100))

            TargetValueBox.FocusLost:Connect(function()
                local targetVal = tonumber(TargetValueBox.Text)
                if not targetVal then
                    selectedItemsData[uniqueKey].Count = 0
                    ItemCard.BackgroundColor3 = Color3.fromRGB(15, 25, 48)
                    return
                end

                local bestItemKey = nil
                local minDiff = math.huge
                local inventory = getInventory()
                local items = inventory and inventory["HarvestedFruits"]
                
                if type(items) == "table" then
                    for k, val in pairs(items) do
                        if type(val) == "table" then
                            local fName = getFriendlyItemName("HarvestedFruits", k, val)
                            if fName == data.DisplayName then
                                local fVal = tonumber(val.Value or val.value or val.SellValue) or 0
                                local diff = math.abs(fVal - targetVal)
                                if diff < minDiff then
                                    minDiff = diff
                                    bestItemKey = k
                                end
                            end
                        end
                    end
                end

                if bestItemKey then
                    selectedItemsData[uniqueKey].ItemKey = bestItemKey
                    selectedItemsData[uniqueKey].Count = 1
                    ItemCard.BackgroundColor3 = Color3.fromRGB(18, 35, 65)
                else
                    selectedItemsData[uniqueKey].Count = 0
                    ItemCard.BackgroundColor3 = Color3.fromRGB(15, 25, 48)
                end
            end)
        else
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
    end
    isScanning = false
end

ScanListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollingFrame.CanvasSize = UDim2.fromOffset(0, ScanListLayout.AbsoluteContentSize.Y + 5)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(RunScanInventory)

local isSending = false
SendButton.MouseButton1Click:Connect(function()
    if isSending then return end
    
    local recipientName = RealTextBox.Text:match("^%s*(.-)%s*$")
    if recipientName == "" then 
        SendButton.Text = "NO USER"
        task.delay(1.5, function() SendButton.Text = "Send" end)
        return 
    end
    
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

    isSending = true
    SendButton.Text = "SENDING..."

    local batches = {}
    local currentBatch = {}
    for _, entry in ipairs(entries) do
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
                            mailboxRemote.SendBatch:Fire(targetUserId, batch, "")
                        elseif mailboxRemote.SendBatch.InvokeServer then
                            mailboxRemote.SendBatch:InvokeServer(targetUserId, batch, "")
                        end
                    end)
                end
            else
                for _, entry in ipairs(entries) do
                    pcall(function()
                        if mailboxRemote.Send then
                            if mailboxRemote.Send.Fire then
                                mailboxRemote.Send.Fire(targetUserId, entry.Category, entry.ItemKey, entry.Count, "")
                            elseif mailboxRemote.Send.InvokeServer then
                                mailboxRemote.Send.InvokeServer(targetUserId, entry.Category, entry.ItemKey, entry.Count, "")
                            end
                        end
                    end)
                end
            end
        end

        AddHistoryCard(recipientName, table.concat(sentSummaryList, ", "), os.date("%I:%M %p"))
        RunScanInventory()
        
        SendButton.Text = "SENT!"
        
        for i = 3, 1, -1 do
            SendButton.Text = "COOLDOWN (" .. i .. ")"
            task.wait(1)
        end
        
        SendButton.Text = "Send"
        isSending = false
    end)
end)

task.spawn(RunScanInventory)
