if not dan.data.records then dan.data.records = {} end

print("Dan PB activated")

local function hander_session_created( event )
  dan.members = {}
end

local function hander_session_destroyed( event )
  dan.members = {}
end

local function handle_session( event )

    if ( event.name == "SessionCreated" ) then
      hander_session_created(event)
    elseif ( event.name == "SessionDestroyed" ) then
      hander_session_destroyed(event)
    end

end

local function handle_player_joined( event )
  member_add( event )
end

local function handle_player_left( event )
  member_del( event )
end

local function handle_command_pb( event )

  local member = dan.members[event.refid]
  local track_id = session.attributes.TrackId
  local vehicle_id = session.members[event.refid].attributes.VehicleId

  if (dan.data.records[member.steamid]) and 
     (dan.data.records[member.steamid][track_id]) and 
     (dan.data.records[member.steamid][track_id][vehicle_id]) and
     (dan.data.records[member.steamid][track_id][vehicle_id].LapTime ~= nil)

  then

    local lap_time = dan.data.records[member.steamid][track_id][vehicle_id].LapTime
    -- SendChatToMember( event.refid, "PB: " .. ms_to_human( lap_time ) )

    local lap_time_human = ms_to_human( lap_time )
    local vehicle_name = get_vehicle_name_by_id( vehicle_id )
    local message = "PB: " .. lap_time_human .. " " .. member.name .. " (" .. vehicle_name .. ")"
    SendChatToAll( message )

  else

    SendChatToMember( event.refid, "PB: no records" )

  end

end

local function handle_command_pb_reset( event )

  local member = dan.members[event.refid]
  local track_id = session.attributes.TrackId
  local vehicle_id = session.members[event.refid].attributes.VehicleId

  if (dan.data.records[member.steamid]) and
     (dan.data.records[member.steamid][track_id]) and
     (dan.data.records[member.steamid][track_id][vehicle_id]) and
     (dan.data.records[member.steamid][track_id][vehicle_id].LapTime)
  then

    dan.data.records[member.steamid][track_id][vehicle_id].LapTime = nil
    SavePersistentData()
    SendChatToMember( event.refid, "PB has been removed" )

  end

end

local function handle_player_chat( event )
  
  local message = event.attributes.Message

  if message == "/pb" then

    handle_command_pb( event )

  elseif message == "/pb reset" then

    handle_command_pb_reset( event )

  end

end

local function handle_player( event )

  if ( event.name == "PlayerJoined" ) then

    handle_player_joined( event )

  elseif ( event.name == "PlayerLeft" ) then

    handle_player_left( event )

  elseif event.name == "PlayerChat" then

    handle_player_chat( event )

  end

end

local function handle_partipant_state( event )

  if event.attributes.NewState == "Racing" then
    dan.members[event.refid].counting = true
  else
    dan.members[event.refid].counting = false
  end

end

local function handle_partipant_impact( event )
  dan.members[event.refid].counting = false
end

local function handle_partipant_cut_track_start( event )
  dan.members[event.refid].counting = false
end

local function handle_partipant_cut_track_end( event )
  dan.members[event.refid].counting = false
end

local function handle_valid_lap( event )

  if not dan.data.records then dan.data.records = {} end

  local member = dan.members[event.refid]
  local track_id = session.attributes.TrackId
  local vehicle_id = session.members[event.refid].attributes.VehicleId
  local lap_time = event.attributes.LapTime
  local record = dan.data.records[member.steamid]

  if not record then record = {} end
  if not record[track_id] then record[track_id] = {} end
  if not record[track_id][vehicle_id] then record[track_id][vehicle_id] = {} end

  if ( not record[track_id][vehicle_id].LapTime ) or
     ( record[track_id][vehicle_id].LapTime > lap_time )
  then

    record[track_id][vehicle_id].LapTime = lap_time
    record[track_id][vehicle_id].Name = member.name
    dan.data.records[member.steamid] = record

    SavePersistentData()

    local lap_time_human = ms_to_human( lap_time )
    local vehicle_name = get_vehicle_name_by_id( vehicle_id )
    local message = "PB: " .. lap_time_human .. " " .. member.name .. " (" .. vehicle_name .. ")"

    SendChatToAll(message)
    log(message)

  end

end

local function handle_partipant_lap( event )

  dump_typed(event)

  if (event.attributes.CountThisLapTimes == 1) and 
    (event.attributes.Sector1Time > 0) and 
    (event.attributes.Sector2Time > 0) and 
    (event.attributes.Sector3Time > 0) and 
    (dan.members[event.refid].counting)
  then
    handle_valid_lap(event)
  else
    dan.members[event.refid].counting = true
  end

end

local function handle_partipant( event )

  if ( event.name == "State" ) then

    handle_partipant_state(event)

  elseif ( event.name == "Impact" ) then

    handle_partipant_impact(event)

  elseif ( event.name == "CutTrackStart" ) then

    handle_partipant_cut_track_start(event)

  elseif ( event.name == "CutTrackEnd" ) then

    handle_partipant_cut_track_end(event)

  elseif ( event.name == "Lap" ) then

    handle_partipant_lap(event)

  end

end

function pb_main( callback, ... )

  if callback == Callback.EventLogged then

    local event = ...

    if ( event.type == "Session" ) then

      handle_session( event )

    elseif ( event.type == "Player" ) then

      handle_player( event )

    elseif ( event.type == "Participant" ) then

      handle_partipant( event )

    end

  end

end

RegisterCallback( pb_main )

EnableCallback( Callback.EventLogged )
EnableCallback( Callback.ParticipantCreated )
EnableCallback( Callback.ParticipantRemoved )

