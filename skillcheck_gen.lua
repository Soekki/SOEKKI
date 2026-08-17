-- Script Path: game:GetService("Workspace").nekTUYT["Skillcheck-gen"]
-- Took 0.43s to decompile.
-- Executor: Xeno (v1.3.60)

-- https://lua.expert/
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkillCheckEvent = ReplicatedStorage.Remotes.Generator:WaitForChild("SkillCheckEvent")
local SkillCheckResultEvent = ReplicatedStorage.Remotes.Generator:WaitForChild("SkillCheckResultEvent")
local KingScourgeStart = ReplicatedStorage.Remotes.KillerPerks.kingscourge:WaitForChild("KingScourgeStart")
local KingScourgeHit = ReplicatedStorage.Remotes.KillerPerks.kingscourge:WaitForChild("KingScourgeHit")
local KingScourgeEnd = ReplicatedStorage.Remotes.KillerPerks.kingscourge:WaitForChild("KingScourgeEnd")
local LocalPlayer = game.Players.LocalPlayer
local v1 = LocalPlayer:GetAttribute("clickhold") or false
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Frame = PlayerGui:WaitForChild("ProgressPromptGui"):WaitForChild("Frame")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Check = PlayerGui:WaitForChild("SkillCheckPromptGui"):WaitForChild("Check")
local Line = Check:WaitForChild("Line")
local Goal = Check:WaitForChild("Goal")
local RunService = game:GetService("RunService")
local v2 = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
local v3 = false
local v4 = nil
local v5 = nil
local v6 = nil
local v7 = false
local v8 = false
local v9 = false
local v10 = 0
local v11 = 0
local v12 = nil
local v13 = nil
local v14 = nil
local Sound = script:WaitForChild("Sound")
local Confirm = script:WaitForChild("Confirm")
local Great = script:WaitForChild("Great")

local function getOppositeScourgeGoal(p1) --[[ getOppositeScourgeGoal | Line: 52 ]]
    return p1 + math.random(135, 225) - 130.5
end

local v15 = nil
local v16 = nil
local v17 = nil

-- SOEKKI: управляется из Modification -> Auto Perfect Skill Check
local function isAutoPerfectEnabled()
    return _G.AutoPerfectSkillCheck == true
end

local function stopMovementCheck() --[[ stopMovementCheck | Line: 61 | Upvalues: v15 (ref) ]]
    if not v15 then
        return
    end

    v15:Disconnect()
    v15 = nil
end

local function stopHpCheck() --[[ stopHpCheck | Line: 68 | Upvalues: v16 (ref) ]]
    if not v16 then
        return
    end

    v16:Disconnect()
    v16 = nil
end

local function stopActionTagCheck() --[[ stopActionTagCheck | Line: 75 | Upvalues: v17 (ref) ]]
    if not v17 then
        return
    end

    v17:Disconnect()
    v17 = nil
end

local function cleanupSkillCheck() --[[ cleanupSkillCheck | Line: 82 | Upvalues: v15 (ref), v16 (ref), v17 (ref) ]]
    if v15 then
        v15:Disconnect()
        v15 = nil
    end

    if v16 then
        v16:Disconnect()
        v16 = nil
    end

    if not v17 then
        return
    end

    v17:Disconnect()
    v17 = nil
end

