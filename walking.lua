-- Roblox PC Walking Script (Silent & Bypass)
-- Keybind: Right Shift (ShiftRight) để bật/tắt đi bộ

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local WalkSpeedValue = 8 -- Tốc độ khi đi bộ (có thể chỉnh tùy ý)
local WalkingEnabled = false
local OriginalSpeed = 16

-- Bypass/Spoof WalkSpeed detection
local mt = getrawmetatable(game)
local oldIndex = mt.__index
local oldNewIndex = mt.__newindex
setreadonly(mt, false)

mt.__index = newcclosure(function(self, key)
    if not checkcaller() and self:IsA("Humanoid") and key == "WalkSpeed" then
        return OriginalSpeed
    end
    return oldIndex(self, key)
end)

mt.__newindex = newcclosure(function(self, key, value)
    if not checkcaller() and self:IsA("Humanoid") and key == "WalkSpeed" then
        OriginalSpeed = value
        if WalkingEnabled then
            return oldNewIndex(self, key, WalkSpeedValue)
        end
    end
    return oldNewIndex(self, key, value)
end)

setreadonly(mt, true)

-- Liên tục giữ tốc độ đi bộ khi bật
RunService.PostSimulation:Connect(function()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if WalkingEnabled then
            if humanoid.WalkSpeed ~= WalkSpeedValue then
                humanoid.WalkSpeed = WalkSpeedValue
            end
        else
            -- Trả lại tốc độ cũ khi tắt đi bộ
            if humanoid.WalkSpeed == WalkSpeedValue then
                humanoid.WalkSpeed = OriginalSpeed
            end
        end
    end
end)

-- Keybind toggle (Right Shift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if not WalkingEnabled then
                if humanoid.WalkSpeed ~= WalkSpeedValue then
                    OriginalSpeed = humanoid.WalkSpeed
                end
            end
        end
        WalkingEnabled = not WalkingEnabled
    end
end)
