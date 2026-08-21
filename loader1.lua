local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local isSystemActive = true 

if not isSystemActive then
    player:Kick("[Security Error]: The key system has been disabled by the developer.")
    return
end

if playerGui:FindFirstChild("HennessyKeySystem") then
    playerGui.HennessyKeySystem:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HennessyKeySystem"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 260)
mainFrame.Position = UDim2.new(0.5, -240, 0.5, -130)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(40, 75, 130)
mainStroke.Thickness = 1.5
mainStroke.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 29, 48)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 350, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Hennessy Mailbox key system"
title.TextColor3 = Color3.fromRGB(225, 235, 250)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Close (X) Button (Moved to the corner since minimize is gone)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 45)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 4)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy() 
end)

local innerPanel = Instance.new("Frame")
innerPanel.Size = UDim2.new(1, -20, 1, -50)
innerPanel.Position = UDim2.new(0, 10, 0, 42)
innerPanel.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
innerPanel.BorderSizePixel = 0
innerPanel.Parent = mainFrame

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 6)
panelCorner.Parent = innerPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(30, 50, 85)
panelStroke.Thickness = 1
panelStroke.Parent = innerPanel

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(0.85, 0, 0, 42)
keyBox.Position = UDim2.new(0.075, 0, 0, 25)
keyBox.PlaceholderText = "Enter your key here..."
keyBox.Text = ""
keyBox.ClearTextOnFocus = false
keyBox.TextColor3 = Color3.fromRGB(240, 245, 255)
keyBox.PlaceholderColor3 = Color3.fromRGB(110, 130, 165)
keyBox.BackgroundColor3 = Color3.fromRGB(16, 24, 40)
keyBox.TextSize = 14
keyBox.Font = Enum.Font.Gotham
keyBox.Parent = innerPanel

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 6)
boxCorner.Parent = keyBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(45, 80, 135)
boxStroke.Thickness = 1
boxStroke.Parent = keyBox

local userDisplay = Instance.new("TextLabel")
userDisplay.Size = UDim2.new(0.85, 0, 0, 36)
userDisplay.Position = UDim2.new(0.075, 0, 0, 78)
userDisplay.BackgroundColor3 = Color3.fromRGB(16, 24, 40)
userDisplay.Text = "Roblox User: " .. player.Name
userDisplay.TextColor3 = Color3.fromRGB(180, 200, 230)
userDisplay.TextSize = 13
userDisplay.Font = Enum.Font.GothamMedium
userDisplay.Parent = innerPanel

local userCorner = Instance.new("UICorner")
userCorner.CornerRadius = UDim.new(0, 6)
userCorner.Parent = userDisplay

local userStroke = Instance.new("UIStroke")
userStroke.Color = Color3.fromRGB(45, 80, 135)
userStroke.Thickness = 1
userStroke.Parent = userDisplay

local verifyBtn = Instance.new("TextButton")
verifyBtn.Size = UDim2.new(0.85, 0, 0, 42)
verifyBtn.Position = UDim2.new(0.075, 0, 0, 135)
verifyBtn.Text = "Verify"
verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyBtn.BackgroundColor3 = Color3.fromRGB(15, 95, 220)
verifyBtn.TextSize, verifyBtn.Font = 15, Enum.Font.GothamBold
verifyBtn.Parent = innerPanel

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = verifyBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Color = Color3.fromRGB(60, 130, 255)
btnStroke.Thickness = 1
btnStroke.Parent = verifyBtn

local popupOverlay = Instance.new("Frame")
popupOverlay.Size = UDim2.new(1, 0, 1, 0)
popupOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
popupOverlay.BackgroundTransparency = 0.6
popupOverlay.Visible = false
popupOverlay.Parent = screenGui

local popupBox = Instance.new("Frame")
popupBox.Size = UDim2.new(0, 280, 0, 100)
popupBox.Position = UDim2.new(0.5, -140, 0.5, -50)
popupBox.BackgroundColor3 = Color3.fromRGB(15, 22, 36)
popupBox.BorderSizePixel = 0
popupBox.Parent = popupOverlay

