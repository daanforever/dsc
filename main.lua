if not dan.participants then dan.participants = {} end

local save_data_interval = 10 * 1000

local function is_time_to_save_data()

  if dan.save_data_requested and ( (dan.save_data_requested + save_data_interval) < GetServerUptimeMs() ) then

    return true

  else

    return false

  end

end

local function handle_session_attributes_changed()

  if is_time_to_save_data() then

    SavePersistentData()

    dan.save_data_requested = false

  end

end

local function handle_session( event )

end

local function handle_partipant_created( event )

  dan.participants[event.participantid] = {}
  dan.participants[event.participantid].refid = event.refid

end

local function handle_partipant_destroyed( event )
  
  if dan.participants[event.participantid] then

    dan.participants[event.participantid] = nil

  end

end

local function handle_partipant( event )

  if ( event.name == "ParticipantCreated" ) then

    handle_partipant_created( event )

  elseif ( event.name == "ParticipantDestroyed" ) then

    handle_partipant_destroyed( event )

  end

end


local function main( callback, ... )

  if callback == Callback.Tick then

    flush()

  elseif callback == Callback.SessionAttributesChanged then
    -- used instead of Tick

    handle_session_attributes_changed()

  elseif callback == Callback.EventLogged then

    local event = ...

    if event.type == "Session" then

      handle_session( event )

    elseif event.type == "Participant" then

      handle_partipant( event )

    end

  end

  invoke_modules( callback, ... )

end

RegisterCallback( main )
EnableCallback( Callback.Tick )
EnableCallback( Callback.EventLogged )
EnableCallback( Callback.SessionAttributesChanged )
EnableCallback( Callback.ServerStateChanged )

-- EnableCallback( Callback.MemberStateChanged )

-- EnableCallback( Callback.MemberStateChanged )
-- EnableCallback( Callback.ParticipantAttributesChanged )
-- EnableCallback( Callback.MemberLeft )

-- EnableCallback( Callback.MemberJoined )
-- EnableCallback( Callback.HostMigrated )
-- EnableCallback( Callback.SessionManagerStateChanged )
-- EnableCallback( Callback.ParticipantCreated )
-- EnableCallback( Callback.ParticipantRemoved )
-- EnableCallback( Callback.NextSessionAttributesChanged )
-- EnableCallback( Callback.MemberAttributesChanged )