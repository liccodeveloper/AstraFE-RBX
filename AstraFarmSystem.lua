-- ═══════════════════════════════════════════════════════════════
-- AstraFarmSystem.lua
-- Module: Select Tool, Auto Farm Level, Fast Attack, Bring Mob
-- Loaded via: loadstring(game:HttpGet("URL"))()
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════
-- State Variables
-- ═══════════════════════════════════════════════════
_G.SelectWeapon = _G.SelectWeapon or "Melee"
_G.AutoFarm = false
_G.AutoAttack = false
_G.BringMonster = false
_G.NotAutoEquip = false

StartBring = false
MonFarm = ""
PosMon = CFrame.new(0, 0, 0)
SelectMonster = nil

World1, World2, World3 = false, false, false
if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then
    World1 = true
elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then
    World2 = true
elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then
    World3 = true
end

-- ═══════════════════════════════════════════════════
-- Load CheckQuest Module (Level Tables)
-- ═══════════════════════════════════════════════════
local ok, err = pcall(function()
    local code = game:HttpGet("https://github.com/liccodeveloper/AstraFE-RBX/raw/refs/heads/main/AstraCheckQuest.lua")
    if not code or code == "" then
        warn("[Astra] CheckQuest: Empty response from GitHub")
        return
    end
    -- Strip UTF-8 BOM if present (PowerShell adds it)
    if string.byte(code, 1) == 239 and string.byte(code, 2) == 187 and string.byte(code, 3) == 191 then
        code = code:sub(4)
    end
    local fn, loadErr = loadstring(code)
    if not fn then
        warn("[Astra] CheckQuest syntax error:", loadErr)
        return
    end
    fn()
    warn("[Astra] CheckQuest loaded successfully!")
end)
if not ok then
    warn("[Astra] CheckQuest load failed:", err)
end

-- ═══════════════════════════════════════════════════
-- Helper Functions
-- ═══════════════════════════════════════════════════
function AutoHaki()
    pcall(function()
        local char = LocalPlayer.Character
        if char and not char:FindFirstChild("HasBuso") then
            ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
        end
    end)
end

function EquipWeapon(weaponName)
    pcall(function()
        if not weaponName then return end
        if _G.NotAutoEquip then return end
        local tool = LocalPlayer.Backpack:FindFirstChild(weaponName)
        if tool then
            LocalPlayer.Character.Humanoid:EquipTool(tool)
        end
    end)
end

function UnEquipWeapon(weaponName)
    pcall(function()
        if not weaponName then return end
        if LocalPlayer.Character:FindFirstChild(weaponName) then
            _G.NotAutoEquip = true
            task.wait(0.3)
            LocalPlayer.Character:FindFirstChild(weaponName).Parent = LocalPlayer.Backpack
            task.wait(0.1)
            _G.NotAutoEquip = false
        end
    end)
end

-- Tween-based teleport (Part-sync method)
local CurrentTween = nil
local TweenPart = nil
local TweenSync = nil

function StopTween(state)
    if not state then
        pcall(function()
            if CurrentTween then CurrentTween:Cancel() end
            if TweenSync then TweenSync:Disconnect() end
            if TweenPart then TweenPart:Destroy() end
        end)
        CurrentTween = nil
        TweenSync = nil
        TweenPart = nil
    end
end

