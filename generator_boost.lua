-- generator_boost.lua
-- SOEKKI - Generator Repair Boost
--
-- Important:
-- This module uses the game's existing Generator.RepairEvent.
-- The server remains authoritative; this script cannot force a repair
-- value that the server rejects.
--
-- UI compatibility:
-- main_ui.lua currently does:
--     GeneratorBoost.Enabled = true
--     GeneratorBoost:Toggle()
-- so Toggle() below intentionally SYNCHRONIZES to Enabled instead of
-- blindly inverting it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================

local DEFAULT_MULTIPLIER = 5
local MIN_MULTIPLIER = 1
local MAX_MULTIPLIER = 20

-- Base interval between repair requests.
-- The actual server-side repair amount/rate is determined by the game.
local BASE_INTERVAL = 0.10

-- ============================================================
-- REMOTES
-- ============================================================

local function FindRemote(path)
    local current = ReplicatedStorage

    for part in string.gmatch(path, "[^.]+") do
        if not current then
            return nil
        end

        current = current:FindFirstChild(part)
    end

    return current
end

local RepairEvent =
    FindRemote("Remotes.Generator.RepairEvent")
    or FindRemote("Remotes.RepairEvent")
    or FindRemote("RepairEvent")
    or ReplicatedStorage:FindFirstChild("RepairEvent", true)

local RepairAnim =
    FindRemote("Remotes.Generator.RepairAnim")
    or FindRemote("Remotes.RepairAnim")
    or FindRemote("RepairAnim")
    or ReplicatedStorage:FindFirstChild("RepairAnim", true)

local RepairVFX =
    FindRemote("Remotes.Generator.RepairVFX")
    or FindRemote("Remotes.RepairVFX")
    or FindRemote("RepairVFX")
    or ReplicatedStorage:FindFirstChild("RepairVFX", true)

print("[GeneratorBoost] 🔧 Found RepairEvent:", RepairEvent and "✅" or "❌")
print("[GeneratorBoost] 🔧 Found RepairAnim:", RepairAnim and "✅" or "❌")
print("[GeneratorBoost] 🔧 Found RepairVFX:", RepairVFX and "✅" or "❌")

-- RepairCommit is intentionally not used: it is not present in the
-- supplied Generator remote list.
local RepairCommit = nil

-- ============================================================
-- STATE
-- ============================================================

local GeneratorBoost = {
    Enabled = false,
    IsRepairing = false,
    CurrentTarget = nil,

    Multiplier = DEFAULT_MULTIPLIER,

    RepairLoopConnection = nil,
    ScanConnection = nil,

    LastRepairSend = 0,
    RepairRequests = 0,
    SuccessfulCalls = 0,

    Connections = {},
}

-- ============================================================
-- HELPERS
-- ============================================================

local function getCharacter()
    return LocalPlayer.Character
end

local function getRootPart()
    local character = getCharacter()

    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getProgress(generator)
    if not generator then
        return 0
    end

    local value =
        generator:GetAttribute("RepairProgress")
        or generator:GetAttribute("Progress")

    if typeof(value) == "number" then
        return value
    end

    return 0
end

local function getInterval()
    local multiplier = tonumber(GeneratorBoost.Multiplier) or DEFAULT_MULTIPLIER

    multiplier = math.clamp(
        multiplier,
        MIN_MULTIPLIER,
        MAX_MULTIPLIER
    )

    -- Higher multiplier = more frequent repair requests.
    return math.max(0.025, BASE_INTERVAL / multiplier)
end

-- ============================================================
-- REPAIR REMOTE
-- ============================================================

local function SendRepairEvent(generator)
    if not RepairEvent then
        warn("[GeneratorBoost] ❌ RepairEvent not found")
        return false
    end

    if not generator or not generator.Parent then
        return false
    end

    local character = getCharacter()

    if not character then
        return false
    end

    GeneratorBoost.RepairRequests += 1

    -- Do NOT fire several guessed argument formats.
    -- The supplied remote dump confirms the RemoteEvent exists,
    -- but not its exact server signature.
    --
    -- The first/most conservative form is the generator itself.
    local ok, err = pcall(function()
        RepairEvent:FireServer(generator)
    end)

    if ok then
        GeneratorBoost.SuccessfulCalls += 1
        return true
    end

    warn("[GeneratorBoost] ❌ RepairEvent call failed:", err)

    return false
