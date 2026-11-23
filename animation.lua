local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- >> ( Remove Anti Gun Macro )
local function do_remove_anti_gun_macro()
    local new_constant = "_!_"
    if not getgc or not getinfo or not setconstant or not getconstants or not islclosure then return end
    
    local gc = getgc()
    for i = 1, #gc do
        local obj = gc[i]
        if type(obj) == "function" and islclosure(obj) then
            local info = getinfo(obj)
            if info and info.source and info.source:find("BaseCamera") then
                local constants = getconstants(obj)
                for idx, constant in pairs(constants) do
                    if constant == "HoldGunBool" or constant == "_!_" then
                        setconstant(obj, idx, new_constant)
                    end
                end
            end
        end
    end
end

-- Run automatically without toggle
task.spawn(do_remove_anti_gun_macro)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    do_remove_anti_gun_macro()
end)

-- >> ( Animation Logic )
local loaded_animation = nil
local animation = nil
local animation_id = "rbxassetid://15609995579" -- Default custom asset ID
local is_playing = false
local play_keybind = Enum.KeyCode.V
local setting_keybind = false
local play_mode = "Hold" -- "Hold" or "Toggle"

local active_tracks = {}

local function stop_all_custom_tracks()
    for _, track in ipairs(active_tracks) do
        pcall(function()
            track:Stop(0)
        end)
    end
    table.clear(active_tracks)
end

local function stop_animation()
    if loaded_animation then
        loaded_animation:Stop(0)
        loaded_animation = nil
    end
    if animation then
        animation:Destroy()
        animation = nil
    end
    stop_all_custom_tracks()
