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
	  AdvanceSession(true)

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

	elseif dan.members[ tonumber( refid ) ].is_admin then

		SendChatToMember(event.refid, "Admin can't be kicked")
		log( dan.members[ event.refid ].name .. " tried to kick another admin " .. dan.members[ tonumber( refid ) ].name )

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

local function handle_admin_command( event )

	local message = event.attributes.Message

	if message == "/help" then

		if dan.members[event.refid].is_admin then

			show_admin_commands( event.refid )

		end

		show_user_commands( event.refid )

	elseif starts_with(message, "/restart") then

		handle_command_restart( event )

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

	elseif starts_with(message, "/practice") then

		handle_command_practice( event )

	elseif starts_with(message, "/qualify") then

		handle_command_qualify( event )

	elseif starts_with(message, "/race") then

		handle_command_race( event )

	elseif starts_with(message, "/kick") then

		handle_command_kick( event )

	end

end

local function handle_command_player_chat( event )

	local message = event.attributes.Message

	-- Handle admin commands
	if dan.members[event.refid].is_admin then

		handle_admin_command( event )

	else -- user is not an admin

		log("CHAT [" .. dan.members[event.refid].name .. "] " .. message)

	end -- dan.members[event.refid].is_admin

end

local function show_welcome( refid )

	send_later( 3000, refid, dan.config.welcome )

end

local function handle_player_joined( event )

	member_add( event )
  show_welcome( event.refid )

	if dan.members[ event.refid ].is_admin then

    show_admin_commands( event.refid, 3000 )

    log("Joined admin " .. dan.members[ event.refid ].name)

  end

  show_user_commands( event.refid, 3000 )

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

		handle_command_player_chat( event )

	end -- event.name == "PlayerChat"

end

local function handle_participant_created( event )

	SendChatToMember( event.refid, "Type /help in chat to get a list of available commands")

end

local function handle_event_participant( event )

	if event.name == "ParticipantCreated" then

		handle_participant_created( event )

	end

end

-- ----------------------------------------------------------------------------
-- Main addon callback
local function dsc_main( callback, ... )

	-- Regular tick
	if callback == Callback.Tick then

		tick()
		flush()

	-- else

	-- 	dump_callback( callback, ... )

	end

  -- Disable overtime
	if callback == Callback.SessionAttributesChanged then

		handle_session_attributes_changed()

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

		if event.type == "Player" then

			handle_event_player( event )

		end

		if event.type == "Participant" then

			handle_event_participant( event )

		end

	end -- callback == Callback.EventLogged


	-- pb_main( callback, ... )
	invoke_modules( callback, ... )

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

-- callback: EventLogged
-- string time: number 1738417289
-- string attributes:
--   string PreviousStage: string Practice1
--   string NewStage: string Race1
--   string Length: number 10
-- string name: string StageChanged
-- string index: number 30
-- string type: string Session
