local WallhackModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Public Variables (these will be set from main script)
WallhackModule.DrawLibEnabled = false
WallhackModule.ShowHP = false
WallhackModule.ShowDistance = false
WallhackModule.ShowWeapon = false
WallhackModule.ShowTracers = false
WallhackModule.ShowName = false
WallhackModule.Show2DBoxes = false
WallhackModule.Show3DBoxes = false

WallhackModule.HighlightEnabled = false
WallhackModule.FillColor = Color3.fromRGB(255, 0, 0)
WallhackModule.FillTransparency = 0.5
WallhackModule.OutlineColor = Color3.fromRGB(255, 255, 255)
WallhackModule.OutlineTransparency = 0
WallhackModule.TeamCheck = false
WallhackModule.AutoTeamColor = false
WallhackModule.ComfortMode = false

-- DrawLib Objects Storage
local DrawingObjects = {}

-- Highlight Objects Storage
local HighlightObjects = {}

-- Rest of the utility functions remain the same
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

local function GetBoxCorners(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    local size = character:GetExtentsSize()
    local cf = hrp.CFrame
    
    local corners = {
        topFrontLeft = cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        topFrontRight = cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        topBackLeft = cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
        topBackRight = cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        bottomFrontLeft = cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        bottomFrontRight = cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        bottomBackLeft = cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        bottomBackRight = cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)
    }
    
    return corners
end

-- DrawLib Functions remain the same but use WallhackModule variables
local function CreateDrawingObject(type, properties)
    local object = Drawing.new(type)
    for property, value in pairs(properties) do
        object[property] = value
    end
    return object
end

