ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback("dhz_jail:GetPlayers",function(source,cb)
    local playerlist = {}
    for _,v in pairs(GetPlayers()) do
        table.insert(playerlist, {
            name = GetPlayerName(v),
            id = v
        })
    end
    cb(playerlist or {})
end)

ESX.RegisterServerCallback('dhz:getUsergroup', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local group = xPlayer.getGroup()
	cb(group)
end)

TriggerEvent('es:addGroupCommand', 'jail', 'admin', function(source, args, user)
	if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then
		TriggerEvent('esx_jailer:sendToJail', source, tonumber(args[1]), tonumber(args[2] * 60))
	else
		TriggerClientEvent('esx:showAdvancedNotification', source, 'Prison', 'Juge', 'ID invalide ou temps invalide', 'CHAR_BLOCKED', 2)
	end
end, function(source, args, user)
	TriggerClientEvent('esx:showAdvancedNotification', source, 'Prison', 'Juge', 'Vous n\'avez pas les permissions suffisante', 'CHAR_BLOCKED', 2)
end, {help = "Mettre un joueur en prison", params = {{name = "id", help = "Prisonnier"}, {name = "Temps", help = "Durée du jail"}}})

TriggerEvent('es:addGroupCommand', 'unjail', 'admin', function(source, args, user)
	if args[1] then
		if GetPlayerName(args[1]) ~= nil then
			TriggerEvent('esx_jailer:unjailQuest', tonumber(args[1]))
		else
			TriggerClientEvent('esx:showAdvancedNotification', source, 'Prison', 'Juge', 'ID invalide', 'CHAR_BLOCKED', 2)
		end
	else
		TriggerEvent('esx_jailer:unjailQuest', source)
	end
end, function(source, args, user)
	TriggerClientEvent('esx:showAdvancedNotification', source, 'Prison', 'Juge', 'Vous n\'avez pas les permissions suffisante', 'CHAR_BLOCKED', 2)
end, {help = "Sortir quelqu'un de prison", params = {{name = "id", help = "Prisonnier"}}})

RegisterServerEvent('esx_jailer:sendToJail')
AddEventHandler('esx_jailer:sendToJail', function(source, target, jailTime)
	local player = source
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			MySQL.Async.execute("UPDATE jail SET jail_time=@jt WHERE identifier=@id", {['@id'] = identifier, ['@jt'] = jailTime})
		else
			MySQL.Async.execute("INSERT INTO jail (identifier,jail_time) VALUES (@identifier,@jail_time)", {['@identifier'] = identifier, ['@jail_time'] = jailTime})
		end
	end)
	
	TriggerClientEvent('esx:showAdvancedNotification', player, 'Prison', 'Juge', GetPlayerName(target)..' est maintenant en prison pour '..ESX.Round(jailTime / 60)..' minutes', 'CHAR_BLOCKED', 2)
	TriggerClientEvent('esx_policejob:unrestrain', target)
	TriggerClientEvent('esx_jailer:jail', target, jailTime)
end)


RegisterServerEvent('esx_jailer:checkJail')
AddEventHandler('esx_jailer:checkJail', function()
	local player = source 
	local identifier = GetPlayerIdentifiers(player)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			TriggerClientEvent('esx_jailer:jail', player, tonumber(result[1].jail_time))
		end
	end)
end)

RegisterServerEvent('esx_jailer:unjailQuest')
AddEventHandler('esx_jailer:unjailQuest', function(source)
	if source ~= nil then
		unjail(source)
	end
end)

RegisterServerEvent('esx_jailer:unjailTime')
AddEventHandler('esx_jailer:unjailTime', function()
	unjail(source)
end)

RegisterServerEvent('esx_jailer:updateRemaining')
AddEventHandler('esx_jailer:updateRemaining', function(jailTime)
	local identifier = GetPlayerIdentifiers(source)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			MySQL.Async.execute("UPDATE jail SET jail_time=@jt WHERE identifier=@id", {['@id'] = identifier, ['@jt'] = jailTime})
		end
	end)
end)

function unjail(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM jail WHERE identifier=@id', {['@id'] = identifier}, function(result)
		if result[1] ~= nil then
			MySQL.Async.execute('DELETE from jail WHERE identifier = @id', {['@id'] = identifier})
		end
	end)
	TriggerClientEvent('esx_jailer:unjail', target)
end
