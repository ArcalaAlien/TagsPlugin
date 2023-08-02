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
	version = "1.0.0",
	url = "N/A"
} 

KeyValues kvStaffTagList;
public void OnPluginStart() {

	// Set new KeyValue list to first KeyValue Tree
	kvStaffTagList = new KeyValues("SnTTags");

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
        PrintToServer("Admin Connected");
        if (connectedAdmin.HasFlag(Admin_Root, Access_Real))
		{
            PrintToServer("Owner Connected");
            GetTag("owner", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            return;
        }
        else if(connectedAdmin.HasFlag(Admin_Unban, Access_Real))
        {
            PrintToServer("Admin Connected");
            GetTag("admin", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
            return;
        }
        else if(connectedAdmin.HasFlag(Admin_Kick, Access_Real) && !connectedAdmin.HasFlag(Admin_Unban))
        {
            PrintToServer("Moderator Connected");
            GetTag("moderator", tagBuffer, 128, colorBuffer, 128);
            ChatProcessor_AddClientTag(client, tagBuffer);
            ChatProcessor_SetTagColor(client, tagBuffer, colorBuffer);
        }
    }
}