local function handleSkillCheck(p1) --[[ handleSkillCheck | Line: 88 | Upvalues: v3 (ref), v7 (ref), v4 (ref), Check (copy), Line (copy), Goal (copy), SkillCheckResultEvent (copy), v5 (ref), v6 (ref), v15 (ref), v16 (ref), v17 (ref), Frame (copy), LocalPlayer (copy), Great (copy), Confirm (copy), CollectionService (copy) ]]
    if not v3 or v7 then
        return
    end

    v7 = true

    if v4 then
        v4:Cancel()
        v4 = nil
    end

    if p1 == "neutral" then
        v3 = false
        Check.Visible = false
        Line.Rotation = 0
        Goal.Rotation = 0
        SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)
    else
        task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
            v3 = false
            Check.Visible = false
            Line.Rotation = 0
            Goal.Rotation = 0
        end)

        if p1 == "fail" then
            Frame.Visible = false
            SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
            LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)
        else
            local Rotation = Line.Rotation
            local v2 = 116 + Goal.Rotation
            local v32 = 159 + Goal.Rotation

            if 102 + Goal.Rotation <= Rotation and Rotation <= v2 then
                SkillCheckResultEvent:FireServer("success", 1, v5, v6)
                Great:Play()
            elseif v2 < Rotation and Rotation <= v32 then
                SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)
                Confirm:Play()
            else
                Frame.Visible = false
                SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
                CollectionService:RemoveTag(v6, "GeneratorPoint")
                LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)
            end
        end
    end

    if v15 then
        v15:Disconnect()
        v15 = nil
    end

    if v16 then
        v16:Disconnect()
        v16 = nil
    end

    if not v17 then
        return
    end

    v17:Disconnect()
    v17 = nil
end

local function endScourgeMode(p1) --[[ endScourgeMode | Line: 141 | Upvalues: v9 (ref), v3 (ref), v7 (ref), LocalPlayer (copy), CollectionService (copy), v14 (ref), v4 (ref), Check (copy), Line (copy), Goal (copy), v15 (ref), v16 (ref), v17 (ref) ]]
    if not v9 then
        return
    end

    v9 = false
    v3 = false
    v7 = true

    if p1 then
        local v1 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CheckInterractable")

        if v1 then
            v1:SetAttribute("isRepairing", false)
        end

        local Character = LocalPlayer.Character

        if Character then
            local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

            if HumanoidRootPart then
                CollectionService:RemoveTag(HumanoidRootPart, "doing action")
                HumanoidRootPart.Anchored = false
            end
        end
    end

    if v14 then
        v14:Cancel()
        v14 = nil
    end

    if v4 then
        v4:Cancel()
        v4 = nil
    end

    Check.Visible = false
    Line.Rotation = 0
    Goal.Rotation = 0

    if v15 then
        v15:Disconnect()
        v15 = nil
    end

    if v16 then
        v16:Disconnect()
        v16 = nil
    end

    if not v17 then
        return
    end

    v17:Disconnect()
    v17 = nil
end

local function startMovementCheck() --[[ startMovementCheck | Line: 169 | Upvalues: v1 (copy), v15 (ref), RunService (copy), v3 (ref), v7 (ref), v2 (copy), v9 (ref), KingScourgeHit (copy), v13 (ref), endScourgeMode (copy), v8 (ref), v4 (ref), Check (copy), Line (copy), Goal (copy), SkillCheckResultEvent (copy), v5 (ref), v6 (ref), v16 (ref), v17 (ref), Frame (copy), LocalPlayer (copy) ]]
    if not v1 then
        return
    end

    if not v15 then
        v15 = RunService.Heartbeat:Connect(function() --[[ Line: 173 | Upvalues: v1 (ref), v15 (ref), v3 (ref), v7 (ref), v2 (ref), v9 (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref), v8 (ref), v4 (ref), Check (ref), Line (ref), Goal (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), v16 (ref), v17 (ref), Frame (ref), LocalPlayer (ref) ]]
            if v1 then
                if v1 and (v3 and not v7) then
                    local v12 = v2:GetMoveVector()

                    if v12.X ~= 0 or v12.Y ~= 0 then
                        if v9 then
                            local v22 = v2:GetMoveVector()

                            if v22.X == 0 and v22.Y == 0 then
                                return
                            end

                            KingScourgeHit:FireServer(v13, "fail")
                            endScourgeMode()

                            return
                        elseif v8 then
                            if v3 and not v7 then
                                v7 = true

                                if v4 then
                                    v4:Cancel()
                                    v4 = nil
                                end

                                task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
                                    v3 = false
                                    Check.Visible = false
                                    Line.Rotation = 0
                                    Goal.Rotation = 0
                                end)
                                Frame.Visible = false
                                SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
                                LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

                                if v15 then
                                    v15:Disconnect()
                                    v15 = nil
                                end

                                if v16 then
                                    v16:Disconnect()
                                    v16 = nil
                                end

                                if v17 then
                                    v17:Disconnect()
                                    v17 = nil
                                end
                            end
                        elseif v3 and not v7 then
                            v7 = true

                            if v4 then
                                v4:Cancel()
                                v4 = nil
                            end

                            v3 = false
                            Check.Visible = false
                            Line.Rotation = 0
                            Goal.Rotation = 0
                            SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)

                            if v15 then
                                v15:Disconnect()
                                v15 = nil
                            end

                            if v16 then
                                v16:Disconnect()
                                v16 = nil
                            end

                            if v17 then
                                v17:Disconnect()
                                v17 = nil
                            end
                        end
                    end
                end

                if v3 or not v15 then
                    return
                end
            elseif not v15 then
                return
            end

            v15:Disconnect()
            v15 = nil
        end)
    end
