local WallhackModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Public Variables
WallhackModule.DrawLibEnabled = false
WallhackModule.ShowHP = false
WallhackModule.ShowDistance = false
WallhackModule.ShowWeapon = false
WallhackModule.ShowTracers = false
WallhackModule.ShowName = false
WallhackModule.Show2DBoxes = false
WallhackModule.Show3DBoxes = false
WallhackModule.HideDeadPlayers = true

WallhackModule.HighlightEnabled = false
WallhackModule.FillColor = Color3.fromRGB(255, 0, 0)
WallhackModule.FillTransparency = 0.5
WallhackModule.OutlineColor = Color3.fromRGB(255, 255, 255)
WallhackModule.OutlineTransparency = 0
WallhackModule.TeamCheck = false
WallhackModule.AutoTeamColor = false
WallhackModule.ComfortMode = false

-- Storage
local DrawingObjects = {}
local HighlightObjects = {}
local CachedPlayers = {}

-- Utility Functions
local function GetDistanceFromCamera(position)
    return (Camera.CFrame.Position - position).Magnitude
end

local function IsAlive(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    return character and humanoid and humanoid.Health > 0
end

local function GetCharacterHealth(character)
    local humanoid = character:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health or 0
end

local function GetPlayerWeapon(character)
    local tool = character:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
end

local function IsPointVisible(point)
    local ray = Ray.new(Camera.CFrame.Position, (point - Camera.CFrame.Position).Unit * 1000)
    local hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, {Camera, LocalPlayer.Character})
    
    if not hit then return true end
    
    local distance = (Camera.CFrame.Position - point).Magnitude
    local hitDistance = (Camera.CFrame.Position - position).Magnitude
    
    return hitDistance > distance
end

