if not dan.data.migrations then dan.data.migrations = {} end
if not dan.data.migrations.applied then dan.data.migrations.applied = {} end

local list = {}

local function migration_sr_to_records()

  for steamid, data in pairs( dan.data.sr ) do

    if not dan.data.records[steamid] then dan.data.records[steamid] = {} end

    dan.data.records[steamid].sr = data.sr
    dan.data.sr[steamid] = nil

  end

end

local function register_migration( num, func )

  list[num] = func

end

local function run_migrations()

  local changed = false

  for num, func in pairs( list ) do

    if not dan.data.migrations.applied[num] then

      func()

      dan.data.migrations.applied[num] = true

      changed = true
      log("Migration " .. num .. " has beed applied")

    else

      log("Migration " .. num .. " already applied. Skip")

    end

  end

  if changed then request_save_data() end

end

function migrations(callback, ...)

  if callback == Callback.ServerStateChanged then

    local status = ...

    if status == "Running" then

      run_migrations()

    end

  end

end

register_migration( 2025022400, migration_sr_to_records )
register_module( migrations )