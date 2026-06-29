local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CommF_ = Remotes:WaitForChild("CommF_")

local Player = Players.LocalPlayer
local Url = getgenv().Url
local Delay = getgenv().Delay

local Inicio = os.time()

local Raridades = {
    [0] = "Common",
    [1] = "Uncommon",
    [2] = "Rare",
    [3] = "Legendary",
    [4] = "Mythical"
}
local count = 0

local FIELD_LIMIT = 1024

local function AddSplitFields(fields, baseName, lines)
    local currentValue = ""
    local part = 1

    local function AddField()
        if currentValue ~= "" then
            table.insert(fields, {
                name = part == 1 and baseName or (baseName .. " " .. part),
                value = currentValue,
                inline = false
            })

            part += 1
            currentValue = ""
        end
    end

    for _, line in ipairs(lines) do
        line = tostring(line)

        local newValue = currentValue == ""
            and line
            or (currentValue .. "\n" .. line)

        if #newValue > FIELD_LIMIT then
            AddField()
            currentValue = line
        else
            currentValue = newValue
        end
    end

    AddField()
end

local function SendEmbed(url, embed)
    local success, result = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                username = "mygame43",
                avatar_url = "https://i.ibb.co/WpRsVKhm/no-Filter.webp",
                embeds = {embed}
            })
        })
    end)

    if success then
        print("Webhook enviado!")
    else
        warn("Erro ao enviar webhook:", result)
    end
end

local function GetInventoryFields()
    local inventoryData = CommF_:InvokeServer("getInventory")
    local grouped = {}
    local inventoryFields = {}

    if type(inventoryData) ~= "table" then
        table.insert(inventoryFields, {
            name = "Inventory",
            value = "Não foi possível carregar o inventário.",
            inline = false
        })

        return inventoryFields
    end

    for _, item in ipairs(inventoryData) do
        local tipo = item.Type or "Desconhecido"

        grouped[tipo] = grouped[tipo] or {}
        table.insert(grouped[tipo], item)
    end

    for tipo, items in pairs(grouped) do
        local value = ""

        for _, item in ipairs(items) do
            local nome = item.Name or "???"
            local quantidade = item.Count and (" x" .. tostring(item.Count)) or ""
            local raridade = Raridades[item.Rarity] or tostring(item.Rarity or "N/A")

            value = value .. string.format(
                "%s%s - %s\n",
                nome,
                quantidade,
                raridade
            )
        end

        if value == "" then
            value = "Nenhum item."
        end

        local lines = {}

        for _, item in ipairs(items) do
            local nome = item.Name or "???"
            local quantidade = item.Count and (" x" .. tostring(item.Count)) or ""
            local raridade = Raridades[item.Rarity] or tostring(item.Rarity or "N/A")

            table.insert(lines, string.format(
                "%s%s - %s",
                nome,
                quantidade,
                raridade
            ))
        end

        AddSplitFields(
            inventoryFields,
            tostring(tipo),
            lines
        )
    end

    return inventoryFields
end

local function Notification()
    count+=1
    game.StarterGui:SetCore("SendNotification", {
    Title = "Embed Sended",
    Text = "Embed Counter: " .. count,
    Duration = 5,
    })
end

local function EnviarStatus()
    local MinutosOnline = math.floor((os.time() - Inicio) / 60)

    local fields = {
        {
            name = "Username",
            value = Player.Name,
            inline = true
        },
        {
            name = "Level",
            value = tostring(Player.Data.Level.Value),
            inline = true
        },
        {
            name = "Race",
            value = tostring(Player.Data.Race.Value),
            inline = true
        },
        {
            name = "Beli",
            value = tostring(Player.Data.Beli.Value),
            inline = true
        },
        {
            name = "Fragments",
            value = tostring(Player.Data.Fragments.Value),
            inline = true
        }
    }

    local inventoryFields = GetInventoryFields()

    for _, field in ipairs(inventoryFields) do
        table.insert(fields, field)
    end

    local Embed = {
        title = "mygame43 Embed Sender v1",
        color = 16711680,
        fields = fields,

        footer = {
            text = "Tempo Online: " .. MinutosOnline .. " minuto(s)"
        },

        timestamp = DateTime.now():ToIsoDate()
    }

    SendEmbed(Url, Embed)
    Notification()
end



EnviarStatus()

task.spawn(function()
    while true do
        task.wait(300)
        EnviarStatus()
    end
end)