function topos(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        StopTween(false)

        -- Create invisible anchored part to tween
        local pt = Instance.new("Part")
        pt.Name = "AstraFarmTween"
        pt.Size = Vector3.new(1, 1, 1)
        pt.Anchored = true
        pt.Transparency = 1
        pt.CanCollide = false
        pt.CFrame = hrp.CFrame
        pt.Parent = char
        TweenPart = pt

        -- Sync HRP to the tweened part
        TweenSync = RunService.Stepped:Connect(function()
            pcall(function()
                if char and hrp and pt and pt.Parent then
                    hrp.CFrame = pt.CFrame
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        end)

        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 300
        local t = math.max(dist / speed, 0.1)

        CurrentTween = TweenService:Create(pt, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        CurrentTween:Play()
        CurrentTween.Completed:Wait()

        StopTween(false)
    end)
end

-- ═══════════════════════════════════════════════════
-- Select Tool Resolver (background loop)
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local sel = _G.SelectWeapon
            if sel == "Melee" then
                for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if t.ToolTip == "Melee" then _G.SelectWeapon = t.Name end
                end
            elseif sel == "Sword" then
                for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if t.ToolTip == "Sword" then _G.SelectWeapon = t.Name end
                end
            elseif sel == "Gun" then
                for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if t.ToolTip == "Gun" then _G.SelectWeapon = t.Name end
                end
            elseif sel == "Fruit" or sel == "Blox Fruit" then
                for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
                    if t.ToolTip == "Blox Fruit" then _G.SelectWeapon = t.Name end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════
-- Helper: Find quest NPC CFrame in workspace
-- ═══════════════════════════════════════════════════
function FindQuestNPC(questName)
    local result = nil
    pcall(function()
        for _, npc in pairs(workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                local head = npc:FindFirstChild("Head")
                if head then
                    local dialog = head:FindFirstChildOfClass("Dialog")
                    local billboard = head:FindFirstChildOfClass("BillboardGui")
                    if dialog or billboard then
                        -- Check if this NPC name relates to our quest
                        if npc:FindFirstChild("Humanoid") then
                            result = npc.HumanoidRootPart.CFrame
                        end
                    end
                end
            end
        end
    end)
    return result
end

-- ═══════════════════════════════════════════════════
-- Auto Farm Level (background loop)
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait(0.1) do
        if _G.AutoFarm then
            local ok, err = pcall(function()
                -- Resolve quest data for current level
                if typeof(CheckQuest) == "function" then
                    CheckQuest()
                else
                    warn("[Astra] CheckQuest not loaded!")
                    return
                end

                if not Mon or not NameQuest then
                    warn("[Astra] No mob/quest for level. Mon=", tostring(Mon), "Quest=", tostring(NameQuest), "Level=", tostring(MyLevel))
                    return
                end

                warn("[Astra] Farming:", Mon, "| Quest:", NameQuest, "| Level:", MyLevel)

                local char = LocalPlayer.Character
                if not char then warn("[Astra] No character") return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then warn("[Astra] No HRP") return end

                local questGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
                if not questGui then warn("[Astra] No Main GUI") return end
                questGui = questGui:FindFirstChild("Quest")
                if not questGui then warn("[Astra] No Quest GUI") return end

                local questVisible = questGui.Visible
                local questText = ""
                pcall(function()
                    questText = questGui.Container.QuestTitle.Title.Text
                end)

                if not questVisible then
                    -- No active quest: go accept one
                    StartBring = false
                    warn("[Astra] Quest NOT visible. CFrameQuest=", tostring(CFrameQuest ~= nil), "NameQuest=", NameQuest, "LevelQuest=", LevelQuest)
                    if CFrameQuest then
                        local dist = (hrp.Position - CFrameQuest.Position).Magnitude
                        warn("[Astra] Distance to quest NPC:", math.floor(dist))
                        if dist > 20 then
                            topos(CFrameQuest)
                        else
                            warn("[Astra] Accepting quest...")
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
                        end
                    else
                        warn("[Astra] No CFrame, accepting quest directly...")
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
                    end
                else
                    -- Quest active
                    if NameMon and questText ~= "" and not string.find(questText, NameMon) then
                        -- Wrong quest, abandon
                        StartBring = false
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
                    else
                        -- Find and attack the target mob
                        local foundMob = false
                        for _, mob in pairs(workspace.Enemies:GetChildren()) do
                            if mob.Name == Mon and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                foundMob = true
                                repeat
                                    task.wait()
                                    EquipWeapon(_G.SelectWeapon)
                                    AutoHaki()
                                    PosMon = mob.HumanoidRootPart.CFrame
                                    topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, 20, 0))
                                    pcall(function()
                                        mob.HumanoidRootPart.CanCollide = false
                                        mob.Humanoid.WalkSpeed = 0
                                        mob.Head.CanCollide = false
                                        mob.HumanoidRootPart.Size = Vector3.new(70, 70, 70)
                                    end)
                                    StartBring = true
                                    MonFarm = mob.Name
                                    game:GetService("VirtualUser"):CaptureController()
                                    game:GetService("VirtualUser"):Button1Down(Vector2.new(1280, 672))
                                until not _G.AutoFarm or not mob.Parent or mob.Humanoid.Health <= 0 or not questGui.Visible
                                break
                            end
                        end

                        if not foundMob then
                            -- Mob not spawned yet, teleport to spawn area
                            if CFrameMon then
                                topos(CFrameMon)
                            end
                            StartBring = false
                        end
                    end
                end
            end)
            if not ok then
                warn("[Astra Farm Error]", err)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- Fast Attack (background loop)
-- ═══════════════════════════════════════════════════
local u4, u5 = nil, nil

-- Find the anti-cheat remote
pcall(function()
    local containers = {
        ReplicatedStorage.Util,
        ReplicatedStorage.Common,
        ReplicatedStorage.Remotes,
        ReplicatedStorage.Assets,
        ReplicatedStorage.FX,
    }
    for _, container in ipairs(containers) do
        pcall(function()
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                    u5 = child:GetAttribute("Id")
                    u4 = child
                end
            end
            container.ChildAdded:Connect(function(child)
                if child:IsA("RemoteEvent") and child:GetAttribute("Id") then
                    u5 = child:GetAttribute("Id")
                    u4 = child
                end
            end)
        end)
    end
end)

task.spawn(function()
    while task.wait(0.0001) do
        if _G.AutoAttack then
            pcall(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end

                local hitTargets = {}

                for _, folder in ipairs({workspace.Enemies, workspace.Characters}) do
                    pcall(function()
                        for _, enemy in ipairs(folder:GetChildren()) do
                            local eHrp = enemy:FindFirstChild("HumanoidRootPart")
                            local eHum = enemy:FindFirstChild("Humanoid")
                            if enemy ~= char and eHrp and eHum and eHum.Health > 0 and (eHrp.Position - hrp.Position).Magnitude <= 60 then
                                for _, part in ipairs(enemy:GetChildren()) do
                                    if part:IsA("BasePart") and (eHrp.Position - hrp.Position).Magnitude <= 60 then
                                        hitTargets[#hitTargets + 1] = {enemy, part}
                                    end
                                end
                            end
                        end
                    end)
                end

                local tool = char:FindFirstChildOfClass("Tool")
                if #hitTargets > 0 and tool and (tool:GetAttribute("WeaponType") == "Melee" or tool:GetAttribute("WeaponType") == "Sword") then
                    pcall(function()
                        require(ReplicatedStorage.Modules.Net):RemoteEvent("RegisterHit", true)
                        ReplicatedStorage.Modules.Net["RE/RegisterAttack"]:FireServer()

                        local head = hitTargets[1][1]:FindFirstChild("Head")
                        if head then
                            ReplicatedStorage.Modules.Net["RE/RegisterHit"]:FireServer(
                                head, hitTargets, {},
                                tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
                            )
                            if u4 and u5 then
                                cloneref(u4):FireServer(
                                    string.gsub("RE/RegisterHit", ".", function(c)
                                        return string.char(bit32.bxor(string.byte(c), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
                                    end),
                                    bit32.bxor(u5 + 909090, ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2),
                                    head, hitTargets
                                )
                            end
                        end
                    end)
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- Bring Mob (background loop)
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait() do
        pcall(function()
            if not _G.BringMonster then return end
            if typeof(CheckQuest) == "function" then CheckQuest() end

            for _, enemy in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
                if _G.BringMonster and (StartBring and enemy.Name == MonFarm or enemy.Name == Mon and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 and (enemy.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 320) then
                    if (enemy.Name == MonFarm or enemy.Name == Mon) and (enemy.HumanoidRootPart.Position - PosMon.Position).Magnitude <= 320 then
                        enemy.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
                        enemy.HumanoidRootPart.CFrame = PosMon
                        enemy.HumanoidRootPart.CanCollide = false
                        enemy.Head.CanCollide = false
                        if enemy.Humanoid:FindFirstChild("Animator") then
                            enemy.Humanoid.Animator:Destroy()
                        end
                        pcall(function()
                            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                        end)
                    end
                end
            end
        end)
    end
end)


-- ═══════════════════════════════════════════════════
-- Module Init: Creates UI elements on given tab
-- ═══════════════════════════════════════════════════
local FarmSystem = {}

function FarmSystem.Init(farmTab)
    farmTab:CreateSection("Combat & Farm")

    farmTab:CreateDropdown({
        Name        = "Select Tool",
        Description = "Choose weapon type for Auto Farm.",
        Options     = {"Melee", "Sword", "Gun", "Blox Fruit"},
        Default     = "Melee",
        Callback    = function(value)
            _G.SelectWeapon = value
        end,
    })

    farmTab:CreateToggle({
        Name        = "Auto Farm Level",
        Description = "Automatically farms mobs based on your level.",
        Default     = false,
        Callback    = function(state)
            _G.AutoFarm = state
            StopTween(_G.AutoFarm)
        end,
    })

    farmTab:CreateToggle({
        Name        = "Fast Attack",
        Description = "Sends rapid hit registration to the server.",
        Default     = false,
        Callback    = function(state)
            _G.AutoAttack = state
        end,
    })

    farmTab:CreateToggle({
        Name        = "Bring Mob",
        Description = "Teleports nearby mobs to your position.",
        Default     = false,
        Callback    = function(state)
            _G.BringMonster = state
        end,
    })
end

return FarmSystem
