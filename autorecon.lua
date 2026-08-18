local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

-- Check if WebhookUrl is already set globally, otherwise default placeholder
local WEBHOOK_URL = getgenv().WebhookUrl or "YOUR_DISCORD_WEBHOOK_URL_HERE"

local function sendWebhook(title, statusText, colorCode)
    if WEBHOOK_URL and WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        task.spawn(function()
            pcall(function()
                local payload = {
                    ["embeds"] = {{
                        ["title"] = title,
                        ["description"] = string.format("**Username:** %s\n**Status:** %s", player.Name, statusText),
                        ["color"] = colorCode,
                        ["footer"] = {
                            ["text"] = os.date("%Y-%m-%d %H:%M:%S") .. " | hennessy malaki tite"
                        }
                    }}
                }
                local encodedData = HttpService:JSONEncode(payload)
                local requestFunc = syn and syn.request or http_request or request or HttpPost
                if requestFunc then
                    requestFunc({
                        Url = WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = encodedData
                    })
                end
            end)
        end)
    end
end

if getgenv().JustReconnectedFlag then
    getgenv().JustReconnectedFlag = nil
    sendWebhook("Reconnected", "Successfully reconnected to the game!", 65280)
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

if targetParent:FindFirstChild("AutoRejoinToggleGUI") then
    targetParent.AutoRejoinToggleGUI:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoRejoinToggleGUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 2147483647
screenGui.Parent = targetParent

-- Single Toggle Button (Auto Reconnect)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 110, 0, 40)
toggleButton.Position = UDim2.new(0, 20, 0, 100)
toggleButton.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "Auto Recon: On"
toggleButton.TextColor3 = Color3.fromRGB(100, 255, 150)
toggleButton.TextSize = 11
toggleButton.ZIndex = 10
toggleButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 70, 95)
stroke.Thickness = 1.5
stroke.Parent = toggleButton

getgenv().AutoRejoinActive = true

toggleButton.MouseButton1Click:Connect(function()
    getgenv().AutoRejoinActive = not getgenv().AutoRejoinActive
    if getgenv().AutoRejoinActive then
        toggleButton.Text = "Auto Recon: On"
        toggleButton.TextColor3 = Color3.fromRGB(100, 255, 150)
    else
        toggleButton.Text = "Auto Recon: Off"
        toggleButton.TextColor3 = Color3.fromRGB(255, 100, 150)
    end
end)

-- ========================================================================
-- WEBHOOK POPUP PROMPT (Textbox, Submit Button, & Kill Switch 'X')
-- ========================================================================
local function createWebhookPopup()
    if WEBHOOK_URL and WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end

    local blurOverlay = Instance.new("Frame")
    blurOverlay.Size = UDim2.new(1, 0, 1, 0)
    blurOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blurOverlay.BackgroundTransparency = 0.5
    blurOverlay.ZIndex = 999
    blurOverlay.Parent = screenGui

    local promptFrame = Instance.new("Frame")
    promptFrame.Size = UDim2.new(0, 360, 0, 160)
    promptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    promptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    promptFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
    promptFrame.BorderSizePixel = 0
    promptFrame.ZIndex = 1000
    promptFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = promptFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(0, 150, 255)
    frameStroke.Thickness = 2
    frameStroke.Parent = promptFrame

    local promptTitle = Instance.new("TextLabel")
    promptTitle.Size = UDim2.new(1, -50, 0, 40)
    promptTitle.Position = UDim2.new(0, 15, 0, 10)
    promptTitle.BackgroundTransparency = 1
    promptTitle.Font = Enum.Font.GothamBold
    promptTitle.Text = "Enter Discord Webhook URL"
    promptTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    promptTitle.TextSize = 16
    promptTitle.TextXAlignment = Enum.TextXAlignment.Left
    promptTitle.ZIndex = 1001
    promptTitle.Parent = promptFrame

    -- Kill Switch Button (X) to close the popup without saving
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 32, 0, 32)
    closeButton.Position = UDim2.new(1, -42, 0, 14)
    closeButton.BackgroundColor3 = Color3.fromRGB(40, 10, 20)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.TextSize = 16
    closeButton.ZIndex = 1002
    closeButton.Parent = promptFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton

    local closeStroke = Instance.new("UIStroke")
    closeStroke.Color = Color3.fromRGB(255, 50, 50)
    closeStroke.Thickness = 1.2
    closeStroke.Parent = closeButton

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 320, 0, 35)
    textBox.Position = UDim2.new(0.5, -160, 0, 60)
    textBox.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    textBox.Font = Enum.Font.Gotham
    textBox.PlaceholderText = "Paste webhook URL here..."
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    textBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
    textBox.TextSize = 13
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 1001
    textBox.Parent = promptFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = textBox

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(60, 75, 105)
    boxStroke.Thickness = 1.2
    boxStroke.Parent = textBox

    local submitButton = Instance.new("TextButton")
    submitButton.Size = UDim2.new(0, 320, 0, 35)
    submitButton.Position = UDim2.new(0.5, -160, 0, 108)
    submitButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    submitButton.Font = Enum.Font.GothamBold
    submitButton.Text = "Submit"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextSize = 14
    submitButton.ZIndex = 1001
    submitButton.Parent = promptFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = submitButton

    submitButton.MouseButton1Click:Connect(function()
        local inputContent = textBox.Text
        if inputContent and inputContent ~= "" then
            WEBHOOK_URL = inputContent
            getgenv().WebhookUrl = inputContent
            promptFrame:Destroy()
            blurOverlay:Destroy()
            sendWebhook("Webhook Connected", "Successfully linked webhook to script!", 65280)
        else
            textBox.PlaceholderText = "Please enter a valid URL!"
        end
    end)

    -- Kill Switch click event to dismiss popup completely
    closeButton.MouseButton1Click:Connect(function()
        promptFrame:Destroy()
        blurOverlay:Destroy()
    end)
end

-- Run popup check
task.spawn(createWebhookPopup)

local hasSentWebhook = false

local function triggerRejoin(reason)
    if not getgenv().AutoRejoinActive then return end
    
    if not hasSentWebhook then
        hasSentWebhook = true
        getgenv().JustReconnectedFlag = true
        sendWebhook("Disconnected", "Reconnecting...", 16711680)
    end

    print("[AutoRejoin] Disconnection detected: " .. tostring(reason))

    while getgenv().AutoRejoinActive do
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
        end)
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        task.wait(4)
    end
end

TeleportService.TeleportInitFailed:Connect(function(targetPlayer, _, errorMessage)
    if targetPlayer == player then
        triggerRejoin("TeleportInitFailed: " .. tostring(errorMessage))
    end
end)

pcall(function()
    GuiService.ErrorMessageChanged:Connect(function()
        local err = GuiService:GetErrorMessage()
        if err and err ~= "" then
            triggerRejoin("GuiService Error: " .. err)
        end
    end)
end)

task.spawn(function()
    while screenGui.Parent do
        task.wait(0.3)
        pcall(function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            if robloxGui then
                for _, descendant in ipairs(robloxGui:GetDescendants()) do
                    if descendant:IsA("TextLabel") and descendant.Visible then
                        local text = string.lower(descendant.Text)
                        if text:find("disconnected") or text:find("lost connection") or text:find("reconnect") or text:find("error code") or text:find("shut down") then
                            triggerRejoin("CoreGui Text Match: " .. descendant.Text)
                        end
                    end
                end
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        triggerRejoin("PlayerRemoving Event")
    end
end)
