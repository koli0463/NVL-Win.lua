--[[
    Cheat Bridge - Kết nối NVL.lua (UI) với da hood (1).lua (Logic)
    
    Cách hoạt động:
    1. NVL.lua tạo giao diện và lưu flags vào library.flags
    2. File này đọc flags từ NVL UI và expose ra getgenv() 
    3. Cheat logic từ da hood (1).lua đọc flags từ getgenv()
    
    Cách sử dụng:
    - Load NVL.lua trước (tạo UI)
    - Sau đó load file này
]]

-- Chờ cho library được load xong
repeat task.wait() until getgenv()._NVL_FLAGS

local ui_flags = getgenv()._NVL_FLAGS
local connections = {}

-- ============================================
-- Shared Services
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = workspace

-- ============================================
-- Shared Variables
-- ============================================
local camera = Workspace.CurrentCamera
local mouse = LocalPlayer:GetMouse()

local local_character = LocalPlayer.Character
local local_parts = {}
local local_tool = nil
local local_gun = nil
local local_knocked = false
local local_armor = 0
local local_reloading = false

local ragebot_target = nil
local legitbot_target = nil
local player_data = {}
local anti_aim = {}

-- ============================================
-- Utility Functions
-- ============================================
local function get_flag(name, default)
    local val = ui_flags[name]
    if val == nil then return default end
    return val
end

local function get_closest_player(max_distance, checks)
    local closest = nil
    local closest_distance = max_distance or 9999
    
    local local_hrp = local_parts["HumanoidRootPart"]
    if not local_hrp then return nil end
    
    local local_pos = local_hrp.Position
    
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        if not hrp or not humanoid then continue end
        if humanoid.Health <= 0 then continue end
        
        -- Check knocked
        local body_effects = character:FindFirstChild("BodyEffects")
        if body_effects then
            local ko = body_effects:FindFirstChild("K.O")
            if ko and ko.Value == true then continue end
        end
        
        local distance = (local_pos - hrp.Position).Magnitude
        
        if distance < closest_distance then
            closest = player
            closest_distance = distance
        end
    end
    
    return closest
end

local function world_to_screen(position)
    local pos, onscreen = camera:WorldToViewportPoint(position)
    return Vector2.new(pos.X, pos.Y), onscreen, pos.Z
end

-- ============================================
-- Character Tracking
-- ============================================
local function on_character_added(character)
    local_gun = nil
    local_tool = nil
    local_knocked = false
    
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end
    
    local_parts = { HumanoidRootPart = hrp }
    
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end
    
    character:WaitForChild("Head", 5)
    
    for _, child in character:GetChildren() do
        local_parts[child.Name] = child
    end
    
    connections[#connections+1] = character.ChildAdded:Connect(function(child)
        local_parts[child.Name] = child
        if child.ClassName == "Tool" then
            local handle = child:FindFirstChild("Handle")
            if handle then
                local_tool = child
                local range = child:FindFirstChild("Range")
                if range then
                    local_gun = range.Value
                end
            end
        end
    end)
    
    connections[#connections+1] = character.ChildRemoved:Connect(function(child)
        local_parts[child.Name] = nil
        if child.ClassName == "Tool" and child == local_tool then
            local_tool = nil
            local_gun = nil
        end
    end)
    
    local_character = character
    
    -- Wait for full load
    character:WaitForChild("FULLY_LOADED_CHAR", 30)
    
    local body_effects = character:WaitForChild("BodyEffects", 10)
    if body_effects then
        local ko = body_effects:WaitForChild("K.O", 10)
        local reload = body_effects:FindFirstChild("Reload")
        local armor = body_effects:FindFirstChild("Armor")
        
        if ko then
            connections[#connections+1] = ko:GetPropertyChangedSignal("Value"):Connect(function()
                local_knocked = ko.Value
            end)
            local_knocked = ko.Value
        end
        
        if reload then
            connections[#connections+1] = reload:GetPropertyChangedSignal("Value"):Connect(function()
                local_reloading = reload.Value
            end)
        end
        
        if armor then
            connections[#connections+1] = armor:GetPropertyChangedSignal("Value"):Connect(function()
                local_armor = armor.Value
            end)
            local_armor = armor.Value
        end
    end
