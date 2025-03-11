# DSC (Dedicated Server Controller) for Automobilista 2

**DSC** is a LUA addon for the Automobilista 2 dedicated server, designed to enhance server management. It allows you to easily configure session conditions, manage players, track records, and more.

## Key Features

- **Session Condition Management**: Adjust race parameters such as weather, time of day, and session duration.
- **Session Control**: Start, stop, and restart sessions.
- **Kick Misbehaving Players**: Remove players who violate server rules.
- **Record Tracking and Display**: Automatically record lap times and display.
- **Safety Rating**: Evaluate player behavior on the track using a safety rating system.

## Installation and Usage

### Installation

1. Clone the repository or download the files into the addons folder of your Automobilista 2 dedicated server (`lua\dan_dsc`).
2. Configure the modules in the `dan_dsc.json` file by enabling or disabling the desired features.
3. Make a backup of your `server.cfg`
4. Open up the server.cfg file and ensure enableLuaApi is true and add dan_dsc to the luaApiAddons section.
```
luaApiAddons : [
    // Core server bootup scripts and helper functions. This will be always loaded first even if not specified here because it's an implicit dependency of all addons.
    "sms_base",

    // There may be other addons here.

    // Dan Dedicated Server Controller
    "dan_dsc"
]

```

5. After the first launch you can edit the `lua_config\dan_dsc_config.json` file.

### Usage

Once installed, the addon will start working automatically. You can manage its features via the server console or by editing the `dan_dsc.json` file.

## Key Files

- `lua\dan_dsc.json`: The main file that allows you to manage active modules.
- `lua_config\dan_dsc_config.json`: The configuration file that allows you to manage configuration parameters.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

Big thanks to x6GoyF for helping with testing and to all the players of ACR server.