print( "Callbacks:" ); dump( Callback, "  " )

print("Dan PB activated")

local addon_storage = ...
local config = addon_storage.config

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
  -- member_add( event )
end

local function handle_player_left( event )
  -- member_del( event )
end

local function handle_player( event )

  if ( event.name == "PlayerJoined" ) then
    handle_player_joined(event)
  elseif ( event.name == "PlayerLeft" ) then
    handle_player_left(event)
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

  if (not record[track_id][vehicle_id].LapTime) or (record[track_id][vehicle_id].LapTime > lap_time) then

    record[track_id][vehicle_id].LapTime = lap_time
    record[track_id][vehicle_id].Name = member.name
    dan.data.records[member.steamid] = record

    SavePersistentData()

    local ins = math.floor( lap_time / 1000 )
    local min = math.floor( ins / 60 )
    local sec = math.floor( ins - min * 60 )
    local ms  = math.floor( lap_time - (min * 60000) - (sec * 1000) )

    local lap_time_human = string.format("%02d:%02d.%03d", min, sec, ms)

    local vehicle_name = get_vehicle_name_by_id( vehicle_id )
    local message = "PB: " .. lap_time_human .. " " .. member.name .. " (" .. vehicle_name .. ")"

    SendChatToAll(message)
    log(message)

  end

end

local function handle_partipant_lap( event )

  dump_typed(event)

  if (event.attributes.CountThisLapTimes == 1) and (dan.members[event.refid].counting) then
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

    if type( event ) == "table" then

      if ( event.type == "Session" ) then

        handle_session(event)

      elseif ( event.type == "Player" ) then

        handle_player(event)

      elseif ( event.type == "Participant" ) then

        handle_partipant(event)

      end

    end

  end


end

-- RegisterCallback( pb_main )
-- EnableCallback( Callback.Tick )
-- EnableCallback( Callback.EventLogged )
EnableCallback( Callback.ParticipantCreated )
EnableCallback( Callback.ParticipantRemoved )

register_module(pb_main)

-- string name: string SessionCreated
-- string type: string Session
-- string time: number 1738303096
-- string index: number 0
-- string attributes:

-- string name: string SessionDestroyed
-- string type: string Session
-- string time: number 1738303377
-- string index: number 31
-- string attributes:

-- string name: string PlayerJoined
-- string type: string Player
-- string refid: number 61632
-- string time: number 1738303096
-- string index: number 1
-- string attributes:
--   string SteamId: string 76561197979302088
--   string Name: string Daan

-- string name: string PlayerLeft
-- string type: string Player
-- string refid: number 61632
-- string time: number 1738303377
-- string index: number 30
-- string attributes:
--   string GameReasonId: number 1
--   string Reason: string left

-- string name: string StageChanged
-- string type: string Session
-- string time: number 1738303214
-- string index: number 12
-- string attributes:
--   string NewStage: string Race1
--   string PreviousStage: string Practice1

-- string name: string State
-- string index: number 8
-- string type: string Participant
-- string time: number 1738301176
-- string attributes:
--   string PreviousState: string InGarage
--   string NewState: string Racing
-- string refid: number 43968
-- string participantid: number 1

-- string name: string Impact
-- string index: number 42
-- string type: string Participant
-- string time: number 1738301737
-- string attributes:
--   string CollisionMagnitude: number 882
--   string OtherParticipantId: number -1
-- string refid: number 27328
-- string participantid: number 2


-- string name: string CutTrackStart
-- string index: number 41
-- string type: string Participant
-- string time: number 1738301727
-- string attributes:
--   string Lap: number 1
--   string IsMainBranch: number 1
--   string RacePosition: number 1
--   string LapTime: number 20156
-- string refid: number 27328
-- string participantid: number 2

-- string name: string CutTrackEnd
-- string participantid: number 5
-- string type: string Participant
-- string refid: number 61632
-- string time: number 1738303296
-- string index: number 21
-- string attributes:
--   string PenaltyValue: number 0
--   string PenaltyThreshold: number 0
--   string ElapsedTime: number 3175
--   string SkippedTime: number 0
--   string PlaceGain: number 0

-- CLEAR LAP
-- string name: string Lap
-- string index: number 35
-- string type: string Participant
-- string time: number 1738301701
-- string attributes:
--   string CountThisLapTimes: number 1
--   string Sector2Time: number 14140
--   string Sector1Time: number 18760
--   string LapTime: number 43663
--   string DistanceTravelled: number 6339
--   string Sector3Time: number 10763
--   string RacePosition: number 1
--   string Lap: number 0
-- string refid: number 27328
-- string participantid: number 2

-- INVALID LAP
-- string name: string Lap
-- string index: number 46
-- string type: string Participant
-- string time: number 1738301771
-- string attributes:
--   string CountThisLapTimes: number 1
--   string Sector2Time: number 39781
--   string Sector1Time: number 20043
--   string LapTime: number 70759
--   string DistanceTravelled: number 3230
--   string Sector3Time: number 10935
--   string RacePosition: number 1
--   string Lap: number 1
-- string refid: number 27328
-- string participantid: number 2