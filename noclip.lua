
-- NOCLIP TOGGLE | standalone client script
-- Walk through collidable parts when ON; restore collisions when OFF.
-- Use as a LocalScript in StarterPlayerScripts or via an executor.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G

if type(env.NoclipToggleCleanup) == "function" then
    pcall(env.NoclipToggleCleanup)
end

local enabled = false
local original = {}
local connections = {}

local gui = Instance.new("ScreenGui")
gui.Name = "ReliableNoclipToggle"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(145, 47)
button.Position = UDim2.new(0, 12, 0.37, 0)
button.BackgroundColor3 = Color3.fromRGB(47, 38, 53)
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "NOCLIP: OFF"
button.Parent = gui
Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)

local function restore()
    for part, wasCollidable in pairs(original) do
        if part and part.Parent then
            pcall(function() part.CanCollide = wasCollidable end)
        end
    end
    table.clear(original)
end

local function setEnabled(value)
    if enabled == value then return end
    enabled = value
    if not enabled then restore() end
    button.Text = enabled and "NOCLIP: ON" or "NOCLIP: OFF"
    button.BackgroundColor3 = enabled
        and Color3.fromRGB(28, 124, 73)
        or Color3.fromRGB(47, 38, 53)
end

connections[#connections + 1] = button.Activated:Connect(function()
    setEnabled(not enabled)
end)

-- Stepped executes before the physics step so collisions stay disabled.
connections[#connections + 1] = RunService.Stepped:Connect(function()
    if not enabled then return end
    local character = player.Character
    if not character then return end
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("BasePart") then
            if original[object] == nil then
                original[object] = object.CanCollide
            end
            if object.CanCollide then object.CanCollide = false end
        end
    end
end)

connections[#connections + 1] = player.CharacterRemoving:Connect(function()
    restore()
end)

env.NoclipToggleCleanup = function()
    setEnabled(false)
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    env.NoclipToggleCleanup = nil
end

print("NOCLIP TOGGLE LOADED: press the button to turn ON or OFF")