local function GetBoxBounds(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local cframe = hrp.CFrame
    local size = character:GetExtentsSize()
    
    local front = cframe.LookVector * (size.Z/2)
    local right = cframe.RightVector * (size.X/2)
    local up = cframe.UpVector * (size.Y/2)
    local pos = cframe.Position
    
    local points = {
        FrontTopLeft = pos + front + up - right,
        FrontTopRight = pos + front + up + right,
        FrontBottomLeft = pos + front - up - right,
        FrontBottomRight = pos + front - up + right,
        BackTopLeft = pos - front + up - right,
        BackTopRight = pos - front + up + right,
        BackBottomLeft = pos - front - up - right,
        BackBottomRight = pos - front - up + right
    }
    
    return points
end

local function CreateDrawingObject(type, properties)
    local object = Drawing.new(type)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

local function CreateESPForPlayer(player)
    if DrawingObjects[player] then return end
    
    local espObjects = {
        Box2D = CreateDrawingObject("Square", {
            Thickness = 1,
            Filled = false,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Visible = false
        }),
        Box3D = {
            Lines = {}
        },
        Name = CreateDrawingObject("Text", {
            Size = 13,
            Center = true,
            Outline = true,
            Color = Color3.new(1, 1, 1),
            Visible = false
        }),
        Health = CreateDrawingObject("Text", {
            Size = 13,
            Center = true,
            Outline = true,
            Color = Color3.new(0, 1, 0),
            Visible = false
        }),
        Distance = CreateDrawingObject("Text", {
            Size = 13,
            Center = true,
            Outline = true,
            Color = Color3.new(1, 1, 1),
            Visible = false
        }),
        Weapon = CreateDrawingObject("Text", {
            Size = 13,
            Center = true,
            Outline = true,
            Color = Color3.new(1, 1, 0),
            Visible = false
        }),
        Tracer = CreateDrawingObject("Line", {
            Thickness = 1,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Visible = false
        })
    }
    
    for i = 1, 12 do
        espObjects.Box3D.Lines[i] = CreateDrawingObject("Line", {
            Thickness = 1,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Visible = false
        })
    end
    
    DrawingObjects[player] = espObjects
end

local function HideESP(objects)
    if not objects then return end
    
    for _, object in pairs(objects) do
        if typeof(object) == "table" then
            if object.Lines then
                for _, line in pairs(object.Lines) do
                    line.Visible = false
                end
            else
                for _, subObject in pairs(object) do
                    subObject.Visible = false
                end
            end
        else
            object.Visible = false
        end
    end
end

local function Update2DBox(player, objects, screenPos, bounds)
    if not WallhackModule.Show2DBoxes then
        objects.Box2D.Visible = false
        return
    end
    
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local anyVisible = false
    
    for _, point in pairs(bounds) do
        local pointScreen = Camera:WorldToViewportPoint(point)
        if pointScreen.Z > 0 then
            if IsPointVisible(point) then
                anyVisible = true
            end
            minX = math.min(minX, pointScreen.X)
            minY = math.min(minY, pointScreen.Y)
            maxX = math.max(maxX, pointScreen.X)
            maxY = math.max(maxY, pointScreen.Y)
        end
    end
    
    objects.Box2D.Position = Vector2.new(minX, minY)
    objects.Box2D.Size = Vector2.new(maxX - minX, maxY - minY)
    objects.Box2D.Visible = anyVisible
end

local function Update3DBox(player, objects, bounds)
    if not WallhackModule.Show3DBoxes then
        for _, line in pairs(objects.Box3D.Lines) do
            line.Visible = false
        end
        return
    end
    
    local connections = {
        {bounds.FrontTopLeft, bounds.FrontTopRight},
        {bounds.FrontTopRight, bounds.FrontBottomRight},
        {bounds.FrontBottomRight, bounds.FrontBottomLeft},
        {bounds.FrontBottomLeft, bounds.FrontTopLeft},
        {bounds.BackTopLeft, bounds.BackTopRight},
        {bounds.BackTopRight, bounds.BackBottomRight},
        {bounds.BackBottomRight, bounds.BackBottomLeft},
        {bounds.BackBottomLeft, bounds.BackTopLeft},
        {bounds.FrontTopLeft, bounds.BackTopLeft},
        {bounds.FrontTopRight, bounds.BackTopRight},
        {bounds.FrontBottomRight, bounds.BackBottomRight},
        {bounds.FrontBottomLeft, bounds.BackBottomLeft}
    }
    
    for i, connection in ipairs(connections) do
        local p1, p2 = connection[1], connection[2]
        local p1Screen = Camera:WorldToViewportPoint(p1)
        local p2Screen = Camera:WorldToViewportPoint(p2)
        
        if p1Screen.Z > 0 and p2Screen.Z > 0 and (IsPointVisible(p1) or IsPointVisible(p2)) then
            objects.Box3D.Lines[i].From = Vector2.new(p1Screen.X, p1Screen.Y)
            objects.Box3D.Lines[i].To = Vector2.new(p2Screen.X, p2Screen.Y)
            objects.Box3D.Lines[i].Visible = true
        else
            objects.Box3D.Lines[i].Visible = false
        end
    end
end

local function UpdateESP()
    for player, objects in pairs(DrawingObjects) do
        if player ~= LocalPlayer and player.Character then
            local isAlive = IsAlive(player)
            if not isAlive and WallhackModule.HideDeadPlayers then
                HideESP(objects)
                continue
            end
            
            if WallhackModule.DrawLibEnabled then
                local character = player.Character
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                
                if humanoidRootPart then
                    local bounds = GetBoxBounds(character)
                    if not bounds then 
                        HideESP(objects)
                        continue 
                    end
                    
                    local screenPos, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                    local isVisible = IsPointVisible(humanoidRootPart.Position)
                    
                    if onScreen then
                        Update2DBox(player, objects, screenPos, bounds)
                        Update3DBox(player, objects, bounds)
                        
                        if WallhackModule.ShowName and isVisible then
                            objects.Name.Text = player.Name
                            objects.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                            objects.Name.Visible = true
                        else
                            objects.Name.Visible = false
                        end
                        
                        if WallhackModule.ShowHP and isVisible then
                            local health = GetCharacterHealth(character)
                            objects.Health.Text = string.format("HP: %d", health)
                            objects.Health.Position = Vector2.new(screenPos.X, screenPos.Y - 25)
                            objects.Health.Color = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
                            objects.Health.Visible = true
                        else
                            objects.Health.Visible = false
                        end
                        
                        if WallhackModule.ShowDistance and isVisible then
                            local distance = math.floor(GetDistanceFromCamera(humanoidRootPart.Position))
                            objects.Distance.Text = string.format("%dm", distance)
                            objects.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 25)
                            objects.Distance.Visible = true
                        else
                            objects.Distance.Visible = false
                        end
                        
                        if WallhackModule.ShowWeapon and isVisible then
                            local weapon = GetPlayerWeapon(character)
                            objects.Weapon.Text = weapon
                            objects.Weapon.Position = Vector2.new(screenPos.X, screenPos.Y + 40)
                            objects.Weapon.Visible = true
                        else
                            objects.Weapon.Visible = false
                        end
                        
                        if WallhackModule.ShowTracers and isVisible then
                            objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                            objects.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            objects.Tracer.Visible = true
                        else
                            objects.Tracer.Visible = false
                        end
                    else
                        HideESP(objects)
                    end
                else
                    HideESP(objects)
                end
            else
                HideESP(objects)
            end
        end
    end
