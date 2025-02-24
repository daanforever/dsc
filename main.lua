if not dan.participants then dan.participants = {} end

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

  elseif callback == Callback.EventLogged then

    local event = ...

    if ( event.type == "Participant" ) then

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