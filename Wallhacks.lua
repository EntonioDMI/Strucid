local WallhackModule = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Constants
local BEAM_WIDTH = 0.3
local MAX_DISTANCE = 1000
local UPDATE_INTERVAL = 1/144 -- 144 FPS cap

-- Public Variables
WallhackModule.ESPEnabled = false
WallhackModule.ShowHP = false
WallhackModule.ShowDistance = false
WallhackModule.ShowWeapon = false
WallhackModule.ShowTracers = false
WallhackModule.ShowName = false
WallhackModule.ShowBoxes = false
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
local ESPObjects = {}
local HighlightObjects = {}
local BeamCache = {}

-- Utility Functions
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

local function GetDistanceFromCamera(position)
    return (Camera.CFrame.Position - position).Magnitude
end

local function CreateBeam()
    local attachment1 = Instance.new("Attachment")
    local attachment2 = Instance.new("Attachment")
    local beam = Instance.new("Beam")
    
    beam.Width0 = BEAM_WIDTH
    beam.Width1 = BEAM_WIDTH
    beam.FaceCamera = true
    beam.Enabled = false
    beam.Attachment0 = attachment1
    beam.Attachment1 = attachment2
    
    return {
        beam = beam,
        attachment1 = attachment1,
        attachment2 = attachment2
    }
end

local function GetOrCreateBeam()
    for _, beamData in pairs(BeamCache) do
        if not beamData.inUse then
            beamData.inUse = true
            return beamData
        end
    end
    
    local beamData = CreateBeam()
    beamData.inUse = true
    table.insert(BeamCache, beamData)
    return beamData
end

local function ReleaseBeam(beamData)
    beamData.inUse = false
    beamData.beam.Enabled = false
end

local function CreateESPObject(player)
    if ESPObjects[player] then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 200, 0, 100)
    billboardGui.AlwaysOnTop = true
    billboardGui.Enabled = false
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboardGui
    
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0, 20)
    healthLabel.Position = UDim2.new(0, 0, 0, 20)
    healthLabel.BackgroundTransparency = 1
    healthLabel.TextColor3 = Color3.new(0, 1, 0)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextSize = 14
    healthLabel.Parent = billboardGui
    
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0, 20)
    distanceLabel.Position = UDim2.new(0, 0, 0, 40)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.new(1, 1, 1)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.TextSize = 14
    distanceLabel.Parent = billboardGui
    
    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(1, 0, 0, 20)
    weaponLabel.Position = UDim2.new(0, 0, 0, 60)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextColor3 = Color3.new(1, 1, 0)
    weaponLabel.TextStrokeTransparency = 0
    weaponLabel.Font = Enum.Font.SourceSansBold
    weaponLabel.TextSize = 14
    weaponLabel.Parent = billboardGui
    
    ESPObjects[player] = {
        billboardGui = billboardGui,
        nameLabel = nameLabel,
        healthLabel = healthLabel,
        distanceLabel = distanceLabel,
        weaponLabel = weaponLabel,
        beams = {}
    }
    
    return ESPObjects[player]
end

