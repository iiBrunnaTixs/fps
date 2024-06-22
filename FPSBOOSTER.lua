if not _G.Ignore then
    _G.Ignore = {} -- Add Instances to this table to ignore them (e.g. _G.Ignore = {workspace.Map, workspace.Map2})
end
if not _G.WaitPerAmount then
    _G.WaitPerAmount = 500 -- Set Higher or Lower depending on your computer's performance
end
if _G.SendNotifications == nil then
    _G.SendNotifications = true -- Set to false if you don't want notifications
end
if _G.ConsoleLogs == nil then
    _G.ConsoleLogs = false -- Set to true if you want console logs (mainly for debugging)
end

local Players, Lighting, StarterGui, MaterialService = game:GetService("Players"), game:GetService("Lighting"), game:GetService("StarterGui"), game:GetService("MaterialService")
local ME, CanBeEnabled = Players.LocalPlayer, {"ParticleEmitter", "Trail", "Smoke", "Fire", "Sparkles"}
local function PartOfCharacter(Instance)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= ME and v.Character and Instance:IsDescendantOf(v.Character) then
            return true
        end
    end
    return false
end
local function DescendantOfIgnore(Instance)
    for _, v in pairs(_G.Ignore) do
        if Instance:IsDescendantOf(v) then
            return true
        end
    end
    return false
end
local function CheckIfBad(Instance)
    if not Instance:IsDescendantOf(Players) and
       (_G.Settings.Players["Ignore Others"] and not PartOfCharacter(Instance) or not _G.Settings.Players["Ignore Others"]) and
       (_G.Settings.Players["Ignore Me"] and ME.Character and not Instance:IsDescendantOf(ME.Character) or not _G.Settings.Players["Ignore Me"]) and
       (_G.Settings.Players["Ignore Tools"] and not Instance:IsA("BackpackItem") and not Instance:FindFirstAncestorWhichIsA("BackpackItem") or not _G.Settings.Players["Ignore Tools"]) and
       (not DescendantOfIgnore(Instance))
    then
        if Instance:IsA("DataModelMesh") then
            if _G.Settings.Meshes.NoMesh and Instance:IsA("SpecialMesh") then
                Instance.MeshId = ""
            end
            if _G.Settings.Meshes.NoTexture and Instance:IsA("SpecialMesh") then
                Instance.TextureId = ""
            end
            if _G.Settings.Meshes.Destroy or _G.Settings["No Meshes"] then
                Instance:Destroy()
            end
        elseif Instance:IsA("FaceInstance") then
            if _G.Settings.Images.Invisible then
                Instance.Transparency = 1
                Instance.Shiny = 1
            end
            if _G.Settings.Images.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("ShirtGraphic") then
            if _G.Settings.Images.Invisible then
                Instance.Graphic = ""
            end
            if _G.Settings.Images.Destroy then
                Instance:Destroy()
            end
        elseif table.find(CanBeEnabled, Instance.ClassName) then
            if _G.Settings.Particles.Invisible then
                Instance.Enabled = false
            end
            if _G.Settings.Particles.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("PostEffect") and _G.Settings.Other["No Camera Effects"] then
            Instance.Enabled = false
        elseif Instance:IsA("Explosion") then
            if _G.Settings.Explosions.Smaller then
                Instance.BlastPressure = 1
                Instance.BlastRadius = 1
            end
            if _G.Settings.Explosions.Invisible then
                Instance.BlastPressure = 1
                Instance.BlastRadius = 1
                Instance.Visible = false
            end
            if _G.Settings.Explosions.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("Clothing") or Instance:IsA("SurfaceAppearance") or Instance:IsA("BaseWrap") then
            if _G.Settings.Other["No Clothes"] then
                Instance:Destroy()
            end
        elseif Instance:IsA("BasePart") and not Instance:IsA("MeshPart") then
            if _G.Settings.Other["Low Quality Parts"] then
                Instance.Material = Enum.Material.Plastic
                Instance.Reflectance = 0
            end
        elseif Instance:IsA("TextLabel") and Instance:IsDescendantOf(workspace) then
            if _G.Settings.TextLabels.LowerQuality then
                Instance.Font = Enum.Font.SourceSans
                Instance.TextScaled = false
                Instance.RichText = false
                Instance.TextSize = 14
            end
            if _G.Settings.TextLabels.Invisible then
                Instance.Visible = false
            end
            if _G.Settings.TextLabels.Destroy then
                Instance:Destroy()
            end
        elseif Instance:IsA("Model") then
            if _G.Settings.Other["Low Quality Models"] then
                Instance.LevelOfDetail = 1
            end
        elseif Instance:IsA("MeshPart") then
            if _G.Settings.MeshParts.LowerQuality then
                Instance.RenderFidelity = 2
                Instance.Reflectance = 0
                Instance.Material = Enum.Material.Plastic
            end
            if _G.Settings.MeshParts.Invisible then
                Instance.Transparency = 1
                Instance.RenderFidelity = 2
                Instance.Reflectance = 0
                Instance.Material = Enum.Material.Plastic
            end
            if _G.Settings.MeshParts.NoTexture then
                Instance.TextureID = ""
            end
            if _G.Settings.MeshParts.NoMesh then
                Instance.MeshId = ""
            end
            if _G.Settings.MeshParts.Destroy then
                Instance:Destroy()
            end
        end
    end
