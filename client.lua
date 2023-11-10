local squads = {
    {
        {
            name = "Franklin",
            model = "player_one",
            weapon = "WEAPON_CARBINERIFLE",
            ammo   = 250,
            position = vector4(2098.037, 4790.901, 41.05114, 107.0197)
        },
        {
            name = "Trevor",
            model = "player_two",
            weapon = "WEAPON_PISTOL",
            ammo   = 250,
            position = vector4(2098.612, 4789.053, 41.01891, 106.9846)
        },
        {
            name = "Micheal",
            model = "player_zero",
            weapon = "WEAPON_PISTOL",
            ammo   = 250,
            position = vector4(2097.39, 4792.676, 41.06048, 110.3104)
        },
    },
    {
        {
            name = "Guard 1",
            model = "mp_m_securoguard_01",
            weapon = "WEAPON_CARBINERIFLE",
            ammo   = 250,
            position = vector4(2088.975, 4786.422, 41.22277, 291.3493)
        },
        {
            name = "Guard 2",
            model = "mp_m_waremech_01",
            weapon = "WEAPON_PISTOL",
            ammo   = 250,
            position = vector4(2087.72, 4788.923, 41.06043, 290.8754)
        },
        {
            name = "Guard 3",
            model = "mp_m_weapexp_01",
            weapon = "WEAPON_PISTOL",
            ammo   = 250,
            position = vector4(2088.699, 4784.441, 41.31112, 293.3613)
        },
    },
}
local peds = {}

---@param coords vector3
---@param text string
function Draw3dText(coords, text)
    local camCoords = GetGameplayCamCoord()
    local dist = #(coords - camCoords)
    local scale = 200 / (GetGameplayCamFov() * dist)
    SetTextColour(255, 188, 0, 255)
    SetTextScale(0.0, 0.3 * scale)
    SetTextFont(4)
    SetTextDropshadow(0, 0, 0, 0, 55)
    SetTextDropShadow()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(coords, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

---@param currentPed table data 
function CreatePedSquad(currentPed)
    local hash = GetHashKey(currentPed.model)

    RequestModel(hash)
    
    while not HasModelLoaded(hash) do
        Wait(100)
    end

    local ped = CreatePed(4, hash, currentPed.position.x,currentPed.position.y,currentPed.position.z-1,currentPed.position.w, false, true)
    peds[#peds+1] = {entity = ped, name = currentPed.name}
    GiveWeaponToPed(ped, GetHashKey(currentPed.weapon) or GetHashKey("WEAPON_PISTOL"), currentPed.ammo or 250, true, true)

    return ped
end

function StartBattle()
    if(#peds < 1) then
        local currentPed = nil

        for squad, data in pairs(squads) do
            local squad_name = "squad_"..squad 
            AddRelationshipGroup("squad_"..squad)
    
            for i=1, #squads[squad] do
                currentPed = squads[squad][i]
                local ped = CreatePedSquad(currentPed)
                SetPedRelationshipGroupHash(ped, squad_name)
            end
    
            for i=1, #squads do
                if(i ~= squad) then
                    -- Add other squads as enemies
                    SetRelationshipBetweenGroups(5, squad_name, "squad_"..i)
                end
            end
        end
    else
        print("You can't do it again, the battle has already started!")
    end

    Citizen.CreateThread(function()
        while (#peds > 0) do
            for i = 1, #peds do
                if peds[i] then 
                    local row    = peds[i]
                    local coords = GetEntityCoords(PlayerPedId())
                    local ped    = GetEntityCoords(row.entity)
                    local vita   = GetEntityHealth(row.entity)
                    local vivo   = (vita > 0)
    
                    print(row.name, vita)
    
                    if (#(coords - ped) <= 5.0 and not vivo) then
                        ped = vec3(ped.x, ped.y, ped.z + 0.9)
                        Draw3dText(ped, ('%s [%s]'):format(row.name, vita))
                    end
    
                    if (not vivo) then
                        DeleteEntity(row.entity)
                        peds[i] = nil
                    end
                end
            end
    
            Citizen.Wait(4)
        end
    end)
end

RegisterCommand("start", function()
    StartBattle()
end)

AddEventHandler("onResourceStop", function(res)
    if(res == GetCurrentResourceName()) then
        for index,ped in pairs(peds) do
            DeleteEntity(ped.entity)
        end
    end
end)