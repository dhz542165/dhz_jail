local IsJailed = false
local unjail = false
local JailTime = 0
local fastTimer = 0
local PositionDePrison = Config.PosPrison
local blip = vector3(1866.66, 2622.46, 45.67)

ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

function EspaceEcrire(TextEntry, ExampleText, MaxStringLenght)
	AddTextEntry('FMMC_KEY_TIP1', TextEntry)
	DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
	blockinput = true
	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
		Citizen.Wait(0)
	end
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult() 
		Citizen.Wait(500)
		blockinput = false
		return result 
	else
		Citizen.Wait(500) 
		blockinput = false 
		return nil 
	end
end

local menuprison = false
RMenu.Add('dhz_jail', 'main', RageUI.CreateMenu("Prison", "", 0,0))
RMenu:Get('dhz_jail', 'main'):SetSubtitle("Liste des joueurs")
RMenu.Add('dhz_jail', 'prison', RageUI.CreateSubMenu(RMenu:Get('dhz_jail', 'main'), "Prison", "Que voulez-vous faire de lui ?"))
RMenu:Get('dhz_jail', 'main').EnableMouse = false
RMenu:Get('dhz_jail', 'main').Closed = function()
	menuprison = false
end

function MenuPrison()
    if menuprison then
        menuprison = false
    else
        menuprison = true
        RageUI.Visible(RMenu:Get('dhz_jail', 'main'), true)
		local playerlist = {}
		ESX.TriggerServerCallback("dhz_jail:GetPlayers", function(cb) 
			playerlist = cb
		end)
        Citizen.CreateThread(function()
			while menuprison do
				Wait(0)
				RageUI.IsVisible(RMenu:Get('dhz_jail', 'main'), true, true, true, function()
					for k,v in pairs(playerlist) do -- for each players do :
						RageUI.ButtonWithStyle(v.name, nil, {RightLabel = "ID : ~g~".. v.id}, true, function(Hovered, Active, Selected)
							if (Selected) then
								IdChoisi = v.id
								IdChoisiNom = v.name
							end
						end, RMenu:Get('dhz_jail', 'prison'))	
					end
				end, function()
				end)

				RageUI.IsVisible(RMenu:Get('dhz_jail', 'prison'), true, true, true, function()
					RageUI.Separator("↓ ~r~Actions possible sur ~s~↓")
					RageUI.Separator("ID : [".. IdChoisi .."] ~r~")
					RageUI.Separator("Joueur : "..IdChoisiNom)

					RageUI.ButtonWithStyle("Mettre en prison", nil, {}, true, function(Hovered, Active, Selected)
						if (Selected) then
							local temps = EspaceEcrire("Temps en minutes", "", 10)
							if temps then
								ExecuteCommand("jail "..IdChoisi.. " " ..temps)
								RageUI.CloseAll()
								menuprison = false
							end
						end
					end)
					RageUI.ButtonWithStyle("Sortir de prison", nil, {}, true, function(Hovered, Active, Selected)
						if (Selected) then
							ExecuteCommand("unjail "..IdChoisi)
						end
					end)
		
				end, function()
				end)
			end	
		end)			
	end				
end

RegisterNetEvent('esx_jailer:jail')
AddEventHandler('esx_jailer:jail', function(jailTime)
	if IsJailed then
		return
	end
	JailTime = jailTime
	local sourcePed = PlayerPedId()
	if DoesEntityExist(sourcePed) then
		Citizen.CreateThread(function()
			TriggerEvent('skinchanger:getSkin', function(skin)
				if skin.sex == 0 then
					TriggerEvent('skinchanger:loadClothes', skin, Config.Tenues['tenue_prison'].homme)
				else
					TriggerEvent('skinchanger:loadClothes', skin, Config.Tenues['tenue_prison'].femme)
				end
			end)
			SetPedArmour(sourcePed, 0)
			ClearPedBloodDamage(sourcePed)
			ResetPedVisibleDamage(sourcePed)
			ClearPedLastWeaponDamage(sourcePed)
			ResetPedMovementClipset(sourcePed, 0)
			SetEntityCoords(sourcePed, PositionDePrison.x, PositionDePrison.y, PositionDePrison.z)
			IsJailed = true
			unjail = false
			while JailTime > 0 and not unjail do
				sourcePed = PlayerPedId()
				RemoveAllPedWeapons(sourcePed, true)
				if IsPedInAnyVehicle(sourcePed, false) then
					ClearPedTasksImmediately(sourcePed)
				end
				if JailTime % 120 == 0 then
					TriggerServerEvent('esx_jailer:updateRemaining', JailTime)
				end
				Citizen.Wait(20000)
				if GetDistanceBetweenCoords(GetEntityCoords(sourcePed), PositionDePrison.x, PositionDePrison.y, PositionDePrison.z) > 10 then
					SetEntityCoords(sourcePed, PositionDePrison.x, PositionDePrison.y, PositionDePrison.z)
					ESX.ShowNotification('Vous n’avez pas le droit d’échapper à la prison!')
				end
				JailTime = JailTime - 20
			end
			TriggerServerEvent('esx_jailer:unjailTime', -1)
			SetEntityCoords(sourcePed, blip.x, blip.y, blip.z)
			IsJailed = false

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
		end)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if JailTime > 0 and IsJailed then
			if fastTimer < 0 then
				fastTimer = JailTime
			end
			Texte2D('Il vous reste ~b~'..ESX.Round(fastTimer)..'~s~ secondes de prison avant de pouvoir sortir', { 0.175, 0.955 } )
			fastTimer = fastTimer - 0.01
		else
			Citizen.Wait(0)
		end
	end
end)