end

local function startHpCheck() --[[ startHpCheck | Line: 204 | Upvalues: v16 (ref), LocalPlayer (copy), v3 (ref), v7 (ref), v9 (ref), KingScourgeHit (copy), v13 (ref), endScourgeMode (copy), v4 (ref), Check (copy), Line (copy), Goal (copy), SkillCheckResultEvent (copy), v5 (ref), v6 (ref), v15 (ref), v17 (ref) ]]
    if v16 then
        return
    end

    local v1 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")

    if v1 then
        local Health = v1.Health

        v16 = v1:GetPropertyChangedSignal("Health"):Connect(function() --[[ Line: 212 | Upvalues: v3 (ref), v7 (ref), v1 (copy), v9 (ref), Health (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref), v4 (ref), Check (ref), Line (ref), Goal (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), v15 (ref), v16 (ref), v17 (ref) ]]
            if not v3 or v7 then
                return
            end

            local Health2 = v1.Health

            if v9 then
                if not (v1.Health < Health) then
                    Health = v1.Health

                    return
                end

                KingScourgeHit:FireServer(v13, "fail")
                endScourgeMode()
                Health = v1.Health
            else
                if Health2 < Health and (v3 and not v7) then
                    v7 = true

                    if v4 then
                        v4:Cancel()
                        v4 = nil
                    end

                    v3 = false
                    Check.Visible = false
                    Line.Rotation = 0
                    Goal.Rotation = 0
                    SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)

                    if v15 then
                        v15:Disconnect()
                        v15 = nil
                    end

                    if v16 then
                        v16:Disconnect()
                        v16 = nil
                    end

                    if v17 then
                        v17:Disconnect()
                        v17 = nil
                    end
                end

                Health = Health2
            end
        end)
    end
end

local function startActionTagCheck() --[[ startActionTagCheck | Line: 231 | Upvalues: v17 (ref), LocalPlayer (copy), v3 (ref), v7 (ref), v9 (ref), KingScourgeHit (copy), v13 (ref), endScourgeMode (copy), v4 (ref), Check (copy), Line (copy), Goal (copy), Frame (copy), SkillCheckResultEvent (copy), v5 (ref), v6 (ref), v15 (ref), v16 (ref) ]]
    if v17 then
        return
    end

    local Character = LocalPlayer.Character

    if not Character then
        return
    end

    if not Character:GetAttribute("Locked") then
        v17 = Character:GetAttributeChangedSignal("Locked"):Connect(function() --[[ Line: 248 | Upvalues: Character (copy), v3 (ref), v7 (ref), v9 (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref), v4 (ref), Check (ref), Line (ref), Goal (ref), Frame (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), LocalPlayer (ref), v15 (ref), v16 (ref), v17 (ref) ]]
            if not Character:GetAttribute("Locked") then
                return
            end

            if not v3 or v7 then
                return
            end

            if v9 then
                KingScourgeHit:FireServer(v13, "fail")
                endScourgeMode(true)

                return
            end

            if not v3 then
                return
            end

            if v7 then
                return
            end

            v7 = true

            if v4 then
                v4:Cancel()
                v4 = nil
            end

            task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
                v3 = false
                Check.Visible = false
                Line.Rotation = 0
                Goal.Rotation = 0
            end)
            Frame.Visible = false
            SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
            LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

            if v15 then
                v15:Disconnect()
                v15 = nil
            end

            if v16 then
                v16:Disconnect()
                v16 = nil
            end

            if not v17 then
                return
            end

            v17:Disconnect()
            v17 = nil
        end)

        return
    end

    if not v3 or v7 then
        return
    end

    if v9 then
        KingScourgeHit:FireServer(v13, "fail")
        endScourgeMode(true)

        return
    end

    if not v3 then
        return
    end

    if v7 then
        return
    end

    v7 = true

    if v4 then
        v4:Cancel()
        v4 = nil
    end

    task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
        v3 = false
        Check.Visible = false
        Line.Rotation = 0
        Goal.Rotation = 0
    end)
    Frame.Visible = false
    SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
    LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

    if v15 then
        v15:Disconnect()
        v15 = nil
    end

    if v16 then
        v16:Disconnect()
        v16 = nil
    end

    if not v17 then
        return
    end

    v17:Disconnect()
    v17 = nil
