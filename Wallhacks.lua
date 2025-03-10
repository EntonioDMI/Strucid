local WallhackModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local DrawLibSettings = {
    Enabled = false,
    ShowHP = false,
    ShowDistance = false,
    ShowWeapon = false,
    ShowTracers = false,
    ShowName = false,
    Show2DBoxes = false,
    Show3DBoxes = false
}

local HighlightSettings = {
    Enabled = false,
    FillColor = Color3.fromRGB(255, 0, 0),
    FillTransparency = 0.5,
    OutlineColor = Color3.fromRGB(255, 255, 255),
    OutlineTransparency = 0,
    TeamCheck = false,
    AutoTeamColor = false,
    ComfortMode = false
}

-- DrawLib Objects Storage
local DrawingObjects = {}

-- Highlight Objects Storage
local HighlightObjects = {}

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

-- DrawLib Functions
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
    if not DrawLibSettings.Show2DBoxes then
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
    if not DrawLibSettings.Show3DBoxes then
        for _, line in pairs(objects.Box3D) do
            line.Visible = false
        end
        return
    end
    
    local corners = GetBoxCorners(character)
    if not corners then return end
    
    -- Update box lines
    for _, corner in pairs(corners) do
        local vector, onScreen = Camera:WorldToViewportPoint(corner.Position)
        if not onScreen then
            for _, line in pairs(objects.Box3D) do
                line.Visible = false
            end
            return
        end
    end
    
    -- Draw 3D box lines
    -- Implementation for drawing the 3D box lines would go here
    -- This requires calculating the positions of all corners and connecting them with lines
end

local function UpdateESP()
    for player, objects in pairs(DrawingObjects) do
        if player ~= LocalPlayer and player.Character and IsAlive(player) then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart and DrawLibSettings.Enabled then
                local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
                
                if onScreen then
                    -- Update 2D Box
                    Update2DBox(player, objects, vector)
                    
                    -- Update 3D Box
                    Update3DBox(player, objects, character)
                    
                    -- Update Name
                    if DrawLibSettings.ShowName then
                        objects.Name.Text = player.Name
                        objects.Name.Position = Vector2.new(vector.X, vector.Y - 40)
                        objects.Name.Visible = true
                    else
                        objects.Name.Visible = false
                    end
                    
                    -- Update Health
                    if DrawLibSettings.ShowHP then
                        local health = GetCharacterHealth(character)
                        objects.Health.Text = string.format("HP: %d", health)
                        objects.Health.Position = Vector2.new(vector.X, vector.Y - 25)
                        objects.Health.Color = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
                        objects.Health.Visible = true
                    else
                        objects.Health.Visible = false
                    end
                    
                    -- Update Distance
                    if DrawLibSettings.ShowDistance then
                        local distance = math.floor(GetDistanceFromCamera(humanoidRootPart.Position))
                        objects.Distance.Text = string.format("%dm", distance)
                        objects.Distance.Position = Vector2.new(vector.X, vector.Y + 25)
                        objects.Distance.Visible = true
                    else
                        objects.Distance.Visible = false
                    end
                    
                    -- Update Weapon
                    if DrawLibSettings.ShowWeapon then
                        local weapon = GetPlayerWeapon(character)
                        objects.Weapon.Text = weapon
                        objects.Weapon.Position = Vector2.new(vector.X, vector.Y + 40)
                        objects.Weapon.Visible = true
                    else
                        objects.Weapon.Visible = false
                    end
                    
                    -- Update Tracer
                    if DrawLibSettings.ShowTracers then
                        objects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        objects.Tracer.To = Vector2.new(vector.X, vector.Y)
                        objects.Tracer.Visible = true
                    else
                        objects.Tracer.Visible = false
                    end
                else
                    -- Hide everything if not on screen
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
                -- Hide everything if conditions not met
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

-- Highlight Functions
local function CreateHighlight(player)
    if not HighlightObjects[player] and player.Character then
        local highlight = Instance.new("Highlight")
        highlight.FillColor = HighlightSettings.FillColor
        highlight.FillTransparency = HighlightSettings.FillTransparency
        highlight.OutlineColor = HighlightSettings.OutlineColor
        highlight.OutlineTransparency = HighlightSettings.OutlineTransparency
        highlight.Parent = player.Character
        HighlightObjects[player] = highlight
    end
end

local function UpdateHighlight(player)
    local highlight = HighlightObjects[player]
    if highlight then
        if HighlightSettings.TeamCheck and player.Team then
            local teamColor = player.TeamColor.Color
            highlight.FillColor = teamColor
            highlight.OutlineColor = teamColor
        elseif HighlightSettings.AutoTeamColor and player.Team and player.Team == LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(128, 128, 128)
            highlight.OutlineColor = Color3.fromRGB(128, 128, 128)
        else
            highlight.FillColor = HighlightSettings.FillColor
            highlight.OutlineColor = HighlightSettings.OutlineColor
        end
        
        highlight.FillTransparency = HighlightSettings.FillTransparency
        highlight.OutlineTransparency = HighlightSettings.OutlineTransparency
    end
end

local function RemoveHighlight(player)
    local highlight = HighlightObjects[player]
    if highlight then
        if HighlightSettings.ComfortMode then
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

-- Module Functions
function WallhackModule.SetDrawLibEnabled(enabled)
    DrawLibSettings.Enabled = enabled
end

function WallhackModule.SetDrawLibSetting(setting, value)
    DrawLibSettings[setting] = value
end

function WallhackModule.SetHighlightEnabled(enabled)
    HighlightSettings.Enabled = enabled
    if not enabled then
        for player, _ in pairs(HighlightObjects) do
            RemoveHighlight(player)
        end
    end
end

function WallhackModule.SetHighlightSetting(setting, value)
    HighlightSettings[setting] = value
end

-- Initialize
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPForPlayer(player)
        if HighlightSettings.Enabled then
            CreateHighlight(player)
        end
    end
end

-- Event Connections
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESPForPlayer(player)
        player.CharacterAdded:Connect(function()
            if HighlightSettings.Enabled then
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
    if DrawLibSettings.Enabled then
        UpdateESP()
    end
    
    if HighlightSettings.Enabled then
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