end
`
local function load_animation()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    if not LocalPlayer:HasAppearanceLoaded() then
        LocalPlayer.CharacterAppearanceLoaded:Wait()
    end

    if animation then
        animation.AnimationId = animation_id
        if loaded_animation then
            loaded_animation:Stop(0)
            loaded_animation = nil
        end
        loaded_animation = humanoid:LoadAnimation(animation)
        table.insert(active_tracks, loaded_animation)
        loaded_animation:Play()
    end
end

local function play_animation()
    stop_animation()
    animation = Instance.new("Animation")
    animation.AnimationId = animation_id
    load_animation()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    if is_playing then
        task.wait(0.5)
        play_animation()
    end
end)

-- >> ( Custom Character Logic )
local last_description = nil
local scale_connection = nil
local custom_char_active = false
local custom_char_connection = nil

local function apply_description(description, clone)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    local head = char:FindFirstChild("Head")

    if description and not clone then
        if last_description then
            last_description:Destroy()
        end
        last_description = description
    end

    local desc_to_apply = description or last_description

    if humanoid and head then
        humanoid:RemoveAccessories()

        local local_description = humanoid:FindFirstChild("HumanoidDescription") or humanoid:GetAppliedDescription()

        if local_description then
            desc_to_apply["BodyTypeScale"] = humanoid["BodyTypeScale"]["Value"]
            desc_to_apply["HeadScale"] = humanoid["HeadScale"]["Value"]
            desc_to_apply["DepthScale"] = humanoid["BodyDepthScale"]["Value"]
            desc_to_apply["HeightScale"] = humanoid["BodyHeightScale"]["Value"]
            desc_to_apply["ProportionScale"] = humanoid["BodyProportionScale"]["Value"]
            desc_to_apply["WidthScale"] = humanoid["BodyWidthScale"]["Value"]
            desc_to_apply:SetEmotes(local_description:GetEmotes())
        end

        local shirt = char:FindFirstChild("Shirt")
        if shirt then shirt:Destroy() end

        local pants = char:FindFirstChild("Pants")
        if pants then pants:Destroy() end

        local shirt_graphic = char:FindFirstChild("Shirt Graphic")
        if shirt_graphic then shirt_graphic:Destroy() end

        task.wait(0.1)
        local apply_ok = pcall(function()
            if setthreadidentity then setthreadidentity(2) end
            humanoid:ApplyDescriptionClientServer(desc_to_apply)
        end)
        if not apply_ok then
            pcall(function()
                if setthreadidentity then setthreadidentity(2) end
                humanoid:ApplyDescription(desc_to_apply)
            end)
        end

        if not clone then
            if scale_connection then scale_connection:Disconnect() end
            scale_connection = humanoid["BodyWidthScale"]:GetPropertyChangedSignal("Value"):Connect(function()
                task.wait()
                if not last_description then return end
                last_description["BodyTypeScale"] = humanoid["BodyTypeScale"]["Value"]
                last_description["HeadScale"] = humanoid["HeadScale"]["Value"]
                last_description["DepthScale"] = humanoid["BodyDepthScale"]["Value"]
                last_description["HeightScale"] = humanoid["BodyHeightScale"]["Value"]
                last_description["ProportionScale"] = humanoid["BodyProportionScale"]["Value"]
                last_description["WidthScale"] = humanoid["BodyWidthScale"]["Value"]
                local scale_apply_ok = pcall(function()
                    if setthreadidentity then setthreadidentity(2) end
                    humanoid:ApplyDescriptionClientServer(last_description)
                end)
                if not scale_apply_ok then
                    pcall(function()
                        if setthreadidentity then setthreadidentity(2) end
                        humanoid:ApplyDescription(last_description)
                    end)
                end
                if scale_connection then scale_connection:Disconnect() end
            end)
        end
    end
end

local function get_user_description(userid)
    if userid and tonumber(userid) then
        local ok, result = pcall(function()
            if setthreadidentity then setthreadidentity(2) end
            return Players:GetHumanoidDescriptionFromUserId(tonumber(userid))
        end)
        if ok and result then
            return result
        end
    end
    return nil
end

-- >> ( UI Setup )
local gui_name = "AnimationPlayerGUI"
local ParentGui = (gethui and gethui()) or CoreGui:FindFirstChild("RobloxGui") or CoreGui

if ParentGui:FindFirstChild(gui_name) then
    ParentGui:FindFirstChild(gui_name):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = gui_name
ScreenGui.Parent = ParentGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Open Button (when minimized via '-')
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 45, 0, 45)
OpenBtn.Position = UDim2.new(0.5, -22, 0, 10)
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Text = "👁"
OpenBtn.TextSize = 20
OpenBtn.Parent = ScreenGui
OpenBtn.Visible = false
OpenBtn.Active = true

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 8)
OpenCorner.Parent = OpenBtn

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 625) -- Expanded size to support dropdown, keybind mode & config system
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -312)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "  Animation Player & CC"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 35, 0, 35)
MinimizeBtn.Position = UDim2.new(1, -70, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = MainFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.Position = UDim2.new(0, 0, 0, 35)
Divider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

local PresetLabel = Instance.new("TextLabel")
PresetLabel.Size = UDim2.new(1, -20, 0, 20)
PresetLabel.Position = UDim2.new(0, 10, 0, 45)
PresetLabel.BackgroundTransparency = 1
PresetLabel.Text = "Presets:"
PresetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PresetLabel.TextSize = 13
PresetLabel.Font = Enum.Font.Gotham
PresetLabel.TextXAlignment = Enum.TextXAlignment.Left
PresetLabel.Parent = MainFrame

local function createButton(text, pos, size, parent)
    local btn = Instance.new("TextButton")
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Text = text
    btn.ZIndex = 3
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    return btn
end

local function addStroke(btn)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 0)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Enabled = false
    stroke.Parent = btn
end

local SleepBtn = createButton("Sleep", UDim2.new(0, 10, 0, 70), UDim2.new(0, 85, 0, 28), MainFrame)
addStroke(SleepBtn)
local FlossBtn = createButton("Floss", UDim2.new(0, 105, 0, 70), UDim2.new(0, 85, 0, 28), MainFrame)
addStroke(FlossBtn)
local HypeBtn = createButton("Hype", UDim2.new(0, 200, 0, 70), UDim2.new(0, 85, 0, 28), MainFrame)
addStroke(HypeBtn)

-- >> ( Dropdown System Helper )
local activeDropdown = nil
local function createDropdownUI(pos, size, placeholder, items, onClick)
    local container = Instance.new("Frame")
    container.Size = size
    container.Position = pos
    container.BackgroundTransparency = 1
    container.ZIndex = 5
    container.Parent = MainFrame
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.TextColor3 = Color3.fromRGB(200, 200, 200)
    button.TextSize = 13
    button.Font = Enum.Font.Gotham
    button.Text = "  " .. placeholder
    button.TextXAlignment = Enum.TextXAlignment.Left
    button.ZIndex = 5
    button.Parent = container
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = button
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
    arrow.TextSize = 12
    arrow.Font = Enum.Font.GothamBold
    arrow.ZIndex = 5
    arrow.Parent = button
    
    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 0, 125)
    list.Position = UDim2.new(0, 0, 1, 3)
    list.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 6
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    list.Parent = container
    
    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = list
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
    
    local function updateItems(newItems)
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        for i, item in ipairs(newItems) do
            local itemName = typeof(item) == "table" and item.Name or item
            local itemVal = typeof(item) == "table" and item.ID or item
            
            local itemBtn = Instance.new("TextButton")
            itemBtn.Size = UDim2.new(1, -4, 0, 25)
            itemBtn.BackgroundTransparency = 1
            itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemBtn.TextSize = 12
            itemBtn.Font = Enum.Font.Gotham
            itemBtn.Text = "  " .. itemName
            itemBtn.TextXAlignment = Enum.TextXAlignment.Left
            itemBtn.ZIndex = 6
            itemBtn.LayoutOrder = i
            itemBtn.Parent = list
            
            itemBtn.MouseEnter:Connect(function()
                itemBtn.BackgroundTransparency = 0.8
                itemBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            end)
            itemBtn.MouseLeave:Connect(function()
                itemBtn.BackgroundTransparency = 1
            end)
            
            itemBtn.MouseButton1Click:Connect(function()
                button.Text = "  " .. itemName
                list.Visible = false
                if activeDropdown == list then
                    activeDropdown = nil
                end
                onClick(itemVal, itemName)
            end)
        end
        list.CanvasSize = UDim2.new(0, 0, 0, #newItems * 25)
    end
    
    updateItems(items)
    
    button.MouseButton1Click:Connect(function()
        if list.Visible then
            list.Visible = false
            if activeDropdown == list then
                activeDropdown = nil
            end
        else
            if activeDropdown and activeDropdown ~= list then
                activeDropdown.Visible = false
            end
            list.Visible = true
            activeDropdown = list
        end
    end)
    
    return {
        Container = container,
        Button = button,
        List = list,
        UpdateItems = updateItems
    }
end

-- >> ( Dropdown Animation List )
local dropdown_animations = {
    {Name = "Mega Poop Aura", ID = "rbxassetid://120062749676884"},
    {Name = "Sleep", ID = "rbxassetid://10714360343"},
    {Name = "Floss", ID = "rbxassetid://10714340543"},
    {Name = "Hype", ID = "rbxassetid://10714369624"},
    {Name = "Hype Dance", ID = "rbxassetid://81108310619663"},
}

local PresetDropdownLabel = Instance.new("TextLabel")
PresetDropdownLabel.Size = UDim2.new(1, -20, 0, 20)
PresetDropdownLabel.Position = UDim2.new(0, 10, 0, 105)
PresetDropdownLabel.BackgroundTransparency = 1
PresetDropdownLabel.Text = "Select Animation (Copies ID):"
PresetDropdownLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PresetDropdownLabel.TextSize = 13
PresetDropdownLabel.Font = Enum.Font.Gotham
PresetDropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
PresetDropdownLabel.ZIndex = 4
PresetDropdownLabel.Parent = MainFrame

-- >> ( Static Controls - Repositioned to make room for dropdown )
local CustomAnimLabel = Instance.new("TextLabel")
CustomAnimLabel.Size = UDim2.new(1, -20, 0, 20)
CustomAnimLabel.Position = UDim2.new(0, 10, 0, 160)
CustomAnimLabel.BackgroundTransparency = 1
CustomAnimLabel.Text = "Custom Animation ID:"
CustomAnimLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
CustomAnimLabel.TextSize = 13
CustomAnimLabel.Font = Enum.Font.Gotham
CustomAnimLabel.TextXAlignment = Enum.TextXAlignment.Left
CustomAnimLabel.ZIndex = 3
CustomAnimLabel.Parent = MainFrame

local CustomInput = Instance.new("TextBox")
CustomInput.Size = UDim2.new(1, -20, 0, 30)
CustomInput.Position = UDim2.new(0, 10, 0, 180)
CustomInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CustomInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomInput.TextSize = 13
CustomInput.Font = Enum.Font.Gotham
CustomInput.Text = "15609995579"
CustomInput.PlaceholderText = "Enter Asset ID"
CustomInput.ZIndex = 3
CustomInput.Parent = MainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = CustomInput

local KeybindBtn = createButton("Anim Keybind (Hold): [ " .. play_keybind.Name .. " ]", UDim2.new(0, 10, 0, 215), UDim2.new(1, -20, 0, 30), MainFrame)

local KeybindStatusBtn = createButton("Status: Hold", UDim2.new(0, 10, 0, 250), UDim2.new(1, -20, 0, 30), MainFrame)
local statusStroke = Instance.new("UIStroke")
statusStroke.Color = Color3.fromRGB(255, 255, 0) -- Yellow for Hold
statusStroke.Thickness = 1.5
statusStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
statusStroke.Enabled = true
statusStroke.Parent = KeybindStatusBtn

local function updateKeybindStatusUI()
    if play_mode == "Hold" then
        KeybindStatusBtn.Text = "Status: Hold"
        statusStroke.Color = Color3.fromRGB(255, 255, 0) -- Yellow
        KeybindBtn.Text = "Anim Keybind (Hold): [ " .. play_keybind.Name .. " ]"
    else
        KeybindStatusBtn.Text = "Status: Toggle"
        statusStroke.Color = Color3.fromRGB(0, 255, 0) -- Green
        KeybindBtn.Text = "Anim Keybind (Toggle): [ " .. play_keybind.Name .. " ]"
    end
end

KeybindStatusBtn.MouseButton1Click:Connect(function()
    if play_mode == "Hold" then
        play_mode = "Toggle"
    else
        play_mode = "Hold"
    end
    updateKeybindStatusUI()
end)

local ToggleBtn = createButton("Play Animation (Toggle)", UDim2.new(0, 10, 0, 285), UDim2.new(1, -20, 0, 35), MainFrame)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
ToggleBtn.Font = Enum.Font.GothamBold

-- Custom Character UI Elements
local CustomCharBtn = createButton("Custom Character", UDim2.new(0, 10, 0, 330), UDim2.new(0, 140, 0, 30), MainFrame)
local CustomCharIcon = Instance.new("TextLabel")
CustomCharIcon.Size = UDim2.new(0, 30, 0, 30)
CustomCharIcon.Position = UDim2.new(0, 155, 0, 330)
CustomCharIcon.BackgroundTransparency = 1
CustomCharIcon.Text = "❌"
CustomCharIcon.TextSize = 18
CustomCharIcon.ZIndex = 3
CustomCharIcon.Parent = MainFrame

local CustomCharInput = Instance.new("TextBox")
CustomCharInput.Size = UDim2.new(1, -20, 0, 30)
CustomCharInput.Position = UDim2.new(0, 10, 0, 365)
CustomCharInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CustomCharInput.TextColor3 = Color3.fromRGB(255, 255, 255)
CustomCharInput.TextSize = 13
CustomCharInput.Font = Enum.Font.Gotham
CustomCharInput.PlaceholderText = "Enter Player User ID"
CustomCharInput.Text = ""
CustomCharInput.ZIndex = 3
CustomCharInput.Parent = MainFrame
local charInputCorner = Instance.new("UICorner")
charInputCorner.CornerRadius = UDim.new(0, 4)
charInputCorner.Parent = CustomCharInput

local AnimPackBtn = createButton("Animation Pack", UDim2.new(0, 10, 0, 400), UDim2.new(0, 140, 0, 30), MainFrame)
local AnimPackIcon = Instance.new("TextLabel")
AnimPackIcon.Size = UDim2.new(0, 30, 0, 30)
AnimPackIcon.Position = UDim2.new(0, 155, 0, 400)
AnimPackIcon.BackgroundTransparency = 1
AnimPackIcon.Text = "❌"
AnimPackIcon.TextSize = 18
AnimPackIcon.ZIndex = 3
AnimPackIcon.Parent = MainFrame

local hide_ui_keybind = Enum.KeyCode.RightShift
local setting_hide_keybind = false
local HideKeybindBtn = createButton("Menu Keybind: [ " .. hide_ui_keybind.Name .. " ]", UDim2.new(0, 10, 0, 440), UDim2.new(1, -20, 0, 35), MainFrame)
HideKeybindBtn.Font = Enum.Font.GothamBold
HideKeybindBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)

-- >> ( Config System UI Setup )
local ConfigDivider = Instance.new("Frame")
ConfigDivider.Size = UDim2.new(1, 0, 0, 1)
ConfigDivider.Position = UDim2.new(0, 0, 0, 485)
ConfigDivider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ConfigDivider.BorderSizePixel = 0
ConfigDivider.ZIndex = 3
ConfigDivider.Parent = MainFrame

local ConfigLabel = Instance.new("TextLabel")
ConfigLabel.Size = UDim2.new(1, -20, 0, 20)
ConfigLabel.Position = UDim2.new(0, 10, 0, 490)
ConfigLabel.BackgroundTransparency = 1
ConfigLabel.Text = "Config System:"
ConfigLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
ConfigLabel.TextSize = 13
ConfigLabel.Font = Enum.Font.Gotham
ConfigLabel.TextXAlignment = Enum.TextXAlignment.Left
ConfigLabel.ZIndex = 3
ConfigLabel.Parent = MainFrame

local ConfigNameInput = Instance.new("TextBox")
ConfigNameInput.Size = UDim2.new(1, -20, 0, 28)
ConfigNameInput.Position = UDim2.new(0, 10, 0, 510)
ConfigNameInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ConfigNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
ConfigNameInput.TextSize = 12
ConfigNameInput.Font = Enum.Font.Gotham
ConfigNameInput.PlaceholderText = "Enter Config Name to Create"
ConfigNameInput.Text = ""
ConfigNameInput.ZIndex = 3
ConfigNameInput.Parent = MainFrame
local configInputCorner = Instance.new("UICorner")
configInputCorner.CornerRadius = UDim.new(0, 4)
configInputCorner.Parent = ConfigNameInput

-- Config list dropdown and action buttons will be created below after logic is setup.

-- >> ( Logic Connections )
local activePreset = nil

local function updateActivePreset(activeBtn)
    SleepBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    FlossBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    HypeBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    
    if SleepBtn:FindFirstChild("UIStroke") then SleepBtn.UIStroke.Enabled = false end
    if FlossBtn:FindFirstChild("UIStroke") then FlossBtn.UIStroke.Enabled = false end
    if HypeBtn:FindFirstChild("UIStroke") then HypeBtn.UIStroke.Enabled = false end
    
    if activeBtn then
        activeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if activeBtn:FindFirstChild("UIStroke") then
            activeBtn.UIStroke.Enabled = true
        end
    end
end

local function applyCustomId()
    if activePreset == nil then
        local id = CustomInput.Text:match("%d+")
        if id then
            animation_id = "rbxassetid://" .. id
        end
    end
end

local function handlePresetClick(btn, animIdStr)
    if activePreset == btn then
        activePreset = nil
        updateActivePreset(nil)
        applyCustomId()
    else
        activePreset = btn
        animation_id = animIdStr
        updateActivePreset(btn)
    end
    if is_playing then play_animation() end
end

SleepBtn.MouseButton1Click:Connect(function()
    handlePresetClick(SleepBtn, "rbxassetid://10714360343")
end)

FlossBtn.MouseButton1Click:Connect(function()
    handlePresetClick(FlossBtn, "rbxassetid://10714340543")
end)

HypeBtn.MouseButton1Click:Connect(function()
    handlePresetClick(HypeBtn, "rbxassetid://10714369624")
end)

CustomInput.FocusLost:Connect(function()
    local id = CustomInput.Text:match("%d+")
    if id then
        activePreset = nil
        updateActivePreset(nil)
        animation_id = "rbxassetid://" .. id
        if is_playing then play_animation() end
    end
end)

KeybindBtn.MouseButton1Click:Connect(function()
    setting_keybind = true
    KeybindBtn.Text = "Press any key..."
    KeybindBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)

HideKeybindBtn.MouseButton1Click:Connect(function()
    setting_hide_keybind = true
    HideKeybindBtn.Text = "Press any key..."
    HideKeybindBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
end)

local function startAnim()
    is_playing = true
    ToggleBtn.Text = "Stop Animation"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    applyCustomId()
    play_animation()
end

local function stopAnim()
    is_playing = false
    ToggleBtn.Text = "Play Animation (Toggle)"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    stop_animation()
end

ToggleBtn.MouseButton1Click:Connect(function()
    if is_playing then stopAnim() else startAnim() end
end)

-- Custom Character Toggle Helpers
local function setCustomCharState(active)
    custom_char_active = active
    if custom_char_active then
        CustomCharIcon.Text = "✅"
        CustomCharBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        local id = CustomCharInput.Text:match("%d+")
        if id then
            local desc = get_user_description(id)
            if desc then
                apply_description(desc)
            end
        end
        
        if custom_char_connection then custom_char_connection:Disconnect() end
        custom_char_connection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if custom_char_active and last_description then
                apply_description(last_description, true)
            end
        end)
    else
        CustomCharIcon.Text = "❌"
        CustomCharBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        
        if custom_char_connection then
            custom_char_connection:Disconnect()
            custom_char_connection = nil
        end
        
        -- revert to original
        local ok, result = pcall(function()
            if setthreadidentity then setthreadidentity(2) end
            return Players:GetHumanoidDescriptionFromUserId(LocalPlayer.UserId)
        end)
        if ok and result then
            apply_description(result)
        end
    end
end

CustomCharBtn.MouseButton1Click:Connect(function()
    setCustomCharState(not custom_char_active)
end)

-- Animation Pack Logic
local pack_animations = {
    ["Chest Pump"] = "rbxassetid://3189779152",
    ["Praying"] = "rbxassetid://3487719500",
    ["Greet"] = "rbxassetid://3189777795",
    ["Dance2"] = "rbxassetid://3189776546",
    ["Dance1"] = "rbxassetid://3189773368",
    ["Lay"] = "rbxassetid://3152378852",
    ["Lean"] = "rbxassetid://3152375249",
    ["T Pose"] = "rbxassetid://11710524200",
    ["Speed Blitz"] = "rbxassetid://11710541744",
    ["Griddy"] = "rbxassetid://11710529220",
    ["Rossy"] = "rbxassetid://11710527244",
    ["Sturdy"] = "rbxassetid://11710524717",
    ["The Default"] = "rbxassetid://11710522278"
}

local anim_pack_connections = {}
local anim_pack_char_added = nil

local function play_pack_animation(anim_name)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end

    stop_animation()

    local old = Instance.new("Animation")
    old.AnimationId = pack_animations[anim_name]
    local loaded = humanoid:LoadAnimation(old)
    loaded.Looped = (anim_name ~= "Chest Pump" and anim_name ~= "Praying" and anim_name ~= "Greet")
    table.insert(active_tracks, loaded)
    loaded:Play()
    old:Destroy()

    local move_connection = nil
    move_connection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
        loaded:Stop(0)
        if move_connection then
            move_connection:Disconnect()
            move_connection = nil
        end
    end)

    task.delay((loaded.Length > 0 and loaded.Length + 0.5) or 2, function()
        if move_connection and not loaded.IsPlaying then
            move_connection:Disconnect()
            move_connection = nil
            loaded:Stop(0)
        end
    end)
end

local function unlock_animation_packs()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local main_screen_gui = gui:WaitForChild("MainScreenGui", 5)
    if not main_screen_gui then return end

    local animation_pack = main_screen_gui:WaitForChild("AnimationPack", 5)
    local animation_plus_pack = main_screen_gui:WaitForChild("AnimationPlusPack", 5)

    if animation_pack and animation_plus_pack then
        animation_pack.Visible = true
        
        table.insert(anim_pack_connections, animation_pack.MouseButton1Click:Connect(function()
            animation_pack.ScrollingFrame.Visible = true
            animation_pack.CloseButton.Visible = true
            animation_plus_pack.Position = UDim2.new(-1, 0, 0.5, 12)
        end))

        table.insert(anim_pack_connections, animation_pack.CloseButton.MouseButton1Click:Connect(function()
            animation_pack.ScrollingFrame.Visible = false
            animation_pack.CloseButton.Visible = false
            animation_plus_pack.Position = UDim2.new(0, 0, 0.5, 12)
        end))

        for _, v in pairs(animation_pack.ScrollingFrame:GetChildren()) do
            if v:IsA("TextButton") then
                local animation = v.Text
                table.insert(anim_pack_connections, v.MouseButton1Click:Connect(function()
                    play_pack_animation(animation)
                end))
            end
        end

        animation_plus_pack.Visible = true

        table.insert(anim_pack_connections, animation_plus_pack.MouseButton1Click:Connect(function()
            animation_plus_pack.ScrollingFrame.Visible = true
            animation_plus_pack.CloseButton.Visible = true
            animation_pack.Position = UDim2.new(-1, 0, 0.5, -12)
        end))

        table.insert(anim_pack_connections, animation_plus_pack.CloseButton.MouseButton1Click:Connect(function()
            animation_plus_pack.ScrollingFrame.Visible = false
            animation_plus_pack.CloseButton.Visible = false
            animation_pack.Position = UDim2.new(0, 0, 0.5, -12)
        end))

        for _, v in pairs(animation_plus_pack.ScrollingFrame:GetChildren()) do
            if v:IsA("TextButton") then
                local animation = v.Text
                table.insert(anim_pack_connections, v.MouseButton1Click:Connect(function()
                    play_pack_animation(animation)
                end))
            end
        end
    end
end

local function lock_animation_packs()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local main_screen_gui = gui:FindFirstChild("MainScreenGui")
    if not main_screen_gui then return end
    local animation_pack = main_screen_gui:FindFirstChild("AnimationPack")
    local animation_plus_pack = main_screen_gui:FindFirstChild("AnimationPlusPack")
    
    if animation_pack then animation_pack.Visible = false end
    if animation_plus_pack then animation_plus_pack.Visible = false end
end

local anim_pack_active = false
local function setAnimPackState(active)
    anim_pack_active = active
    
    for _, conn in pairs(anim_pack_connections) do
        conn:Disconnect()
    end
    table.clear(anim_pack_connections)
    
    if anim_pack_char_added then
        anim_pack_char_added:Disconnect()
        anim_pack_char_added = nil
    end

    if anim_pack_active then
        AnimPackIcon.Text = "✅"
        AnimPackBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        
        anim_pack_char_added = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(1)
            if anim_pack_active then
                unlock_animation_packs()
            end
        end)
        
        unlock_animation_packs()
    else
        AnimPackIcon.Text = "❌"
        AnimPackBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        
        lock_animation_packs()
    end
end

AnimPackBtn.MouseButton1Click:Connect(function()
    setAnimPackState(not anim_pack_active)
end)

-- >> ( Config File Logic )
local savedConfigs = {}
local selectedConfig = ""

local function refreshConfigs()
    table.clear(savedConfigs)
    if isfolder and listfiles then
        if not isfolder("AnimationPlayerConfigs") then
            pcall(makefolder, "AnimationPlayerConfigs")
        end
        local ok, files = pcall(listfiles, "AnimationPlayerConfigs")
        if ok and files then
            for _, file in ipairs(files) do
                local name = file:match("([^/\\]+)%.json$")
                if name then
                    table.insert(savedConfigs, name)
                end
            end
        end
    end
end

local function saveConfig(name)
    if not name or name == "" then return end
    if makefolder then
        pcall(makefolder, "AnimationPlayerConfigs")
    end
    
    local configData = {
        animation_id = animation_id,
        play_keybind = play_keybind.Name,
        hide_ui_keybind = hide_ui_keybind.Name,
        custom_char_id = CustomCharInput.Text,
        custom_char_active = custom_char_active,
        anim_pack_active = anim_pack_active,
        play_mode = play_mode
    }
    
    local success, json = pcall(function()
        return HttpService:JSONEncode(configData)
    end)
    
    if success and json and writefile then
        pcall(writefile, "AnimationPlayerConfigs/" .. name .. ".json", json)
    end
end

local function loadConfig(name)
    if not name or name == "" then return end
    local filePath = "AnimationPlayerConfigs/" .. name .. ".json"
    if isfile and isfile(filePath) and readfile then
        local success, content = pcall(readfile, filePath)
        if success and content then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if decodeSuccess and data then
                -- Apply animation ID
                if data.animation_id then
                    animation_id = data.animation_id
                    local idOnly = animation_id:match("%d+")
                    CustomInput.Text = idOnly or ""
                    if is_playing then
                        play_animation()
                    end
                end
                
                -- Apply play keybind
                if data.play_keybind then
                    pcall(function()
                        play_keybind = Enum.KeyCode[data.play_keybind]
                        KeybindBtn.Text = "Anim Keybind (Hold): [ " .. play_keybind.Name .. " ]"
                    end)
                end
                
                -- Apply hide keybind
                if data.hide_ui_keybind then
                    pcall(function()
                        hide_ui_keybind = Enum.KeyCode[data.hide_ui_keybind]
                        HideKeybindBtn.Text = "Hide UI Keybind: [ " .. hide_ui_keybind.Name .. " ]"
                    end)
                end
                
                -- Apply Custom Character ID
                if data.custom_char_id then
                    CustomCharInput.Text = data.custom_char_id
                end
                
                -- Apply Custom Character Active
                if data.custom_char_active ~= nil then
                    setCustomCharState(data.custom_char_active)
                end
                
                -- Apply Anim Pack Active
                if data.anim_pack_active ~= nil then
                    setAnimPackState(data.anim_pack_active)
                end
                
                -- Apply play mode
                if data.play_mode then
                    play_mode = data.play_mode
                    updateKeybindStatusUI()
                end
            end
        end
    end
end

-- >> ( Setup Dropdowns )
local AnimDropdown = createDropdownUI(
    UDim2.new(0, 10, 0, 125),
    UDim2.new(1, -20, 0, 28),
    "Select Animation...",
    dropdown_animations,
    function(val, name)
        -- Auto copy to clipboard
        if setclipboard then
            setclipboard(val)
        elseif toclipboard then
            toclipboard(val)
        end
        
        -- Apply ID
        animation_id = val
        local idOnly = val:match("%d+")
        CustomInput.Text = idOnly or ""
        
        activePreset = nil
        updateActivePreset(nil)
        
        if is_playing then
            play_animation()
        end
    end
)

local ConfigDropdown
ConfigDropdown = createDropdownUI(
    UDim2.new(0, 10, 0, 545),
    UDim2.new(1, -20, 0, 28),
    "Select Config...",
    savedConfigs,
    function(name)
        selectedConfig = name
        loadConfig(name)
    end
)

local function updateConfigDropdownList()
    refreshConfigs()
    if ConfigDropdown then
        ConfigDropdown.UpdateItems(savedConfigs)
    end
end

-- >> ( Config Action Buttons )
local CreateBtn = createButton("Create", UDim2.new(0, 10, 0, 580), UDim2.new(0, 65, 0, 28), MainFrame)
local UpdateBtn = createButton("Update", UDim2.new(0, 80, 0, 580), UDim2.new(0, 65, 0, 28), MainFrame)
local DeleteBtn = createButton("Delete", UDim2.new(0, 150, 0, 580), UDim2.new(0, 65, 0, 28), MainFrame)
local RefreshBtn = createButton("Refresh", UDim2.new(0, 220, 0, 580), UDim2.new(0, 65, 0, 28), MainFrame)

CreateBtn.MouseButton1Click:Connect(function()
    local name = ConfigNameInput.Text:gsub("%s+", "")
    if name == "" then return end
    saveConfig(name)
    ConfigNameInput.Text = ""
    updateConfigDropdownList()
end)

UpdateBtn.MouseButton1Click:Connect(function()
    if selectedConfig ~= "" then
        saveConfig(selectedConfig)
    end
end)

DeleteBtn.MouseButton1Click:Connect(function()
    if selectedConfig ~= "" then
        local filePath = "AnimationPlayerConfigs/" .. selectedConfig .. ".json"
        if delfile and isfile and isfile(filePath) then
            pcall(delfile, filePath)
        end
        selectedConfig = ""
        ConfigDropdown.Button.Text = "  Select Config..."
        updateConfigDropdownList()
    end
end)

RefreshBtn.MouseButton1Click:Connect(function()
    updateConfigDropdownList()
end)

-- >> ( Keybind Processing )
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if setting_keybind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            play_keybind = input.KeyCode
            if play_mode == "Hold" then
                KeybindBtn.Text = "Anim Keybind (Hold): [ " .. input.KeyCode.Name .. " ]"
            else
                KeybindBtn.Text = "Anim Keybind (Toggle): [ " .. input.KeyCode.Name .. " ]"
            end
            KeybindBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            setting_keybind = false
        end
        return
    end

    if setting_hide_keybind then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            hide_ui_keybind = input.KeyCode
            HideKeybindBtn.Text = "Menu Keybind: [ " .. input.KeyCode.Name .. " ]"
            HideKeybindBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
            setting_hide_keybind = false
        end
        return
    end

    if gameProcessed then return end

    if input.KeyCode == hide_ui_keybind then
        if MainFrame.Visible or OpenBtn.Visible then
            MainFrame.Visible = false
            OpenBtn.Visible = false
        else
            MainFrame.Visible = true
            OpenBtn.Visible = false
        end
    end

    if input.KeyCode == play_keybind then
        if play_mode == "Hold" then
            startAnim()
        else
            if is_playing then
                stopAnim()
            else
                startAnim()
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if not setting_keybind and input.KeyCode == play_keybind then
        if play_mode == "Hold" then
            stopAnim()
        end
    end
end)

-- Dragging Logic
local function makeDraggable(guiObj)
    local dragging, dragInput, dragStart, startPos
    
    guiObj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObj.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    guiObj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame)
makeDraggable(OpenBtn)

-- Init
updateActivePreset(nil)
updateConfigDropdownList()
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    stop_animation()
    if custom_char_connection then custom_char_connection:Disconnect() end
    if anim_pack_char_added then anim_pack_char_added:Disconnect() end
    if anim_pack_connections then
        for _, conn in pairs(anim_pack_connections) do conn:Disconnect() end
    end
end)
