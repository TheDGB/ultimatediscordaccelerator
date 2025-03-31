/*****************************************************************************
                       Ultimate Discord Accelerator
******************************************************************************/

#include <sourcemod>
#include <discord>
#include <files>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

ConVar g_hWebhook;
ConVar g_hWebhookPublic;

ConVar g_cvEnable;
ConVar g_cvPrivateCrashID, g_cvPublicCrashID;
ConVar g_cvPrivateCrashLink, g_cvPublicCrashLink;
ConVar g_cvPrivateSMVersion, g_cvPublicSMVersion;
ConVar g_cvPrivateSteamInfo, g_cvPublicSteamInfo;
ConVar g_cvPrivateGameName, g_cvPublicGameName;
ConVar g_cvPrivateMapThumb, g_cvPublicMapThumb;
ConVar g_cvPrivateMapImage, g_cvPublicMapImage;
ConVar g_cvPrivateTitle, g_cvPublicTitle;
ConVar g_cvPrivateEmbedColor, g_cvPublicEmbedColor;

char g_sWebhook[255];
char path[128];
char g_sWebhookPublic[255];
char g_sCrashID[64];
char g_sLastMap[64];

Handle g_hMapTimer;

Handle Hlogs;

int index;

public Plugin myinfo = 
{
    name = "Ultimate Discord Accelerator",
    author = "johnoclock/DGB",
    description = "Sends discord message when server crashes",
    version = "2.6",
    url = ""
}