RegisterNetEvent('esx_jailer:unjail')
AddEventHandler('esx_jailer:unjail', function(source)
	unjail = true
	JailTime = 0
	fastTimer = 0
end)

AddEventHandler('playerSpawned', function(spawn)
	if IsJailed then
		SetEntityCoords(PlayerPedId(), PositionDePrison.x, PositionDePrison.y, PositionDePrison.z)
	else
		TriggerServerEvent('esx_jailer:checkJail')
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(0) 
	TriggerServerEvent('esx_jailer:checkJail')
end)

Citizen.CreateThread(function()
	local prison = AddBlipForCoord(blip)
	SetBlipSprite (prison, 188)
	SetBlipDisplay(prison, 4)
	SetBlipScale  (prison, 0.8)
	SetBlipColour (prison, 1)
	SetBlipAsShortRange(prison, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Prison')
	EndTextCommandSetBlipName(prison)
end)

function Texte2D(text, pos)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextScale(0.45, 0.45)
	SetTextColour(255, 255, 255, 255)
	SetTextDropShadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()

	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(table.unpack(pos))
end

Keys.Register('F7', 'Admin', 'Ouvrir le menu jail', function()
	ESX.TriggerServerCallback('dhz:getUsergroup', function(group)
		playergroup = group
		if playergroup == 'mod' or playergroup == 'admin' or playergroup == 'superadmin' or playergroup == 'owner' then
			if menuprison == false then
				MenuPrison()
			end
		else
			ESX.ShowNotification("Vous n'êtes pas staff")
		end
	end)
end)

local zones = {
	{ ['x'] = 1641.64, ['y'] = 2571.08, ['z'] = 45.56}
}

local danslazone = false
local sortir = false
local zone = 1

Citizen.CreateThread(function() 
	if Config.UtiliserSafeZone then
		while not NetworkIsPlayerActive(PlayerId()) do 
			Citizen.Wait(0) 
		end	
		while true do 
			Citizen.Wait(0) 
			local player = PlayerPedId() 
			local x,y,z = table.unpack(GetEntityCoords(player, true)) 
			local dist = Vdist(zones[zone].x, zones[zone].y, zones[zone].z, x, y, z)
			if dist <= 50.0 then
				if not danslazone then	 ESX.ShowNotification("Vous etes dans une ~g~zone safe~s~ !")																	   
					NetworkSetFriendlyFireOption(false) 
					ClearPlayerWantedLevel(PlayerId()) 
					SetCurrentPedWeapon(player,GetHashKey("WEAPON_UNARMED"),true) 
					danslazone = true 
					sortir = false 
				end 
			else 
				if not sortir then 
					ESX.ShowNotification("Vous n etes plus dans une ~r~zone safe~s~ !")	 
					NetworkSetFriendlyFireOption(true) 
					sortir = true 
					danslazone = false 
				end 
			end 
			if danslazone then 
				DisableControlAction(2, 37, true) 
				DisablePlayerFiring(player,true)  
				DisableControlAction(0, 106, true)  
				if IsDisabledControlJustPressed(2, 37) then  
					SetCurrentPedWeapon(player,GetHashKey("WEAPON_UNARMED"),true)  
					ESX.ShowNotification("Vous ne pouvez pas utiliser ~r~vos armes~s~ dans ~g~une zone safe~s~ !")	 
				end 
				if IsDisabledControlJustPressed(0, 106) then  
					SetCurrentPedWeapon(player,GetHashKey("WEAPON_UNARMED"),true)  
					ESX.ShowNotification("Vous ne pouvez pas ~r~vous battre~s~ dans ~g~une zone safe~s~ !")	 
				end 
			end 
		end 
	end
end)


Citizen.CreateThread(function()
	if Config.UtiliserSafeZone then 
		while not NetworkIsPlayerActive(PlayerId()) do 
			Citizen.Wait(0) 
		end	
		while true do 
			local playerPed = GetPlayerPed(-1) 
			local x, y, z = table.unpack(GetEntityCoords(playerPed, true)) 
			local minzone = 100000 
			for i = 1, #zones, 1 do 
				dist = Vdist(zones[i].x, zones[i].y, zones[i].z, x, y, z) 
				if dist < minzone then 
					minzone = dist zone = i 
				end 
				Citizen.Wait(15000) 
			end
		end 
	end
end)