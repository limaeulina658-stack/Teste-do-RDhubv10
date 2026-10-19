-- MeleeMastery v6.4 corrigido
-- Este arquivo baixa o original e aplica correcoes antes de executar.
-- Correcoes:
-- 1) posiciona o jogador acima do topo do modelo do NPC;
-- 2) desativa o aumento artificial gigante da hitbox do NPC;
-- 3) substitui mouse1click/mouse1press/mouse1release por Tool:Activate(),
--    mantendo um intervalo minimo de 0,5 segundo entre ativacoes.

local sourceUrl = "https://raw.githubusercontent.com/cristhianberitto-dev/Rd-hub-talvez-definitivo/main/MeleeMastery_Only_v6.4.luau"

local fetchOk, source = pcall(function()
    return game:HttpGet(sourceUrl)
end)

if not fetchOk or type(source) ~= "string" or #source < 1000 then
    error("MeleeMastery corrigido: nao foi possivel baixar o arquivo original. Verifique a conexao do executor.")
end

source = source:gsub("\r\n", "\n")

local function replaceOnce(oldText, newText, description)
    local first = source:find(oldText, 1, true)
    if not first then
        error("MeleeMastery corrigido: nao encontrei o trecho esperado para: " .. description .. ". O arquivo original pode ter mudado.")
    end
    local second = source:find(oldText, first + #oldText, true)
    if second then
        error("MeleeMastery corrigido: encontrei mais de uma ocorrencia de: " .. description .. ". Execucao cancelada por seguranca.")
    end
    source = source:sub(1, first - 1) .. newText .. source:sub(first + #oldText)
end

-- Calcula a altura usando o topo real do modelo, nao o centro do HumanoidRootPart.
replaceOnce(
    "local desiredY = targetRoot.Position.Y + Height",
    "local boxCFrame, boxSize = target:GetBoundingBox()\n                        local desiredY = boxCFrame.Position.Y + (boxSize.Y / 2) + Height",
    "calculo de altura"
)

-- Desativa a chamada que redimensionava o HumanoidRootPart do NPC para 28-48 studs.
local sourceAfterHitbox, hitboxCallCount = source:gsub("\n[ \t]*EnlargeTargetHitbox%(target%)\n", "\n                        -- Hitbox artificial desativada para evitar sobreposicao com o NPC.\n", 1)
if hitboxCallCount ~= 1 then
    error("MeleeMastery corrigido: chamada de aumento da hitbox nao encontrada. Execucao cancelada.")
end
source = sourceAfterHitbox

-- Substitui as funcoes de mouse do executor por ativacao da ferramenta Melee equipada.
local attackStart = source:find("local function ClickAttack()", 1, true)
if not attackStart then
    error("MeleeMastery corrigido: funcao ClickAttack nao encontrada. Execucao cancelada.")
end
local hitboxMarker = source:find("-- Aumenta a hitbox do NPC", attackStart, true)
if not hitboxMarker then
    error("MeleeMastery corrigido: limite da funcao ClickAttack nao encontrado. Execucao cancelada.")
end

local safeAttack = [[local function ClickAttack()
    if os.clock() - lastClick < 0.5 then return false end
    local character = Player.Character
    if not character then return false end

    local tool = nil
    for _, item in ipairs(character:GetChildren()) do
        if item:IsA("Tool") and item.ToolTip == "Melee" then
            tool = item
            break
        end
    end
    if not tool then return false end

    lastClick = os.clock()
    local ok = pcall(function()
        tool:Activate()
    end)
    return ok
end
]]

source = source:sub(1, attackStart - 1) .. safeAttack .. source:sub(hitboxMarker)
source = source:gsub("v6%.4 | click 0%.5s %+ hitbox controlada", "v6.4 corrigida | altura pelo topo do NPC")
source = source:gsub("print%(%\"%[MeleeMastery%] v6%.4 carregada; click a cada 0%.5s %+ hitbox do NPC controlada para alcance%.%\"%)", "print(\"[MeleeMastery] v6.4 corrigida carregada; hitbox artificial desativada.\")")

local compileOk, compiled = pcall(loadstring, source)
if not compileOk or type(compiled) ~= "function" then
    error("MeleeMastery corrigido: falha ao preparar o script. O original pode ter mudado ou ocorrido erro de compilacao.")
end

return compiled()
