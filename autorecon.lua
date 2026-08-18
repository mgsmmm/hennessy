local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

-- ========================================================================
-- DISCORD WEBHOOK URL HERE (OR SET VIA getgenv().WebhookUrl)
-- ========================================================================
local WEBHOOK_URL = getgenv().WebhookUrl or ""

local function sendWebhook(title, statusText, colorCode)
    if WEBHOOK_URL and WEBHOOK_URL ~= "" and WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE" then
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

-- ========================================================================
-- UI CONTAINER (Holds Toggle Button & Webhook Setup Box)
-- ========================================================================
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 110, 0, 85)
mainFrame.Position = UDim2.new(0, 20, 0, 100)
mainFrame.BackgroundTransparency = 1
mainFrame.ZIndex = 10
mainFrame.Parent = screenGui

-- Single Toggle Button (Auto Reconnect)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 110, 0, 38)
toggleButton.Position = UDim2.new(0, 0, 0, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "Auto Recon: On"
toggleButton.TextColor3 = Color3.fromRGB(100, 255, 150)
toggleButton.TextSize = 11
toggleButton.ZIndex = 11
toggleButton.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = toggleButton

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 70, 95)
stroke.Thickness = 1.5
stroke.Parent = toggleButton

-- Webhook Input Box
local webhookBox = Instance.new("TextBox")
webhookBox.Size = UDim2.new(0, 110, 0, 32)
webhookBox.Position = UDim2.new(0, 0, 0, 46)
webhookBox.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
webhookBox.Font = Enum.Font.Gotham
webhookBox.PlaceholderText = "Paste Webhook..."
webhookBox.Text = (WEBHOOK_URL ~= "" and WEBHOOK_URL ~= "YOUR_DISCORD_WEBHOOK_URL_HERE") and WEBHOOK_URL or ""
webhookBox.TextColor3 = Color3.fromRGB(220, 225, 240)
webhookBox.PlaceholderColor3 = Color3.fromRGB(120, 130, 150)
webhookBox.TextSize = 10
webhookBox.ClearTextOnFocus = false
webhookBox.ZIndex = 11
webhookBox.Parent = mainFrame

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = webhookBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(50, 60, 85)
boxStroke.Thickness = 1.2
boxStroke.Parent = webhookBox

webhookBox.FocusLost:Connect(function(enterPressed)
    if webhookBox.Text ~= "" then
        WEBHOOK_URL = webhookBox.Text
        getgenv().WebhookUrl = webhookBox.Text
    end
end)

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

local hasSentWebhook = false

local function triggerRejoin(reason)
    if not getgenv().AutoRejoinActive then return end
    
    if not hasSentWebhook then
        hasSentWebhook = true
        getgenv().JustReconnectedFlag = true
        sendWebhook("Disconnected", "Reconnecting...", 16711680)
    end

    print("[AutoRejoin] Disconnection detected: " + tostring(reason))

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
        triggerRejoin("TeleportInitFailed: " + tostring(errorMessage))
    end
end)

pcall(function()
    GuiService.ErrorMessageChanged:Connect(function()
        local err = GuiService:GetErrorMessage()
        if err and err ~= "" then
            triggerRejoin("GuiService Error: " + err)
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
                            triggerRejoin("CoreGui Text Match: " + descendant.Text)
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
