local function handle_player( event )
  -- body
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

register_module( convoy )