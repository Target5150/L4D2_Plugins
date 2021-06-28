#pragma semicolon 1

#include <colors>
#pragma newdecls required
#include <sourcemod>
#include <basecomm>
#include <l4d2_name_tag>

ConVar hCvarCvarChange, hCvarNameChange, hCvarSpecNameChange, hCvarSpecSeeChat;
bool bCvarChange, bNameChange, bSpecNameChange, bSpecSeeChat, bBSCAvailable, bLNTAvailable;

public Plugin myinfo = 
{
    name = "BeQuiet",
    author = "Sir",
    description = "Please be Quiet!",
    version = "1.33.7",
    url = "https://github.com/SirPlease/SirCoding"
}

public void OnPluginStart()
{
    AddCommandListener(Say_Callback, "say");
    AddCommandListener(TeamSay_Callback, "say_team");

    //Server CVar
    HookEvent("server_cvar", Event_ServerConVar, EventHookMode_Pre);
    HookEvent("player_changename", Event_NameChange, EventHookMode_Pre);

    //Cvars
    hCvarCvarChange = CreateConVar("bq_cvar_change_suppress", "1", "Silence Server Cvars being changed, this makes for a clean chat with no disturbances.");
    hCvarNameChange = CreateConVar("bq_name_change_suppress", "1", "Silence Player name Changes.");
    hCvarSpecNameChange = CreateConVar("bq_name_change_spec_suppress", "1", "Silence Spectating Player name Changes.");
    hCvarSpecSeeChat = CreateConVar("bq_show_player_team_chat_spec", "1", "Show Spectators Survivors and Infected Team chat?");

    bCvarChange = GetConVarBool(hCvarCvarChange);
    bNameChange = GetConVarBool(hCvarNameChange);
    bSpecNameChange = GetConVarBool(hCvarSpecNameChange);
    bSpecSeeChat = GetConVarBool(hCvarSpecSeeChat);

    hCvarCvarChange.AddChangeHook(cvarChanged);
    hCvarNameChange.AddChangeHook(cvarChanged);
    hCvarSpecNameChange.AddChangeHook(cvarChanged);
    hCvarSpecSeeChat.AddChangeHook(cvarChanged);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("BaseComm_IsClientGagged");
    return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
    // l4d2_name_tag.smx
    bBSCAvailable = LibraryExists("basecomm");
    // l4d2_name_tag.smx
    bLNTAvailable = LibraryExists("l4d2_name_tag");
}

public Action Say_Callback(int client, char[] command, int args)
{
    char sChat[256];
    GetCmdArgString(sChat, sizeof(sChat));
    StripQuotes(sChat);

    if(IsChatTrigger() && (sChat[0] == '!' || sChat[0] == '/' || sChat[0] == '@'))
    {
        return Plugin_Handled;
    }

    if (bBSCAvailable && BaseComm_IsClientGagged(client))
    {
        return Plugin_Handled;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            char name_tag[256];

            if (bLNTAvailable)
            {
                LMT_GetNameTag(client, name_tag, sizeof(name_tag));
            }

            if (GetClientTeam(client) == 1)
            {
                CPrintToChatEx(i, client, "*SPEC* %s{teamcolor}%N{default} :  %s", name_tag, client, sChat);
            }
            else
            {
                CPrintToChatEx(i, client, "%s{teamcolor}%N{default} :  %s", name_tag, client, sChat);
            }
        }
    }

    return Plugin_Handled; 
}

public Action TeamSay_Callback(int client, char[] command, int args)
{
    char sChat[256];
    GetCmdArgString(sChat, sizeof(sChat));
    StripQuotes(sChat);

    if(IsChatTrigger() && (sChat[0] == '!' || sChat[0] == '/' || sChat[0] == '@'))
    {
        return Plugin_Handled;
    }

    if (bBSCAvailable && BaseComm_IsClientGagged(client))
    {
        return Plugin_Handled;
    }

    if (bSpecSeeChat && GetClientTeam(client) != 1)
    {
        int i = 1;
        while (i <= 65)
        {
            if (IsValidClient(i) && GetClientTeam(i) == 1)
            {
                char name_tag[256];

                if (bLNTAvailable)
                {
                    LMT_GetNameTag(client, name_tag, sizeof(name_tag));
                }

                CPrintToChat(i, "{default}(%s) %s{blue}%N{default} :  {olive}%s", GetStrTeamName(client), name_tag, client, sChat);
            }
            i++;
        }
    }

    int team = GetClientTeam(client);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i) && GetClientTeam(i) == team)
        {
            char name_tag[256];

            if (bLNTAvailable)
            {
                LMT_GetNameTag(client, name_tag, sizeof(name_tag));
            }

            CPrintToChatEx(i, client, "{default}(%s) %s{teamcolor}%N{default} :  %s", GetStrTeamName(client), name_tag, client, sChat);
        }
    }

    return Plugin_Handled;
}

public Action Event_ServerConVar(Event event, const char[] name, bool dontBroadcast)
{
    if (bCvarChange) return Plugin_Handled;
    return Plugin_Continue;
}

public Action Event_NameChange(Event event, const char[] name, bool dontBroadcast)
{
    int clientid = event.GetInt("userid");
    int client = GetClientOfUserId(clientid); 

    if (IsValidClient(client))
    {
        if (GetClientTeam(client) == 1 && bSpecNameChange) return Plugin_Handled;
        else if (bNameChange) return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void cvarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
    bCvarChange = hCvarCvarChange.BoolValue;
    bNameChange = hCvarNameChange.BoolValue;
    bSpecNameChange = hCvarSpecNameChange.BoolValue;
    bSpecSeeChat = hCvarSpecNameChange.BoolValue;
}

stock bool IsValidClient(int client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client)) return false; 
    return true;
}

stock char GetStrTeamName(int client)
{
    char strTeamName[10];

    switch (GetClientTeam(client))
    {
        case 1:
            strTeamName = "Spectator";
        case 2:
            strTeamName = "Survivor";
        case 3:
            strTeamName = "Infected";
    }

    return strTeamName;
}