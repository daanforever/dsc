local addon_storage = ...
local config = addon_storage.config
local addon_data = addon_storage.data

if not dan then dan = {} end
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

function member_add( event )

  local refid = event.refid

  if dan.members[refid] ~= nil then return end

  dan.members[refid] = {}
  dan.members[refid].name = event.attributes.Name
  dan.members[refid].steamid = tostring(event.attributes.SteamId)
  dan.members[refid].is_admin = is_admin(dan.members[refid].steamid)

  if dan.members[refid].is_admin then
    send_later(2100, refid, {
      "Admin privileges granted",
      "Available commands:",
      "/players - get list in format: ID Name",
      "/kick ID reason - kick player by ID (from /players)",
      "Example: /kick 123 Rammed and blocked the road",
      "/next - restart practice or transition from practice to racing"
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