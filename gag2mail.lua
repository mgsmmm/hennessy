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

local function getFriendlyItemName(category, itemKey)
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
	if MailboxItemCatalog and MailboxItemCatalog.IsGiftable then
		local ok, result = pcall(MailboxItemCatalog.IsGiftable, category)
		if ok and result ~= true and category ~= "Eggs" and category ~= "Egg" then return false end
	end
	if category == "HarvestedFruits" then return type(value) == "table" and value.Id ~= nil end
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
    return create("UICorner", parent, {CornerRadius = radius or UDim.new(0, 6)})
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
    Size = UDim2.new(0, 480, 0, 270),
    Position = UDim2.new(0.5, -240, 0.5, -135),
    BackgroundColor3 = Color3.fromRGB(8, 14, 28),
    BorderSizePixel = 0
})
addCorner(MainWindow, UDim.new(0, 10))
addStroke(MainWindow, Color3.fromRGB(0, 162, 255), 2, 0.3)

-- DRAGGABLE IMPLEMENTATION
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

local HeaderTitle = create("TextLabel", MainWindow, {
    Size = UDim2.new(0, 280, 0, 20),
    Position = UDim2.new(0, 8, 0, 4),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Hennessy Mailbox (99,990 max items)",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left
})

local CloseButton = create("TextButton", MainWindow, {
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(1, -24, 0, 4),
    BackgroundColor3 = Color3.fromRGB(200, 50, 50),
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 9,
    ZIndex = 5
})
addCorner(CloseButton, UDim.new(0, 4))
CloseButton.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local MinimizeButton = create("TextButton", MainWindow, {
    Size = UDim2.new(0, 20, 0, 20),
    Position = UDim2.new(1, -48, 0, 4),
    BackgroundColor3 = Color3.fromRGB(40, 60, 90),
    Text = "-",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    ZIndex = 5
})
addCorner(MinimizeButton, UDim.new(0, 4))

local isMinimized = false
MinimizeButton.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, child in ipairs(MainWindow:GetChildren()) do
        if child:IsA("GuiObject") and child ~= HeaderTitle and child ~= CloseButton and child ~= MinimizeButton then
            child.Visible = not isMinimized
        end
    end
    local targetSize = isMinimized and UDim2.new(0, 480, 0, 28) or UDim2.new(0, 480, 0, 270)
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
    Size = UDim2.new(1, 0, 0, 80),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = Color3.fromRGB(15, 25, 48),
    ZIndex = 2
})
addCorner(RecipientContainer)

-- Left margin/width layout ensuring text elements stay completely to the left of the 70px avatar box
local AvatarImage = create("ImageLabel", RecipientContainer, {
    Size = UDim2.new(0, 70, 0, 70),
    Position = UDim2.new(1, -75, 0, 5),
    BackgroundColor3 = Color3.fromRGB(20, 35, 60),
    Image = "",
    ZIndex = 5
})
addCorner(AvatarImage, UDim.new(0, 4))
addStroke(AvatarImage, Color3.fromRGB(55, 75, 110))

local RealTextBox = create("TextBox", RecipientContainer, {
    Size = UDim2.new(1, -82, 0, 20),
    Position = UDim2.new(0, 5, 0, 4),
    BackgroundColor3 = Color3.fromRGB(15, 28, 50),
    BorderSizePixel = 0,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    PlaceholderText = "Username...",
    PlaceholderColor3 = Color3.fromRGB(170, 170, 170),
    Font = Enum.Font.GothamBold,
    TextSize = 8,
    ClearTextOnFocus = false,
    ZIndex = 4
})
addCorner(RealTextBox, UDim.new(0, 4))
addStroke(RealTextBox, Color3.fromRGB(55, 75, 110))

local UserIdLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -82, 0, 14),
    Position = UDim2.new(0, 5, 0, 26),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "ID: Ready",
    TextColor3 = Color3.fromRGB(150, 180, 220),
    TextSize = 7.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local StatusLabel = create("TextLabel", RecipientContainer, {
    Size = UDim2.new(1, -82, 0, 14),
    Position = UDim2.new(0, 5, 0, 41),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamSemibold,
    Text = "Status: Idle",
    TextColor3 = Color3.fromRGB(170, 170, 170),
    TextSize = 7,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local SendButton = create("TextButton", RecipientContainer, {
    Size = UDim2.new(1, -82, 0, 18),
    Position = UDim2.new(0, 5, 0, 57),
    BackgroundColor3 = Color3.fromRGB(0, 110, 220),
    Font = Enum.Font.GothamBold,
    Text = "Send",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 8,
    ZIndex = 4
})
addCorner(SendButton, UDim.new(0, 4))
addStroke(SendButton, Color3.fromRGB(0, 162, 255))

local function CheckUser(username)
    username = username:match("^%s*(.-)%s*$")
    if username == "" or #username < 3 then
        UserIdLabel.Text = "ID: Ready"
        StatusLabel.Text = "Status: Idle"
        StatusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
        AvatarImage.Image = ""
        return
    end

    UserIdLabel.Text = "ID: Searching..."
    StatusLabel.Text = "Status:searching..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
    AvatarImage.Image = ""

    task.spawn(function()
        local success, userId = pcall(function()
            return Players:GetUserIdFromNameAsync(username)
        end)
        if success and userId then
            UserIdLabel.Text = "ID: " .. userId
            StatusLabel.Text = "Status: player found"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
            
            local okThumb, thumbUrl = pcall(function()
                return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            if okThumb and thumbUrl then
                AvatarImage.Image = thumbUrl
            end
        else
            UserIdLabel.Text = "ID: Not Found"
            StatusLabel.Text = "Status: player not found"
            StatusLabel.TextColor3 = Color3.fromRGB(220, 50, 50)
            AvatarImage.Image = ""
        end
    end)
end

RealTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    CheckUser(RealTextBox.Text)
end)

local HistoryContainer = create("Frame", LeftSideContainer, {
    Size = UDim2.new(1, 0, 1, -86),
    Position = UDim2.new(0, 0, 0, 86),
    BackgroundColor3 = Color3.fromRGB(12, 22, 44),
    ZIndex = 2
})
addCorner(HistoryContainer)

create("TextLabel", HistoryContainer, {
    Size = UDim2.new(1, -8, 0, 16),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "📜 HISTORY",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 8.5,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 3
})

local TotalSentLabel = create("TextLabel", HistoryContainer, {
    Size = UDim2.new(1, -4, 0, 16),
    Position = UDim2.new(0, 0, 0, 4),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamBold,
    Text = "Sent: 0",
    TextColor3 = Color3.fromRGB(0, 200, 255),
    TextSize = 8.5,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 3
})

local HistoryScroll = create("ScrollingFrame", HistoryContainer, {
    Size = UDim2.new(1, -8, 1, -46),
    Position = UDim2.new(0, 4, 0, 22),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 2,
    ZIndex = 3
})

local HistList = create("UIListLayout", HistoryScroll, {Padding = UDim.new(0, 4)})

local function UpdateHistoryTotal()
    local total = 0
    for _, v in ipairs(HistoryScroll:GetChildren()) do
        if v:IsA("Frame") then total = total + 1 end
    end
    TotalSentLabel.Text = "Sent: " .. total
end

HistList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    HistoryScroll.CanvasSize = UDim2.fromOffset(0, HistList.AbsoluteContentSize.Y + 4)
    UpdateHistoryTotal()
end)

local function AddHistoryCard(username, itemsText, timeStr)
    local Card = create("Frame", HistoryScroll, {
        Size = UDim2.new(1, -2, 0, 38),
        BackgroundColor3 = Color3.fromRGB(15, 28, 55),
        ZIndex = 4
    })
    addCorner(Card, UDim.new(0, 4))
    
    create("TextLabel", Card, {
        Size = UDim2.new(0, 90, 0, 12),
        Position = UDim2.new(0, 5, 0, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = username,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5
    })
    
    create("TextLabel", Card, {
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 5, 0, 15),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamSemibold,
        Text = itemsText,
        TextColor3 = Color3.fromRGB(0, 220, 255),
        TextSize = 7,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5
    })
    
    create("TextLabel", Card, {
        Size = UDim2.new(0, 55, 0, 12),
        Position = UDim2.new(1, -58, 0, 3),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = timeStr,
        TextColor3 = Color3.fromRGB(180, 190, 210),
        TextSize = 7,
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

local SearchBox = create("TextBox", InventoryContainer, {
    Size = UDim2.new(1, -8, 0, 20),
    Position = UDim2.new(0, 4, 0, 4),
    BackgroundColor3 = Color3.fromRGB(18, 28, 50),
    PlaceholderText = "🔍 Search Item in Inventory...",
    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
    TextColor3 = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.GothamBold,
    Text = "",
    TextSize = 7.5,
    ZIndex = 4
})
addCorner(SearchBox, UDim.new(0, 4))
addStroke(SearchBox, Color3.fromRGB(35, 55, 85))

local ScrollingFrame = create("ScrollingFrame", InventoryContainer, {
    Size = UDim2.new(1, -8, 1, -30),
    Position = UDim2.new(0, 4, 0, 28),
    BackgroundTransparency = 1,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 2,
    ZIndex = 3
})

local ScanListLayout = create("UIListLayout", ScrollingFrame, {
    Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder
})

local selectedItemsData = {}
local totalItemsCount = 0

local isScanning = false
local function RunScanInventory()
    if isScanning then return end
    isScanning = true

    for _, child in ipairs(ScrollingFrame:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    
    selectedItemsData = {}
    local inventory = getInventory()
    local categories = getMailboxCategories()
    local displayList = {}
    local searchText = SearchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if inventory then
        for _, category in ipairs(categories) do
            local items = inventory[category]
            if type(items) == "table" then
                for itemKey, value in pairs(items) do
                    if isGiftable(category, itemKey, value) then
                        local count, sendFullCount = 1, false
                        if category ~= "Pets" and category ~= "HarvestedFruits" then
                            count, sendFullCount = getStackCount(value)
                            count = count or 0
                        else
                            count = 1
                        end

                        local friendlyName = getFriendlyItemName(category, itemKey)
                        local matchesSearch = (searchText == "") or friendlyName:lower():match(searchText) or tostring(itemKey):lower():match(searchText)

                        if matchesSearch and count > 0 then
                            table.insert(displayList, {
                                Category = normalizePayloadCategory(category),
                                ItemKey = itemKey,
                                DisplayName = friendlyName,
                                Quantity = count,
                                SendFullCount = sendFullCount
                            })
                        end
                    end
                end
            end
        end
    end

    totalItemsCount = #displayList
    
    if totalItemsCount == 0 then
        create("TextLabel", ScrollingFrame, {
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundTransparency = 1,
            Font = Enum.Font.Gotham,
            Text = "No items found.",
            TextColor3 = Color3.fromRGB(150, 170, 200),
            TextSize = 7.5,
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
            SendFullCount = data.SendFullCount
        }

        local ItemCard = create("Frame", ScrollingFrame, {
            Size = UDim2.new(1, -2, 0, 28),
            BackgroundColor3 = Color3.fromRGB(15, 25, 48),
            ZIndex = 4
        })
        addCorner(ItemCard, UDim.new(0, 4))
        
        create("TextLabel", ItemCard, {
            Size = UDim2.new(1, -115, 1, 0),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            Text = data.DisplayName .. " (" .. data.Quantity .. ")",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 7,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 5
        })

        local QtyControlHolder = create("Frame", ItemCard, {
            Size = UDim2.new(0, 110, 0, 20),
            Position = UDim2.new(1, -112, 0, 4),
            BackgroundTransparency = 1,
            ZIndex = 5
        })

        local MinusBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 16, 0, 18),
            Position = UDim2.new(0, 0, 0, 1),
            BackgroundColor3 = Color3.fromRGB(30, 45, 75),
            Font = Enum.Font.GothamBold,
            Text = "-",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 9,
            ZIndex = 6
        })
        addCorner(MinusBtn, UDim.new(0, 3))

        local QtyBox = create("TextBox", QtyControlHolder, {
            Size = UDim2.new(0, 42, 0, 18),
            Position = UDim2.new(0, 18, 0, 1),
            BackgroundColor3 = Color3.fromRGB(10, 18, 35),
            Font = Enum.Font.GothamBold,
            Text = "0",
            TextColor3 = Color3.fromRGB(0, 220, 255),
            TextSize = 7,
            ClearTextOnFocus = false,
            ZIndex = 6
        })
        addCorner(QtyBox, UDim.new(0, 3))
        addStroke(QtyBox, Color3.fromRGB(40, 65, 100))

        local PlusBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 16, 0, 18),
            Position = UDim2.new(0, 62, 0, 1),
            BackgroundColor3 = Color3.fromRGB(30, 45, 75),
            Font = Enum.Font.GothamBold,
            Text = "+",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 9,
            ZIndex = 6
        })
        addCorner(PlusBtn, UDim.new(0, 3))

        local MaxBtn = create("TextButton", QtyControlHolder, {
            Size = UDim2.new(0, 28, 0, 18),
            Position = UDim2.new(0, 80, 0, 1),
            BackgroundColor3 = Color3.fromRGB(0, 110, 220),
            Font = Enum.Font.GothamBold,
            Text = "MAX",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 6,
            ZIndex = 6
        })
        addCorner(MaxBtn, UDim.new(0, 3))

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
    ScrollingFrame.CanvasSize = UDim2.fromOffset(0, ScanListLayout.AbsoluteContentSize.Y + 4)
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(RunScanInventory)

-- Send Button functionality: instant dispatch with a 3-second post-send cooldown
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
        if #currentBatch >= 10 then
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
        
        -- 3 seconds cooldown after sending
        for i = 3, 1, -1 do
            SendButton.Text = "COOLDOWN (" .. i .. ")"
            task.wait(1)
        end
        
        SendButton.Text = "Send"
        isSending = false
    end)
end)

task.spawn(RunScanInventory)