end

local function tweenLineRotation() --[[ Line: 262 ]]
    v7 = false

    if isAutoPerfectEnabled() then
        -- Perfect-зона оригинала: Goal+102 .. Goal+116.
        -- Останавливаем линию в центре Perfect и сразу отправляем success.
        local perfectRotation = Goal.Rotation + 109
        Line.Rotation = perfectRotation
        v7 = true
        v3 = false
        Check.Visible = false
        SkillCheckResultEvent:FireServer("success", 1, v5, v6)

        if v15 then
            v15:Disconnect()
            v15 = nil
        end
        if v16 then
            v16:Disconnect()
            v16 = nil
        end
        if v17 then
            v17:Disconnect()
            v17 = nil
        end
        return
    end

    local v1 = if LocalPlayer.Character then LocalPlayer.Character:GetAttribute("skillcheckspeed") or 1 else 1

    v4 = TweenService:Create(Line, TweenInfo.new(math.max(1.3 * v1, 0.4), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
        Rotation = 360
    })
    v4.Completed:Connect(function() --[[ Line: 271 | Upvalues: v3 (ref), v7 (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), LocalPlayer (ref), Check (ref), Line (ref), Goal (ref), v15 (ref), v16 (ref), v17 (ref) ]]
        if not v3 or v7 then
            return
        end

        SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
        LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)
        v3 = false
        Check.Visible = false
        Line.Rotation = 0
        Goal.Rotation = 0

        if v15 then
            v15:Disconnect()
            v15 = nil
        end

        if v16 then
            v16:Disconnect()
            v16 = nil
        end

        if not v17 then
            return
        end

        v17:Disconnect()
        v17 = nil
    end)
    v4:Play()
end

local function startScourgeSpin() --[[ startScourgeSpin | Line: 287 | Upvalues: v9 (ref), LocalPlayer (copy), v11 (ref), v10 (ref), Line (copy), v14 (ref), TweenService (copy), KingScourgeHit (copy), v13 (ref), endScourgeMode (copy) ]]
    if not v9 then
        return
    end

    local v2 = v11 - v10 + 1

    v14 = TweenService:Create(Line, TweenInfo.new(math.max(1.3 * (if LocalPlayer.Character then LocalPlayer.Character:GetAttribute("skillcheckspeed") or 1 else 1) * (if v2 == 1 then 1.4 elseif v2 == 2 then 1.2 else 1), 0.4), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
        Rotation = Line.Rotation + 360
    })
    v14.Completed:Connect(function(p1) --[[ Line: 309 | Upvalues: v9 (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref) ]]
        if p1 ~= Enum.PlaybackState.Completed then
            return
        end

        if v9 then
            KingScourgeHit:FireServer(v13, "fail")
            endScourgeMode()
        end
    end)
    v14:Play()
end