local popStroke = Instance.new("UIStroke")
popStroke.Color = Color3.fromRGB(45, 80, 135)
popStroke.Thickness = 1.5
popStroke.Parent = popupBox

local popCorner = Instance.new("UICorner")
popCorner.CornerRadius = UDim.new(0, 8)
popCorner.Parent = popupBox

local popText = Instance.new("TextLabel")
popText.Size = UDim2.new(1, 0, 1, 0)
popText.BackgroundTransparency = 1
popText.Text = "USERNAME MISMATCHED"
popText.TextColor3 = Color3.fromRGB(235, 85, 85)
popText.TextSize = 15
popText.Font = Enum.Font.GothamBold
popText.Parent = popupBox

local function triggerPopup(messageText, isSuccess)
    popText.Text = messageText
    if isSuccess then
        popText.TextColor3 = Color3.fromRGB(75, 215, 115)
    else
        popText.TextColor3 = Color3.fromRGB(235, 85, 85)
    end
    popupOverlay.Visible = true

    task.delay(2, function()
        popupOverlay.Visible = false
    end)
end

-- KEYS HERE 
local validKeys = {
    ["ADMIN1"] = "Codenameq94",
    ["ADMIN2"] = "robloxthat01",
    ["ADMIN3"] = "robloxthatzero",
    ["ADMIN4"] = "Robloxthatzero1",
    ["4mP9qR2xL7nT1yK"] = "stashlyseeds1",
    ["7hF2wQ8kJ3dN6bX"] = "stashlyseeds2",
    ["9pL1vC4zH5mR8fY"] = "stashlyseeds3",
    ["2kX6nB9sD3tW1jQ"] = "stashlyseeds4",
    ["5cV8mZ2xP7fY4hK"] = "stashlyseeds5",
    ["1jN3bV6cX9lQ2wR"] = "stashlyseeds6",
    ["8tH5kL1zM4pR7dF"] = "stashlyseeds7",
    ["3wY7jX2cN6vB9sP"] = "stashlyseeds8",
    ["6qM4fR8tD1hK3zJ"] = "stashlyseeds9",
    ["0sX2vN5bL7mQ9wK"] = "stashlyseeds10",
    ["4pC1zH3xR6fY8tD"] = "stashlyseeds11",
    ["7jB9mL2kW4vQ6nP"] = "stashlyseeds12",
    ["2hF5dX8cM1tZ3sJ"] = "stashlyseeds13",
    ["9qW3vL6pR8fY1xK"] = "stashlyseeds14",
    ["1mX7nB4zD2hQ5wJ"] = "stashlyseeds15",
    ["6kC2sH9xL3tP8fR"] = "stashlyseeds16",
    ["5jV8zM1qW4fY7dX"] = "stashlyseeds17",
    ["3pL6bN2cR9mK1wT"] = "stashlyseeds18",
    ["8hX4vF7jD1sQ3zM"] = "stashlyseeds19",
    ["0wY1zC5xL8pR2nK"] = "stashlyseeds20",
    ["4mB9qH3tM6fV7jP"] = "stashlyseeds21",
    ["7sN2dL8cX1wK4zQ"] = "stashlyseeds22",
    ["2pK5xV1mR3fY9hJ"] = "stashlyseeds23",
    ["9jW6bC4zL7tQ8wX"] = "stashlyseeds24",
    ["1hF3nL8pR2mK5dD"] = "stashlyseeds25",
    ["6tX9zM2qW5fY1vK"] = "stashlyseeds26",
    ["4qC7vB1xH3sP6jR"] = "stashlyseeds27",
    ["8pL2zN5dL8mQ9wT"] = "stashlyseeds28",
    ["3jK6xH9cR1fY4tM"] = "stashlyseeds29",
    ["5wV1mB3qW7pK8zJ"] = "stashlyseeds30",
    ["2sN4dL7xL2hQ9vX"] = "user31",
    ["7hX8vF1zM5pR3jK"] = "user32",
    ["0mY3bC6cX9tW2sP"] = "user33",
    ["4pK9qL2wR4fY1hD"] = "user34",
    ["8jN5zM1dL7sQ6vX"] = "user35",
    ["1wX3vH8xK2mP9tJ"] = "user36",
    ["6qC2bN5zR1fY4wK"] = "user37",
    ["3tL7xM4qW8hK2sP"] = "user38",
    ["9pS1dL6cX3vQ5jR"] = "user39",
    ["2hV8zC9xL1mP4tK"] = "user40",
    ["5mB3qH2tR7fY6wJ"] = "user41",
    ["7kX1nL5zD3sQ8vX"] = "user42",
    ["0jC6vB8xR2mK1wP"] = "user43",
    ["4wN2zM9dL4fY7hT"] = "user44",
    ["8pL5xH3qW1sQ6jK"] = "user45",
    ["3sK1bN7cX8mP2vX"] = "user46",
    ["6hX4vM2zR9fY5wJ"] = "user47",
    ["1qC8dL6xL3tQ7sP"] = "user48",
    ["9jV2zH1qW5pK4hK"] = "user49",
    ["2mN7bC3xR8mP1wT"] = "user50",
    ["5pL4xV9dL2sQ6zJ"] = "user51",
    ["7tX6zM1qW3fY8hK"] = "user52",
    ["0hC3nL5cX7tP2sP"] = "user53",
    ["4qS8vB2zR1mK9wX"] = "user54",
    ["8jK1xH6dL4fY3tJ"] = "user55",
    ["3wN5zM7qW2sQ8vK"] = "user56",
    ["6pL9bN4xR5mP1jP"] = "user57",
    ["1hX2vC8cX3tQ7sT"] = "user58",
    ["9mC5zH1qW6pK2wX"] = "user59",
    ["2sV3dL9xL8mP4jK"] = "user60",
    ["7pX7zM2pR1fY5hJ"] = "user61",
    ["0qL4bN6cX2tQ9wK"] = "user62",
    ["4jK8vH3zR5mP1sP"] = "user63",
    ["8wN1zM7dL3fY6tX"] = "user64",
    ["3sS6xV2qW9sQ4jK"] = "user65",
    ["5hX9bC5xL1mP8wJ"] = "user66",
    ["1pC2dL4zR7fY3hT"] = "user67",
    ["6jV3zH8qW2pK9sP"] = "user68",
    ["9wN7bN1cX4mP5vX"] = "user69",
    ["2tL5xV6dL6sQ1zK"] = "user70",
    ["7hX1zM9xR3fY8wJ"] = "user71",
    ["0qC8bC2qW5tQ4jP"] = "user72",
    ["4pS4dL7zR8mP6hT"] = "user73",
    ["8jK3vH1xL2sQ9vK"] = "user74",
    ["3mN6zM5dL1fY7wX"] = "user75",
    ["6sL2bN8qW9mP3jK"] = "user76",
    ["1hX7xV4cX4sQ2sP"] = "user77",
    ["9qC1zH9rR7fY5hJ"] = "user78",
    ["2jV5dL3zL6mP1wK"] = "user79",
    ["5wN8bN6qW1sQ4jT"] = "user80",
    ["7pL3xV2xR3fY8vX"] = "user81",
    ["0hX6zM7dL8mP9wJ"] = "user82",
    ["4qC9bC1qW2sQ5sP"] = "user83",
    ["8jK2dL4zR4fY7hK"] = "user84",
    ["3sS5vH8xL5sQ1vT"] = "user85",
    ["6mN1zM2dL9mP6wX"] = "user86",
    ["1pL7bN9qW6sQ3jP"] = "user87",
    ["9hX4xV3cX7fY2sJ"] = "user88",
    ["2qC6zH8rR1mP8wK"] = "user89",
    ["5jV3dL1zL3sQ4hK"] = "user90",
    ["7wN9bN5qW8mP9vT"] = "user91",
    ["0pL2xV7xR2fY1jP"] = "user92",
    ["4hX8zM4dL5sQ6wJ"] = "user93",
    ["8qC1bC9qW4sQ7sP"] = "user94",
    ["3jK5dL2zR6fY2hK"] = "user95",
    ["6sS7vH6xL9sQ3vT"] = "user96",
    ["1mN4zM3dL7mP5wX"] = "user97",
    ["5aB39xK92mQ1wZ8"] = "user98",
    ["9xK92mQ1wZ8v4mP"] = "user99",
    ["2mQ1wZ8v4mP9qR2"] = "user100",
    ["3xK92mQ1wZ8v4mP"] = "user101",
    ["8qR2xL7nT1yK4mP"] = "user102",
    ["1wQ8kJ3dN6bX7hF"] = "user103",
    ["6zH5mR8fY9pL1vC"] = "user104",
    ["2sD3tW1jQ2kX6nB"] = "user105",
    ["9xP7fY4hK5cV8mZ"] = "user106",
    ["4cX9lQ2wR1jN3bV"] = "user107",
    ["7zM4pR7dF8tH5kL"] = "user108",
    ["3cN6vB9sP3wY7jX"] = "user109",
    ["8tD1hK3zJ6qM4fR"] = "user110",
    ["1bL7mQ9wK0sX2vN"] = "user111",
    ["5xR6fY8tD4pC1zH"] = "user112",
    ["0kW4vQ6nP7jB9mL"] = "user113",
    ["6cM1tZ3sJ2hF5dX"] = "user114",
    ["9pR8fY1xK9qW3vL"] = "user115",
    ["2zD2hQ5wJ1mX7nB"] = "user116",
    ["7xL3tP8fR6kC2sH"] = "user117",
    ["1qW4fY7dX5jV8zM"] = "user118",
    ["4cR9mK1wT3pL6bN"] = "user119",
    ["8jD1sQ3zM8hX4vF"] = "user120",
    ["0xL8pR2nK0wY1zC"] = "user121",
    ["3tM6fV7jP4mB9qH3"] = "user122",
    ["7cX1wK4zQ7sN2dL"] = "user123",
    ["2mR3fY9hJ2pK5xV1"] = "user124",
    ["6zL7tQ8wX9jW6bC"] = "user125",
    ["1pR2mK5dD1hF3nL"] = "user126",
    ["5qW5fY1vK6tX9zM2"] = "user127",
    ["0xH3sP6jR4qC7vB1"] = "user128",
    ["5dL8mQ9wT8pL2zN5"] = "user129",
    ["3cR1fY4tM3jK6xH9"] = "user130",
    ["7qW7pK8zJ5wV1mB3"] = "user131",
    ["2xL2hQ9vX2sN4dL7"] = "user132",
    ["6zM5pR3jK7hX8vF1"] = "user133",
    ["0cX9tW2sP0mY3bC6"] = "user134",
    ["4wR4fY1hD4pK9qL2"] = "user135",
    ["9dL7sQ6vX8jN5zM1"] = "user136",
    ["2xK2mP9tJ1wX3vH8"] = "user137",
    ["7zR1fY4wK6qC2bN5"] = "user138",
    ["1qW8hK2sP3tL7xM4"] = "user139",
    ["5cX3vQ5jR9pS1dL6"] = "user140",
    ["0xL1mP4tK2hV8zC9"] = "user141",
    ["4tR7fY6wJ5mB3qH2"] = "user142",
    ["8zD3sQ8vX7kX1nL5"] = "user143",
    ["2xR2mK1wP0jC6vB8"] = "user144",
    ["6dL4fY7hT4wN2zM9"] = "user145",
    ["1qW1sQ6jK8pL5xH3"] = "user146",
    ["5cX8mP2vX3sK1bN7"] = "user147",
    ["0zR9fY5wJ6hX4vM2"] = "user148",
    ["4xL3tQ7sP1qC8dL6"] = "user149",
    ["8qW5pK4hK9jV2zH1"] = "user150",
    ["3xR8mP1wT2mN7bC3"] = "user151",
    ["7dL2sQ6zJ5pL4xV9"] = "user152",
    ["1qW3fY8hK7tX6zM1"] = "user153",
    ["5cX7tP2sP0hC3nL5"] = "user154",
    ["0zR1mK9wX4qS8vB2"] = "user155",
    ["4dL4fY3tJ8jK1xH6"] = "user156",
    ["8qW2sQ8vK3wN5zM7"] = "user157",
    ["2xR5mP1jP6pL9bN4"] = "user158",
    ["6cX3tQ7sT1hX2vC8"] = "user159",
    ["1qW6pK2wX9mC5zH1"] = "user160",
    ["5xL8mP4jK2sV3dL9"] = "user161",
    ["0pR1fY5hJ7pX7zM2"] = "user162",
    ["4cX2tQ9wK0qL4bN6"] = "user163",
    ["8zR5mP1sP4jK8vH3"] = "user164",
    ["3dL3fY6tX8wN1zM7"] = "user165",
    ["7qW9sQ4jK3sS6xV2"] = "user166",
    ["1xL1mP8wJ5hX9bC5"] = "user167",
    ["6zR7fY3hT1pC2dL4"] = "user168",
    ["2qW2pK9sP6jV3zH8"] = "user169",
    ["9cX4mP5vX9wN7bN1"] = "user170",
    ["4dL6sQ1zK2tL5xV6"] = "user171",
    ["8xR3fY8wJ7hX1zM9"] = "user172",
    ["3qW5tQ4jP0qC8bC2"] = "user173",
    ["7zR8mP6hT4pS4dL7"] = "user174",
    ["1xL2sQ9vK8jK3vH1"] = "user175",
    ["5dL1fY7wX3mN6zM5"] = "user176",
    ["0qW9mP3jK6sL2bN8"] = "user177",
    ["4cX4sQ2sP1hX7xV4"] = "user178",
    ["8zR7fY5hJ9qC1zH9"] = "user179",
    ["2zL6mP1wK2jV5dL3"] = "user180",
    ["6qW1sQ4jT5wN8bN6"] = "user181",
    ["1xR3fY8vX7pL3xV2"] = "user182",
    ["5dL8mP9wJ0hX6zM7"] = "user183",
    ["0qW2sQ5sP4qC9bC1"] = "user184",
    ["4zR4fY7hK8jK2dL4"] = "user185",
    ["8xL5sQ1vT3sS5vH8"] = "user186",
    ["3dL9mP6wX6mN1zM2"] = "user187",
    ["7qW6sQ3jP1pL7bN9"] = "user188",
    ["1cX7fY2sJ9hX4xV3"] = "user189",
    ["6rR1mP8wK2qC6zH8"] = "user190",
    ["2zL3sQ4hK5jV3dL1s"] = "user191",
    ["5qW8mP9vT7wN9bN5"] = "user192",
    ["9xR2fY1jP0pL2xV7"] = "user193",
    ["4dL5sQ6wJ4hX8zM4"] = "user194",
    ["8qW4sQ7sP8qC1bC9"] = "user195",
    ["3zR6fY2hK3jK5dL2"] = "user196",
    ["7xL9sQ3vT6sS7vH6"] = "user197",
    ["1dL7mP5wX1mN4zM3"] = "user198",
    ["5qW6sQ2sP5aB39xK9"] = "user199",
    ["9cX7fY5hJ9xK92mQ1"] = "user200",
    ["2rR1mP8wK2mQ1wZ8"] = "user201",
    ["6zL3sQ4hK4mP9qR2"] = "user202",
    ["1qW8mP9vT7hF2wQ8"] = "user203",
    ["5xR2fY1jP9pL1vC4"] = "user204",
    ["0dL5sQ6wJ2kX6nB9"] = "user205",
    ["4qW4sQ7sP5cV8mZ2"] = "user206",
    ["8zR6fY2hK1jN3bV6"] = "user207",
    ["3xL9sQ3vT8tH5kL1"] = "user208",
    ["7dL7mP5wX3wY7jX2"] = "user209",
    ["1qW6sQ2sP6qM4fR8"] = "user210",
    ["5cX7fY5hJ0sX2vN5b"] = "user211",
    ["0rR1mP8wK4pC1zH3"] = "user212",
    ["4zL3sQ4hK7jB9mL2"] = "user213",
    ["8qW8mP9vT2hF5dX8"] = "user214",
    ["3xR2fY1jP9qW3vL6"] = "user215",
    ["7dL5sQ6wJ1mX7nB4"] = "user216",
    ["1qW4sQ7sP6kC2sH9"] = "user217",
    ["5zR6fY2hK5jV8zM1"] = "user218",
    ["9xL9sQ3vT3pL6bN2"] = "user219",
    ["2dL7mP5wX8hX4vF7"] = "user220",
    ["6qW6sQ2sP0wY1zC5"] = "user221",
    ["1cX7fY5hJ4mB9qH3"] = "user222",
    ["5rR1mP8wK7sN2dL8"] = "user223",
    ["0zL3sQ4hK2pK5xV1"] = "user224",
    ["4qW8mP9vT9jW6bC4"] = "user225",
    ["8xR2fY1jP1hF3nL8"] = "user226",
    ["3dL5sQ6wJ6tX9zM2"] = "user227",
    ["7qW4sQ7sP4qC7vB1"] = "user228",
    ["1zR6fY2hK8pL2zN5"] = "user229",
    ["5xL9sQ3vT3jK6xH9"] = "user230",
    ["9dL7mP5wX5wV1mB3"] = "user231",
    ["2qW6sQ2sP2sN4dL7"] = "user232",
    ["6cX7fY5hJ7hX8vF1"] = "user233",
    ["1rR1mP8wK0mY3bC6"] = "user234",
    ["5zL3sQ4hK4pK9qL2"] = "user235",
    ["0qW8mP9vT8jN5zM1"] = "user236",
    ["4xR2fY1jP1wX3vH8"] = "user237",
    ["8dL5sQ6wJ6qC2bN5"] = "user238",
    ["3qW4sQ7sP3tL7xM4"] = "user239",
    ["7zR6fY2hK9pS1dL6"] = "user240",
    ["1xL9sQ3vT2hV8zC9"] = "user241",
    ["5dL7mP5wX5mB3qH2"] = "user242",
    ["9qW6sQ2sP7kX1nL5"] = "user243",
    ["2cX7fY5hJ0jC6vB8"] = "user244",
    ["6rR1mP8wK4wN2zM9"] = "user245",
    ["1zL3sQ4hK8pL5xH3"] = "user246",
    ["5qW8mP9vT3sK1bN7"] = "user247",
    ["0xR2fY1jP6hX4vM2"] = "user248",
    ["4dL5sQ6wJ1qC8dL6"] = "user249",
    ["8qW4sQ7sP9jV2zH1"] = "user250",
    ["3zR6fY2hK2mN7bC3"] = "user251",
    ["7xL9sQ3vT5pL4xV9"] = "user252",
    ["1dL7mP5wX7tX6zM1"] = "user253",
    ["5qW6sQ2sP0hC3nL5"] = "user254",
    ["9cX7fY5hJ4qS8vB2"] = "user255",
    ["2rR1mP8wK8jK1xH6"] = "user256",
    ["6zL3sQ4hK3wN5zM7"] = "user257",
    ["1qW8mP9vT6pL9bN4"] = "user258",
    ["5xR2fY1jP1hX2vC8"] = "user259",
    ["0dL5sQ6wJ9mC5zH1"] = "user260",
    ["4qW4sQ7sP2sV3dL9"] = "user261",
    ["8zR6fY2hK7pX7zM2"] = "user262",
    ["3xL9sQ3vT0qL4bN6"] = "user263",
    ["7dL7mP5wX4jK8vH3"] = "user264",
    ["1qW6sQ2sP8wN1zM7"] = "user265",
    ["5cX7fY5hJ3sS6xV2"] = "user266",
    ["0rR1mP8wK5hX9bC5"] = "user267",
    ["4zL3sQ4hK1pC2dL4"] = "user268",
    ["8qW8mP9vT6jV3zH8"] = "user269",
    ["3xR2fY1jP9wN7bN1"] = "user270",
    ["7dL5sQ6wJ2tL5xV6"] = "user271",
    ["1qW4sQ7sP7hX1zM9"] = "user272",
    ["5zR6fY2hK0qC8bC2"] = "user273",
    ["9xL9sQ3vT4pS4dL7"] = "user274",
    ["2dL7mP5wX8jK3vH1"] = "user275",
    ["6qW6sQ2sP3mN6zM5"] = "user276",
    ["1cX7fY5hJ6sL2bN8"] = "user277",
    ["5rR1mP8wK1hX7xV4"] = "user278",
    ["0zL3sQ4hK9qC1zH9"] = "user279",
    ["4qW8mP9vT2jV5dL3"] = "user280",
    ["8xR2fY1jP5wN8bN6"] = "user281",
    ["3dL5sQ6wJ7pL3xV2"] = "user282",
    ["7qW4sQ7sP0hX6zM7"] = "user283",
    ["1zR6fY2hK4qC9bC1"] = "user284",
    ["5xL9sQ3vT8jK2dL4"] = "user285",
    ["9dL7mP5wX3sS5vH8"] = "user286",
    ["2qW6sQ2sP6mN1zM2"] = "user287",
    ["6cX7fY5hJ1pL7bN9"] = "user288",
    ["1rR1mP8wK9hX4xV3"] = "user289",
    ["5zL3sQ4hK2qC6zH8"] = "user290",
    ["0qW8mP9vT5jV3dL1"] = "user291",
    ["4xR2fY1jP7wN9bN5"] = "user292",
    ["8dL5sQ6wJ0pL2xV7"] = "user293",
    ["3qW4sQ7sP4hX8zM4"] = "user294",
    ["7zR6fY2hK8qC1bC9"] = "user295",
    ["1xL9sQ3vT3jK5dL2"] = "user296",
    ["5dL7mP5wX6sS7vH6"] = "user297",
    ["9qW6sQ2sP1mN4zM3"] = "user298",
    ["2cX7fY5hJ5aB39xK9"] = "user299",
    ["6rR1mP8wK9xK92mQ1"] = "user300",
}

verifyBtn.MouseButton1Click:Connect(function()
    if not isSystemActive then
        player:Kick("System offline.")
        return
    end

    keyBox:ReleaseFocus()

    local enteredKey = tostring(keyBox.Text):match("^%s*(.-)%s*$")
    local actualUsername = player.Name:lower()

    if enteredKey == "" then
        triggerPopup("Please enter a key!", false)
        return
    end

    if validKeys[enteredKey] then
        local whitelistedUser = validKeys[enteredKey]:lower()

        if whitelistedUser == actualUsername then
            triggerPopup("Access Granted!\nWelcome, " .. player.Name, true)
            
            task.delay(2, function()
                screenGui:Destroy()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/mgsmmm/hennessy/refs/heads/main/m.lua"))()
            end)
        else
            triggerPopup("USERNAME MISMATCHED", false)
        end
    else
        triggerPopup("Invalid Key!", false)
    end
end)
