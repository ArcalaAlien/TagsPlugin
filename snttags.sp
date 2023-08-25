#include <sourcemod>
#include <admin>
#include <clients>
#include <clientprefs>
#include <keyvalues>
#include <files>
#include <topmenus>
#include <chat-processor>

public Plugin:myinfo =
{
	name = "Surf'N'Turf Player Tag System",
	author = "Arcala the Gyiyg",
	description = "Plugin that lets users add tags before their name.",
	version = "1.0.0",
	url = "N/A"
} 

KeyValues kvPlayerTagList;
Cookie ckEquippedTag;
TopMenu mTagMenu;
TopMenuObject mobjPlayerTags;
TopMenuObject mobjAwardedTags;
TopMenuObject mobjEarlyTags;

bool bTagEquipped[MAXPLAYERS + 1] = { false, ... };

public void OnPluginStart() {
	//Register "tagtest" to test the tag function
	RegConsoleCmd("sm_tag", SetTag, "Brings up a menu to allow players to change their tags.");
	RegConsoleCmd("sm_tags", SetTag, "Brings up a menu to allow players to change their tags.");
	RegConsoleCmd("sm_tagmenu", SetTag, "Brings up a menu to allow players to change their tags.");

	// Set new KeyValue list to first KeyValue Tree
	kvPlayerTagList = new KeyValues("SnTTags");

	// Creats a file path that prints to the snttags.cfg file
	char ConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/snttags.cfg");

	// Imports all KeyValue trees snttags.cfg
	kvPlayerTagList.ImportFromFile(ConfigPath);

	//Register the cookie that will keep track of what tag a client has equipped.
	ckEquippedTag = RegClientCookie("Equipped_Tag", "The tag a player has equipped", CookieAccess_Protected);

	mTagMenu = new TopMenu(TopMenu_TagCategories);
	mobjPlayerTags = mTagMenu.AddCategory("PlayerTags", TopMenu_PlayerTags);
	mobjAwardedTags = mTagMenu.AddCategory("ContestTags", TopMenu_ContestTags);
	mobjEarlyTags = mTagMenu.AddCategory("SupporterTags", TopMenu_SupporterTags);

}

void GetTagInfo(char[] tagType, char[] displayBuffer, int displayBufferLen)
{
	if (kvPlayerTagList.JumpToKey("PlayerTags"))
	{
		if (kvPlayerTagList.JumpToKey(tagType))
		{
			kvPlayerTagList.GetString("display", displayBuffer, displayBufferLen)
			kvPlayerTagList.Rewind();
		}
	}
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
void ToggleTag(int client, char[] tagType, bool eraseTag)
{
	char equippedTagBuffer[128];
	char displayBuffer[128];
	char colorBuffer[128];
	GetClientCookie(client, ckEquippedTag, equippedTagBuffer, 128);
	if (kvPlayerTagList.JumpToKey("PlayerTags"))
	{
		if (kvPlayerTagList.JumpToKey(tagType))
		{
			kvPlayerTagList.GetString("display", displayBuffer, 128)
			kvPlayerTagList.GetString("color", colorBuffer, 128)
			kvPlayerTagList.Rewind();
			if (bTagEquipped[client] && eraseTag && StrEqual(equippedTagBuffer, tagType))
			{
				ChatProcessor_RemoveClientTag(client, displayBuffer);
				SetClientCookie(client, ckEquippedTag, "No Tag Equipped");
				bTagEquipped[client] = !bTagEquipped[client];
				return;
			}
			else if (equippedTagBuffer[0] == '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") == 0))
			{
				ChatProcessor_AddClientTag(client, displayBuffer);
				ChatProcessor_SetTagColor(client, displayBuffer, colorBuffer);
				SetClientCookie(client, ckEquippedTag, tagType);
				bTagEquipped[client] = true;
				return;
			}
			else
			{
				char previousTag[32];
				GetTagInfo(equippedTagBuffer, previousTag, 32)
				ChatProcessor_RemoveClientTag(client, previousTag);
				ChatProcessor_AddClientTag(client, displayBuffer);
				ChatProcessor_SetTagColor(client, displayBuffer, colorBuffer);
				SetClientCookie(client, ckEquippedTag, tagType);
				bTagEquipped[client] = true;
				return;
			}
		}
	}
}	

void TopMenu_TagCategories(TopMenu menu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "SnT Tag Menu");
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (topobj_id == mobjPlayerTags)
		{
			Format(buffer, maxlength, "Player Tags");
		}
		else if (topobj_id == mobjAwardedTags)
		{
			Format(buffer, maxlength, "Contest Tags");
		}
		else if (topobj_id == mobjEarlyTags)
		{
			Format(buffer, maxlength, "Early Supporter Tags");
		}
		else
		{
			Format(buffer, maxlength, "INVALID_MENU_OPTION");
		}
	}
}

