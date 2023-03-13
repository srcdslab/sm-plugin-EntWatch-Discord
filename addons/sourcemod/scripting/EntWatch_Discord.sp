#pragma semicolon 1

#include <EntWatch>

#define PLUGIN_NAME "EntWatch_Discord"
#define STEAM_API_CVAR "eban_steam_api"

#include <RelayHelper>

#pragma newdecls required

Global_Stuffs g_Eban;

public Plugin myinfo =
{
	name 		= PLUGIN_NAME,
	author 		= ".Rushaway, Dolly, koen",
	version 	= "1.0",
	description = "Send EntWatch Ban/Unban notifications to discord",
	url 		= "https://nide.gg"
};

public void OnPluginStart() {
	g_Eban.enable 	= CreateConVar("eban_discord_enable", "1", "Toggle eban notification system", _, true, 0.0, true, 1.0);
	g_Eban.webhook 	= CreateConVar("eban_discord", "", "The webhook URL of your Discord channel. (Eban)", FCVAR_PROTECTED);
	g_Eban.website	= CreateConVar("eban_website", "", "The Ebans Website for your server (that sends the user to ebans list page)", FCVAR_PROTECTED);
	
	RelayHelper_PluginStart();
	
	AutoExecConfig(true, PLUGIN_NAME);
	
	/* Incase of a late load */
	for(int i = 1; i <= MaxClients; i++) {
		if(!IsClientInGame(i) || IsFakeClient(i) || IsClientSourceTV(i) || g_sClientAvatar[i][0]) {
			return;
		}
		
		OnClientPostAdminCheck(i);
	}
}

public void OnClientPostAdminCheck(int client) {
	if(IsFakeClient(client) || IsClientSourceTV(client)) {
		return;
	}
	
	GetClientSteamAvatar(client);
}

public void OnClientDisconnect(int client) {
	g_sClientAvatar[client][0] = '\0';
}

public void EntWatch_OnClientBanned(int admin, int length, int target, const char[] reason)
{
	if(!g_Eban.enable.BoolValue) {
		return;
	}
	
	if(admin < 1) {
		return;
	}
	
	int ebansNumber = EntWatch_GetClientEbansNumber(target);
	SendDiscordMessage(g_Eban, Message_Type_Eban, admin, target, length, reason, ebansNumber, 0, _, g_sClientAvatar[target]);
}

public void EntWatch_OnClientUnbanned(int admin, int target, const char[] reason)
{
    if(!g_Eban.enable.BoolValue) {
    	return;
    }
    
    if(admin < 1) {
		return;
	}
	
    int ebansNumber = EntWatch_GetClientEbansNumber(target);
    SendDiscordMessage(g_Eban, Message_Type_Eunban, admin, target, -1, reason, ebansNumber, 0, _, g_sClientAvatar[target]);
}
