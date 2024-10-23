--Settings--
local ESP = {
    Enabled = false,
    Boxes = true,
    BoxShift = CFrame.new(0,-1.5,0),
    BoxSize = Vector3.new(4,6,0),
    Color = Color3.fromRGB(255, 0, 0),
    FaceCamera = false,
    Names = true,
    TeamColor = false, -- Set to false to use a fixed color
    Thickness = 2,
    AttachShift = 1,
    TeamMates = false, -- Do not show teammates
    Players = true,
    
    Objects = setmetatable({}, {__mode = "kv"}),
    Overrides = {}
}

--Declarations--
local cam = workspace.CurrentCamera
local ViewportSize = cam.ViewportSize
local ViewportX = ViewportSize.X
local ViewportY = ViewportSize.Y

local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()

local V3new = Vector3.new
local WorldToViewportPoint = cam.WorldToViewportPoint

--Functions--
local function Draw(obj, props)
    local new = Drawing.new(obj)
    
    props = props or {}
    for i, v in pairs(props) do
        new[i] = v
    end

    return new
end

function ESP:GetTeam(p)
    return p and p.Team
end

function ESP:IsTeamMate(p)
    return self:GetTeam(p) == self:GetTeam(plr)
end

function ESP:GetColor(obj)
    return self.Color -- Use a fixed color
end

function ESP:GetPlrFromChar(char)
    return plrs:GetPlayerFromCharacter(char)
end

function ESP:Toggle(bool)
    self.Enabled = bool
    if not bool then
        for i,v in pairs(self.Objects) do
            if v.Type == "Box" then
                if v.Temporary then
                    v:Remove()
                else
                    for i,v in pairs(v.Components) do
                        v.Visible = false
                    end
                end
            end
        end
    end
end

function ESP:GetBox(obj)
    return self.Objects[obj]
end

function ESP:AddObjectListener(parent, options)
    local function NewListener(c)
        if c:IsA(options.Type) and (not options.Name or c.Name == options.Name) then
            if not options.Validator or options.Validator(c) then
                local box = ESP:Add(c, {
                    PrimaryPart = c:WaitForChild(options.PrimaryPart),
                    Color = options.Color,
                    Name = options.CustomName,
                    IsEnabled = options.IsEnabled,
                    RenderInNil = options.RenderInNil
                })
                if options.OnAdded then
                    coroutine.wrap(options.OnAdded)(box)
                end
            end
        end
    end

    parent.ChildAdded:Connect(NewListener)
    for i,v in pairs(parent:GetChildren()) do
        coroutine.wrap(NewListener)(v)
    end
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for i,v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
        self.Components[i] = nil
    end
end

function boxBase:Update()
    if not self.PrimaryPart then
        return self:Remove()
    end

    local allow = true
    if self.Player and not ESP.TeamMates and ESP:IsTeamMate(self.Player) then
        allow = false
    end

    if not allow then
        for i,v in pairs(self.Components) do
            v.Visible = false
        end
        return
    end

    -- Calculations for positioning
    local cf = self.PrimaryPart.CFrame
    local locs = {
        TagPos = cf * ESP.BoxShift * CFrame.new(0, 3, 0),
    }

    if ESP.Names then
        local TagPos, Vis = cam:WorldToViewportPoint(locs.TagPos.p)
        
        if Vis then
            self.Components.Name.Visible = true
            self.Components.Name.Position = Vector2.new(TagPos.X, TagPos.Y)
            self.Components.Name.Text = self.Name
            self.Components.Name.Color = Color3.new(1, 1, 1) -- White color
            self.Components.Name.OutlineColor = Color3.new(0, 0, 0) -- Black outline
            self.Components.Distance.Visible = true
            self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
            self.Components.Distance.Text = math.floor((cam.CFrame.p - cf.p).Magnitude) .. "m away"
            self.Components.Distance.Color = Color3.new(1, 1, 1) -- White color
            self.Components.Distance.OutlineColor = Color3.new(0, 0, 0) -- Black outline
        else
            self.Components.Name.Visible = false
            self.Components.Distance.Visible = false
        end
    end
end

function ESP:Add(obj, options)
    if not obj.Parent then
        return
    end

    local box = setmetatable({
        Name = options.Name or obj.Name,
        Type = "Box",
        Color = options.Color,
        Object = obj,
        PrimaryPart = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart"),
        Components = {},
        IsEnabled = options.IsEnabled,
        Temporary = options.Temporary,
    }, boxBase)

    if self:GetBox(obj) then
        self:GetBox(obj):Remove()
    end

    box.Components["Name"] = Draw("Text", {
        Text = box.Name,
        Color = Color3.new(1, 1, 1), -- White color for name
        Center = true,
        Outline = true,
        Size = 19,
        Visible = self.Enabled and self.Names,
    })

    box.Components["Distance"] = Draw("Text", {
        Color = Color3.new(1, 1, 1), -- White color for distance
        Center = true,
        Outline = true,
        Size = 19,
        Visible = self.Enabled and self.Names,
    })

    self.Objects[obj] = box

    obj.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            box:Remove()
        end
    end)

    return box
end

game:GetService("RunService").RenderStepped:Connect(function()
    if ESP.Enabled then
        for _, v in next, ESP.Objects do
            if v.Update then
                pcall(v.Update, v)
            end
        end
    end
end)

return ESP
