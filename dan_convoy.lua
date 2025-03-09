local convoys = {}
local members = {}

local function find_convoy_by( refid )

  local result = nil

  for num, convoy in ipairs( convoys ) do

    if (convoy.leader == refid) or (table.contains( convoy.members, refid )) then

      result = num

    end

  end

  return result

end

local function already_member_of_convoy( event )

  local message = string.format( "You are already a member of the convoy. Type '/convoy leave' to leave")
  SendChatToMember( event.refid, message )

end

local function handle_player_joined( event )

end

local function handle_convoy_status( event )

  if table.size( convoys ) > 0 then

    for num, convoy in ipairs( convoys ) do

      local message = string.format( "#%d leader: %s, size: %d", num, members[event.refid], table.size( convoy.members ) + 1 )
      SendChatToMember( event.refid, message )

    end

  else

    SendChatToMember( event.refid, "Convoys not found" )

  end

end

local function handle_convoy_new( event )

  if find_convoy_by( event.refid ) then

    already_member_of_convoy( event )

  else

    table.insert( convoys, { leader = event.refid, members = {} } )
    members[event.refid] = dan.members[event.refid].name

    local message = string.format( "%s created a new convoy #%d", dan.members[event.refid].name, table.size( convoys ) )
    SendChatToAll( message )
    log( message )

  end

end

local function handle_convoy_join( event )

  if find_convoy_by( event.refid ) then

    already_member_of_convoy( event )

  else

    if convoys[1] then

      table.insert( convoys[1].members, event.refid )
      members[event.refid] = dan.members[event.refid].name

      SendChatToAll( members[event.refid] .. " joined to the convoy #1" )

    else

      SendChatToMember( event.refid, "No convoys found. Type '/convoy start' to start a new convoy." )

    end

  end

end

local function handle_convoy_join_n( event )

  if find_convoy_by( event.refid ) then

    already_member_of_convoy( event )

  else

    local num = tonumber(string.match(event.attributes.Message, '%d+'))

    if num then

      if convoys[num] then

        table.insert( convoys[num].members, event.refid )
        members[event.refid] = dan.members[event.refid].name

        SendChatToAll( members[event.refid] .. " joined to the convoy #" .. num )

      else

        SendChatToMember( event.refid, "Convoy #" .. num .. " not found" )

      end

    else

      handle_convoy_join( event )

    end

  end

end

local function handle_convoy_leave_leader( event, num )

  if convoys[num].members[1] then

    old_leader = convoys[num].leader
    convoys[num].leader = convoys[num].members[1]
    table.remove( convoys[num].members, 1 )

    local message = string.format("%s left convoy #%d. New leader %s", members[old_leader], num, members[convoys[num].leader] )
    SendChatToAll( message )
    log( message )

  else

    old_leader = convoys[num].leader
    convoys[num] = nil

    local message = string.format("%s disbanded the convoy #%d", members[old_leader], num )
    SendChatToAll( message )
    log( message )

  end

end

local function handle_convoy_leave_member( event, num )

  for idx, refid in ipairs( convoys[num].members ) do

    if refid == event.refid then

      convoys[num].members[idx] = nil

      local message = string.format("%s left convoy #%d", members[event.refid], num )
      SendChatToAll( message )
      log( message )
      break

    end

  end

end


local function handle_convoy_leave( event )

  local num = find_convoy_by( event.refid )

  if num then

    if convoys[num].leader == event.refid then

      handle_convoy_leave_leader( event, num )

    else

      handle_convoy_leave_member( event, num )

    end

    members[event.refid] = nil

  else

    SendChatToMember( event.refid, "You are not a member of any convoy" )

  end

end

local function handle_player_left( event )

  local num = find_convoy_by( event.refid )

  if num then

    if convoys[num].leader == event.refid then

      handle_convoy_leave_leader( event, num )

    else

      handle_convoy_leave_member( event, num )

    end

    members[event.refid] = nil

  end

end

local function handle_player_chat( event )

  local message = event.attributes.Message

  if message == "/convoy" then

    handle_convoy_status( event )

  elseif message == "/convoy new" then

    handle_convoy_new( event )

  elseif message == "/convoy join" then

    handle_convoy_join( event )

  elseif starts_with(message, "/convoy join ") then

    handle_convoy_join_n( event )

  elseif message == "/convoy leave" then

    handle_convoy_leave( event )

  end

end

local function handle_player( event )

  if event.name == "PlayerJoined" then

    handle_player_joined( event )

  elseif event.name == "PlayerLeft" then

    handle_player_left( event )

  elseif event.name == "PlayerChat" then

    handle_player_chat( event )

  end

end

local function handle_partipant_state( event )
  -- body
end

local function handle_partipant_lap( event )
  -- body
end

local function handle_partipant_created( event )

end

local function handle_partipant_destroyed( event )
  
end

local function handle_partipant( event )

  if ( event.name == "State" ) then

    handle_partipant_state( event )

  elseif ( event.name == "Lap" ) then

    handle_partipant_lap( event )

  elseif ( event.name == "ParticipantCreated" ) then

    handle_partipant_created( event )

  elseif ( event.name == "ParticipantDestroyed" ) then

    handle_partipant_destroyed( event )

  end

end

function convoy_main(callback, ...)

  if callback == Callback.EventLogged then

    local event = ...

    if ( event.type == "Player" ) then

      handle_player( event )

    elseif ( event.type == "Participant" ) then

      handle_partipant( event )

    end

  end

end

register_module( convoy_main )

add_user_commands({

  " /convoy - shows the status of convoys",
  " /convoy new - create a new convoy",
  " /convoy join - join the first convoy",
  " /convoy join N - join the Nth convoy",
  " /convoy leave - leave the convoy",
  -- " /convoy start - the convoy starts moving"

})