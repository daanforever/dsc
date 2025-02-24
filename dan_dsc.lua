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
	  AdvanceSession(false)

	end

end

-- Helper functions -----------------------------------------------------------

local function restart_later( delay )
	scheduled_restart = delay + GetServerUptimeMs();
end

local function handle_command_players( event )

	for refid, member in pairs(dan.members) do
		refid = string.format("%-7d", refid)
		SendChatToMember( event.refid,  refid .. " " .. member.name)
	end

end

local function handle_command_restart( event )

	local default_restart_time = 60000
	local restart_time = tonumber(string.match(event.attributes.Message, '%d+')) * 1000

	if restart_time == nil then restart_time = default_restart_time end

	log(
		"Received request to restart the server from " .. 
		dan.members[event.refid].name .. " " .. 
		dan.members[event.refid].steamid .. " in " .. restart_time .. " seconds"
	)

	broadcast_message({"The server will restart in " .. math.floor(restart_time / 1000) .. " seconds."})

	if restart_time > 60000 then
		broadcast_message({"The server will restart in 60 seconds."}, restart_time - 60000)
	end
	
	if restart_time > 30000 then
		broadcast_message({"The server will restart in 30 seconds."}, restart_time - 30000)
	end

	if restart_time > 10000 then
		broadcast_message({"The server will restart in 10 seconds."}, restart_time - 10000)
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

	elseif dan.members[ tonumber( refid ) ].is_admin then

		SendChatToMember(event.refid, "Admin can't be kicked")
		log( dan.members[ event.refid ].name .. " tried to kick another admin " .. dan.members[ tonumber( refid ) ].name )

	else

		refid = tonumber(refid)
		message = "Kicked " .. dan.members[refid].name .. " by " .. 
		           dan.members[event.refid].name .. " \"" .. reason .. "\""
		
		SendChatToAll( message )
		KickMember( refid )
		log( message )

	end

end

local function handle_command_advance( event )

	if session.attributes.SessionStage ~= "Race1" then

		SendChatToAll(dan.members[event.refid].name .. " changed the session")
		log("Received request to advance session from " .. dan.members[event.refid].name .. " " .. dan.members[event.refid].steamid)
		AdvanceSession(true)

	end

end

local function handle_session_attributes_changed()

		if (session.attributes.SessionState == "Race") and (session.attributes.SessionPhase) == "Green" then

			if session.attributes["SessionTimeElapsed"] >= session.attributes["SessionTimeDuration"] then
				-- Elapsed >= Duration

				if (session.attributes.SessionStage == "Practice1") and (scheduled_advance == 0) then

					SendChatToAll("The race is over!")
					SendChatToAll("30 seconds to cooldown")

					scheduled_advance = 30 * 1000 + GetServerUptimeMs();

				end

			end

		end

end

local function handle_command_practice( event )

	local duration = tonumber(string.match(event.attributes.Message, '%d+'))

	if ( duration >= 5 ) or ( duration <= 90 ) then

		SendChatToAll( dan.members[event.refid].name .. " changed the practice duration to " .. duration .. " minutes" )
		SendChatToAll( "Changes will ONLY take effect in the next lobby" )
		log("Received a request from " .. dan.members[event.refid].name .. " to change PracticeLength to " .. duration .. " minutes" )		

		SetNextSessionAttributes( { PracticeLength = duration } )

	end

end

local function handle_command_qualify( event )

	local duration = tonumber(string.match(event.attributes.Message, '%d+'))

	if ( duration >= 5 ) or ( duration <= 90 ) then

		SendChatToAll( dan.members[event.refid].name .. " changed the qualify duration to " .. duration .. " minutes" )
		SendChatToAll( "Changes will ONLY take effect in the next lobby" )
		log("Received a request from " .. dan.members[event.refid].name .. " to change QualifyLength to " .. duration .. " minutes" )		

		SetNextSessionAttributes( { QualifyLength = duration } )

	end

end


local function handle_command_race( event )

	local duration = tonumber(string.match(event.attributes.Message, '%d+'))

	if ( duration >= 5 ) or ( duration <= 60 ) then

		SendChatToAll( dan.members[event.refid].name .. " changed the race duration to " .. duration .. " minutes" )
		SendChatToAll( "Changes will ONLY take effect in the next lobby (after the next race)" )
		log("Received a request from " .. dan.members[event.refid].name .. " to change RaceLength to " .. duration .. " minutes" )		

		SetNextSessionAttributes( { RaceLength = duration } )

	end

