
local function handle_partipant_created( event )

  participants[event.participantid] = {}
  participants[event.participantid].refid = event.refid

end

local function handle_partipant_destroyed( event )
  
  if participants[event.participantid] then

    participants[event.participantid] = nil

  end

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

function convoy(callback, ...)

  if callback == Callback.EventLogged then

    local event = ...

    if ( event.type == "Player" ) then

      handle_player( event )

    elseif ( event.type == "Participant" ) then

      handle_partipant( event )

    end

  end

end

register_module(convoy)