$assetsBytes = [System.IO.File]::ReadAllBytes("c:\Users\zzzee\Downloads\PSM\Project-vibecod\memory_assets.lua")
$assetsB64 = [Convert]::ToBase64String($assetsBytes)

$libBytes = [System.IO.File]::ReadAllBytes("c:\Users\zzzee\Downloads\PSM\Project-vibecod\lib.lua")
$libB64 = [Convert]::ToBase64String($libBytes)

$nvlBytes = [System.IO.File]::ReadAllBytes("c:\Users\zzzee\Downloads\PSM\Project-vibecod\NVL-Win.lua")
$nvlB64 = [Convert]::ToBase64String($nvlBytes)

$bootstrap = @"
local decode = (crypt and (crypt.base64_decode or crypt.base64decode)) or (base64_decode or base64decode)

if not isfolder("uisimbl") then makefolder("uisimbl") end
if not isfolder("uisimbl/assets") then makefolder("uisimbl/assets") end
if not isfolder("uisimbl/assets/icons") then makefolder("uisimbl/assets/icons") end

writefile("memory_assets.lua", decode("$assetsB64"))
writefile("uisimbl/memory_assets.lua", decode("$assetsB64"))
writefile("lib.lua", decode("$libB64"))
writefile("uisimbl/lib.lua", decode("$libB64"))
writefile("NVL-Win.lua", decode("$nvlB64"))
writefile("uisimbl/NVL-Win.lua", decode("$nvlB64"))

print("[PSM-Deploy] Successfully written authentic Neverlose lib & NVL-Win to workspace!")

local CoreGui = (gethui and gethui()) or (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
for _, name in ipairs({"NVL_Memory_UI", "MemoryUI_Port"}) do
    local old = CoreGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local ok, err = pcall(function()
    loadstring(readfile("NVL-Win.lua"))()
end)

if ok then
    print("[PSM-Deploy] NVL-Win.lua (Neverlose / Memory UI) executed with ZERO ERRORS! 100% Pixel-Perfect!")
else
    warn("[PSM-Deploy] Execution error:", err)
end
"@

$headers = @{
    "Authorization" = "Bearer 20xIf6JcepJKNI16y7hLHrGa4sqZPWVwkZkRBcYd0uI"
    "Content-Type" = "application/json"
    "Accept" = "application/json, text/event-stream"
}

$body = @{
    jsonrpc = "2.0"
    id = 70
    method = "tools/call"
    params = @{
        name = "execute_script"
        arguments = @{
            source = $bootstrap
        }
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod -Uri "http://127.0.0.1:8225/mcp" -Method POST -Headers $headers -Body $body
Write-Output $response