end

local function handle_command_rules( event )

	if dan.members[ event.refid ].is_admin then

		broadcast_message( dan.config.rules )

	else

		SendChatToMember( event.refid, dan.config.rules )

	end

end

local function handle_admin_command( event )

	local message = event.attributes.Message

	if starts_with(message, "/restart") then

		handle_command_restart( event )

	elseif message == "/advance" or message == "/next" then

		handle_command_advance( event )

	elseif starts_with(message, "/kick") then

		handle_command_kick( event )

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

	elseif starts_with(message, "/practice") then

		handle_command_practice( event )

	elseif starts_with(message, "/qualify") then

		handle_command_qualify( event )

	elseif starts_with(message, "/race") then

		handle_command_race( event )

	end

end

local function handle_command_help( event )

	if dan.members[event.refid].is_admin then

		show_admin_commands( event.refid, 0 )

	end

	show_user_commands( event.refid, 0 )

end

local function handle_user_command( event )

	local message = event.attributes.Message

	if message == "/help" then

		handle_command_help( event )

	elseif message == "/rules" then

		handle_command_rules( event )

	end

end

local function handle_player_chat( event )

	local message = event.attributes.Message

	if dan.members[event.refid].is_admin then

		handle_admin_command( event )

	end

	handle_user_command( event )

	log("CHAT [" .. dan.members[event.refid].name .. "] " .. message)

end

local function show_welcome( refid )

	send_later( 3000, refid, dan.config.welcome )

end

local function show_rules( refid )

	send_later( 3000, refid, dan.config.rules )

end

local function handle_player_joined( event )

	member_add( event )
  show_welcome( event.refid )
  show_rules( event.refid )

	if dan.members[ event.refid ].is_admin then

    -- show_admin_commands( event.refid, 3000 )

    log("Joined admin " .. dan.members[ event.refid ].name)

  end

  -- show_user_commands( event.refid, 3000 )

  send_later( 3000, event.refid, { "Type /help in chat to get a list of available commands" } )

end

local function hander_session_created( event )
  dan.members = {}
end

local function hander_session_destroyed( event )
  dan.members = {}
end

local function handle_event_session( event )

  if ( event.name == "SessionCreated" ) then

    hander_session_created(event)

  elseif ( event.name == "SessionDestroyed" ) then

    hander_session_destroyed(event)

  end

end

local function handle_event_player( event )

	-- PlayerJoined
	if event.name == "PlayerJoined" then

		handle_player_joined( event )

	end

	-- PlayerLeft
	if event.name == "PlayerLeft" then

		member_del( event )

	end

	if event.name == "PlayerChat" then

		handle_player_chat( event )

	end -- event.name == "PlayerChat"

end

local function handle_participant_created( event )

	-- SendChatToMember( event.refid, "Type /help in chat to get a list of available commands")

end

local function handle_event_participant( event )

	if event.name == "ParticipantCreated" then

		handle_participant_created( event )

	end

end

local function handle_event_logged( event )

  if ( event.type == "Session" ) then

    handle_event_session( event )

  elseif event.type == "Player" then

		handle_event_player( event )

	elseif event.type == "Participant" then

		handle_event_participant( event )

	end

end

-- ----------------------------------------------------------------------------
-- Main addon callback
local function dsc( callback, ... )

	-- Regular tick
	if callback == Callback.Tick then

		tick()

	elseif callback == Callback.SessionAttributesChanged then
	
		handle_session_attributes_changed()

	elseif callback == Callback.NextSessionAttributesChanged then

		local changed = ...

		log("NextAttributes changed:")
		dump_list(changed, session.next_attributes)

	elseif callback == Callback.EventLogged then

		local event = ...

		log("Dump callback: " .. value_to_callback[ callback ])
		dump_typed( event )

		handle_event_logged( event )

	end -- callback == Callback.EventLogged

end -- function dsc_main

register_module( dsc )

add_admin_commands({

  " /kick ID reason - kick player by ID (from /players)",
  " /next - restart practice or transition practice > qualify > racing",
  " /players - get list in format: ID Name",
  " /practice N - change the practice duration to N minutes (min 5, max 60)",
  " /qualify N - change the qualification duration to N minutes (min 5, max 60)",
  " /race N - change the race duration to N minutes (min 5, max 60)",
  " /rules - repeat the rules to everyone"

})

add_user_commands({

  " /help - shows available commands",
  " /rules - shows server rules"

})

print("DSC activated")

-- EOF --