local function CreateESPForPlayer(player)
    local espObjects = {
        Box2D = CreateDrawingObject("Square", {
            Thickness = 1,
            Filled = false,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Visible = false
        }),
        Box3D = {
            TopLine = CreateDrawingObject("Line", {
                Thickness = 1,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            BottomLine = CreateDrawingObject("Line", {
                Thickness = 1,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            LeftLine = CreateDrawingObject("Line", {
                Thickness = 1,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            }),
            RightLine = CreateDrawingObject("Line", {
                Thickness = 1,
                Transparency = 1,
                Color = Color3.new(1, 1, 1),
                Visible = false
            })
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
    DrawingObjects[player] = espObjects
end

local function Update2DBox(player, objects, vector)
    if not WallhackModule.Show2DBoxes then
        objects.Box2D.Visible = false
        return
    end
    
    local character = player.Character
    if not character then return end
    
    local size = character:GetExtentsSize()
    local scale = 1 / (vector.Z * 0.75) * 1000
    local width = math.floor(size.X * scale)
    local height = math.floor(size.Y * scale)
    
    objects.Box2D.Size = Vector2.new(width, height)
    objects.Box2D.Position = Vector2.new(vector.X - width / 2, vector.Y - height / 2)
    objects.Box2D.Visible = true
end

local function Update3DBox(player, objects, character)
    if not WallhackModule.Show3DBoxes then
        for _, line in pairs(objects.Box3D) do
            line.Visible = false
        end
        return
    end
    
    local corners = GetBoxCorners(character)
    if not corners then return end
    
    for _, corner in pairs(corners) do
        local vector, onScreen = Camera:WorldToViewportPoint(corner.Position)
        if not onScreen then
            for _, line in pairs(objects.Box3D) do
                line.Visible = false
            end
            return
        end
    end
    
    -- 3D box implementation would go here
end

local function UpdateESP()
    for player, objects in pairs(DrawingObjects) do
        if player ~= LocalPlayer and player.Character and IsAlive(player) then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart and WallhackModule.DrawLibEnabled then
                local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                
                if onScreen then
                    Update2DBox(player, objects, vector)
                    Update3DBox(player, objects, character)
                    
                    if WallhackModule.ShowName then
                        objects.Name.Text = player.Name
                        objects.Name.Position = Vector2.new(vector.X, vector.Y - 40)
                        objects.Name.Visible = true
                    else
                        objects.Name.Visible = false
                    end
                    
                    if WallhackModule.ShowHP then
                        local health = GetCharacterHealth(character)
                        objects.Health.Text = string.format("HP: %d", health)
                        objects.Health.Position = Vector2.new(vector.X, vector.Y - 25)
                        objects.Health.Color = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
                        objects.Health.Visible = true
                    else
                        objects.Health.Visible = false
                    end
                    
                    if WallhackModule.ShowDistance then
                        local distance = math.floor(GetDistanceFromCamera(humanoidRootPart.Position))
                        objects.Distance.Text = string.format("%dm", distance)
                        objects.Distance.Position = Vector2.new(vector.X, vector.Y + 25)
                        objects.Distance.Visible = true
                    else
                        objects.Distance.Visible = false
                    end
                    
                    if WallhackModule.ShowWeapon then
                        local weapon = GetPlayerWeapon(character)
                        objects.Weapon.Text = weapon
                        objects.Weapon.Position = Vector2.new(vector.X, vector.Y + 40)
                        objects.Weapon.Visible = true
                    else
                        objects.Weapon.Visible = false
                    end
                    
                    if WallhackModule.ShowTracers then
                        objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        objects.Tracer.To = Vector2.new(vector.X, vector.Y)
                        objects.Tracer.Visible = true
                    else
                        objects.Tracer.Visible = false
                    end
                else
                    for _, object in pairs(objects) do
                        if typeof(object) == "table" then
                            for _, subObject in pairs(object) do
                                subObject.Visible = false
                            end
                        else
                            object.Visible = false
                        end
                    end
                end
            else
                for _, object in pairs(objects) do
                    if typeof(object) == "table" then
                        for _, subObject in pairs(object) do
                            subObject.Visible = false
                        end
                    else
                        object.Visible = false
                    end
                end
            end
        end
    end
end

local function CreateHighlight(player)
    if not HighlightObjects[player] and player.Character then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = WallhackModule.FillColor
        highlight.FillTransparency = WallhackModule.FillTransparency
        highlight.OutlineColor = WallhackModule.OutlineColor
        highlight.OutlineTransparency = WallhackModule.OutlineTransparency
        highlight.Parent = player.Character
        HighlightObjects[player] = highlight
    end
end

local function UpdateHighlight(player)
    local highlight = HighlightObjects[player]
    if highlight then
        if WallhackModule.TeamCheck and player.Team then
            local teamColor = player.TeamColor.Color
            highlight.FillColor = teamColor
            highlight.OutlineColor = teamColor
        elseif WallhackModule.AutoTeamColor and player.Team and player.Team == LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(128, 128, 128)
            highlight.OutlineColor = Color3.fromRGB(128, 128, 128)
        else
            highlight.FillColor = WallhackModule.FillColor
            highlight.OutlineColor = WallhackModule.OutlineColor
        end
        
        highlight.FillTransparency = WallhackModule.FillTransparency
        highlight.OutlineTransparency = WallhackModule.OutlineTransparency
    end
end

local function RemoveHighlight(player)
    local highlight = HighlightObjects[player]
    if highlight then
        if WallhackModule.ComfortMode then
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(highlight, tweenInfo, {
                FillTransparency = 1,
                OutlineTransparency = 1
            })
            tween.Completed:Connect(function()
                highlight:Destroy()
                HighlightObjects[player] = nil
            end)
            tween:Play()
        else
            highlight:Destroy()
            HighlightObjects[player] = nil
        end
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
        player.CharacterAdded:Connect(function()
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
                for _, subObject in pairs(object) do
                    subObject:Remove()
                end
            else
                object:Remove()
            end
        end
        DrawingObjects[player] = nil
    end
    RemoveHighlight(player)
end)

RunService.RenderStepped:Connect(function()
    if WallhackModule.DrawLibEnabled then
        UpdateESP()
    end
    
    if WallhackModule.HighlightEnabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if IsAlive(player) then
                    CreateHighlight(player)
                    UpdateHighlight(player)
                else
                    RemoveHighlight(player)
                end
            end
        end
    end
end)

return WallhackModule
