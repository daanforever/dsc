local debug_mode = true

local addon_storage = ...

if not dan then dan = {} end
if not dan.modules then dan.modules = {} end
if not dan.members then dan.members = {} end
if not dan.scheduled_broadcasts then dan.scheduled_broadcasts = {} end
if not dan.scheduled_messages then dan.scheduled_messages = {} end

dan.config = addon_storage.config
if not dan.config.admins then dan.config.admins = {} end
if not dan.config.welcome then dan.config.welcome = {} end
if not dan.config.rules then dan.config.rules = {} end

dan.data = addon_storage.data
if not dan.data then dan.data = {} end

local function normalize_storage( original )
  
  local result = {}

  if type( original ) ~= "table" then

    if k == tostring( tonumber( original ) ) then
      result = tonumber( original )
    else
      result = original
    end

  else

    for k, v in pairs( original ) do

      if k == tostring( tonumber( k ) ) then
        result[ tonumber(k) ] = normalize_storage( v )
      else
        result[ k ] = normalize_storage( v )
      end

    end

  end

  return result

end

dan.data = normalize_storage( dan.data )
addon_storage.data = dan.data

function DEBUG( text )

  if debug_mode then
    log( text )
  end

end

function log( text )

  local text = text or ''
  local ts = ''
  ts = tostring("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [DSC]: " .. text)
  return print(ts)

end

function show_user_commands( refid, delay )

  delay = delay or 0

  send_later(delay, refid, {

    "Commands:",
    " /pb - shows your Personal Best time",
    " /pb reset - resets your Personal Best time"

  })
  
end

function member_add( event )

  local refid = event.refid

  if dan.members[refid] ~= nil then return end

  dan.members[refid] = {}
  dan.members[refid].name = event.attributes.Name
  dan.members[refid].steamid = tonumber(event.attributes.SteamId)
  dan.members[refid].is_admin = is_admin(dan.members[refid].steamid)

end

function member_del( event )
  dan.members[event.refid] = nil
end

function is_admin( steamid )

  local result = false

  for _,v in pairs(dan.config.admins) do
    if tonumber(v) == steamid then result = true end
  end

  return result

end

-- Usage: broadcast_message(["Hello"], 1000)
-- delay in milliseconds
function broadcast_message(messages, delay)

  delay = delay or 0

  local send_time = delay + GetServerUptimeMs();

  if dan.scheduled_broadcasts[send_time] == nil then
    dan.scheduled_broadcasts[send_time] = messages

  else

    for _, message in ipairs(messages) do

      table.insert(dan.scheduled_broadcasts[send_time], message)

    end

  end

end

-- Usage: send_later(1, 1001, {"Hello", "World"})
-- delay in seconds
function send_later(delay, refid, messages)

  log("send_later: " .. delay .. " " .. refid .. " " .. #messages)

  local send_time = delay + GetServerUptimeMs();

  if dan.scheduled_messages[send_time] == nil then

    dan.scheduled_messages[send_time] = {}
    dan.scheduled_messages[send_time][refid] = messages

  elseif dan.scheduled_messages[send_time][refid] == nil then

    dan.scheduled_messages[send_time][refid] = messages

  else

    for _, message in ipairs(messages) do
      table.insert(dan.scheduled_messages[send_time][refid], message)
    end

  end

end

function flush()

  local now = GetServerUptimeMs()

  flush_broadcasts(now)
  flush_messages(now)

end

function flush_broadcasts(now)

  for time, messages in pairs( dan.scheduled_broadcasts ) do
    if now >= time then

      for _, message  in ipairs(messages) do
        SendChatToAll("[Server]: " .. message)
      end

      dan.scheduled_broadcasts[ time ] = nil
    end
  end

end

function flush_messages(now)

  for time, refids in pairs( dan.scheduled_messages ) do
    if now >= time then

      for refid, messages  in pairs(refids) do
        for _, message in ipairs(messages) do

          if dan.members[refid] then

            SendChatToMember(refid, message)
            log("Sent to " .. dan.members[refid].name .. ": " .. message) 

          end

        end
      end

      dan.scheduled_messages[ time ] = nil
    end
  end
  
end

function starts_with( str, start )
  return str:sub(1, #start) == start
end

function ms_to_human( lap_time )
    lap_time = tonumber( lap_time )

    local ins = math.floor( lap_time / 1000 )
    local min = math.floor( ins / 60 )
    local sec = math.floor( ins - min * 60 )
    local ms  = math.floor( lap_time - (min * 60000) - (sec * 1000) )

    return string.format("%02d:%02d.%03d", min, sec, ms)
end