#include <sourcemod>
#include <discord>
#include <files>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

ConVar g_hWebhook;
ConVar g_hWebhookPublic;

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
    version = "2.0",
    url = ""
}

public void OnPluginStart()
{
    RegPluginLibrary("discord-api");

    g_hWebhook = CreateConVar("discord_webhook_crashlogger", "", "Private webhook for crash logs", FCVAR_PROTECTED);
    g_hWebhookPublic = CreateConVar("discord_webhook_crashlogger_public", "", "Public webhook for crash logs", FCVAR_PROTECTED);

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

    PrintToServer("Crash ID detected: %s", g_sCrashID);
    
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
	char thumbURL[256];
    char sServerAppID[32];
    char sSteamAppID[32];
	char sSteamGame[64];
    char sSourceMod[32];
    
    ConVar cvHostname = FindConVar("hostname");
    GetConVarString(cvHostname, sHostname, sizeof(sHostname));
    GetCurrentMap(mapName, sizeof(mapName));
    
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
        default:
        {
            strcopy(sServerAppID, sizeof(sServerAppID), "N/A");
            strcopy(sSteamAppID, sizeof(sSteamAppID), "N/A");
        }
    }
    
    ConVar cvSourceMod = FindConVar("sourcemod_version");
    if(cvSourceMod != null)
    {
        GetConVarString(cvSourceMod, sSourceMod, sizeof(sSourceMod));
    }
    else
    {
        strcopy(sSourceMod, sizeof(sSourceMod), "Unknown");
    }
    
    Format(sLink, sizeof(sLink), "[Clique Aqui](https://crash.limetech.org/?id=%s)", g_sCrashID[index]);
	Format(thumbURL, sizeof(thumbURL), "https://image.gametracker.com/images/maps/160x120/tf2/%s.jpg", g_sLastMap);

    DiscordWebHook hook = new DiscordWebHook(g_sWebhook);
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetTitle("SERVER CRASH!");
    Embed.SetColor("#FF0000");
	Embed.AddField("Map:", strlen(g_sLastMap) > 0 ? g_sLastMap : "Desconhecido", false);
    Embed.AddField("Crash ID:", g_sCrashID[index], true);
    Embed.AddField("Crash Limetech Link:", sLink, true);
    Embed.AddField("Steam Server App ID:", sServerAppID, true);
    Embed.AddField("Steam App ID:", sSteamAppID, true);
	Embed.AddField("Steam Game:", sSteamGame, true);
    Embed.AddField("SourceMod Version:", sSourceMod, true);
    
    char footerText[128];
    Format(footerText, sizeof(footerText), "%s • %s ", GetHostName(), GetFormattedTime());
    
    Embed.SetFooter(footerText);
	Embed.SetThumb(thumbURL);
    
    hook.SlackMode = true;
    hook.Embed(Embed);
    hook.Send();
    
    delete hook;
}

void SendPublicCrash()
{
    char sLink[128];
    char sHostname[64];
    char thumbURL[256];
    char mapName[128];
	
	GetCurrentMap(mapName, sizeof(mapName));  
    
    ConVar cvHostname = FindConVar("hostname");
    GetConVarString(cvHostname, sHostname, sizeof(sHostname));
	
	Format(sLink, sizeof(sLink), "[Click Here](https://crash.limetech.org/?id=%s)", g_sCrashID[index]);
    Format(thumbURL, sizeof(thumbURL), "https://image.gametracker.com/images/maps/160x120/tf2/%s.jpg", g_sLastMap);
	
    DiscordWebHook hook = new DiscordWebHook(g_sWebhookPublic);
    MessageEmbed Embed = new MessageEmbed();
    
    Embed.SetTitle("SERVER UNRESPONSIVE!");
    Embed.SetColor("#FF0000");
	Embed.AddField("Map:", strlen(g_sLastMap) > 0 ? g_sLastMap : "Desconhecido", true);
    Embed.AddField("Crash ID", g_sCrashID[index], false);
	Embed.AddField("Crash Limetech Link", sLink, false);
	
	char footerText[128];
	Format(footerText, sizeof(footerText), "%s • %s ", GetHostName(), GetFormattedTime());
	
	Embed.SetFooter(footerText);
	Embed.SetThumb(thumbURL);
    
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