#include <sourcemod>
#include <colors>

#define NAME_TAG_FILE_PATH "configs/l4d2_name_tag.txt"
#define PLUGIN_VERSION     "1.0"
#define TAG_MAX_LENGTH     256
#define PF_MAX_LENGTH      32

// ConVars
ConVar CVLmtAdminPrefix;
ConVar CVLmtModeratorPrefix;

// Variables
char cLmtAdminPrefix[PF_MAX_LENGTH];
char cLmtModeratorPrefix[PF_MAX_LENGTH];
char cNameTag[MAXPLAYERS+1][TAG_MAX_LENGTH];
Handle hNameTagListKV;

public Plugin myinfo =  
{
    name = "L4D2 Name Tag",
    author = "PaaNChaN",
    description = "add nametag to the chat function of bequiet.smx",
    version = PLUGIN_VERSION,
    url = "https://github.com/PaaNChaN/L4D2_Plugins"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("LMT_GetNameTag", Native_LMT_GetNameTag);
    
    RegPluginLibrary("l4d2_name_tag");
    return APLRes_Success;
}

public int Native_LMT_GetNameTag(Handle plugin, int numParams)
{
    new client = GetNativeCell(1);

    if (IsClientInGame(client) && !IsFakeClient(client))
    {
        SetNativeString(2, cNameTag[client], GetNativeCell(3));
        return _:true;
    }

    return _:false;
}

public void OnPluginStart()
{
    if (!IsNameTagFileExist())
    {
        SetFailState("Couldn't load l4d2_name_tag.txt!");
    }

    CVLmtAdminPrefix     = CreateConVar("lmt_admin_prefix", "(A)", "type of admin prefix.");
    CVLmtModeratorPrefix = CreateConVar("lmt_moderator_prefix", "(M)", "type of moderator prefix.");

    RegAdminCmd("sm_lnametag", LoadNameTag_Cmd, ADMFLAG_BAN, "load the NameTag");
    RegAdminCmd("sm_lnt",      LoadNameTag_Cmd, ADMFLAG_BAN, "load the NameTag");

    CVLmtAdminPrefix.AddChangeHook(OnConVarChanged);
    CVLmtModeratorPrefix.AddChangeHook(OnConVarChanged);
}

public void OnConfigsExecuted()
{
    CVLmtAdminPrefix.GetString(cLmtAdminPrefix, sizeof(cLmtAdminPrefix));
    CVLmtModeratorPrefix.GetString(cLmtModeratorPrefix, sizeof(cLmtModeratorPrefix));
    LoadNameTag();
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    CVLmtAdminPrefix.GetString(cLmtAdminPrefix, sizeof(cLmtAdminPrefix));
    CVLmtModeratorPrefix.GetString(cLmtModeratorPrefix, sizeof(cLmtModeratorPrefix));
    LoadNameTag();
}

public void OnClientPostAdminCheck(int client)
{
    getClientNameTag(client);
}

public Action LoadNameTag_Cmd(int client, int args)
{
    CPrintToChatAll("<{green}NameTag{default}> NameTag was reloaded.");
    LoadNameTag();
}

public void LoadNameTag()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            getClientNameTag(i);
        }
    }
}

public void getClientNameTag(client)
{
    if (!IsNameTagFileExist())
    {
        return;
    }

    cNameTag[client] = "";

    KvRewind(hNameTagListKV);
    if (KvGotoFirstSubKey(hNameTagListKV))
    {
        char sAuth[64];
        GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
        do
        {
            char sBuffer[TAG_MAX_LENGTH];
            KvGetSectionName(hNameTagListKV, sBuffer, sizeof(sBuffer));
            if(strcmp(sAuth, sBuffer) == 0)
            {
                KvGetString(hNameTagListKV, "tag", sBuffer, sizeof(sBuffer));
                Format(cNameTag[client], TAG_MAX_LENGTH, "%s ", sBuffer);
                break;
            }
        } while (KvGotoNextKey(hNameTagListKV));
    }

    if (IsClientAdmin(client, Admin_Root) && strlen(cLmtAdminPrefix) > 0)
    {
        Format(cNameTag[client], TAG_MAX_LENGTH, "{green}%s{default} %s", cLmtAdminPrefix, cNameTag[client]);
    }
    else if (IsClientAdmin(client, Admin_Generic) && strlen(cLmtModeratorPrefix) > 0)
    {
        Format(cNameTag[client], TAG_MAX_LENGTH, "{olive}%s{default} %s", cLmtModeratorPrefix, cNameTag[client]);
    }
}

stock bool IsClientAdmin(int client, AdminFlag flag)
{
    AdminId aid = GetUserAdmin(client);

    if(GetAdminFlag(aid, flag))
    {
        return true;
    }

    return false;
}

stock bool IsNameTagFileExist()
{
    char sBuffer[128];
    hNameTagListKV = CreateKeyValues("NameTag");
    BuildPath(Path_SM, sBuffer, sizeof(sBuffer), NAME_TAG_FILE_PATH);

    if (!FileToKeyValues(hNameTagListKV, sBuffer))
    {
        return false;
    }
    
    return true;
}