end

local function SendRepairAnim(generator)
    if not RepairAnim then
        return false
    end

    if not generator or not generator.Parent then
        return false
    end

    local character = getCharacter()

    if not character then
        return false
    end

    local ok = pcall(function()
        RepairAnim:FireServer(generator)
    end)

    return ok
end

-- ============================================================
-- STATUS
-- ============================================================

function GeneratorBoost:GetStatus()
    return {
        Enabled = self.Enabled,
        IsRepairing = self.IsRepairing,
        CurrentTarget = self.CurrentTarget,
        Multiplier = self.Multiplier,
        RepairRequests = self.RepairRequests,
        SuccessfulCalls = self.SuccessfulCalls,
        Interval = getInterval(),
    }
end

function GeneratorBoost:SetMultiplier(value)
    value = tonumber(value)

    if not value then
        return self.Multiplier
    end

    self.Multiplier = math.clamp(
        value,
        MIN_MULTIPLIER,
        MAX_MULTIPLIER
    )

    print(
        "[GeneratorBoost] ⚙ Multiplier set to x"
            .. tostring(self.Multiplier)
    )

    return self.Multiplier
end

function GeneratorBoost:GetMultiplier()
    return self.Multiplier
end

-- ============================================================
-- STOP
-- ============================================================

function GeneratorBoost:StopRepair()
    if self.IsRepairing then
        print("[GeneratorBoost] ⏹ Stopping repair loop...")
    end

    self.IsRepairing = false
    self.CurrentTarget = nil

    if self.RepairLoopConnection then
        self.RepairLoopConnection:Disconnect()
        self.RepairLoopConnection = nil
    end

    self.LastRepairSend = 0
end

-- ============================================================
-- REPAIR LOOP
-- ============================================================

local function StartRepairLoop(generator)
    if not generator or not generator.Parent then
        warn("[GeneratorBoost] ⚠ Generator is invalid")
        return
    end

    if not GeneratorBoost.Enabled then
        warn("[GeneratorBoost] ⚠ Cannot start repair: boost is disabled")
        return
    end

    local character = getCharacter()

    if not character then
        warn("[GeneratorBoost] ⚠ Character not found")
        return
    end

    GeneratorBoost:StopRepair()

    GeneratorBoost.IsRepairing = true
    GeneratorBoost.CurrentTarget = generator
    GeneratorBoost.LastRepairSend = 0

    print(
        "[GeneratorBoost] ⚡ Starting repair loop on generator:",
        generator.Name,
        "x" .. tostring(GeneratorBoost.Multiplier)
    )

    local elapsed = 0

    GeneratorBoost.RepairLoopConnection =
        RunService.Heartbeat:Connect(function(dt)
            if not GeneratorBoost.Enabled then
                GeneratorBoost:StopRepair()
                return
            end

            if not GeneratorBoost.IsRepairing then
                return
            end

            if not generator or not generator.Parent then
                warn("[GeneratorBoost] ⚠ Generator disappeared")
                GeneratorBoost:StopRepair()
                return
            end

            local currentCharacter = getCharacter()

            if not currentCharacter then
                GeneratorBoost:StopRepair()
                return
            end

            local progress = getProgress(generator)

            if progress >= 100 then
                print("[GeneratorBoost] ✅ Generator completed!")
                GeneratorBoost:StopRepair()
                return
            end

            elapsed += dt

            local interval = getInterval()

            if elapsed < interval then
                return
            end

            elapsed = 0

            -- One request per interval.
            -- This avoids the old five-times-per-cycle remote spam.
            SendRepairEvent(generator)

            -- Animation is cosmetic and only sent when the remote exists.
            SendRepairAnim(generator)
        end)
end

-- ============================================================
-- START REPAIR
-- ============================================================

