-- Dynamic Race System

local drs_enabled = true
local race_mode = false
local max = 15
local min = 5

local race_length = 10

local function handle_player_joined( event )

  if (drs_enabled) and (not race_mode) and (#dan.members >= max) then

    race_mode = true

    if session.next_attributes.RaceLength == 0 then

      SetSessionAttributes( { RaceLength = race_length } )
      SetNextSessionAttributes( { RaceLength = race_length } )
      
    end

    SendChatToAll("[DynamicRace] Reached " .. max .. " players. Enable the race (next lobby)")

  end

end

local function handle_player_left( event )

  if (drs_enabled) and (race_mode) and (#dan.members < min) then

    race_mode = false

    if session.next_attributes.RaceLength ~= 0 then

      SetSessionAttributes( { RaceLength = 0 } )
      SetNextSessionAttributes( { RaceLength = 0 } )
      
    end

    SendChatToAll("[DynamicRace] Less than " .. min .. " players. Disable the race (next lobby)")

  end

end

local function handle_command_drs_status( event )

  if (drs_enabled) then

    SendChatToMember( event.refid, "DRS enabled" )

  else

    SendChatToMember( event.refid, "DRS disabled" )

  end

end

local function handle_command_drs_enable( event )

  if (drs_enabled) then

    SendChatToMember( event.refid, "DRS already enabled" )

  else

    drs_enabled = true
    SendChatToMember( event.refid, "DRS enabled" )

  end

end

local function handle_command_drs_disable( event )

  if (drs_enabled) then

    drs_enabled = false
    SendChatToMember( event.refid, "DRS disabled" )

  else

    SendChatToMember( event.refid, "DRS already disabled" )

  end

end

local function handle_player_chat( event )
  
  local message = event.attributes.Message

  if (message == "/drs") or (message == "/drs status") then

    handle_command_drs_status( event )

  elseif message == "/drs enable" then

    handle_command_drs_enable( event )

  elseif message == "/drs disable" then

    handle_command_drs_disable( event )

  end

end

local function handle_event_player( event )
  
  if event.name == "PlayerJoined" then

    handle_player_joined( event )

  elseif event.name == "PlayerLeft" then

    handle_player_left( event )

  elseif event.name == "PlayerChat" then

    handle_player_chat( event )

  end

end

function dr_main(callback, ...)

  -- Handle event
  if callback == Callback.EventLogged then

    local event = ...

    if event.type == "Player" then

      handle_event_player( event )

    end

  end -- callback == Callback.EventLogged

end

register_module(dr_main)

print("Dan DRS activated")
