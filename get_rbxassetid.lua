-- Auto Get RbxAssetId - Silent Mode
-- Execute = auto copy rbxassetid vào clipboard

local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local DEFAULT_CATALOG_IDS = {
    120062749676884, -- Mega Poop Aura
    -- Thêm ID khác vào đây
}

local function copyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    end
end

local function getRbxAssetId(catalogId)
    -- Method 1: game:GetObjects
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. tostring(catalogId))
    end)

    if ok and objects and #objects > 0 then
        for _, obj in pairs(objects) do
            local function search(o, depth)
                if depth > 10 then return nil end
                if o:IsA("Animation") and o.AnimationId ~= "" then
                    return o.AnimationId
                end
                if o:IsA("KeyframeSequence") then
                    return "rbxassetid://" .. tostring(catalogId)
                end
                pcall(function()
                    if o.AnimationId and o.AnimationId ~= "" then
                        return o.AnimationId
                    end
                end)
                for _, child in pairs(o:GetChildren()) do
                    local r = search(child, (depth or 0) + 1)
                    if r then return r end
                end
                return nil
            end
            local result = search(obj, 0)
            if result then return result end
        end
        return "rbxassetid://" .. tostring(catalogId)
    end

    -- Method 2: InsertService
    local ok2, model = pcall(function()
        return InsertService:LoadAsset(catalogId)
    end)

    if ok2 and model then
        local found = nil
        local function findAnim(parent, depth)
            if depth > 10 or found then return end
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("Animation") and child.AnimationId ~= "" then
                    found = child.AnimationId
                    return
                end
                if child:IsA("KeyframeSequence") then
                    found = "rbxassetid://" .. tostring(catalogId)
                    return
                end
                findAnim(child, depth + 1)
            end
        end
        findAnim(model, 0)
        pcall(function() model:Destroy() end)
        if found then return found end
    end

    -- Method 3: MarketplaceService
    local ok3, info = pcall(function()
        return MarketplaceService:GetProductInfo(catalogId)
    end)

    if ok3 and info then
        local animTypes = {[24] = true, [61] = true}
        if animTypes[info.AssetTypeId] then
            return "rbxassetid://" .. tostring(catalogId)
        end
    end

    -- Fallback
    return "rbxassetid://" .. tostring(catalogId)
end

-- Auto run + copy
local results = {}
for _, id in ipairs(DEFAULT_CATALOG_IDS) do
    local assetId = getRbxAssetId(id)
    table.insert(results, assetId)
end

if #results == 1 then
    copyToClipboard(results[1])
else
    copyToClipboard(table.concat(results, "\n"))
end

-- Global helper (dùng sau khi execute)
getgenv().getAssetId = function(id)
    local r = getRbxAssetId(id)
    copyToClipboard(r)
    return r
end