local function UpdateESPObject(player, character)
    local espObject = ESPObjects[player]
    if not espObject or not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Update BillboardGui position
    espObject.billboardGui.Parent = humanoidRootPart
    
    -- Update labels
    if WallhackModule.ShowName then
        espObject.nameLabel.Text = player.Name
        espObject.nameLabel.Visible = true
    else
        espObject.nameLabel.Visible = false
    end
    
    if WallhackModule.ShowHP then
        local health = GetCharacterHealth(character)
        espObject.healthLabel.Text = string.format("HP: %d", health)
        espObject.healthLabel.TextColor3 = Color3.fromRGB(255 - (health * 2.55), health * 2.55, 0)
        espObject.healthLabel.Visible = true
    else
        espObject.healthLabel.Visible = false
    end
    
    if WallhackModule.ShowDistance then
        local distance = math.floor(GetDistanceFromCamera(humanoidRootPart.Position))
        espObject.distanceLabel.Text = string.format("%dm", distance)
        espObject.distanceLabel.Visible = true
    else
        espObject.distanceLabel.Visible = false
    end
    
    if WallhackModule.ShowWeapon then
        local weapon = GetPlayerWeapon(character)
        espObject.weaponLabel.Text = weapon
        espObject.weaponLabel.Visible = true
    else
        espObject.weaponLabel.Visible = false
    end
    
    -- Update box beams
    if WallhackModule.ShowBoxes then
        local size = character:GetExtentsSize()
        local cf = humanoidRootPart.CFrame
        
        local corners = {
            cf * CFrame.new(size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
            cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
            cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)
        }
        
        local connections = {
            {1, 2}, {2, 3}, {3, 4}, {4, 1},
            {5, 6}, {6, 7}, {7, 8}, {8, 5},
            {1, 5}, {2, 6}, {3, 7}, {4, 8}
        }
        
        -- Release old beams
        for _, beamData in pairs(espObject.beams) do
            ReleaseBeam(beamData)
        end
        table.clear(espObject.beams)
        
        -- Create new beams
        for _, connection in ipairs(connections) do
            local beamData = GetOrCreateBeam()
            beamData.attachment1.WorldPosition = corners[connection[1]].Position
            beamData.attachment2.WorldPosition = corners[connection[2]].Position
            beamData.beam.Color = ColorSequence.new(WallhackModule.OutlineColor)
            beamData.beam.Transparency = NumberSequence.new(WallhackModule.OutlineTransparency)
            beamData.beam.Enabled = true
            
            beamData.attachment1.Parent = humanoidRootPart
            beamData.attachment2.Parent = humanoidRootPart
            beamData.beam.Parent = humanoidRootPart
            
            table.insert(espObject.beams, beamData)
        end
    else
        for _, beamData in pairs(espObject.beams) do
            ReleaseBeam(beamData)
        end
        table.clear(espObject.beams)
    end
    
    -- Update tracer
    if WallhackModule.ShowTracers then
        if not espObject.tracer then
            espObject.tracer = GetOrCreateBeam()
        end
        
        local screenSize = Camera.ViewportSize
        local screenCenter = Vector3.new(screenSize.X/2, screenSize.Y, 0)
        
        espObject.tracer.attachment1.WorldPosition = Camera.CFrame:PointToWorldSpace(screenCenter)
        espObject.tracer.attachment2.WorldPosition = humanoidRootPart.Position
        espObject.tracer.beam.Color = ColorSequence.new(WallhackModule.OutlineColor)
        espObject.tracer.beam.Transparency = NumberSequence.new(WallhackModule.OutlineTransparency)
        espObject.tracer.beam.Enabled = true
        
        espObject.tracer.attachment1.Parent = Camera
        espObject.tracer.attachment2.Parent = humanoidRootPart
        espObject.tracer.beam.Parent = Camera
    elseif espObject.tracer then
        ReleaseBeam(espObject.tracer)
        espObject.tracer = nil
    end
end

local function RemoveESPObject(player)
    local espObject = ESPObjects[player]
    if not espObject then return end
    
    espObject.billboardGui:Destroy()
    
    for _, beamData in pairs(espObject.beams) do
        ReleaseBeam(beamData)
    end
    
    if espObject.tracer then
        ReleaseBeam(espObject.tracer)
    end
    
    ESPObjects[player] = nil
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
        if WallhackModule.ESPEnabled then
            CreateESPObject(player)
        end
        if WallhackModule.HighlightEnabled then
            CreateHighlight(player)
        end
    end
end

-- Event Connections
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        if WallhackModule.ESPEnabled then
            CreateESPObject(player)
        end
        
        player.CharacterAdded:Connect(function(character)
            if WallhackModule.HighlightEnabled then
                CreateHighlight(player)
            end
        end)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESPObject(player)
    RemoveHighlight(player)
end)

-- Update Loop
local lastUpdate = 0

RunService.RenderStepped:Connect(function()
    local currentTime = tick()
    if currentTime - lastUpdate >= UPDATE_INTERVAL then
        lastUpdate = currentTime
        
        if WallhackModule.ESPEnabled then
            for player, espObject in pairs(ESPObjects) do
                if player ~= LocalPlayer and player.Character then
                    if IsAlive(player) or not WallhackModule.HideDeadPlayers then
                        espObject.billboardGui.Enabled = true
                        UpdateESPObject(player, player.Character)
                    else
                        espObject.billboardGui.Enabled = false
                        for _, beamData in pairs(espObject.beams) do
                            ReleaseBeam(beamData)
                        end
                        table.clear(espObject.beams)
                        if espObject.tracer then
                            ReleaseBeam(espObject.tracer)
                            espObject.tracer = nil
                        end
                    end
                end
            end
        else
            for _, espObject in pairs(ESPObjects) do
                espObject.billboardGui.Enabled = false
                for _, beamData in pairs(espObject.beams) do
                    ReleaseBeam(beamData)
                end
                table.clear(espObject.beams)
                if espObject.tracer then
                    ReleaseBeam(espObject.tracer)
                    espObject.tracer = nil
                end
            end
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
