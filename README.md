# Ultimate Discord Aceelerator
This is a Source Mod plugin that sends crash reports to discord with Accelerator.
This plugin is a modification of the "New Discord Accelerator" plugin by "Johnoclock" to implement more things to the plugin.

Do you have a suggestion for the plugin? You can make a **pull request!**

> ***(Warning: You have two versions of the ultimate discord accelerator, with more customization.)***

#### Commands

| **ConVars**                                   | **Default Value** | **Description**                                             |
|-----------------------------------------------|-------------------|-------------------------------------------------------------|
| `discord_crashlogger_enable`                  | `1`               | Enables or disables the plugin                              |
| `discord_webhook_crashlogger`                 | ``                | Private webhook link for crash logs                         |
| `discord_webhook_crashlogger_public`          | ``                | Public webhook link for crash logs                          |

> ***(Example of a webhook link: https://discord.com/api/webhooks/...)***

#### Private Webhook Commands

| **ConVars**                                   | **Default Value** | **Description**                                             |
|-----------------------------------------------|-------------------|-------------------------------------------------------------|
| `discord_crashlogger_private_crashid`         | `1`               | Enable/disable crash ID (private)                           |
| `discord_crashlogger_private_crashlink`       | `1`               | Enable/disable crash link (private)                         |
| `discord_crashlogger_private_smversion`       | `1`               | Enable/disable SM version (private)                         |
| `discord_crashlogger_private_steaminfo`       | `1`               | Enable/disable Steam info (private)                         |
| `discord_crashlogger_private_gamename`        | `1`               | Enable/disable game name (private)                          |
| `discord_crashlogger_private_mapthumb`        | `1`               | Enable/disable thumbnail (private)                          |
| `discord_crashlogger_private_mapimage`        | ``                | Map image URL (private, use %s for map)                     |
| `discord_crashlogger_private_title`           | `Server Crashed!` | Private webhook title                                       |
| `discord_crashlogger_private_embedcolor`      | `#FF0000`         | Private embed color (hexadecimal format)                    |

> ***(Example of a map image url: https://image.gametracker.com/images/maps/160x120/(putgamenamehere)/%s.jpg)***

#### Public Webhook Commands

| **ConVars**                                   | **Default Value** | **Description**                                             |
|-----------------------------------------------|-------------------|-------------------------------------------------------------|
| `discord_crashlogger_public_crashid`          | `1`               | Enable/disable crash ID (public)                            |
| `discord_crashlogger_public_crashlink`        | `0`               | Enable/disable crash link (public)                          |
| `discord_crashlogger_public_smversion`        | `0`               | Enable/disable SM version (public)                          |
| `discord_crashlogger_public_steaminfo`        | `0`               | Enable/disable Steam info (public)                          |
| `discord_crashlogger_public_gamename`         | `1`               | Enable/disable game name (public)                           |
| `discord_crashlogger_public_mapthumb`         | `0`               | Enable/disable thumbnail (public)                           |
| `discord_crashlogger_public_mapimage`         | ``                | Map image URL (public, use %s for map)                      |
| `discord_crashlogger_public_title`            | `Server Crashed!` | Public webhook title                                        |
| `discord_crashlogger_public_embedcolor`       | `#FF0000`         | Public embed color (hexadecimal format)                     |

#### Dependencies.
- [Sourcemod 1.12+](https://www.sourcemod.net/downloads.php)
- [Accelerator](https://forums.alliedmods.net/showthread.php?t=277703&)
- [Discord API](https://github.com/Cruze03/sourcemod-discord/tree/master)
- [SM Jansson]([https://github.com/Cruze03/sourcemod-discord/tree/master](https://github.com/davenonymous/SMJansson/blob/master/pawn/scripting/include/smjansson.inc))

#### Supported Games.
- Team Fortress 2
- Half-Life 2 Deathmatch
- Left 4 Dead
- Left 4 Dead 2
- Counter-Strike: Source

# **Enjoy the plugin!**

[![](https://dcbadge.vercel.app/api/server/xftqrvZSAw)](https://discord.gg/xftqrvZSAw)
