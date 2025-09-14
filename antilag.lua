-- CLEAN + NO-WALLS + ESP + FPS/PING DISPLAY + BRAINHOT ESP + ANTI-AURA LAG (ATUALIZADO)
-- Integra versão melhorada do softenWalls para reduzir lag: remove SurfaceAppearance/Decals/Textures,
-- desliga sombras, remove partículas/luzes e opcionalmente destroi as paredes identificadas.

-- ============ CONFIG =============
local ENABLE_STRIP_SKINS   = true
local ENABLE_NO_WALLS      = true
local ENABLE_WALL_HACK     = true
local WALL_SCAN_INTERVAL   = 5.0
local SHOW_FPS_PING        = true
local ENABLE_BRAINHOT_ESP  = true
local ENABLE_ANTI_AURA_LAG = true

-- WALLS
local WALL_KEYWORDS = {"wall","parede","barrier","invisible","barreira","colisão","block","border","gate","bar","kill","killbrick","structure","base","home"}
local ENABLE_REMOVE_WALLS = false
local WALL_TAG             = "NoWallProcessed"
local WALL_TRANSPARENCY    = 0.8

-- ============ ANTI-AURA CONFIG =============
local AURA_KEYWORDS = {
    "aura", "effect", "efeito", "glow", "brilho", "sparkle", "particle", 
    "fogo", "fire", "fumaça", "smoke", "luz", "light", "raio", "beam",
    "magic", "mágica", "halo", "circle", "ring", "shockwave", "onda"
}
local AURA_TAG = "AntiAuraProcessed"

-- ============ BRAINHOT ESP CONFIG =============
local allowSecretByName = {
    ["La Sahur Combinasion"]      = true,
    ["Graipuss Medussi"]          = true,
    ["Pot Hotspot"]               = true,
    ["Chicleteira Bicicleteira"]  = true,
    ["La Grande Combinasion"]     = true,
    ["Los Combinasionas"]         = true,
    ["Nuclearo Dinossauro"]       = true,
    ["La Karkerkar Combinasion"]  = true,
    ["Los Hotspotsitos"]          = true,
    ["Tralaledon"]                = true,
    ["Esok Sekolah"]              = true,
    ["Ketupat Kepat"]             = true,
    ["Los Bros"]                  = true,
    ["La Supreme Combinasion"]    = true,
    ["Ketchuru and Musturu"]      = true,
    ["Garama and Madundung"]      = true,
    ["Spaghetti Tualetti"]        = true,
    ["Dragon Cannelloni"]         = true,
    ["Secret Lucky Block"]        = true,
}

-- ============ SERVICES ============
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local StatsService   = game:GetService("Stats")
local LocalPlayer    = Players.LocalPlayer
local CoreGui        = game:GetService("CoreGui")
local Workspace      = game:GetService("Workspace")

-- ============ FPS/PING DISPLAY ============
local fpsPingGui = nil
local rainbowOffset = 0
local frameCount = 0
local lastFpsUpdate = 0
local currentFps = 0

local function createFpsPingDisplay()
    if not SHOW_FPS_PING then return end
    
    if fpsPingGui then fpsPingGui:Destroy() end
    
    fpsPingGui = Instance.new("ScreenGui")
    fpsPingGui.Name = "FpsPingDisplay"
    fpsPingGui.ResetOnSpawn = false
    fpsPingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    fpsPingGui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 200, 0, 40)
    frame.Position = UDim2.new(0.5, -100, 0, 10)
    frame.BackgroundTransparency = 0.8
    frame.BackgroundColor3 = Color3.new(0, 0, 0)
    frame.BorderSizePixel = 0
    frame.Parent = fpsPingGui
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FpsLabel"
    fpsLabel.Size = UDim2.new(0.5, 0, 1, 0)
    fpsLabel.Position = UDim2.new(0, 0, 0, 0)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: 0"
    fpsLabel.TextColor3 = Color3.new(1, 1, 1)
    fpsLabel.TextScaled = true
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame
    
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(0.5, 0, 1, 0)
    pingLabel.Position = UDim2.new(0.5, 0, 0, 0)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "PING: 0ms"
    pingLabel.TextColor3 = Color3.new(1, 1, 1)
    pingLabel.TextScaled = true
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Right
    pingLabel.Parent = frame
    
    return fpsLabel, pingLabel
