-- Dynamic Race System

if not dan.config.drs then dan.config.drs = {} end
if not dan.config.drs.race then dan.config.drs.race = {} end

local drs_enabled = dan.config.drs.enabled
local race_length = dan.config.drs.race.length
local min = dan.config.drs.min
local max = dan.config.drs.max

local race_mode = false

local function handle_player_joined( event )

  DEBUG("[DRS] handle_player_joined entered")
  DEBUG("drs_enabled=" .. tostring(drs_enabled) .. " race_mode=" .. tostring(race_mode) .. " #dan.members=" .. table.size(dan.members))

  if (drs_enabled) and (not race_mode) and (table.size(dan.members) >= max) and
     (session.next_attributes.RaceLength == 0)
  then

    DEBUG("[DRS] handle_player_joined enable race_mode")

    race_mode = true

    if (session.attributes.RaceLength == 0) then
      SetSessionAttributes( { RaceLength = race_length } )
    end


    if (session.next_attributes.RaceLength == 0) then
      SetNextSessionAttributes( { RaceLength = race_length } )
    end

    SendChatToAll("[DynamicRace] Reached " .. max .. " players. Enabling the race (next lobby)")

  else

    DEBUG("[DRS] handle_player_joined not all conditions are met")

  end

end

local function handle_player_left( event )

  DEBUG("[DRS] handle_player_left entered")
  DEBUG("drs_enabled=" .. tostring(drs_enabled) .. " race_mode=" .. tostring(race_mode) .. " #dan.members=" .. table.size(dan.members))

  if (drs_enabled) and (race_mode) and (table.size(dan.members) < min) then

    DEBUG("[DRS] handle_player_left disable race_mode")

    race_mode = false

    if (session.attributes.RaceLength ~= 0) then
      SetSessionAttributes( { RaceLength = 0 } )
    end


    if (session.next_attributes.RaceLength ~= 0) then
      SetNextSessionAttributes( { RaceLength = 0 } )
    end

    SendChatToAll("[DynamicRace] Less than " .. min .. " players. Disable the race (next lobby)")

  else

    DEBUG("[DRS] handle_player_left not all conditions are met")

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
