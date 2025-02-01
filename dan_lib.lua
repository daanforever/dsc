local addon_storage = ...
local config = addon_storage.config
local addon_data = addon_storage.data

if not dan then dan = {} end
if not dan.modules then dan.modules = {} end
if not dan.members then dan.members = {} end
if not dan.scheduled_broadcasts then dan.scheduled_broadcasts = {} end
if not dan.scheduled_messages then dan.scheduled_messages = {} end
if not config.admins then config.admins = {} end

dan.data = addon_storage.data
local intkey_table_names = { records = true }
dan.data = table.deep_copy_normalized( dan.data, intkey_table_names )
addon_storage.data = dan.data

if not dan.data then dan.data = {} end

function log( text )

  local text = text or ''
  local ts = ''
  ts = tostring("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [DSC]: " .. text)
  return print(ts)

end

function register_module( callback )
  table.insert(dan.modules, callback)
end

function invoke_modules( ... )

  for _, f in ipairs(dan.modules) do
    f(...)
  end

end

function member_add( event )

  local refid = event.refid

  if dan.members[refid] ~= nil then return end

  dan.members[refid] = {}
  dan.members[refid].name = event.attributes.Name
  dan.members[refid].steamid = tostring(event.attributes.SteamId)
  dan.members[refid].is_admin = is_admin(dan.members[refid].steamid)

  if dan.members[refid].is_admin then
    send_later(3000, refid, {
      "Admin privileges granted",
      "Available commands:",
      "/next - restart practice or transition from practice to racing",
      "/kick ID reason - kick player by ID (from /players)",
      "Example: /kick 123 Rammed and blocked the road",
      "/players - get list in format: ID Name",
      "/race N - change the race duration to N minutes (min 5, max 60)"
    })
    log("Joined admin " .. dan.members[refid].name)
  else
    log("Joined user " .. dan.members[refid].name)
  end

end

function member_del( event )
  dan.members[event.refid] = nil
end

function is_admin( steamid )

  local result = false

  for i,v in pairs(config.admins) do
    if v == steamid then result = true end
  end

  return result

end

-- Usage: broadcast_later(1, ["Hello"])
-- delay in seconds
function broadcast_later(delay, messages)

  local send_time = delay + GetServerUptimeMs();

  if dan.scheduled_broadcasts[send_time] == nil then
    dan.scheduled_broadcasts[send_time] = messages
  else

    for _, message in ipairs(messages) do
      table.insert(dan.scheduled_broadcasts[send_time], message)
    end

  end

end

-- Usage: send_later(1, { 1001 : {"Hello", "World"} })
-- delay in seconds
function send_later(delay, refid, messages)

  -- log("send_later: " .. delay .. " " .. refid .. " " .. message)

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

function dump_list( names, list )
    for _, name in ipairs( names ) do
      print( "- " .. name .. " = " .. tostring( list[ name ] ) )
    end
end

function dump_callback(callback, ...)
  
  log( "Callback: " .. value_to_callback[callback] )

  local args = {...}

  for __, arg in ipairs(args) do

    if type( arg ) == "table" then
      dump_typed( arg )
    else
      print("Scalar: " .. arg)
    end

  end

  log( "session.attributes:")
  log( "  SessionStage: " .. session.attributes.SessionStage )
  log( "  SessionPhase: " .. session.attributes.SessionPhase )
  log( "  SessionState: " .. session.attributes.SessionState )

end

function starts_with( str, start )
  return str:sub(1, #start) == start
end