KingScourgeStart.OnClientEvent:Connect(function(p1, p2, p3) --[[ Line: 318 | Upvalues: v9 (ref), LocalPlayer (copy), v10 (ref), v11 (ref), v12 (ref), v13 (ref), v5 (ref), v6 (ref), v3 (ref), v7 (ref), v8 (ref), Check (copy), Line (copy), Goal (copy), Sound (copy), v1 (copy), v15 (ref), RunService (copy), v2 (copy), KingScourgeHit (copy), endScourgeMode (copy), v4 (ref), SkillCheckResultEvent (copy), v16 (ref), v17 (ref), Frame (copy), startHpCheck (copy), startActionTagCheck (copy), startScourgeSpin (copy) ]]
    if v9 then
        return
    end

    local v14 = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("CheckInterractable")

    if not (v14 and v14:GetAttribute("isRepairing")) then
        return
    end

    v9 = true
    v10 = p3 or 1
    v11 = p3 or 1
    v12 = p1
    v13 = p2
    v5 = p1
    v6 = p2
    v3 = true
    v7 = false
    v8 = true
    Check.Visible = true
    Line.Rotation = 0
    Goal.Rotation = math.random(0, 200)
    Sound:Play()

    if not v1 or v15 then
        startHpCheck()
        startActionTagCheck()
        startScourgeSpin()

        return
    end

    v15 = RunService.Heartbeat:Connect(function() --[[ Line: 173 | Upvalues: v1 (ref), v15 (ref), v3 (ref), v7 (ref), v2 (ref), v9 (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref), v8 (ref), v4 (ref), Check (ref), Line (ref), Goal (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), v16 (ref), v17 (ref), Frame (ref), LocalPlayer (ref) ]]
        if v1 then
            if v1 and (v3 and not v7) then
                local v12 = v2:GetMoveVector()

                if v12.X ~= 0 or v12.Y ~= 0 then
                    if v9 then
                        local v22 = v2:GetMoveVector()

                        if v22.X == 0 and v22.Y == 0 then
                            return
                        end

                        KingScourgeHit:FireServer(v13, "fail")
                        endScourgeMode()

                        return
                    elseif v8 then
                        if v3 and not v7 then
                            v7 = true

                            if v4 then
                                v4:Cancel()
                                v4 = nil
                            end

                            task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
                                v3 = false
                                Check.Visible = false
                                Line.Rotation = 0
                                Goal.Rotation = 0
                            end)
                            Frame.Visible = false
                            SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
                            LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

                            if v15 then
                                v15:Disconnect()
                                v15 = nil
                            end

                            if v16 then
                                v16:Disconnect()
                                v16 = nil
                            end

                            if v17 then
                                v17:Disconnect()
                                v17 = nil
                            end
                        end
                    elseif v3 and not v7 then
                        v7 = true

                        if v4 then
                            v4:Cancel()
                            v4 = nil
                        end

                        v3 = false
                        Check.Visible = false
                        Line.Rotation = 0
                        Goal.Rotation = 0
                        SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)

                        if v15 then
                            v15:Disconnect()
                            v15 = nil
                        end

                        if v16 then
                            v16:Disconnect()
                            v16 = nil
                        end

                        if v17 then
                            v17:Disconnect()
                            v17 = nil
                        end
                    end
                end
            end

            if v3 or not v15 then
                return
            end
        elseif not v15 then
            return
        end

        v15:Disconnect()
        v15 = nil
    end)
    startHpCheck()
    startActionTagCheck()
    startScourgeSpin()
end)
KingScourgeEnd.OnClientEvent:Connect(function(p1) --[[ Line: 346 | Upvalues: v13 (ref), endScourgeMode (copy) ]]
    if v13 ~= p1 then
        return
    end

    endScourgeMode()
end)

local Character = LocalPlayer.Character