end

if local_character then
    task.spawn(on_character_added, local_character)
end
connections[#connections+1] = LocalPlayer.CharacterAdded:Connect(on_character_added)

-- ============================================
-- Movement Features
-- ============================================

-- CFrame Speed
local cframe_speed_active = false
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_cframe_speed") then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if not hrp or local_knocked then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local move_direction = humanoid.MoveDirection
    if move_direction.Magnitude == 0 then return end
    
    local speed = 2
    hrp.CFrame = hrp.CFrame + (move_direction * speed)
end)

-- CFrame Fly
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_cframe_fly") then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if not hrp or local_knocked then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    
    local speed = 2
    local cam_cf = camera.CFrame
    
    local move = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        move = move + cam_cf.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        move = move - cam_cf.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        move = move - cam_cf.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        move = move + cam_cf.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        move = move + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        move = move - Vector3.new(0, 1, 0)
    end
    
    if move.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (move.Unit * speed)
    end
    
    hrp.Velocity = Vector3.new(0, 0, 0)
end)

-- Noclip
connections[#connections+1] = RunService.Stepped:Connect(function()
    if not get_flag("misc_noclip") then return end
    
    if local_character then
        for _, part in local_character:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Remove Jump Cooldown
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_remove_jump_cooldown") then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        humanoid.JumpPower = humanoid.JumpPower > 0 and humanoid.JumpPower or 50
    end
end)

-- Remove Slowdowns
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_remove_slowdowns") then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health > 0 then
        if humanoid.WalkSpeed < 16 then
            humanoid.WalkSpeed = 16
        end
    end
end)

-- No Void Kill
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_no_void_kill") then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if hrp and hrp.Position.Y < -50 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 50, hrp.Position.Z)
        hrp.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- No Sit
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_no_sit") then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Sit then
        humanoid.Sit = false
    end
end)

-- Instant Stand
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("misc_instant_stand") then return end
    
    local humanoid = local_character and local_character:FindFirstChild("Humanoid")
    if humanoid and humanoid:GetState() == Enum.HumanoidStateType.FallingDown then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end)

-- ============================================
-- Aimbot / Silent Aim
-- ============================================
local aimbot_target = nil

local function get_aimbot_target()
    if not get_flag("aimbot_enabled") then
        aimbot_target = nil
        return nil
    end
    
    local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local closest_player = nil
    local closest_distance = math.huge
    
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        if not character then continue end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        if not hrp or not humanoid or not head then continue end
        if humanoid.Health <= 0 then continue end
        
        -- Knocked check
        local body_effects = character:FindFirstChild("BodyEffects")
        if body_effects then
            local ko = body_effects:FindFirstChild("K.O")
            if ko and ko.Value == true then continue end
        end
        
        local screen_pos, onscreen = world_to_screen(head.Position)
        if not onscreen then continue end
        
        local distance = (screen_center - screen_pos).Magnitude
        
        if distance < closest_distance then
            closest_player = player
            closest_distance = distance
        end
    end
    
    aimbot_target = closest_player
    return closest_player
end

-- Aim Assist
connections[#connections+1] = RunService.RenderStepped:Connect(function()
    if not get_flag("aimbot_assist") then return end
    if local_knocked then return end
    
    local target = get_aimbot_target()
    if not target or not target.Character then return end
    
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    
    local screen_pos, onscreen = world_to_screen(head.Position)
    if not onscreen then return end
    
    local screen_center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    local offset = (screen_pos - screen_center) * 0.15
    
    mousemoverel(offset.X, offset.Y)
end)

-- ============================================
-- Anti-Aim Features
-- ============================================

