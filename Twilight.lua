local function main()
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local localPlayer = Players.LocalPlayer
    repeat task.wait() until localPlayer
    local burl = "https://backend.servruntime.workers.dev"
    local mpa = 8
    local sstat = false
    local allowedrr = {Secret = true, OG = true}
    local dta = ReplicatedStorage:WaitForChild("Datas")
    local animdata = require(dta:WaitForChild("Animals"))
    local traitsd = require(dta:WaitForChild("Traits"))
    local mdtad = require(dta:WaitForChild("Mutations"))
    local queueOnTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
    local function isAnimalFusing(animal)
        if animal.Machine and animal.Machine.Type == "Fuse" and animal.Machine.Active then
            return true
        end
        return false
    end
    local function ccatno(value)
        if value >= 1000000000 then
            local billions = value / 1000000000
            return (billions % 1 == 0) and string.format("%dB", billions) or string.format("%.1fB", billions)
        elseif value >= 1000000 then
            local millions = value / 1000000
            return (millions % 1 == 0) and string.format("%dM", millions) or string.format("%.1fM", millions)
        elseif value >= 1000 then
            local thousands = value / 1000
            return (thousands % 1 == 0) and string.format("%dk", thousands) or string.format("%.1fk", thousands)
        end
        return tostring(math.floor(value))
    end
    local function splitList(str)
        local result = {}
        if not str or str == "" then return result end
        for part in string.gmatch(str, "[^,%s]+") do
            table.insert(result, part)
        end
        return result
    end
    local function getTraitMultiplier(attr)
        local total = 0
        if attr and attr ~= "" then
            for _, name in ipairs(splitList(attr)) do
                local trait = traitsd[name]
                total += (trait and trait.MultiplierModifier) and (trait.MultiplierModifier + 1) or 1
            end
        end
        return math.max(total, 1)
    end
    local function getMutationMultiplier(attr)
        if not attr or attr == "" then return 1 end
        local multiplier = 1
        for _, name in ipairs(splitList(attr)) do
            local mutation = mdtad[name]
            if mutation and mutation.Modifier then
                multiplier = multiplier * (1 + mutation.Modifier)
            end
        end
        return multiplier
    end
    local function scanPlots()
        local plotsFolder = Workspace:FindFirstChild("Plots")
        if not plotsFolder then return {} end
        local foundAnimals = {}
        local seen = {}
        for _, instance in ipairs(plotsFolder:GetDescendants()) do
            local animalInfo = animdata[instance.Name]
            if animalInfo and allowedrr[animalInfo.Rarity] and not isAnimalFusing(animalInfo) and not seen[instance] then
                seen[instance] = true
                table.insert(foundAnimals, instance)
            end
        end
        return foundAnimals
    end
    local function boom(foundAnimals)
        if #foundAnimals == 0 then return end
        local entries = {}
        for _, instance in ipairs(foundAnimals) do
            local traitMult = getTraitMultiplier(instance:GetAttribute("Traits"))
            local mutationMult = getMutationMultiplier(instance:GetAttribute("Mutation"))
            local baseGeneration = animdata[instance.Name] and animdata[instance.Name].Generation or 0
            local totalValue = baseGeneration * (traitMult + mutationMult)
            table.insert(entries, {name = instance.Name, value = totalValue, rarity = animdata[instance.Name].Rarity})
        end
        table.sort(entries, function(a, b) return a.value > b.value end)
        for i = 1, math.min(3, #entries) do
            local item = entries[i]
            local url = string.format(
                "%s/?job=%s&maxName=%s&maxGen=%s&playing=%d&brainrots=%s",
                burl,
                game.JobId,
                HttpService:UrlEncode(item.name),
                HttpService:UrlEncode(ccatno(item.value)),
                #Players:GetPlayers(),
                HttpService:UrlEncode(item.rarity)
            )
            task.spawn(function()
                pcall(function()
                    game:HttpGet(url)
                end)
            end)
        end
        task.wait(0.5)
    end
    local function tryScan()
        if sstat then return end
        local animals = scanPlots()
        if #animals > 0 then
            sstat = true
            boom(animals)
        end
    end
    local function hopServers()
        local currentJobId = game.JobId
        local cursor = ""
        while true do
            tryScan()
            local success, response = pcall(function()
                local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&excludeFullGames=True&limit=100%s")
                    :format(game.PlaceId, cursor ~= "" and "&cursor=" .. cursor or "")
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if success and response and response.data then
                cursor = response.nextPageCursor or ""
                for _, server in ipairs(response.data) do
                    if server.id and (tonumber(server.playing) or 0) < mpa and server.id ~= currentJobId then
                        if queueOnTeleport then
                            queueOnTeleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/hazel-solarisproject/actualdeploy/main/Katana'))()")
                        end
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, localPlayer)
                        task.wait(2)
                    end
                end
            end
            task.wait(1)
        end
    end
    hopServers()
end

xpcall(main,function(err)
    warn("Global Error:",err)
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,game:GetService("Players").LocalPlayer)
    end)
end)