public void OnPluginStart()
{
    RegPluginLibrary("discord-api");

    g_cvEnable = CreateConVar("discord_crashlogger_enable", "1", "Enables or disables the plugin", _, true, 0.0, true, 1.0);
    
    g_hWebhook = CreateConVar("discord_webhook_crashlogger", "", "Private webhook link for crash logs", FCVAR_PROTECTED);
    g_cvPrivateCrashID = CreateConVar("discord_crashlogger_private_crashid", "1", "Enable/disable crash ID (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateCrashLink = CreateConVar("discord_crashlogger_private_crashlink", "1", "Enable/disable crash link (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateSMVersion = CreateConVar("discord_crashlogger_private_smversion", "1", "Enable/disable SM version (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateSteamInfo = CreateConVar("discord_crashlogger_private_steaminfo", "1", "Enable/disable Steam info (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateGameName = CreateConVar("discord_crashlogger_private_gamename", "1", "Enable/disable game name (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateMapThumb = CreateConVar("discord_crashlogger_private_mapthumb", "1", "Enable/disable thumbnail (private)", _, true, 0.0, true, 1.0);
    g_cvPrivateMapImage = CreateConVar("discord_crashlogger_private_mapimage", "", "Map image URL (private, use %s for map)");
    g_cvPrivateTitle = CreateConVar("discord_crashlogger_private_title", "", "Private webhook title");
	g_cvPrivateEmbedColor = CreateConVar("discord_crashlogger_private_embedcolor", "#FF0000", "Private embed color (hexadecimal format)");

    g_hWebhookPublic = CreateConVar("discord_webhook_crashlogger_public", "", "Public webhook link for crash logs", FCVAR_PROTECTED);
    g_cvPublicCrashID = CreateConVar("discord_crashlogger_public_crashid", "1", "Enable/disable crash ID (public)", _, true, 0.0, true, 1.0);
    g_cvPublicCrashLink = CreateConVar("discord_crashlogger_public_crashlink", "1", "Enable/disable crash link (public)", _, true, 0.0, true, 1.0);
    g_cvPublicSMVersion = CreateConVar("discord_crashlogger_public_smversion", "1", "Enable/disable SM version (public)", _, true, 0.0, true, 1.0);
    g_cvPublicSteamInfo = CreateConVar("discord_crashlogger_public_steaminfo", "1", "Enable/disable Steam info (public)", _, true, 0.0, true, 1.0);
    g_cvPublicGameName = CreateConVar("discord_crashlogger_public_gamename", "1", "Enable/disable game name (public)", _, true, 0.0, true, 1.0);
    g_cvPublicMapThumb = CreateConVar("discord_crashlogger_public_mapthumb", "1", "Enable/disable thumbnail (public)", _, true, 0.0, true, 1.0);
    g_cvPublicMapImage = CreateConVar("discord_crashlogger_public_mapimage", "", "Map image URL (public, use %s for map)");
    g_cvPublicTitle = CreateConVar("discord_crashlogger_public_title", "", "Public webhook title");
	g_cvPublicEmbedColor = CreateConVar("discord_crashlogger_public_embedcolor", "#FF0000", "Public embed color (hexadecimal format))");

    GetConVarString(g_hWebhook, g_sWebhook, sizeof(g_sWebhook));
    GetConVarString(g_hWebhookPublic, g_sWebhookPublic, sizeof(g_sWebhookPublic));

    BuildPath(Path_SM, path, sizeof(path), "/logs/accelerator.log");
    Hlogs = OpenFile(path, "r", false);

    AutoExecConfig(true, "Discord_CrashLogger");
	
    File file = OpenFile("addons/sourcemod/data/crashlastmap.txt", "r");
    if(file != null)
    {
        if(!file.EndOfFile() && file.ReadLine(g_sLastMap, sizeof(g_sLastMap)))
        {
            TrimString(g_sLastMap);
        }
        delete file;
    }
	
	LoadLastMap();
}

public void OnMapStart()
{
    if(g_hMapTimer != null)
    {
        KillTimer(g_hMapTimer);
        g_hMapTimer = null;
    }
    
    g_hMapTimer = CreateTimer(10.0, Timer_UpdateLastMap);
}

public Action Timer_UpdateLastMap(Handle timer)
{
    char currentMap[64];
    GetCurrentMap(currentMap, sizeof(currentMap));
    
    if(!StrEqual(currentMap, "background_01") && !StrEqual(currentMap, "test"))
    {
        strcopy(g_sLastMap, sizeof(g_sLastMap), currentMap);
        SaveLastMap();
    }
    
    g_hMapTimer = null;
    return Plugin_Stop;
}

void LoadLastMap()
{
    File file = OpenFile("addons/sourcemod/data/crashlastmap.txt", "r");
    if(file != null)
    {
        if(!file.EndOfFile() && file.ReadLine(g_sLastMap, sizeof(g_sLastMap)))
        {
            TrimString(g_sLastMap);
        }
        delete file;
    }
}

void SaveLastMap()
{
    File file = OpenFile("addons/sourcemod/data/crashlastmap.txt", "w");
    if(file != null)
    {
        file.WriteLine(g_sLastMap);
        delete file;
    }
}

public void OnConfigsExecuted()
{
    if(!g_cvEnable.BoolValue) return;

    GetConVarString(g_hWebhook, g_sWebhook, sizeof(g_sWebhook));
    GetConVarString(g_hWebhookPublic, g_sWebhookPublic, sizeof(g_sWebhookPublic));

    if (!Hlogs)
        return;

    FileSeek(Hlogs, -sizeof(g_sCrashID), SEEK_END);
    ReadFileString(Hlogs, g_sCrashID, sizeof(g_sCrashID));
    index = StrContains(g_sCrashID, "Crash ID: ");
    
    if(index == -1)
        return;

    g_sCrashID[index + 10 + 14] = '\0';
    ReplaceString(g_sCrashID, sizeof(g_sCrashID), "Crash ID: ", "", false);
    TrimString(g_sCrashID);

    PrintToDiscord();

    delete Hlogs;
    Hlogs = null;
    
    if (FileExists(path))
    {
        DeleteFile(path);
    }
}

void SendPrivateCrash()
{
    char sLink[128];
    char sHostname[64];  
    char mapName[64];
    char sServerAppID[32];
    char sSteamAppID[32];
	char sSteamGame[64];
    char sSourceMod[32];
    
    GetConVarString(FindConVar("hostname"), sHostname, sizeof(sHostname));
    GetCurrentMap(mapName, sizeof(mapName));
    Format(sLink, sizeof(sLink), "[Click Here](https://crash.limetech.org/?id=%s)", g_sCrashID[index]);

    EngineVersion engine = GetEngineVersion();
    switch(engine)
    {
        case Engine_TF2:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "232250");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "440");
            strcopy(sSteamGame, sizeof(sSteamGame), "Team Fortress 2");
        }
        case Engine_HL2DM:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "232370");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "320");
            strcopy(sSteamGame, sizeof(sSteamGame), "Half-Life 2 Deathmatch");
        }
        case Engine_Left4Dead:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "222840");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "500");
            strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead");
        }
        case Engine_Left4Dead2:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "222860");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "550");
            strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead 2");
        }
        case Engine_CSS:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "232330");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "240");
            strcopy(sSteamGame, sizeof(sSteamGame), "Counter-Strike: Source");
        }
        default:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "N/A");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "N/A");
            strcopy(sSteamGame, sizeof(sSteamGame), "N/A");
        }
    }

    ConVar cvSourceMod = FindConVar("sourcemod_version");
    GetConVarString(cvSourceMod, sSourceMod, sizeof(sSourceMod));

    DiscordWebHook hook = new DiscordWebHook(g_sWebhook);
    MessageEmbed Embed = new MessageEmbed();

    char title[256];
    g_cvPrivateTitle.GetString(title, sizeof(title));
    Embed.SetTitle(strlen(title) > 0 ? title : "SERVER CRASH!");

    char embedColor[16];
    g_cvPrivateEmbedColor.GetString(embedColor, sizeof(embedColor));
    Embed.SetColor(embedColor);
    Embed.AddField("Map:", strlen(g_sLastMap) > 0 ? g_sLastMap : "Unknown", true);

    if(g_cvPrivateCrashID.BoolValue)
        Embed.AddField("Crash ID:", g_sCrashID[index], true);

    if(g_cvPrivateCrashLink.BoolValue)
        Embed.AddField("Crash Limetech Link:", sLink, true);

    if(g_cvPrivateSteamInfo.BoolValue)
    {
        Embed.AddField("Steam Server App ID:", sServerAppID, true);
        Embed.AddField("Steam App ID:", sSteamAppID, true);
    }

    if(g_cvPrivateGameName.BoolValue)
        Embed.AddField("Steam Game:", sSteamGame, true);

    if(g_cvPrivateSMVersion.BoolValue)
        Embed.AddField("SourceMod Version:", sSourceMod, true);

    if(g_cvPrivateMapThumb.BoolValue)
    {
        char mapImage[256];
        g_cvPrivateMapImage.GetString(mapImage, sizeof(mapImage));
        if(strlen(mapImage) > 0)
            ReplaceString(mapImage, sizeof(mapImage), "%s", g_sLastMap);
        else
            Format(mapImage, sizeof(mapImage), "https://image.gametracker.com/images/maps/160x120/tf2/%s.jpg", g_sLastMap);
        
        Embed.SetThumb(mapImage);
    }

    char footerText[128];
    Format(footerText, sizeof(footerText), "%s • %s ", sHostname, GetFormattedTime());
    Embed.SetFooter(footerText);

    hook.SlackMode = true;
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