-- Velocity Desync
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("aa_velocity_desync") then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if not hrp or local_knocked then return end
    
    local h_offset = get_flag("aa_horizontal_offset", 5)
    local v_offset = get_flag("aa_vertical_offset", 5)
    
    hrp.Velocity = Vector3.new(
        math.random(-h_offset, h_offset) * 10,
        math.random(-v_offset, v_offset) * 5,
        math.random(-h_offset, h_offset) * 10
    )
end)

-- Spinbot
connections[#connections+1] = RunService.RenderStepped:Connect(function()
    if not get_flag("char_spinbot") then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if not hrp or local_knocked then return end
    
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(30), 0)
end)

-- Anti Stomp
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("aa_anti_stomp") then return end
    if not local_knocked then return end
    
    local hrp = local_parts["HumanoidRootPart"]
    if not hrp then return end
    
    -- Move away when knocked
    hrp.Velocity = Vector3.new(math.random(-50, 50), 20, math.random(-50, 50))
end)

-- ============================================
-- ESP (Basic Drawing ESP)
-- ============================================
local esp_drawings = {}

local function clear_esp()
    for player, drawings in esp_drawings do
        for _, drawing in drawings do
            if drawing and drawing.Remove then
                drawing:Remove()
            end
        end
    end
    esp_drawings = {}
end

local function create_esp_drawing(player)
    if esp_drawings[player] then return end
    
    local drawings = {}
    
    -- Box
    drawings.box = Drawing.new("Square")
    drawings.box.Thickness = 1
    drawings.box.Filled = false
    drawings.box.Visible = false
    
    -- Name
    drawings.name = Drawing.new("Text")
    drawings.name.Size = 13
    drawings.name.Center = true
    drawings.name.Outline = true
    drawings.name.Visible = false
    
    -- Health bar
    drawings.health_bg = Drawing.new("Square")
    drawings.health_bg.Thickness = 1
    drawings.health_bg.Filled = true
    drawings.health_bg.Visible = false
    
    drawings.health = Drawing.new("Square")
    drawings.health.Thickness = 1
    drawings.health.Filled = true
    drawings.health.Visible = false
    
    -- Tool text
    drawings.tool = Drawing.new("Text")
    drawings.tool.Size = 12
    drawings.tool.Center = true
    drawings.tool.Outline = true
    drawings.tool.Visible = false
    
    esp_drawings[player] = drawings
end

local function remove_esp_drawing(player)
    local drawings = esp_drawings[player]
    if not drawings then return end
    
    for _, drawing in drawings do
        if drawing and drawing.Remove then
            drawing:Remove()
        end
    end
    esp_drawings[player] = nil
end

