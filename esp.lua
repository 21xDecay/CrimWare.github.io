--Settings--
local ESP = {
    Enabled = false,
    Boxes = true,
    BoxShift = CFrame.new(0, -1.5, 0),
    BoxSize = Vector3.new(4, 6, 0),
    Color = Color3.fromRGB(255, 0, 0),
    FaceCamera = false,
    Names = true,
    TeamColor = false,
    Thickness = 2,
    Players = true,
    
    Objects = setmetatable({}, {__mode = "kv"}), -- Weak table to auto-cleanup
}

--Declarations--
local cam = workspace.CurrentCamera
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer

--Functions--
local function Draw(obj, props)
    local new = Drawing.new(obj)
    for i, v in pairs(props) do
        new[i] = v
    end
    return new
end

function ESP:GetTeam(p)
    return p and p.Team
end

function ESP:IsTeamMate(p)
    return self:GetTeam(p) == self:GetTeam(plr) -- Check if player is a teammate
end

function ESP:Add(obj)
    if not obj.Parent or self:IsTeamMate(self:GetPlrFromChar(obj)) then
        return -- Skip adding ESP for teammates or non-existing objects
    end

    local box = {
        Name = obj.Name,
        Object = obj,
        Components = {},
    }

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

    box.Components["Tracer"] = Draw("Line", {
        Thickness = self.Thickness,
        Color = Color3.new(1, 1, 1), -- White color for tracers
        Transparency = 1,
        Visible = self.Enabled,
    })

    self.Objects[obj] = box

    obj.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            box:Remove()
        end
    end)

    return box
end

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for _, v in pairs(self.Components) do
        v.Visible = false
        v:Remove()
        self.Components[_] = nil
    end
end

function boxBase:Update()
    if not self.PrimaryPart or ESP:IsTeamMate(ESP:GetPlrFromChar(self.Object)) then
        return self:Remove() -- Remove ESP for teammates
    end

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
            self.Components.Distance.Visible = true
            self.Components.Distance.Position = Vector2.new(TagPos.X, TagPos.Y + 14)
            self.Components.Distance.Text = math.floor((cam.CFrame.p - cf.p).Magnitude) .. "m away"
        else
            self.Components.Name.Visible = false
            self.Components.Distance.Visible = false
        end
    end
    
    -- Update tracers
    if ESP.Tracers then
        local TorsoPos, Vis6 = cam:WorldToViewportPoint(locs.TagPos.p)
        
        if Vis6 then
            self.Components.Tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            self.Components.Tracer.To = Vector2.new(TorsoPos.X, TorsoPos.Y)
            self.Components.Tracer.Visible = true
        else
            self.Components.Tracer.Visible = false
        end
    else
        self.Components.Tracer.Visible = false
    end
end

function ESP:Toggle(bool)
    self.Enabled = bool
    for _, v in pairs(self.Objects) do
        if bool then
            v:Update() -- Update ESP if enabled
        else
            v:Remove() -- Remove ESP if disabled
        end
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    if ESP.Enabled then
        for _, v in pairs(ESP.Objects) do
            if v.Update then
                pcall(v.Update, v)
            end
        end
    end
end)

return ESP