function GeneratorBoost:StartRepairOnTarget(generator)
    if not self.Enabled then
        warn("[GeneratorBoost] ⚠ Boost is disabled. Enable it first.")
        return false
    end

    if not generator or not generator.Parent then
        warn("[GeneratorBoost] ⚠ Invalid generator")
        return false
    end

    local progress = getProgress(generator)

    if progress >= 100 then
        print("[GeneratorBoost] ⚠ Generator is already completed")
        return false
    end

    if self.IsRepairing and self.CurrentTarget == generator then
        print("[GeneratorBoost] ℹ Already repairing this generator")
        return true
    end

    StartRepairLoop(generator)

    return self.IsRepairing
end

-- ============================================================
-- ENABLE / DISABLE
-- ============================================================

function GeneratorBoost:SetEnabled(state)
    state = state == true

    if self.Enabled == state then
        -- Keep the UI and module synchronized.
        if not state then
            self:StopRepair()
        end

        return self.Enabled
    end

    self.Enabled = state

    if state then
        print("[GeneratorBoost] 🟢 Boost ENABLED!")

        local nearest = self:GetNearestGenerator()

        if nearest then
            self:StartRepairOnTarget(nearest)
        else
            print("[GeneratorBoost] ⚠ No generator found; auto-scan enabled")
            self:StartAutoScan()
        end
    else
        print("[GeneratorBoost] 🔴 Boost DISABLED!")
        self:StopRepair()

        if self.ScanConnection then
            self.ScanConnection:Disconnect()
            self.ScanConnection = nil
        end
    end

    return self.Enabled
end

-- Compatibility with the current main_ui.lua.
--
-- Current UI first changes .Enabled and then calls :Toggle().
-- Therefore this function synchronizes to .Enabled instead of
-- inverting it a second time.
function GeneratorBoost:Toggle()
    local desiredState = self.Enabled == true

    print(
        "[GeneratorBoost] 🔄 Sync Toggle ->",
        desiredState and "ON" or "OFF"
    )

    return self:SetEnabled(desiredState)
end

-- ============================================================
-- AUTO SCAN
-- ============================================================

function GeneratorBoost:StartAutoScan()
    if self.ScanConnection then
        self.ScanConnection:Disconnect()
        self.ScanConnection = nil
    end

    if not self.Enabled then
        return
    end

    self.ScanConnection =
        RunService.Heartbeat:Connect(function()
            if not self.Enabled then
                if self.ScanConnection then
                    self.ScanConnection:Disconnect()
                    self.ScanConnection = nil
                end

                return
            end

            if not self.IsRepairing then
                local nearest = self:GetNearestGenerator()

                if nearest then
                    self:StartRepairOnTarget(nearest)
                end
            end
        end)
end

-- ============================================================
-- FIND NEAREST GENERATOR
-- ============================================================

function GeneratorBoost:GetNearestGenerator()
    local rootPart = getRootPart()

    if not rootPart then
        return nil, math.huge
    end

    local nearest = nil
    local nearestDist = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Generator" then
            local progress = getProgress(obj)

            if progress < 100 then
                local centerPart =
                    obj.PrimaryPart
                    or obj:FindFirstChild("defaultMaterial", true)
                    or obj:FindFirstChildWhichIsA("BasePart", true)

                if centerPart and centerPart:IsA("BasePart") then
                    local dist =
                        (centerPart.Position - rootPart.Position).Magnitude

                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end

    return nearest, nearestDist
end

-- ============================================================
-- CHARACTER CLEANUP
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.15)

    if GeneratorBoost.IsRepairing then
        print("[GeneratorBoost] 🔄 Character changed; stopping repair")
        GeneratorBoost:StopRepair()
    end
end)

-- ============================================================
-- EXPORT
-- ============================================================

_G.GeneratorBoost = GeneratorBoost

print("[GeneratorBoost] ✅ Loaded!")
print(
    "[GeneratorBoost] 💡 Multiplier:",
    "x" .. tostring(GeneratorBoost.Multiplier)
)
print("[GeneratorBoost] 💡 UI-compatible SetEnabled/Toggle ready")
print("[GeneratorBoost] 💡 RepairEvent:", RepairEvent and "READY" or "MISSING")

return GeneratorBoost