end

local function CreateHighlight(player)
    if not player.Character then return end
    
    if not HighlightObjects[player] then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = WallhackModule.FillColor
        highlight.FillTransparency = WallhackModule.FillTransparency
        highlight.OutlineColor = WallhackModule.OutlineColor
        highlight.OutlineTransparency = WallhackModule.OutlineTransparency
        highlight.Parent = player.Character
        HighlightObjects[player] = highlight
    end
    
    return HighlightObjects[player]
end

local function UpdateHighlight(player)
    local highlight = HighlightObjects[player]
    if not highlight then return end
    
    if WallhackModule.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
        highlight.FillTransparency = 1
        highlight.OutlineTransparency = 1
    elseif WallhackModule.AutoTeamColor and player.Team then
        highlight.FillColor = player.TeamColor.Color
        highlight.OutlineColor = player.TeamColor.Color
        highlight.FillTransparency = WallhackModule.FillTransparency
        highlight.OutlineTransparency = WallhackModule.OutlineTransparency
    else
        highlight.FillColor = WallhackModule.FillColor
        highlight.OutlineColor = WallhackModule.OutlineColor
        highlight.FillTransparency = WallhackModule.FillTransparency
        highlight.OutlineTransparency = WallhackModule.OutlineTransparency
    end
end

local function RemoveHighlight(player)
    local highlight = HighlightObjects[player]
    if not highlight then return end
    
    if WallhackModule.ComfortMode then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(highlight, tweenInfo, {
            FillTransparency = 1,
            OutlineTransparency = 1
        })
        tween.Completed:Connect(function()
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            HighlightObjects[player] = nil
        end)
        tween:Play()
    else
        highlight:Destroy()
        HighlightObjects[player] = nil
    end
end

-- Initialize
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPForPlayer(player)
        if WallhackModule.HighlightEnabled then
            CreateHighlight(player)
        end
    end
end

-- Event Connections
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESPForPlayer(player)
        
        player.CharacterAdded:Connect(function(character)
            if WallhackModule.HighlightEnabled then
                CreateHighlight(player)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if DrawingObjects[player] then
        for _, object in pairs(DrawingObjects[player]) do
            if typeof(object) == "table" then
                if object.Lines then
                    for _, line in pairs(object.Lines) do
                        line:Remove()
                    end
                else
                    for _, subObject in pairs(object) do
                        subObject:Remove()
                    end
                end
            else
                object:Remove()
            end
        end
        DrawingObjects[player] = nil
    end
    RemoveHighlight(player)
end)

-- Update Loop
local lastUpdate = 0
local updateInterval = 1/144 -- 144 FPS cap

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= updateInterval then
        lastUpdate = currentTime
        
        if WallhackModule.DrawLibEnabled then
            UpdateESP()
        end
        
        if WallhackModule.HighlightEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    if IsAlive(player) or not WallhackModule.HideDeadPlayers then
                        local highlight = CreateHighlight(player)
                        if highlight then
                            UpdateHighlight(player)
                        end
                    else
                        RemoveHighlight(player)
                    end
                end
            end
        else
            for player in pairs(HighlightObjects) do
                RemoveHighlight(player)
            end
        end
    end
end)

return WallhackModule
