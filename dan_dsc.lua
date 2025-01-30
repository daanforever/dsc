--[[

TODO:
* Write available commands to admins
* /race laps
* /qualification time
* /practice time
* /vote next
* /vote kick
* /list
* Personal best

DONE:
* /restart N
* Announce the end of the race

--]]

print( "Callbacks:" ); dump( Callback, "  " )

local addon_storage = ...
local config = addon_storage.config
local members = {}
local session_time_duration = 0
local scheduled_broadcasts = {}
local scheduled_restart = 0
local scheduled_advance = 0


if type( config.admins ) ~= "table" then config.admins = {} end

-- The tick that processes all queued sends
local function tick()

	local now = GetServerUptimeMs()

	for time, message in pairs( scheduled_broadcasts ) do

		if now >= time then

			SendChatToAll("[Server]: " .. message)
			scheduled_broadcasts[ time ] = nil

		end

	end

	if scheduled_restart > 0 and now >= scheduled_restart then

		scheduled_restart = 0
		ServerRestart()

	end

	if scheduled_advance > 0 and now >= scheduled_advance then

		scheduled_advance = 0
	  AdvanceSession(true)

	end

end

-- Helper functions -----------------------------------------------------------

local function log( text )
	local text = text or ''
	local ts = ''
	ts = tostring("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [DSC]: " .. text)
	return print(ts)
end

-- Usage: is_admin()
local function is_admin( steamid )
	local result = false

	for i,v in pairs(config.admins) do
		if v == steamid then result = true end
	end

	return result
end

local function dump_list( names, list )
		for _, name in ipairs( names ) do
			print( "- " .. name .. " = " .. tostring( list[ name ] ) )
		end
end

local function starts_with(str, start)
	return str:sub(1, #start) == start
 end

-- Usage: broadcast_later(1, "Hello")
-- delay in seconds
local function broadcast_later(delay, message)
	local send_time = delay * 1000 + GetServerUptimeMs();
	scheduled_broadcasts[send_time] = message
end

local function restart_later(delay)
	scheduled_restart = delay * 1000 + GetServerUptimeMs();
end

-- ----------------------------------------------------------------------------
-- Main addon callback
local function addon_callback( callback, ... )

	-- Regular tick
	if callback == Callback.Tick then
		tick()
	-- else
	-- 	local event = ...

	-- 	log("Dump callback: " .. value_to_callback[ callback ])
		
	-- 	if type(event) == "table" then
	-- 		dump_typed(event)
	-- 	else
	-- 		log(event)
	-- 	end

	-- 	log("************")
	end

  -- Disable overtime
	if callback == Callback.SessionAttributesChanged then
		local changed = ...

		-- log("Attributes changed:")
		-- dump_list(changed, session.attributes)

		if session.attributes["SessionState"] == "Race" and session.attributes["SessionPhase"] == "Green" then

			if session.attributes["SessionTimeElapsed"] == session.attributes["SessionTimeDuration"] then
				-- Elapsed >= Duration

				if scheduled_advance == 0 then

					SendChatToAll("The race is over!")
					SendChatToAll("30 seconds to cooldown")

					scheduled_advance = 30 * 1000 + GetServerUptimeMs();

				end

			end

		end

	end

	if callback == Callback.NextSessionAttributesChanged then
		local changed = ...

		log("NextAttributes changed:")
		dump_list(changed, session.next_attributes)
	end

	-- Handle event
	if callback == Callback.EventLogged then
		local event = ...

		if ( event.type == "Session" ) and ( event.name == "StateChanged" ) then
			if ( event.attributes.NewState == "Loading" ) then
				SavePersistentData()
			end
		end

		if ( event.type == "Session" ) and ( event.name == "SessionDestroyed" ) then
			members = {}
		end

		-- Handle event.type Player
		if event.type == "Player" then

			-- PlayerJoined
			if event.name == "PlayerJoined" then
				members[event.refid] = {}
				members[event.refid].name = event.attributes.Name
				members[event.refid].steamid = tostring(event.attributes.SteamId)
				members[event.refid].is_admin = is_admin(members[event.refid].steamid)

				if members[event.refid].is_admin then
					SendChatToMember( event.refid, "[DRB]: Administrator privileges granted")
					log("Joined admin " .. members[event.refid].name)
				else
					log("Joined user " .. members[event.refid].name)
				end
			end

			-- PlayerLeft
			if event.name == "PlayerLeft" then
				members[event.refid] = nil	
			end

			if event.name == "PlayerChat" then

  			local message = event.attributes.Message

				-- Handle admin commands
				if members[event.refid].is_admin then


					if starts_with(message, "/restart") then

						local default_restart_time = 60
						local restart_time = tonumber(string.match(message, '%d+'))

						if restart_time == nil then restart_time = default_restart_time end

						log("Received request to restart the server from " .. members[event.refid].name .. " " .. members[event.refid].steamid .. " in " .. restart_time .. " seconds")

						broadcast_later(0, "The server will restart in " .. restart_time .. " seconds.")

						if restart_time > 60 then
							broadcast_later(restart_time - 60, "The server will restart in 60 seconds.")
						end
						
						if restart_time > 30 then
							broadcast_later(restart_time - 30, "The server will restart in 30 seconds.")
						end

						if restart_time > 10 then
							broadcast_later(restart_time - 10, "The server will restart in 10 seconds.")
						end

						restart_later(restart_time)

					elseif message == "/advance" or message == "/next" then

						log("Received request to advance session from " .. members[event.refid].name .. " " .. members[event.refid].steamid)
						AdvanceSession(true)

					elseif message == "/stop" then

						log("Received request to stop session from " .. members[event.refid].name .. " " .. members[event.refid].steamid)
						StopSession()

					elseif starts_with(message, "/maxplayers") then

						local maxplayers = tonumber(string.match(message, '/maxplayers%s*(%d+)'))
						SendChatToMember( event.refid, "MaxPlayers=" .. maxplayers .. " effective next Lobby.")

						local attributes = { MaxPlayers = maxplayers }
						log("Received request to change MaxPlayers to " .. maxplayers)		

						SetNextSessionAttributes( attributes )

					end	

				else -- user is not an admin

					log("CHAT [" .. members[event.refid].name .. "] " .. message)

				end -- members[event.refid].is_admin

			end -- event.name == "PlayerChat"

		end -- event.type == "Player"

	end -- callback == Callback.EventLogged
end -- function addon_callback

-- Main
RegisterCallback( addon_callback )
-- EnableCallback( Callback.Tick )
-- EnableCallback( Callback.MemberStateChanged )
-- EnableCallback( Callback.EventLogged )
-- EnableCallback( Callback.ServerStateChanged )

-- EnableCallback( Callback.MemberStateChanged )
-- EnableCallback( Callback.ParticipantAttributesChanged )
EnableCallback( Callback.Tick )
-- EnableCallback( Callback.ServerStateChanged )
EnableCallback( Callback.EventLogged )
-- EnableCallback( Callback.MemberLeft )
EnableCallback( Callback.SessionAttributesChanged )
-- EnableCallback( Callback.MemberJoined )
-- EnableCallback( Callback.HostMigrated )
-- EnableCallback( Callback.SessionManagerStateChanged )
-- EnableCallback( Callback.ParticipantCreated )
-- EnableCallback( Callback.ParticipantRemoved )
EnableCallback( Callback.NextSessionAttributesChanged )
-- EnableCallback( Callback.MemberAttributesChanged )

log("DSC activated")

-- EOF --
