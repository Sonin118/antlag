-- CLEAN + NO-WALLS + ESP (ATUALIZADO)
-- Integra versão melhorada do softenWalls para reduzir lag: remove SurfaceAppearance/Decals/Textures,
-- desliga sombras, remove partículas/luzes e opcionalmente destroi as paredes identificadas.
-- Coloque este arquivo como LocalScript (por exemplo em StarterPlayerScripts) se o propósito
-- for apenas afetar o cliente. Para efeito de performance real no servidor, as alterações devem ser
-- aplicadas em ServerScriptService por quem administra o jogo.

-- ============ CONFIG =============
local ENABLE_STRIP_SKINS   = true
local ENABLE_NO_WALLS      = true
local ENABLE_WALL_HACK     = true  -- Novo: torna paredes transparentes como wall hack
local WALL_SCAN_INTERVAL   = 5.0   -- Aumentado para reduzir custo ainda mais

-- WALLS
local WALL_KEYWORDS = {"wall","parede","barrier","invisible","barreira","colisão","block","border","gate","bar","kill","killbrick"}
local ENABLE_REMOVE_WALLS = false    -- true = DESTRÓI as partes identificadas (melhor performance, altera mapa)
local WALL_TAG             = "NoWallProcessed"

-- Configurações para wall hack
local WALL_TRANSPARENCY    = 0.5  -- Transparência das paredes (0 = invisível, 1 = opaco)

-- ============ SERVICES ============
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer    = Players.LocalPlayer

-- ============ CONFIG ESP ============
local ENABLE_PLAYER_OUTLINE_ESP = true
local PLAYER_OUTLINE_COLOR = Color3.fromRGB(0, 120, 255) -- Azul tipo bloom

local playerHighlights = {}

local function createHighlight(character)
    if not character then return end
    local hl = Instance.new("Highlight")
    hl.Name = "PlayerOutlineESP"
    hl.FillTransparency = 1 -- Transparente por dentro
    hl.OutlineColor = PLAYER_OUTLINE_COLOR
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = character
    return hl
end