SkillCheckEvent.OnClientEvent:Connect(function(p1, p2) --[[ Line: 355 | Upvalues: Character (copy), v6 (ref), v5 (ref), v3 (ref), v7 (ref), v8 (ref), Check (copy), Line (copy), Goal (copy), Sound (copy), v1 (copy), v15 (ref), RunService (copy), v2 (copy), v9 (ref), KingScourgeHit (copy), v13 (ref), endScourgeMode (copy), v4 (ref), SkillCheckResultEvent (copy), v16 (ref), v17 (ref), Frame (copy), LocalPlayer (copy), startHpCheck (copy), startActionTagCheck (copy), tweenLineRotation (copy) ]]
    local CheckInterractable = Character:FindFirstChild("CheckInterractable")

    print(CheckInterractable)

    if not CheckInterractable:GetAttribute("isRepairing") then
        return
    end

    v6 = p2
    v5 = p1
    v3 = true
    v7 = false
    v8 = false
    Check.Visible = false
    Line.Rotation = 0
    Goal.Rotation = 0
    Sound:Play()

    if not v1 or v15 then
        startHpCheck()
        startActionTagCheck()
        task.delay(0.5, function() --[[ Line: 378 | Upvalues: v3 (ref), v8 (ref), Check (ref), Goal (ref), tweenLineRotation (ref) ]]
            if v3 then
                v8 = true
                Check.Visible = true
                Goal.Rotation = math.random(0, 200)
                tweenLineRotation()
            end
        end)

        return
    end

    v15 = RunService.Heartbeat:Connect(function() --[[ Line: 173 | Upvalues: v1 (ref), v15 (ref), v3 (ref), v7 (ref), v2 (ref), v9 (ref), KingScourgeHit (ref), v13 (ref), endScourgeMode (ref), v8 (ref), v4 (ref), Check (ref), Line (ref), Goal (ref), SkillCheckResultEvent (ref), v5 (ref), v6 (ref), v16 (ref), v17 (ref), Frame (ref), LocalPlayer (ref) ]]
        if v1 then
            if v1 and (v3 and not v7) then
                local v12 = v2:GetMoveVector()

                if v12.X ~= 0 or v12.Y ~= 0 then
                    if v9 then
                        local v22 = v2:GetMoveVector()

                        if v22.X == 0 and v22.Y == 0 then
                            return
                        end

                        KingScourgeHit:FireServer(v13, "fail")
                        endScourgeMode()

                        return
                    elseif v8 then
                        if v3 and not v7 then
                            v7 = true

                            if v4 then
                                v4:Cancel()
                                v4 = nil
                            end

                            task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
                                v3 = false
                                Check.Visible = false
                                Line.Rotation = 0
                                Goal.Rotation = 0
                            end)
                            Frame.Visible = false
                            SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
                            LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

                            if v15 then
                                v15:Disconnect()
                                v15 = nil
                            end

                            if v16 then
                                v16:Disconnect()
                                v16 = nil
                            end

                            if v17 then
                                v17:Disconnect()
                                v17 = nil
                            end
                        end
                    elseif v3 and not v7 then
                        v7 = true

                        if v4 then
                            v4:Cancel()
                            v4 = nil
                        end

                        v3 = false
                        Check.Visible = false
                        Line.Rotation = 0
                        Goal.Rotation = 0
                        SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)

                        if v15 then
                            v15:Disconnect()
                            v15 = nil
                        end

                        if v16 then
                            v16:Disconnect()
                            v16 = nil
                        end

                        if v17 then
                            v17:Disconnect()
                            v17 = nil
                        end
                    end
                end
            end

            if v3 or not v15 then
                return
            end
        elseif not v15 then
            return
        end

        v15:Disconnect()
        v15 = nil
    end)
    startHpCheck()
    startActionTagCheck()
    task.delay(0.5, function() --[[ Line: 378 | Upvalues: v3 (ref), v8 (ref), Check (ref), Goal (ref), tweenLineRotation (ref) ]]
        if v3 then
            v8 = true
            Check.Visible = true
            Goal.Rotation = math.random(0, 200)
            tweenLineRotation()
        end
    end)