void SendPublicCrash()
{
    char sLink[128];
    char sHostname[64];
	char sServerAppID[32];
    char sSteamAppID[32];
	char sSteamGame[64];
    
    GetConVarString(FindConVar("hostname"), sHostname, sizeof(sHostname));
    Format(sLink, sizeof(sLink), "[Click Here](https://crash.limetech.org/?id=%s)", g_sCrashID[index]);

    DiscordWebHook hook = new DiscordWebHook(g_sWebhookPublic);
    MessageEmbed Embed = new MessageEmbed();

    char title[256];
    g_cvPublicTitle.GetString(title, sizeof(title));
    Embed.SetTitle(strlen(title) > 0 ? title : "SERVER UNRESPONSIVE!");

    char embedColor[16];
    g_cvPublicEmbedColor.GetString(embedColor, sizeof(embedColor));
    Embed.SetColor(embedColor);
    Embed.AddField("Map:", strlen(g_sLastMap) > 0 ? g_sLastMap : "Unknown", true);

    if(g_cvPublicCrashID.BoolValue)
        Embed.AddField("Crash ID:", g_sCrashID[index], false);

    if(g_cvPublicCrashLink.BoolValue)
        Embed.AddField("Crash Limetech Link:", sLink, false);
		
    if(g_cvPublicSteamInfo.BoolValue)
    {
        EngineVersion engine = GetEngineVersion();
        switch(engine)
        {
             case Engine_TF2:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232250");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "440");
				 strcopy(sSteamGame, sizeof(sSteamGame), "Team Fortress 2");
             }
             case Engine_HL2DM:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232370");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "320");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Half-Life 2 Deathmatch");
             }
             case Engine_Left4Dead:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "222840");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "500");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead");
             }
             case Engine_Left4Dead2:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "222860");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "550");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead 2");
             }
             case Engine_CSS:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232330");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "240");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Counter-Strike: Source");
             }
             default:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "N/A");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "N/A");
                 strcopy(sSteamGame, sizeof(sSteamGame), "N/A");
             }
         }
        Embed.AddField("Steam Server App ID", sServerAppID, true);
        Embed.AddField("Steam App ID", sSteamAppID, true);
    }

    if(g_cvPublicGameName.BoolValue)
    {
        EngineVersion engine = GetEngineVersion();
        switch(engine)
        {
             case Engine_TF2:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232250");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "440");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Team Fortress 2");
             }
             case Engine_HL2DM:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232370");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "320");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Half-Life 2 Deathmatch");
             }
             case Engine_Left4Dead:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "222840");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "500");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead");
             }
             case Engine_Left4Dead2:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "222860");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "550");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Left 4 Dead 2");
             }
             case Engine_CSS:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "232330");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "240");
                 strcopy(sSteamGame, sizeof(sSteamGame), "Counter-Strike: Source");
             }
             default:
             {
                 strcopy(sServerAppID, sizeof(sServerAppID), "N/A");
                 strcopy(sSteamAppID, sizeof(sSteamAppID), "N/A");
                 strcopy(sSteamGame, sizeof(sSteamGame), "N/A");
             }
         }
        Embed.AddField("Steam Game:", sSteamGame, true);
    }

    if(g_cvPublicSMVersion.BoolValue)
    {
        char sSourceMod[32];
        ConVar cvSourceMod = FindConVar("sourcemod_version");
        GetConVarString(cvSourceMod, sSourceMod, sizeof(sSourceMod));
        Embed.AddField("SourceMod Version", sSourceMod, true);
    }

    if(g_cvPublicMapThumb.BoolValue)
    {
        char mapImage[256];
        g_cvPublicMapImage.GetString(mapImage, sizeof(mapImage));
        if(strlen(mapImage) > 0)
            ReplaceString(mapImage, sizeof(mapImage), "%s", g_sLastMap);
        else
            Format(mapImage, sizeof(mapImage), "https://image.gametracker.com/images/maps/160x120/tf2/%s.jpg", g_sLastMap);
        
        Embed.SetThumb(mapImage);
    }

    char footerText[128];
    Format(footerText, sizeof(footerText), "%s • %s ", sHostname, GetFormattedTime());
    Embed.SetFooter(footerText);

    hook.SlackMode = true;
    hook.Embed(Embed);
    hook.Send();
    delete hook;
}

stock char[] GetFormattedTime()
{
    char time[32];
    FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M");
    return time;
}

stock char[] GetHostName() 
{
    char sHostname[64];
	ConVar cvHostname = FindConVar("hostname");
    GetConVarString(cvHostname, sHostname, sizeof(sHostname));
    return sHostname;
}

public void PrintToDiscord()
{
    if(strlen(g_sWebhook) > 0)
        SendPrivateCrash();
    
    if(strlen(g_sWebhookPublic) > 0)
        SendPublicCrash();
}