local function setupPlayerESP(player)
    if not ENABLE_PLAYER_OUTLINE_ESP then return end
    if player == LocalPlayer then return end

    local function onCharacterAdded(character)
        task.wait(0.1)
        if playerHighlights[player] then
            playerHighlights[player]:Destroy()
            playerHighlights[player] = nil
        end
        local hl = createHighlight(character)
        playerHighlights[player] = hl
    end

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(function()
        if playerHighlights[player] then
            playerHighlights[player]:Destroy()
            playerHighlights[player] = nil
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    setupPlayerESP(p)
end
Players.PlayerAdded:Connect(setupPlayerESP)

-- ============ UTILS ============
local function strContainsAny(s, list)
    s = string.lower(s or "")
    for _,w in ipairs(list) do
        if string.find(s, string.lower(w)) then
            return true
        end
    end
    return false
end

local function safeGetHead(char)
    return char and char:FindFirstChild("Head")
end

-- Cache para jogadores já processados
local processedPlayers = {}

-- ============ STRIP SKINS ============
local function stripCharacter(character)
    if not ENABLE_STRIP_SKINS or not character then return end
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") then
            pcall(function() item:Destroy() end)
        end
    end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("Shirt") or part:IsA("Pants") or part:IsA("ShirtGraphic") then
            pcall(function() part:Destroy() end)
        end
        if part:IsA("CharacterMesh") then pcall(function() part:Destroy() end) end
        if part:IsA("Decal") or part:IsA("Texture") then pcall(function() part:Destroy() end) end
        if part:IsA("SpecialMesh") then
            pcall(function()
                part.TextureId = ""
                if part.MeshType == Enum.MeshType.FileMesh then part.MeshId = "" end
            end)
        end
        if part:IsA("MeshPart") then
            pcall(function()
                part.TextureID = ""
                part.Color = Color3.fromRGB(163,162,165)
                part.Material = Enum.Material.Plastic
            end)
        end
        if part:IsA("SurfaceAppearance") then pcall(function() part:Destroy() end) end
        if part:IsA("BasePart") then
            pcall(function()
                part.Color = Color3.fromRGB(163,162,165)
                part.Material = Enum.Material.Plastic
                part.Transparency = 0
                part.Reflectance = 0
                part.BrickColor = BrickColor.new("Medium stone grey")
            end)
        end
        if part:IsA("ParticleEmitter") or part:IsA("Fire") or part:IsA("Smoke") or
           part:IsA("Sparkles") or part:IsA("Light") or part:IsA("PointLight") or
           part:IsA("SpotLight") or part:IsA("SurfaceLight") or
           part:IsA("Trail") or part:IsA("Beam") then
            pcall(function() part:Destroy() end)
        end
    end
    local head = character:FindFirstChild("Head")
    if head then
        for _, item in pairs(head:GetChildren()) do
            if item:IsA("Decal") or string.find(string.lower(item.Name), "face") then
                pcall(function() item:Destroy() end)
            end
        end
        pcall(function()
            head.Color = Color3.fromRGB(163,162,165)
            head.Material = Enum.Material.Plastic
        end)
    end
    local bodyColors = character:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        pcall(function()
            local stone = BrickColor.new("Medium stone grey")
            bodyColors.HeadColor    = stone
            bodyColors.TorsoColor   = stone
            bodyColors.LeftArmColor = stone
            bodyColors.RightArmColor= stone
            bodyColors.LeftLegColor = stone
            bodyColors.RightLegColor= stone
        end)
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                pcall(function()
                    if not tostring(track.Animation.AnimationId):find("rbxasset") then track:Stop() end
                end)
            end
        end
        pcall(function()
            local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
            if description then description:Destroy() end
        end)
    end
end

local function processPlayer(player)
    if player ~= LocalPlayer and not processedPlayers[player] then
        processedPlayers[player] = true
        if player.Character then stripCharacter(player.Character) end
        player.CharacterAdded:Connect(function(character)
            task.wait(0.5)
            stripCharacter(character)
        end)
        player.CharacterAppearanceLoaded:Connect(function(character) stripCharacter(character) end)
    end
end

for _, p in ipairs(Players:GetPlayers()) do processPlayer(p) end
Players.PlayerAdded:Connect(processPlayer)

-- ============ NO-WALLS (MELHORADO) ============
local lastWallScan = 0

-- Função para aplicar wall hack (tornar paredes transparentes)
local function applyWallHack(inst)
    if not ENABLE_WALL_HACK then return end
    if processedParts[inst] then return end
    processedParts[inst] = true
    pcall(function()
        inst.CanCollide = false
        inst.CastShadow = false
        inst.Transparency = WALL_TRANSPARENCY
        -- Use SmoothPlastic for better transparent effect
        inst.Material = Enum.Material.SmoothPlastic
        inst.Reflectance = 0
        if inst.LocalTransparencyModifier ~= nil then
            inst.LocalTransparencyModifier = WALL_TRANSPARENCY
        end
        -- Preserve decals and textures for visual perception
        -- Only remove SurfaceAppearance which can be heavy
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("SurfaceAppearance") then
                pcall(function() d:Destroy() end)
            elseif d:IsA("MeshPart") then
                pcall(function()
                    d.TextureID = ""
                    d.MeshId = ""
                    d.Transparency = WALL_TRANSPARENCY
                    d.Material = Enum.Material.SmoothPlastic
                end)
            end
        end
        -- Marca como processado
        pcall(function() CollectionService:AddTag(inst, WALL_TAG) end)
    end)
end

local function processPartForPerformance(inst)
    -- Aplica wall hack ou remoção otimizada
    if ENABLE_WALL_HACK then
        applyWallHack(inst)
    elseif ENABLE_REMOVE_WALLS then
        pcall(function() inst:Destroy() end)
    else
        pcall(function()
            inst.CanCollide = false
            inst.CastShadow = false
            inst.Transparency = 1
            inst.Material = Enum.Material.Plastic
            inst.Reflectance = 0
            if inst.LocalTransparencyModifier ~= nil then
                inst.LocalTransparencyModifier = 1
            end
            -- Remove elementos visuais
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then
                    pcall(function() d:Destroy() end)
                elseif d:IsA("MeshPart") then
                    pcall(function()
                        d.TextureID = ""
                        d.MeshId = ""
                        d.Transparency = 1
                        d.CastShadow = false
                    end)
                end
            end
            -- Marca como processado
            pcall(function() CollectionService:AddTag(inst, WALL_TAG) end)
        end)
    end
end

local function softenWalls()
    if not ENABLE_NO_WALLS then return end
    if tick() - lastWallScan < WALL_SCAN_INTERVAL then return end
    lastWallScan = tick()

    -- iterar workspace e processar partes não marcadas
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("BasePart") and not CollectionService:HasTag(inst, WALL_TAG) then
            local n = inst.Name or ""
            if strContainsAny(n, WALL_KEYWORDS) then
                processPartForPerformance(inst)
            end
        end
    end
end

-- ============ HEARTBEAT LOOP OTIMIZADO ============
local frame = 0
RunService.Heartbeat:Connect(function()
    frame += 1
    if frame >= 120 then -- ~2s (reduzido para economizar CPU ainda mais)
        frame = 0
        if ENABLE_STRIP_SKINS then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    -- Verificação otimizada para itens novos
                    for _, item in pairs(p.Character:GetChildren()) do
                        if item:IsA("Accessory") or item:IsA("Hat") or
                           item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                            pcall(function() item:Destroy() end)
                        end
                    end
                end
            end
        end
        if ENABLE_NO_WALLS then softenWalls() end
    end
end)

print(("="):rep(52))
print("✓ SCRIPT ANTILAG MELHORADO ATIVADO")
if ENABLE_STRIP_SKINS then print("→ Remoção otimizada de skins/roupas/acessórios") end
if ENABLE_NO_WALLS then
    print("→ Walls processadas. Intervalo de scan: "..tostring(WALL_SCAN_INTERVAL).."s")
    if ENABLE_WALL_HACK then
        print("→ WALL HACK ATIVO: paredes transparentes (efeito visual)")
    elseif ENABLE_REMOVE_WALLS then
        print("→ MODO REMOVER ATIVO: paredes serão DESTRUÍDAS")
    else
        print("→ Walls invisíveis (sem colisão)")
    end
end
print("→ Loop otimizado para reduzir uso de CPU")
print(("="):rep(52))