end

local function Notify(title, text, duration)
    if _G.SendNotifications then
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration,
            Button1 = "Okay"
        })
    end
end

local function Log(message)
    if _G.ConsoleLogs then
        warn(message)
    end
end

if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

if not _G.Settings then
    _G.Settings = {
        Players = {
            ["Ignore Me"] = true,
            ["Ignore Others"] = true,
            ["Ignore Tools"] = true
        },
        Meshes = {
            NoMesh = true,
            NoTexture = true,
            Destroy = true
        },
        Images = {
            Invisible = true,
            Destroy = true
        },
        Explosions = {
            Smaller = true,
            Invisible = true,
            Destroy = true
        },
        Particles = {
            Invisible = true,
            Destroy = true
        },
        TextLabels = {
            LowerQuality = true,
            Invisible = true,
            Destroy = true
        },
        MeshParts = {
            LowerQuality = true,
            Invisible = true,
            NoTexture = true,
            NoMesh = true,
            Destroy = true
        },
        Other = {
            ["FPS Cap"] = 240,
            ["No Camera Effects"] = true,
            ["No Clothes"] = true,
            ["Low Water Graphics"] = true,
            ["No Shadows"] = true,
            ["Low Rendering"] = true,
            ["Low Quality Parts"] = true,
            ["Low Quality Models"] = true,
            ["Reset Materials"] = true,
            ["Lower Quality MeshParts"] = true
        }
    }
end

Notify("discord.gg/rips", "Loading FPS Booster...", math.huge)

coroutine.wrap(pcall)(function()
    if _G.Settings.Other["Low Water Graphics"] then
        repeat task.wait() until workspace:FindFirstChildOfClass("Terrain")
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 0
        if sethiddenproperty then
            sethiddenproperty(terrain, "Decoration", false)
        else
            Notify("discord.gg/rips", "Your exploit does not support sethiddenproperty, please use a different exploit.", 5)
            Log("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
        Notify("discord.gg/rips", "Low Water Graphics Enabled", 5)
        Log("Low Water Graphics Enabled")
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.Other["No Shadows"] then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.ShadowSoftness = 0
        if sethiddenproperty then
            sethiddenproperty(Lighting, "Technology", 2)
        else
            Notify("discord.gg/rips", "Your exploit does not support sethiddenproperty, please use a different exploit.", 5)
            Log("Your exploit does not support sethiddenproperty, please use a different exploit.")
        end
        Notify("discord.gg/rips", "No Shadows Enabled", 5)
        Log("No Shadows Enabled")
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.Other["Low Rendering"] then
        settings().Rendering.QualityLevel = "Level01"
        settings().Rendering.MeshPartDetailLevel = "Level01"
        Notify("discord.gg/rips", "Low Rendering Enabled", 5)
        Log("Low Rendering Enabled")
    end
end)

coroutine.wrap(pcall)(function()
    if _G.Settings.Other["FPS Cap"] then
        setfpscap(_G.Settings.Other["FPS Cap"])
        Notify("discord.gg/rips", "FPS Cap Set to " .. tostring(_G.Settings.Other["FPS Cap"]), 5)
        Log("FPS Cap Set to " .. tostring(_G.Settings.Other["FPS Cap"]))
    end
end)

local DescendantAddedConnection, AncestryChangedConnection
local function SetupConnections()
    DescendantAddedConnection = game.DescendantAdded:Connect(function(Instance)
        CheckIfBad(Instance)
    end)
    AncestryChangedConnection = game.AncestryChanged:Connect(function(Instance)
        CheckIfBad(Instance)
    end)
end

local function DisconnectConnections()
    if DescendantAddedConnection then
        DescendantAddedConnection:Disconnect()
        DescendantAddedConnection = nil
    end
    if AncestryChangedConnection then
        AncestryChangedConnection:Disconnect()
        AncestryChangedConnection = nil
    end
end

local function OptimizeGame()
    for _, Instance in ipairs(game:GetDescendants()) do
        CheckIfBad(Instance)
        if _G.WaitPerAmount > 0 and _ % _G.WaitPerAmount == 0 then
            task.wait()
        end
    end
end

DisconnectConnections()
SetupConnections()
OptimizeGame()

Notify("discord.gg/rips", "FPS Booster Loaded!", 5)
Log("FPS Booster Loaded!")
