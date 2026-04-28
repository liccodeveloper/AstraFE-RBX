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
pcall(function()
    loadstring(game:HttpGet("CHECKQUEST_MODULE_URL_HERE"))()
end)

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

-- Tween-based teleport
local CurrentTween = nil

function StopTween(state)
    if not state and CurrentTween then
        pcall(function() CurrentTween:Cancel() end)
        CurrentTween = nil
    end
end

function topos(targetCFrame)
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if CurrentTween then
            pcall(function() CurrentTween:Cancel() end)
        end

        local dist = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 300
        local t = math.max(dist / speed, 0.01)

        CurrentTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        CurrentTween:Play()

        while CurrentTween and CurrentTween.PlaybackState == Enum.PlaybackState.Playing do
            task.wait()
        end

        if CurrentTween then
            pcall(function() CurrentTween:Cancel() end)
        end
        CurrentTween = nil
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
-- Auto Farm Level (background loop)
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while task.wait() do
        if _G.AutoFarm then
            pcall(function()
                local questGui = LocalPlayer.PlayerGui.Main.Quest
                local questText = questGui.Container.QuestTitle.Title.Text

                if typeof(CheckQuest) == "function" then CheckQuest() end

                if not questGui.Visible then
                    StartBring = false
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and CFrameQuest then
                        if (hrp.Position - CFrameQuest.Position).Magnitude > 20 then
                            topos(CFrameQuest)
                        else
                            ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, LevelQuest)
                        end
                    end
                else
                    if NameMon and not string.find(questText, NameMon) then
                        StartBring = false
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("AbandonQuest")
                    else
                        if Mon and game:GetService("Workspace").Enemies:FindFirstChild(Mon) then
                            for _, mob in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
                                if mob.Name == Mon and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
                                    repeat
                                        task.wait()
                                        EquipWeapon(_G.SelectWeapon)
                                        AutoHaki()
                                        PosMon = mob.HumanoidRootPart.CFrame
                                        topos(mob.HumanoidRootPart.CFrame * CFrame.new(0, 30, 0))
                                        mob.HumanoidRootPart.CanCollide = false
                                        mob.Humanoid.WalkSpeed = 0
                                        mob.Head.CanCollide = false
                                        mob.HumanoidRootPart.Size = Vector3.new(70, 70, 70)
                                        StartBring = true
                                        MonFarm = mob.Name
                                        game:GetService("VirtualUser"):CaptureController()
                                        game:GetService("VirtualUser"):Button1Down(Vector2.new(1280, 672))
                                    until not _G.AutoFarm or mob.Humanoid.Health <= 0 or not mob.Parent or not questGui.Visible
                                end
                            end
                        else
                            if CFrameMon then
                                topos(CFrameMon)
                            end
                            StartBring = false
                        end
                    end
                end
            end)
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
-- Noclip for farming (keeps character uncollidable)
-- ═══════════════════════════════════════════════════
task.spawn(function()
    pcall(function()
        RunService.Stepped:Connect(function()
            if _G.AutoFarm or _G.BringMonster then
                pcall(function()
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
            end
        end)
    end)
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