connections[#connections+1] = RunService.RenderStepped:Connect(function()
    local esp_enabled = get_flag("esp_enabled")
    
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        
        if not esp_enabled then
            remove_esp_drawing(player)
            continue
        end
        
        local character = player.Character
        if not character then
            remove_esp_drawing(player)
            continue
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        local head = character:FindFirstChild("Head")
        
        if not hrp or not humanoid or not head then
            remove_esp_drawing(player)
            continue
        end
        
        local pos, onscreen = camera:WorldToViewportPoint(hrp.Position)
        
        if not onscreen then
            if esp_drawings[player] then
                for _, drawing in esp_drawings[player] do
                    drawing.Visible = false
                end
            end
            continue
        end
        
        create_esp_drawing(player)
        local drawings = esp_drawings[player]
        
        local head_pos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
        local foot_pos = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        
        local box_height = math.abs(head_pos.Y - foot_pos.Y)
        local box_width = box_height * 0.6
        
        local box_x = pos.X - box_width / 2
        local box_y = head_pos.Y
        
        -- Box ESP
        if get_flag("esp_box") then
            local box_color = get_flag("esp_box_color", Color3.fromRGB(255, 255, 255))
            drawings.box.Size = Vector2.new(box_width, box_height)
            drawings.box.Position = Vector2.new(box_x, box_y)
            drawings.box.Color = box_color
            drawings.box.Visible = true
        else
            drawings.box.Visible = false
        end
        
        -- Name ESP
        if get_flag("esp_nombre") then
            local name_color = get_flag("esp_nombre_color", Color3.fromRGB(255, 255, 255))
            drawings.name.Text = player.DisplayName
            drawings.name.Position = Vector2.new(pos.X, box_y - 15)
            drawings.name.Color = name_color
            drawings.name.Visible = true
        else
            drawings.name.Visible = false
        end
        
        -- Health bar
        if get_flag("esp_health_bar") then
            local health_color = get_flag("esp_health_bar_color", Color3.fromRGB(0, 255, 0))
            local health_pct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            
            drawings.health_bg.Size = Vector2.new(2, box_height)
            drawings.health_bg.Position = Vector2.new(box_x - 5, box_y)
            drawings.health_bg.Color = Color3.fromRGB(30, 30, 30)
            drawings.health_bg.Visible = true
            
            drawings.health.Size = Vector2.new(2, box_height * health_pct)
            drawings.health.Position = Vector2.new(box_x - 5, box_y + box_height * (1 - health_pct))
            drawings.health.Color = health_color
            drawings.health.Visible = true
        else
            drawings.health_bg.Visible = false
            drawings.health.Visible = false
        end
        
        -- Tool ESP
        if get_flag("esp_tool") then
            local tool_color = get_flag("esp_tool_color", Color3.fromRGB(255, 255, 255))
            local tool = character:FindFirstChildOfClass("Tool")
            drawings.tool.Text = tool and tool.Name or ""
            drawings.tool.Position = Vector2.new(pos.X, box_y + box_height + 2)
            drawings.tool.Color = tool_color
            drawings.tool.Visible = tool ~= nil
        else
            drawings.tool.Visible = false
        end
    end
end)

-- Cleanup on player leaving
connections[#connections+1] = Players.PlayerRemoving:Connect(function(player)
    remove_esp_drawing(player)
end)

-- ============================================
-- Highlight ESP
-- ============================================
local highlights = {}

connections[#connections+1] = RunService.Heartbeat:Connect(function()
    local highlight_enabled = get_flag("esp_highlight")
    local highlight_color = get_flag("esp_highlight_color", Color3.fromRGB(0, 153, 255))
    
    for _, player in Players:GetPlayers() do
        if player == LocalPlayer then continue end
        
        local character = player.Character
        
        if not highlight_enabled or not character then
            if highlights[player] then
                highlights[player]:Destroy()
                highlights[player] = nil
            end
            continue
        end
        
        if not highlights[player] then
            local h = Instance.new("Highlight")
            h.FillColor = highlight_color
            h.OutlineColor = highlight_color
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0
            h.Adornee = character
            h.Parent = character
            highlights[player] = h
        else
            highlights[player].FillColor = highlight_color
            highlights[player].OutlineColor = highlight_color
            if highlights[player].Adornee ~= character then
                highlights[player].Adornee = character
                highlights[player].Parent = character
            end
        end
    end
end)

connections[#connections+1] = Players.PlayerRemoving:Connect(function(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end)

-- ============================================
-- Auto Reload
-- ============================================
connections[#connections+1] = RunService.Heartbeat:Connect(function()
    if not get_flag("aimbot_autoreload") then return end
    
    if local_tool and local_character then
        local ammo = local_tool:FindFirstChild("Ammo")
        if ammo and ammo.Value <= 0 and not local_reloading then
            local event = ReplicatedStorage:FindFirstChild("MainEvent")
            if event then
                event:FireServer("Reload")
            end
        end
    end
end)

-- ============================================
-- Expose for external use  
-- ============================================
getgenv()._CHEAT_BRIDGE = {
    get_flag = get_flag,
    get_closest_player = get_closest_player,
    world_to_screen = world_to_screen,
    player_data = player_data,
    connections = connections,
    unload = function()
        for _, conn in connections do
            pcall(function() conn:Disconnect() end)
        end
        clear_esp()
        for player, h in highlights do
            pcall(function() h:Destroy() end)
        end
        highlights = {}
    end
}

print("[NVL Bridge] Cheat logic loaded successfully!")