void TopMenu_PlayerTags(TopMenu menu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "SnT Tag Menu");
	}
	else if (action == TopMenuAction_DisplayOption)
	{

	}
}

void TopMenu_ContestTags(TopMenu menu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "SnT Tag Menu");
	}
}

void TopMenu_SupporterTags(TopMenu menu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "SnT Tag Menu");
	}
}

public void OnClientCookiesCached(int client)
{
	char equippedTagBuffer[128];
	GetClientCookie(client, ckEquippedTag, equippedTagBuffer, 128);
	if (equippedTagBuffer[0] == '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") == 0)) // if cookie isn't set
	{
		SetClientCookie(client, ckEquippedTag, "No Tag Equipped")
		return;
	}
	else
	{
		ToggleTag(client, equippedTagBuffer, false);
	}
}

// Thanks to the SourceMod API forums for this code.
Menu BuildTagMenu()
{
	char TagListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TagListPath, sizeof(TagListPath), "configs/taglist.txt");
	File file = OpenFile(TagListPath, "rt");
	if (file == null)
	{
		PrintToServer("Unable to load taglist.txt");
		return null;
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Menu_ToggleTag);
	char tagName[255];
	while (!file.EndOfFile() && file.ReadLine(tagName, sizeof(tagName)))
	{
		if (tagName[0] == ';' || !IsCharAlpha(tagName[0]))
		{
			continue;
		}

		/* Cut off the name at any whitespace */
		int len = strlen(tagName);
		for (int i = 0; i < len; i++)
		{
			if (IsCharSpace(tagName[i]))
			{
				tagName[i] = '\0';
				break;
			}
		}
		/* Add it to the menu */

		char displayBuffer[128];
		char menuItemBuffer[256];
		GetTagInfo(tagName, displayBuffer, 128);
		Format(menuItemBuffer, 256, "%s", displayBuffer);
		menu.AddItem(tagName, menuItemBuffer);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Surf 'n' Turf Tags:");

	return menu;
}

public void OnMapStart()
{
    //mTagMenu = BuildTopMenu();
}

public void OnMapEnd()
{
    delete mTagMenu;
}

public int Menu_ToggleTag(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char menuItemBuffer[255];
		char equippedTagBuffer[255];
		GetClientCookie(param1, ckEquippedTag, equippedTagBuffer, 255);
		menu.GetItem(param2, menuItemBuffer, 255);
		if (strcmp(menuItemBuffer, equippedTagBuffer, false) == 0)
		{
			ToggleTag(param1, equippedTagBuffer, true);
		}
		else
		{
			ToggleTag(param1, menuItemBuffer, false);
		}
	}
}

public Action:SetTag(int client, int args)
{
	if (mTagMenu == null){
		PrintToConsole(client, "[SNTTags]: configs/taglist.txt was not found.");
		return Plugin_Handled;
	}
	if (args > 0)
	{
		ReplyToCommand(client, "\x01\x04[SNTTags] Usage: \x01\x01/tag, /tags, or /tagmenu")
	}
	mTagMenu.Display(client, TopMenuPosition_Start);
	return Plugin_Handled;
}