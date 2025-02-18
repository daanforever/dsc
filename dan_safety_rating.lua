if not dan.data.sr then dan.data.sr = {} end

local watch_time = 5000
local black = {}
local white = {}
local kick_rating = 0.1

local function handle_session_attributes_changed()

  local now = GetServerUptimeMs()
  local changed = false

  for participant_id, time in pairs(white) do

    if now >= time then

      white[participant_id] = nil

    end

  end

  for pid, data in pairs(black) do

    if now >= data.timer then
      -- Time to punish

      local sr = dan.data.sr[data.steamid].sr
      local delta = 0 

      if sr > 1 then 

        delta = 1 / sr

      elseif sr > 0 then

        delta = 1 / 10 * sr

      end

      sr = sr - delta

      local message = "SR: " .. data.name .. " decrease " .. trunc2(sr) .. " (-" .. delta .. ")"
      log( message )
      -- SendChatToAll(message)

      if sr <= kick_rating then

        message = string.format("SR: %s has a dangerous SR level %.02f. Kicking", data.name, sr)
        SendChatToAll( message )

        if dan.members[data.refid] then
          -- Player is on the server

          KickMember( data.refid )

        end

      end

      dan.data.sr[data.steamid].sr = sr

      black[pid] = nil
      changed = true

    end

  end

  if changed then
    SavePersistentData()
  end

end

local function get_sr_text( event )

  local member = dan.members[event.refid]
  return "SR: " .. trunc2(dan.data.sr[member.steamid].sr) .. " " .. member.name

end

local function handle_command_sr( event )

  SendChatToAll( get_sr_text( event ) )

end

local function handle_player_chat( event )
  
  local message = event.attributes.Message

  if message == "/sr" then

    handle_command_sr( event )

  end

end

local function handle_player_joined( event )

  local member = dan.members[event.refid]

  if not dan.data.sr[member.steamid] then

    dan.data.sr[member.steamid] = {}
    dan.data.sr[member.steamid].sr = 1

  end

end

local function handle_player( event )

  if event.name == "PlayerJoined" then

    handle_player_joined( event )

  elseif event.name == "PlayerChat" then

    handle_player_chat( event )

  end

end

local function handle_partipant_state( event )
end

local function get_timer()

  return watch_time + GetServerUptimeMs()

end

local function fill_refid( w, refid )

  if w and (not w.refid) then
    -- we know steamid of participant_id

    w.refid = refid
    w.steamid = dan.members[refid].steamid
    w.name = dan.members[refid].name

  end

end

local function set_white_timer( pid )

    if pid >= 0 then
      -- other_participant_id = -1 when impact with wall

      white[pid] = get_timer()

    end

end

local function set_black_timer( pid )

    if pid >= 0 then
      -- other_participant_id = -1 when impact with wall

      if not black[pid] then black[pid] = {} end

      black[pid].timer = get_timer()

    end

end

local function handle_partipant_impact( event )

  -- single impact
  -- multiple impact

  -- string index: number 1498
  -- string name: string Impact
  -- string refid: number 56706
  -- string type: string Participant
  -- string participantid: number 4
  -- string attributes:
  --   string OtherParticipantId: number 20
  --   string CollisionMagnitude: number 1000

  local participant_id = event.participantid
  local other_participant_id = event.attributes.OtherParticipantId

  -- Currently do not take into account collisions with walls
  if other_participant_id < 0 then

    return

  end

  -- black[other_participant_id] missing steamid on the first impact
  fill_refid( black[participant_id], event.refid )

  if white[participant_id] then
    -- He accidentally got caught in the chain impact. No action required
    -- participant_id GOOD

  elseif white[other_participant_id] then
    -- other_participant_id GOOD

    if black[participant_id] then
      -- The guy is already being blacked
      -- participant_id BAD

    else
      -- He accidentally got caught in the chain impact
      -- participant_id GOOD

      set_white_timer( participant_id )

    end

  elseif black[participant_id] and black[other_participant_id] then
    -- Repeated impact. No action is required.

  elseif black[participant_id] then
    -- The chain impact of a good guy
    -- participant_id BAD
    -- other_participant_id GOOD

    set_white_timer( other_participant_id )

  elseif black[other_participant_id] then
    -- The chain impact of a good guy
    -- participant_id GOOD
    -- other_participant_id BAD

    set_white_timer( participant_id )

  else
    -- first or single impact

    set_black_timer( participant_id )
    set_black_timer( other_participant_id )

    fill_refid( black[participant_id], event.refid )
    -- we don't know steamid of other_participant_id

  end

end

local function handle_partipant_cut_track_start( event )
end

local function handle_partipant_cut_track_end( event )
end

local function handle_partipant_lap( event )

  local member = dan.members[event.refid]

  if (event.attributes.CountThisLapTimes == 1) and 
    (event.attributes.Sector1Time > 0) and 
    (event.attributes.Sector2Time > 0) and 
    (event.attributes.Sector3Time > 0)
  then

    local sr = dan.data.sr[member.steamid].sr
    local delta = 1 / sr

    local message = "SR: " .. member.name .. " increase " .. trunc2(sr) .. " (+" .. trunc2(delta) .. ")"
    log(message)

    dan.data.sr[member.steamid].sr = sr + delta
    SavePersistentData()

  end

end

local function handle_partipant_created( event )

  -- SendChatToAll( get_sr_text( event ) )

end


local function handle_partipant( event )

  if ( event.name == "State" ) then

    handle_partipant_state( event )

  elseif ( event.name == "Impact" ) then

    handle_partipant_impact( event )

  elseif ( event.name == "CutTrackStart" ) then

    handle_partipant_cut_track_start( event )

  elseif ( event.name == "CutTrackEnd" ) then

    handle_partipant_cut_track_end( event )

  elseif ( event.name == "Lap" ) then

    handle_partipant_lap( event )

  elseif ( event.name == "ParticipantCreated" ) then

    handle_partipant_created( event )

  end

end

function sr_main(callback, ...)

  if callback == Callback.SessionAttributesChanged then
    -- used instead of Tick

    handle_session_attributes_changed()

  elseif callback == Callback.EventLogged then

    local event = ...

    if ( event.type == "Player" ) then

      handle_player( event )

    elseif ( event.type == "Participant" ) then

      handle_partipant( event )

    end

  end

end

register_module(sr_main)

-- EOF --

-- [2025-02-16 12:47:21] [DSC]: Dump callback: EventLogged
-- string index: number 1498
-- string name: string Impact
-- string refid: number 56706
-- string type: string Participant
-- string participantid: number 4
-- string attributes:
--   string OtherParticipantId: number 20
--   string CollisionMagnitude: number 1000
-- string time: number 1739699240
-- [2025-02-16 12:47:21] [DSC]: Dump callback: EventLogged
-- string index: number 1499
-- string name: string Impact
-- string refid: number 10822
-- string type: string Participant
-- string participantid: number 20
-- string attributes:
--   string OtherParticipantId: number 4
--   string CollisionMagnitude: number 513
-- string time: number 1739699240
