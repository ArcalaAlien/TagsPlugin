#include <sourcemod>
#include <admin>
#include <clients>
#include <keyvalues>
#include <files>
#include <chat-processor>

public Plugin:myinfo =
{
	name = "Surf'N'Turf Admin Tag System",
	author = "Arcala the Gyiyg",
	description = "Plugin that automatically adds tags to admin's names when they join the server",
	version = "1.0.1",
	url = "N/A"
} 

KeyValues kvStaffTagList;
bool StaffTagEnabled[MAXPLAYERS + 1] = {false, ... };

public void OnPluginStart() {

	// Set new KeyValue list to first KeyValue Tree
	kvStaffTagList = new KeyValues("SnTTags");
    RegAdminCmd("sm_atag", Toggle_AdminTag, ADMFLAG_GENERIC, "Toggles whether your tag is being shown");

	// Creats a file path that prints to the snttags.cfg file
	char ConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/snttags.cfg");

	// Imports all KeyValue trees snttags.cfg
	kvStaffTagList.ImportFromFile(ConfigPath);

}

/**
 * Description
 *
 * @param client    Client who's cookie will be set
 * @param tagType	Name of the keyvalue of what tag will be set
 * @param displayBuffer   char array to store the returned "display" keyvalue of the tag
 * @param displayBufferLen   Length of the above char array
 * @param colorBuffer   char array to store the returned "color" keyvalue of the tag
 * @param colorBufferLen   Length of the above char array
 * @param isStaff   Boolean value, set to true if you need to set a player's staff tag, otherwise set to false.
 * @return Returns   true if function was able to grab the tag from the config file.
 */
bool GetTag(char[] tagType, char[] displayBuffer, int displayBufferLen, char[] colorBuffer, int colorBufferLen)
{
	if (kvStaffTagList.GotoFirstSubKey())
	{
		if (kvStaffTagList.JumpToKey(tagType))
		{
			kvStaffTagList.GetString("display", displayBuffer, displayBufferLen)
			kvStaffTagList.GetString("color", colorBuffer, colorBufferLen)
			kvStaffTagList.Rewind();
			return true;
		}
		else
		{
			return false;
		}
	}
	return false;
}	

public void OnClientPostAdminCheck(int client)
{
    char tagBuffer[128];
    char colorBuffer[128];
    AdminId connectedAdmin = GetUserAdmin(client);
    if (connectedAdmin)
    {
        if (connectedAdmin.HasFlag(Admin_Root, Access_Real))
		{
            GetTag("owner", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
            return;
        }
        else if(connectedAdmin.HasFlag(Admin_Unban, Access_Real))
        {
            GetTag("admin", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
            return;
        }
        else if(connectedAdmin.HasFlag(Admin_Kick, Access_Real) && !connectedAdmin.HasFlag(Admin_Unban))
        {
            GetTag("moderator", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
        }
    }
}

public Action:Toggle_AdminTag(int client, int params)
{
    char tagBuffer[128];
    char colorBuffer[128];
    AdminId connectedAdmin = GetUserAdmin(client);
    if (connectedAdmin && !StaffTagEnabled[client])
    {
        if (connectedAdmin.HasFlag(Admin_Root, Access_Real))
		{
            GetTag("owner", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
            return Plugin_Handled;
        }
        else if(connectedAdmin.HasFlag(Admin_Unban, Access_Real))
        {
            GetTag("admin", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
            return Plugin_Handled;
        }
        else if(connectedAdmin.HasFlag(Admin_Kick, Access_Real) && !connectedAdmin.HasFlag(Admin_Unban))
        {
            GetTag("moderator", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            StaffTagEnabled[client] = true;
            return Plugin_Handled;
        }
    }
    else if(connectedAdmin && StaffTagEnabled[client])
    {
        if (connectedAdmin.HasFlag(Admin_Root, Access_Real))
        {
            ChatProcessor_RemoveClientTag(client, "Owner | ");
            StaffTagEnabled[client] = false;
            return Plugin_Handled;
        }
        else if(connectedAdmin.HasFlag(Admin_Unban, Access_Real))
        {
            ChatProcessor_RemoveClientTag(client, "Admin | ");
            StaffTagEnabled[client] = false;
            return Plugin_Handled;
        }
        else if(connectedAdmin.HasFlag(Admin_Kick, Access_Real) && !connectedAdmin.HasFlag(Admin_Unban))
        {
            ChatProcessor_RemoveClientTag(client, "Mod | ");
            StaffTagEnabled[client] = false;
            return Plugin_Handled;
        }
    }
    return Plugin_Handled;
}