end)
UserInputService.InputBegan:Connect(function(p1, p2) --[[ Line: 389 | Upvalues: v3 (ref), v9 (ref), Line (copy), Goal (copy), v10 (ref), endScourgeMode (copy), v14 (ref), startScourgeSpin (copy), KingScourgeHit (copy), v13 (ref), Great (copy), Confirm (copy), handleSkillCheck (copy) ]]
    if p2 then
        return
    end

    if p1.KeyCode ~= Enum.KeyCode.Space then
        return
    end

    if not v3 then
        return
    end

    if not v9 then
        handleSkillCheck("success")

        return
    end

    local Rotation = Line.Rotation
    local v1 = 102 + Goal.Rotation
    local v2 = 116 + Goal.Rotation
    local v32 = 159 + Goal.Rotation

    local function advanceZone() --[[ advanceZone | Line: 400 | Upvalues: v10 (ref), endScourgeMode (ref), Goal (ref), Line (ref), v14 (ref), startScourgeSpin (ref) ]]
        v10 = v10 - 1

        if v10 <= 0 then
            endScourgeMode()

            return true
        end

        Goal.Rotation = Line.Rotation + math.random(135, 225) - 130.5

        if not v14 then
            startScourgeSpin()

            return false
        end

        v14:Cancel()
        v14 = nil
        startScourgeSpin()

        return false
    end

    if v1 <= Rotation and Rotation <= v2 then
        KingScourgeHit:FireServer(v13, "success")
        Great:Play()
        v10 = v10 - 1

        local v4

        if v10 <= 0 then
            endScourgeMode()
            v4 = true
        else
            Goal.Rotation = Line.Rotation + math.random(135, 225) - 130.5

            if v14 then
                v14:Cancel()
                v14 = nil
            end

            startScourgeSpin()
            v4 = false
        end

        if v4 then
        end
    elseif v2 < Rotation and Rotation <= v32 then
        KingScourgeHit:FireServer(v13, "neutral")
        Confirm:Play()
        v10 = v10 - 1

        local v5

        if v10 <= 0 then
            endScourgeMode()
            v5 = true
        else
            Goal.Rotation = Line.Rotation + math.random(135, 225) - 130.5

            if v14 then
                v14:Cancel()
                v14 = nil
            end

            startScourgeSpin()
            v5 = false
        end

        if v5 then
        end
    else
        KingScourgeHit:FireServer(v13, "fail")
        endScourgeMode()
    end
end)
UserInputService.InputEnded:Connect(function(p1, p2) --[[ Line: 436 | Upvalues: v3 (ref), v1 (copy), v8 (ref), v7 (ref), v4 (ref), Check (copy), Line (copy), Goal (copy), SkillCheckResultEvent (copy), v5 (ref), v6 (ref), v15 (ref), v16 (ref), v17 (ref), Frame (copy), LocalPlayer (copy) ]]
    if p2 then
        return
    end

    if p1.UserInputType ~= Enum.UserInputType.MouseButton1 or (not v3 or v1) then
        return
    end

    if v8 then
        if not v3 then
            return
        end

        if v7 then
            return
        end

        v7 = true

        if v4 then
            v4:Cancel()
            v4 = nil
        end

        task.delay(0.1, function() --[[ Line: 107 | Upvalues: v3 (ref), Check (ref), Line (ref), Goal (ref) ]]
            v3 = false
            Check.Visible = false
            Line.Rotation = 0
            Goal.Rotation = 0
        end)
        Frame.Visible = false
        SkillCheckResultEvent:FireServer("fail", -10, v5, v6)
        LocalPlayer.Character.CheckInterractable:SetAttribute("isRepairing", false)

        if v15 then
            v15:Disconnect()
            v15 = nil
        end

        if v16 then
            v16:Disconnect()
            v16 = nil
        end

        if not v17 then
            return
        end

        v17:Disconnect()
        v17 = nil
    else
        if not v3 then
            return
        end

        if v7 then
            return
        end

        v7 = true

        if v4 then
            v4:Cancel()
            v4 = nil
        end

        v3 = false
        Check.Visible = false
        Line.Rotation = 0
        Goal.Rotation = 0
        SkillCheckResultEvent:FireServer("neutral", 0, v5, v6)

        if v15 then
            v15:Disconnect()
            v15 = nil
        end

        if v16 then
            v16:Disconnect()
            v16 = nil
        end

        if v17 then
            v17:Disconnect()
            v17 = nil
        end
    end
end)
