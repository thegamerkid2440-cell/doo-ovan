
-- FLY TOGGLE | standalone client script
-- Use as a LocalScript in StarterPlayerScripts or via an executor.
-- Press FLY ON/OFF; hold UP/DOWN on mobile. Space/Ctrl on PC.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local env = (getgenv and getgenv()) or _G
if type(env.FlyToggleCleanup) == "function" then
    pcall(env.FlyToggleCleanup)
end

local SPEED = 48
local VERTICAL_SPEED = 40
local connections = {}
local flying = false
local goingUp, goingDown = false, false
local attachment, mover, root, humanoid
local priorAutoRotate = true
local controls

pcall(function()
    local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
    if module then controls = require(module):GetControls() end
end)

local function on(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local gui = Instance.new("ScreenGui")
gui.Name = "ReliableFlyToggle"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function makeButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.fromOffset(126, 43)
    button.Position = UDim2.new(1, -138, 0.37, y)
    button.BackgroundColor3 = Color3.fromRGB(27, 35, 48)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.Text = text
    button.Parent = gui
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
    return button
end

local toggle = makeButton("FLY: OFF", 0)
local upButton = makeButton("HOLD: UP", 50)
local downButton = makeButton("HOLD: DOWN", 100)

local function stopFly()
    if not flying then return end
    flying = false
    goingUp, goingDown = false, false
    if mover then mover:Destroy(); mover = nil end
    if attachment then attachment:Destroy(); attachment = nil end
    if humanoid and humanoid.Parent then
        humanoid.AutoRotate = priorAutoRotate
        if humanoid.Health > 0 then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    toggle.Text = "FLY: OFF"
    toggle.BackgroundColor3 = Color3.fromRGB(27, 35, 48)
end

local function startFly()
    local character = player.Character
    root = character and character:FindFirstChild("HumanoidRootPart")
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then
        toggle.Text = "WAIT FOR SPAWN"
        return
    end

    priorAutoRotate = humanoid.AutoRotate
    humanoid.AutoRotate = false
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)

    attachment = Instance.new("Attachment")
    attachment.Name = "FlyAttachment"
    attachment.Parent = root

    mover = Instance.new("LinearVelocity")
    mover.Name = "FlyVelocity"
    mover.Attachment0 = attachment
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    mover.ForceLimitsEnabled = false
    mover.VectorVelocity = Vector3.zero
    mover.Parent = root

    flying = true
    toggle.Text = "FLY: ON"
    toggle.BackgroundColor3 = Color3.fromRGB(26, 125, 73)
end

on(toggle.Activated, function()
    if flying then stopFly() else startFly() end
end)

local function bindHold(button, setter)
    on(button.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setter(true)
        end
    end)
    on(button.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setter(false)
        end
    end)
end

bindHold(upButton, function(value) goingUp = value end)
bindHold(downButton, function(value) goingDown = value end)

local heldSpace, heldCtrl = false, false
on(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Space then heldSpace = true end
    if input.KeyCode == Enum.KeyCode.LeftControl then heldCtrl = true end
end)
on(UserInputService.InputEnded, function(input)
    if input.KeyCode == Enum.KeyCode.Space then heldSpace = false end
    if input.KeyCode == Enum.KeyCode.LeftControl then heldCtrl = false end
end)

on(RunService.Heartbeat, function(dt)
    if not flying then return end
    if not root or not root.Parent or not humanoid or humanoid.Health <= 0 then
        stopFly()
        return
    end

    local camera = workspace.CurrentCamera
    if not camera then return end
    local move = Vector3.zero
    local stick
    if controls then
        local ok, value = pcall(function() return controls:GetMoveVector() end)
        if ok then stick = value end
    end
    if stick then
        move = camera.CFrame.RightVector * stick.X
            - camera.CFrame.LookVector * stick.Z
    else
        move = humanoid.MoveDirection
    end
    if move.Magnitude > 1 then move = move.Unit end

    local vertical = ((goingUp or heldSpace) and 1 or 0)
        - ((goingDown or heldCtrl) and 1 or 0)
    local target = move * SPEED + Vector3.yAxis * (vertical * VERTICAL_SPEED)
    mover.VectorVelocity = mover.VectorVelocity:Lerp(target, math.clamp(dt * 12, 0, 1))
end)

on(player.CharacterRemoving, stopFly)

env.FlyToggleCleanup = function()
    stopFly()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    gui:Destroy()
    env.FlyToggleCleanup = nil
end

print("FLY TOGGLE LOADED: FLY ON/OFF; hold UP or DOWN")
