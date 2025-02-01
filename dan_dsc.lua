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

local addon_storage = ...
local config = addon_storage.config
local session_time_duration = 0
local scheduled_broadcasts = {}
local scheduled_restart = 0
local scheduled_advance = 0

-- The tick that processes all queued sends
local function tick()

	local now = GetServerUptimeMs()

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

local function dump_list( names, list )
		for _, name in ipairs( names ) do
			print( "- " .. name .. " = " .. tostring( list[ name ] ) )
		end
end

local function starts_with( str, start )
	return str:sub(1, #start) == start
 end

local function restart_later( delay )
	scheduled_restart = delay + GetServerUptimeMs();
end

local function handle_command_players( event )

	for refid, member in pairs(dan.members) do
		refid = string.format("%-7d", refid)
		SendChatToMember( event.refid,  refid .. " " .. member.name)
	end

end

local function handle_command_restart( message )

	local default_restart_time = 60000
	local restart_time = tonumber(string.match(message, '%d+')) * 1000

	if restart_time == nil then restart_time = default_restart_time end

	log(
		"Received request to restart the server from " .. 
		dan.members[event.refid].name .. " " .. 
		dan.members[event.refid].steamid .. " in " .. restart_time .. " seconds"
	)

	broadcast_later(0, {"The server will restart in " .. math.floor(restart_time / 1000) .. " seconds."})

	if restart_time > 60000 then
		broadcast_later(restart_time - 60000, {"The server will restart in 60 seconds."})
	end
	
	if restart_time > 30000 then
		broadcast_later(restart_time - 30000, {"The server will restart in 30 seconds."})
	end

	if restart_time > 10000 then
		broadcast_later(restart_time - 10000, {"The server will restart in 10 seconds."})
	end

	restart_later(restart_time)

end

local function handle_command_kick( event )

	local refid, reason = string.match(event.attributes.Message, '/kick%s+(%d+)%s+(.*)')

	if ( refid == nil ) or ( reason == nil ) then

		SendChatToMember(event.refid, "/kick ID reason")
		SendChatToMember(event.refid, "Example: /kick 0 rammed and blocked the road")

	elseif not dan.members[ tonumber( refid ) ] then

		SendChatToMember(event.refid, "Player with ID " .. refid .. " not found")

	else

		refid = tonumber(refid)
		message = "Kicked " .. dan.members[refid].name .. " by " .. 
		           dan.members[event.refid].name .. " \"" .. reason .. "\""
		
		SendChatToAll()
		KickMember( refid )
		log( message )

	end

end

local function handle_command_advance( event )

	SendChatToAll(dan.members[event.refid].name .. " changed session")
	log("Received request to advance session from " .. dan.members[event.refid].name .. " " .. dan.members[event.refid].steamid)
	AdvanceSession(true)

end

-- ----------------------------------------------------------------------------
-- Main addon callback
local function dsc_main( callback, ... )

	-- Regular tick
	if callback == Callback.Tick then

		tick()
		flush()

	end

  -- Disable overtime
	if callback == Callback.SessionAttributesChanged then
		local changed = ...

		-- log("Attributes changed:")
		-- dump_list(changed, session.attributes)

		if session.attributes["SessionState"] == "Race" and session.attributes["SessionPhase"] == "Green" then

			if session.attributes["SessionTimeElapsed"] >= session.attributes["SessionTimeDuration"] then
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

		log("Dump callback: " .. value_to_callback[ callback ])
		dump_typed( event )

		if ( event.type == "Session" ) and ( event.name == "StateChanged" ) then
			if ( event.attributes.NewState == "Loading" ) then
				SavePersistentData()
			end
		end

		if ( event.type == "Session" ) and ( event.name == "SessionDestroyed" ) then
			dan.members = {}
		end

		-- Handle event.type Player
		if event.type == "Player" then

			-- PlayerJoined
			if event.name == "PlayerJoined" then
				member_add( event )
			end

			-- PlayerLeft
			if event.name == "PlayerLeft" then
				member_del( event )
			end

			if event.name == "PlayerChat" then

  			local message = event.attributes.Message

				-- Handle admin commands
				if dan.members[event.refid].is_admin then

					if starts_with(message, "/restart") then

						handle_command_restart( message )

					elseif message == "/advance" or message == "/next" then

						handle_command_advance( event )

					elseif message == "/stop" then

						log("Received request to stop session from " .. dan.members[event.refid].name .. " " .. dan.members[event.refid].steamid)
						StopSession()

					elseif starts_with(message, "/maxplayers") then

						local maxplayers = tonumber(string.match(message, '/maxplayers%s*(%d+)'))
						SendChatToMember( event.refid, "MaxPlayers=" .. maxplayers .. " effective next Lobby.")

						local attributes = { MaxPlayers = maxplayers }
						log("Received request to change MaxPlayers to " .. maxplayers)		

						SetNextSessionAttributes( attributes )

	  			elseif message == "/players" then

	  				handle_command_players( event )

	  			elseif starts_with(message, "/kick") then

	  				handle_command_kick( event )

	  			end


				else -- user is not an admin

					log("CHAT [" .. dan.members[event.refid].name .. "] " .. message)

				end -- dan.members[event.refid].is_admin

			end -- event.name == "PlayerChat"

		end -- event.type == "Player"

	end -- callback == Callback.EventLogged


	pb_main(callback, ...)
end -- function dsc_main

-- Main
RegisterCallback( dsc_main )
-- EnableCallback( Callback.Tick )
-- EnableCallback( Callback.MemberStateChanged )
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
-- EnableCallback( Callback.NextSessionAttributesChanged )
-- EnableCallback( Callback.MemberAttributesChanged )

print("DSC activated")

-- EOF --