end

local function getRainbowColor(offset)
    local time = tick() + offset
    local r = math.sin(time * 1) * 0.5 + 0.5
    local g = math.sin(time * 1 + 2) * 0.5 + 0.5
    local b = math.sin(time * 1 + 4) * 0.5 + 0.5
    return Color3.new(r, g, b)
end

-- Sistema de FPS correto e único
local function updateFpsCounter()
    frameCount = frameCount + 1
    local currentTime = tick()
    
    if currentTime - lastFpsUpdate >= 0.5 then -- Atualiza a cada 0.5 segundos
        currentFps = math.floor(frameCount / (currentTime - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = currentTime
        return true
    end
    return false
end

local function updateFpsPingDisplay(fpsLabel, pingLabel)
    if not SHOW_FPS_PING or not fpsLabel or not pingLabel then return end
    
    -- Atualiza FPS
    fpsLabel.Text = "FPS: " .. currentFps
    
    -- Atualiza PING
    local success, pingValue = pcall(function()
        local stats = StatsService:FindFirstChild("PerformanceStats")
        if stats then
            local pingStats = stats:FindFirstChild("Ping")
            if pingStats then
                return math.floor(pingStats:GetValue())
            end
        end
        return "N/A"
    end)
    
    pingLabel.Text = "PING: " .. (success and pingValue or "N/A") .. (success and "ms" or "")
    
    -- Aplica efeito rainbow
    rainbowOffset = rainbowOffset + 0.05
    local rainbowColor = getRainbowColor(rainbowOffset)
    fpsLabel.TextColor3 = rainbowColor
    pingLabel.TextColor3 = rainbowColor
end

-- Inicializa o display de FPS/PING
local fpsLabel, pingLabel = nil, nil
if SHOW_FPS_PING then
    fpsLabel, pingLabel = createFpsPingDisplay()
    lastFpsUpdate = tick()
end

-- ============ ANTI-AURA SYSTEM ============
local lastAuraScan = 0
local AURA_SCAN_INTERVAL = 3.0

local function isAuraEffect(instance)
    local name = string.lower(instance.Name or "")
    if strContainsAny(name, AURA_KEYWORDS) then
        return true
    end
    
    if instance:IsA("ParticleEmitter") or instance:IsA("Fire") or 
       instance:IsA("Smoke") or instance:IsA("Sparkles") or
       instance:IsA("Beam") or instance:IsA("Trail") then
        return true
    end
    
    return false
end

local function removeAuraEffects()
    if not ENABLE_ANTI_AURA_LAG then return end
    if tick() - lastAuraScan < AURA_SCAN_INTERVAL then return end
    lastAuraScan = tick()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            for _, descendant in ipairs(player.Character:GetDescendants()) do
                if not CollectionService:HasTag(descendant, AURA_TAG) and isAuraEffect(descendant) then
                    pcall(function()
                        if descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or 
                           descendant:IsA("Smoke") or descendant:IsA("Sparkles") or
                           descendant:IsA("Beam") or descendant:IsA("Trail") then
                            descendant.Enabled = false
                            task.spawn(function()
                                task.wait(0.1)
                                pcall(function() descendant:Destroy() end)
                            end)
                        end
                        CollectionService:AddTag(descendant, AURA_TAG)
                    end)
                end
            end
        end
    end
    
    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if not CollectionService:HasTag(descendant, AURA_TAG) and isAuraEffect(descendant) then
            pcall(function()
                if descendant:IsA("ParticleEmitter") or descendant:IsA("Fire") or 
                   descendant:IsA("Smoke") or descendant:IsA("Sparkles") or
                   descendant:IsA("Beam") or descendant:IsA("Trail") then
                    descendant.Enabled = false
                    task.spawn(function()
                        task.wait(0.1)
                        pcall(function() descendant:Destroy() end)
                    end)
                end
                CollectionService:AddTag(descendant, AURA_TAG)
            end)
        end
    end
end

-- ============ BRAINHOT ESP (USANDO LÓGICA DA CALCULADORA) ============
local brainhotHighlights = {}

local function createBrainhotHighlight(overhead, ownerName)
    if not overhead then return end
    
    local hl = Instance.new("Highlight")
    hl.Name = "BrainhotESP"
    hl.FillTransparency = 0.3
    hl.OutlineColor = Color3.fromRGB(255, 50, 50)
    hl.FillColor = Color3.fromRGB(255, 150, 150)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = overhead
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BrainhotName"
    billboard.Size = UDim2.new(0, 300, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = overhead
    
    local label = Instance.new("TextLabel")
    label.Name = "NameLabel"
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = overhead:FindFirstChild('DisplayName') and overhead.DisplayName.Text or "Unknown"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Parent = billboard
    
    local ownerLabel = Instance.new("TextLabel")
    ownerLabel.Name = "OwnerLabel"
    ownerLabel.Size = UDim2.new(1, 0, 0.5, 0)
    ownerLabel.Position = UDim2.new(0, 0, 0.5, 0)
    ownerLabel.BackgroundTransparency = 1
    ownerLabel.Text = "Dono: " .. (ownerName or "Unknown")
    ownerLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
    ownerLabel.TextScaled = true
    ownerLabel.Font = Enum.Font.Gotham
    ownerLabel.TextStrokeTransparency = 0
    ownerLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    ownerLabel.Parent = billboard
    
    return hl
end

-- Função que usa EXATAMENTE a mesma lógica da calculadora
local function scanForBrainhots()
    if not ENABLE_BRAINHOT_ESP then return end
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return end

    for _, plot in pairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild('PlotSign')
        local ownerName =
            sign and sign:FindFirstChild('SurfaceGui') and
            sign.SurfaceGui:FindFirstChild('Frame') and
            sign.SurfaceGui.Frame:FindFirstChild('TextLabel') and
            sign.SurfaceGui.Frame.TextLabel.Text

        if ownerName and plot:FindFirstChild('AnimalPodiums') then
            ownerName = ownerName:gsub("'s Base", ""):gsub("%s+$", "")

            for _, podium in pairs(plot.AnimalPodiums:GetChildren()) do
                local overhead = podium:FindFirstChild('Base')
                              and podium.Base:FindFirstChild('Spawn')
                              and podium.Base.Spawn:FindFirstChild('Attachment')
                              and podium.Base.Spawn.Attachment:FindFirstChild('AnimalOverhead')

                if overhead then
                    local rarityObj = overhead:FindFirstChild('Rarity')
                    if rarityObj and rarityObj.Text == "Secret" then
                        local displayName = overhead:FindFirstChild('DisplayName')
                        if displayName then
                            local petName = displayName.Text
                            
                            -- Usa a mesma lógica da calculadora
                            if allowSecretByName[petName] and not brainhotHighlights[overhead] then
                                local highlight = createBrainhotHighlight(overhead, ownerName)
                                brainhotHighlights[overhead] = highlight
                                
                                -- Conecta para limpar quando o objeto for removido
                                overhead.AncestryChanged:Connect(function()
                                    if not overhead.Parent and brainhotHighlights[overhead] then
                                        brainhotHighlights[overhead]:Destroy()
                                        brainhotHighlights[overhead] = nil
                                    end)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Limpa highlights de objetos que não existem mais ou não são mais válidos
    for overhead, highlight in pairs(brainhotHighlights) do
        if not overhead.Parent then
            highlight:Destroy()
            brainhotHighlights[overhead] = nil
        else
            local rarityObj = overhead:FindFirstChild('Rarity')
            local displayName = overhead:FindFirstChild('DisplayName')
            
            if not rarityObj or not displayName or rarityObj.Text ~= "Secret" or not allowSecretByName[displayName.Text] then
                highlight:Destroy()
                brainhotHighlights[overhead] = nil
            end
        end
    end
end

-- ============ PLAYER ESP ============
local ENABLE_PLAYER_OUTLINE_ESP = true
local PLAYER_OUTLINE_COLOR = Color3.fromRGB(0, 120, 255)

local playerHighlights = {}

local function createHighlight(character)
    if not character then return end
    local hl = Instance.new("Highlight")
    hl.Name = "PlayerOutlineESP"
    hl.FillTransparency = 1
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
        end
        playerHighlights[player] = createHighlight(character)
    end

    if player.Character then
        task.spawn(onCharacterAdded, player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    player.CharacterRemoving:Connect(function()
        if playerHighlights[player] then
            playerHighlights[player]:Destroy()
            playerHighlights[player] = nil
        end
    end)
end

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

-- ============ STRIP SKINS ============
local function stripCharacter(character)
    if not ENABLE_STRIP_SKINS or not character then return end
    
    for _, item in pairs(character:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Hat") then
            pcall(item.Destroy, item)
        end
    end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("Shirt") or part:IsA("Pants") or part:IsA("ShirtGraphic") then
            pcall(part.Destroy, part)
        elseif part:IsA("CharacterMesh") then
            pcall(part.Destroy, part)
        elseif part:IsA("Decal") or part:IsA("Texture") then
            pcall(part.Destroy, part)
        elseif part:IsA("SpecialMesh") then
            pcall(function()
                part.TextureId = ""
                if part.MeshType == Enum.MeshType.FileMesh then part.MeshId = "" end
            end)
        elseif part:IsA("MeshPart") then
            pcall(function()
                part.TextureID = ""
                part.Color = Color3.fromRGB(163,162,165)
                part.Material = Enum.Material.Plastic
            end)
        elseif part:IsA("SurfaceAppearance") then
            pcall(part.Destroy, part)
        elseif part:IsA("BasePart") then
            pcall(function()
                part.Color = Color3.fromRGB(163,162,165)
                part.Material = Enum.Material.Plastic
                part.Transparency = 0
                part.Reflectance = 0
            end)
        elseif part:IsA("ParticleEmitter") or part:IsA("Fire") or part:IsA("Smoke") or
               part:IsA("Sparkles") or part:IsA("Light") or part:IsA("PointLight") or
               part:IsA("SpotLight") or part:IsA("SurfaceLight") or
               part:IsA("Trail") or part:IsA("Beam") then
            pcall(part.Destroy, part)
        end
    end
end

local function processPlayer(player)
    if player == LocalPlayer then return end
    
    if player.Character then
        stripCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        stripCharacter(character)
    end)
end

-- ============ NO-WALLS ============
local lastWallScan = 0
local processedParts = {}

local function applyWallHack(inst)
    if not ENABLE_WALL_HACK then return end
    if processedParts[inst] then return end
    processedParts[inst] = true
    
    pcall(function()
        inst.CanCollide = false
        inst.CastShadow = false
        inst.Transparency = WALL_TRANSPARENCY
        inst.Material = Enum.Material.SmoothPlastic
        inst.Reflectance = 0
        
        if inst.LocalTransparencyModifier ~= nil then
            inst.LocalTransparencyModifier = WALL_TRANSPARENCY
        end
        
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("SurfaceAppearance") then
                pcall(d.Destroy, d)
            elseif d:IsA("MeshPart") then
                pcall(function()
                    d.TextureID = ""
                    d.MeshId = ""
                    d.Transparency = WALL_TRANSPARENCY
                    d.Material = Enum.Material.SmoothPlastic
                end)
            end
        end
        
        CollectionService:AddTag(inst, WALL_TAG)
    end)
end

local function processPartForPerformance(inst)
    if ENABLE_WALL_HACK then
        applyWallHack(inst)
    elseif ENABLE_REMOVE_WALLS then
        pcall(inst.Destroy, inst)
    else
        pcall(function()
            inst.CanCollide = false
            inst.CastShadow = false
            inst.Transparency = WALL_TRANSPARENCY -- Usa transparência configurável
            inst.Material = Enum.Material.Plastic
            inst.Reflectance = 0
            
            if inst.LocalTransparencyModifier ~= nil then
                inst.LocalTransparencyModifier = WALL_TRANSPARENCY
            end
            
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("SurfaceAppearance") or d:IsA("Decal") or d:IsA("Texture") then
                    pcall(d.Destroy, d)
                elseif d:IsA("MeshPart") then
                    pcall(function()
                        d.TextureID = ""
                        d.MeshId = ""
                        d.Transparency = WALL_TRANSPARENCY -- Transparente ao invés de invisível
                        d.CastShadow = false
                    end)
                elseif d:IsA("BasePart") then
                    pcall(function()
                        d.Transparency = WALL_TRANSPARENCY
                        d.CastShadow = false
                    end)
                end
            end
            
            CollectionService:AddTag(inst, WALL_TAG)
        end)
    end
end

local function softenWalls()
    if not ENABLE_NO_WALLS then return end
    if tick() - lastWallScan < WALL_SCAN_INTERVAL then return end
    lastWallScan = tick()

    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and not CollectionService:HasTag(inst, WALL_TAG) then
            local n = inst.Name or ""
            if strContainsAny(n, WALL_KEYWORDS) then
                processPartForPerformance(inst)
            end
        end
    end
end

-- ============ MAIN LOOP OTIMIZADO ============
local brainhotScanCounter = 0
local auraScanCounter = 0
local wallScanCounter = 0
local skinScanCounter = 0

RunService.Heartbeat:Connect(function(deltaTime)
    -- Sistema de FPS único e correto
    local shouldUpdateDisplay = updateFpsCounter()
    
    if shouldUpdateDisplay and SHOW_FPS_PING then
        updateFpsPingDisplay(fpsLabel, pingLabel)
    end
    
    -- Contadores para diferentes sistemas
    brainhotScanCounter = brainhotScanCounter + 1
    auraScanCounter = auraScanCounter + 1
    wallScanCounter = wallScanCounter + 1
    skinScanCounter = skinScanCounter + 1
    
    -- Brainhot ESP (0.5 segundo - mais frequente para detectar rapidamente)
    if ENABLE_BRAINHOT_ESP and brainhotScanCounter >= 30 then
        brainhotScanCounter = 0
        task.spawn(scanForBrainhots)
    end
    
    -- Anti-Aura (0.5 segundo)
    if ENABLE_ANTI_AURA_LAG and auraScanCounter >= 30 then
        auraScanCounter = 0
        task.spawn(removeAuraEffects)
    end
    
    -- Walls (2 segundos)
    if ENABLE_NO_WALLS and wallScanCounter >= 120 then
        wallScanCounter = 0
        task.spawn(softenWalls)
    end
    
    -- Skin cleanup (3 segundos)
    if ENABLE_STRIP_SKINS and skinScanCounter >= 180 then
        skinScanCounter = 0
        task.spawn(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    for _, item in pairs(p.Character:GetChildren()) do
                        if item:IsA("Accessory") or item:IsA("Hat") or
                           item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") then
                            pcall(item.Destroy, item)
                        end
                    end
                end
            end
        end)
    end
end)

-- ============ INICIALIZAÇÃO ============
-- Setup inicial de jogadores
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        processPlayer(p)
        setupPlayerESP(p)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        processPlayer(player)
        setupPlayerESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if playerHighlights[player] then
        playerHighlights[player]:Destroy()
        playerHighlights[player] = nil
    end
end)

-- Escaneamentos iniciais
if ENABLE_BRAINHOT_ESP then
    task.delay(1, scanForBrainhots) -- Mais rápido para detectar brainhots
end

if ENABLE_ANTI_AURA_LAG then
    task.delay(1, removeAuraEffects)
end

if ENABLE_NO_WALLS then
    task.delay(3, softenWalls)
end

print(("="):rep(52))
print("✓ SCRIPT ANTILAG MELHORADO ATIVADO")
if SHOW_FPS_PING then print("→ Display de FPS/PING ativado (sistema único)") end
if ENABLE_BRAINHOT_ESP then print("→ ESP para brainhots especiais ativado (USANDO LÓGICA DA CALCULADORA)") end
if ENABLE_ANTI_AURA_LAG then print("→ Anti-lag para auras/efeitos ativado") end
if ENABLE_STRIP_SKINS then print("→ Remoção otimizada de skins/roupas/acessórios") end
if ENABLE_NO_WALLS then
    print("→ Walls/estruturas processadas. Intervalo: "..WALL_SCAN_INTERVAL.."s")
    print("→ Transparência: "..(WALL_TRANSPARENCY * 100).."%")
    print("→ "..(ENABLE_WALL_HACK and "WALL HACK ATIVO" or ENABLE_REMOVE_WALLS and "MODO REMOVER ATIVO" or "Estruturas transparentes"))
    print("→ Detecta: walls, structures, base, home + outras")
end
print("→ Sistema de FPS único e correto")
print("→ Loop otimizado com task.spawn")
print("→ ESP de brainhots corrigido para detectar em Plots")
print("→ Mostra nome do brainhot e dono")
print(("="):rep(52))
