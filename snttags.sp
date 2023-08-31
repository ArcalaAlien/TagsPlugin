#include <sourcemod>
#include <admin>
#include <clients>
#include <clientprefs>
#include <keyvalues>
#include <files>
#include <menus>
#include <chat-processor>

public Plugin:myinfo =
{
	name = "Surf'N'Turf Player Tag System",
	author = "Arcala the Gyiyg",
	description = "Plugin that lets users add tags before their name.",
	version = "2.0.0",
	url = "N/A"
} 

KeyValues kvPlayerTagList;
Cookie ckEquippedTag;
Cookie ckEquippedTagList;
Menu mTagHomeMenu;
Menu mTagPlayerMenu;
Menu mTagAwardMenu;
Menu mTagSupporterMenu;
Menu mTagDonatorMenu;

bool bTagEquipped[MAXPLAYERS + 1] = { false, ... };

public void OnPluginStart() {
	//Register "tagtest" to test the tag function
	RegConsoleCmd("sm_tag", Action_OpenMenu, "Brings up a menu to allow players to change their tags.");
	RegConsoleCmd("sm_tags", Action_OpenMenu, "Brings up a menu to allow players to change their tags.");
	RegConsoleCmd("sm_tagmenu", Action_OpenMenu, "Brings up a menu to allow players to change their tags.");

	// Set new KeyValue list to first KeyValue Tree
	kvPlayerTagList = new KeyValues("SnTTags");

	// Creats a file path that prints to the snttags.cfg file
	char ConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/snttags.cfg");

	// Imports all KeyValue trees snttags.cfg
	kvPlayerTagList.ImportFromFile(ConfigPath);


	//Register the cookie that will keep track of what tag a client has equipped.
	ckEquippedTag = RegClientCookie("Equipped_Tag", "The tag a player has equipped", CookieAccess_Protected);
	ckEquippedTagList = RegClientCookie("Equipped_Tag_Keylist", "The keylist the equipped tag is in", CookieAccess_Protected);

	mTagHomeMenu = BuildHomeMenu();
	mTagPlayerMenu = BuildPlayerTagMenu();
	mTagAwardMenu = BuildAwardTagMenu();
	mTagSupporterMenu = BuildSupporterTagMenu();
	mTagDonatorMenu = BuildDonatorTagMenu();

}

void GetTagInfo(char[] tagList, char[] tagType, char[] displayBuffer, int displayBufferLen)
{
	if (kvPlayerTagList.JumpToKey(tagList))
	{
		if (kvPlayerTagList.JumpToKey(tagType))
		{
			kvPlayerTagList.GetString("display", displayBuffer, displayBufferLen)
			kvPlayerTagList.Rewind();
		}
	}
}

bool GetTagForUser(char[] SteamID, char[] tagType)
{
	if (kvPlayerTagList.JumpToKey("AwardTags"))
	{
		if (kvPlayerTagList.JumpToKey(tagType))
		{
			char SteamIDBuffer[32];
			kvPlayerTagList.GetString("steamid", SteamIDBuffer, sizeof(SteamIDBuffer));
			if (StrEqual(SteamID, SteamIDBuffer))
			{
				kvPlayerTagList.Rewind();
				return true;
			}
			else
			{
				kvPlayerTagList.Rewind();
				return false;
			}
		}
	}
	return false;
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
void ToggleTag(int client, char[] tagList, char[] tagType, bool eraseTag)
{
	char equippedTagBuffer[128];
	char displayBuffer[128];
	char colorBuffer[128];
	GetClientCookie(client, ckEquippedTag, equippedTagBuffer, 128);
	if (kvPlayerTagList.JumpToKey(tagList))
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
				SetClientCookie(client, ckEquippedTagList, "No Tag Equipped");
				bTagEquipped[client] = !bTagEquipped[client];
				return;
			}
			else if (equippedTagBuffer[0] == '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") == 0))
			{
				ChatProcessor_AddClientTag(client, displayBuffer);
				ChatProcessor_SetTagColor(client, displayBuffer, colorBuffer);
				SetClientCookie(client, ckEquippedTag, tagType);
				SetClientCookie(client, ckEquippedTagList, tagList);
				bTagEquipped[client] = true;
				return;
			}
			else
			{
				char previousTag[32];
				GetTagInfo(tagList, equippedTagBuffer, previousTag, 32)
				ChatProcessor_RemoveClientTag(client, previousTag);
				ChatProcessor_AddClientTag(client, displayBuffer);
				ChatProcessor_SetTagColor(client, displayBuffer, colorBuffer);
				SetClientCookie(client, ckEquippedTag, tagType);
				SetClientCookie(client, ckEquippedTagList, tagList);
				bTagEquipped[client] = true;
				return;
			}
		}
	}
}	

public void OnClientCookiesCached(int client)
{
	char equippedTagBuffer[128];
	char equippedTagListBuffer[128];
	GetClientCookie(client, ckEquippedTag, equippedTagBuffer, 128);
	GetClientCookie(client, ckEquippedTagList, equippedTagListBuffer, 128);
	if (equippedTagBuffer[0] == '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") == 0)) // if cookie isn't set
	{
		SetClientCookie(client, ckEquippedTag, "No Tag Equipped")
		SetClientCookie(client, ckEquippedTagList, "No Tag Equipped");
		return;
	}
	else
	{
		ToggleTag(client, equippedTagListBuffer, equippedTagBuffer, false);
	}
}

public int Tags_PlayerTagMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menuItemBuffer[255];
			char equippedTagBuffer[255];
			char equippedTagList[32];
			GetClientCookie(param1, ckEquippedTag, equippedTagBuffer, 255);
			GetClientCookie(param1, ckEquippedTagList, equippedTagList, 32);
			menu.GetItem(param2, menuItemBuffer, 255);
			PrintToServer("[SNTTags] Menu Item Selected: %s, Current Tag Equipped: %s, Equipped Tag's List: %s", menuItemBuffer, equippedTagBuffer, equippedTagList);
			if (strcmp(menuItemBuffer, equippedTagBuffer, false) == 0)
			{
				ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
				PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully unequipped your tag");
			}
			else
			{
				if (equippedTagBuffer[0] != '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") != 0))
				{
					ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
				}
				ToggleTag(param1, "PlayerTags", menuItemBuffer, false);
				char selectedTag[32];
				GetTagInfo("PlayerTags", menuItemBuffer, selectedTag, sizeof(selectedTag));
				PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully equipped %s", selectedTag);
			}
		}
		case MenuAction_Cancel:
		{
			mTagHomeMenu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
		}
	}
	return 0;
}

public int Tags_AwardTagMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menuItemBuffer[255];
			char equippedTagBuffer[255];
			char equippedTagList[32];
			char AuthIDBuffer[32];
			GetClientAuthId(param1, AuthId_Steam3, AuthIDBuffer, sizeof(AuthIDBuffer));
			GetClientCookie(param1, ckEquippedTag, equippedTagBuffer, 255);
			GetClientCookie(param1, ckEquippedTagList, equippedTagList, 32);
			menu.GetItem(param2, menuItemBuffer, 255);
			PrintToServer("[SNTTags] Menu Item Selected: %s, Current Tag Equipped: %s, Equipped Tag's List: %s", menuItemBuffer, equippedTagBuffer, equippedTagList);
			if (GetTagForUser(AuthIDBuffer, menuItemBuffer))
			{
				if (strcmp(menuItemBuffer, equippedTagBuffer, false) == 0)
				{
					ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully unequipped your tag.")
				}
				else
				{
					if (equippedTagBuffer[0] != '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") != 0))
					{
						ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
					}
					ToggleTag(param1, "AwardTags", menuItemBuffer, false);
					char selectedTag[32];
					GetTagInfo("AwardTags", menuItemBuffer, selectedTag, sizeof(selectedTag));
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully equipped %s", selectedTag);
				}
			}
			else
			{
				PrintToChat(param1, "\x04[SNTTags]: \x01You are unable to equip this tag.")
			}
		}
		case MenuAction_Cancel:
		{
			mTagHomeMenu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
		}
	}
	return 0;
}

public int Tags_SupporterTagMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menuItemBuffer[255];
			char equippedTagBuffer[255];
			char equippedTagList[32];
			AdminId clientSupporter = GetUserAdmin(param1) 
			GetClientCookie(param1, ckEquippedTag, equippedTagBuffer, 255);
			GetClientCookie(param1, ckEquippedTagList, equippedTagList, 32);
			menu.GetItem(param2, menuItemBuffer, 255);
			PrintToServer("[SNTTags] Menu Item Selected: %s, Current Tag Equipped: %s, Equipped Tag's List: %s", menuItemBuffer, equippedTagBuffer, equippedTagList);
			if (GetAdminFlag(clientSupporter, Admin_Custom1))
			{
				if (strcmp(menuItemBuffer, equippedTagBuffer, false) == 0)
				{
					ToggleTag(param1, "SupporterTags", equippedTagBuffer, true);
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully unequipped your tag.")
				}
				else
				{
					if (equippedTagBuffer[0] != '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") != 0))
					{
						ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
					}
					ToggleTag(param1, "SupporterTags", menuItemBuffer, false);
					char selectedTag[32];
					GetTagInfo("SupporterTags", menuItemBuffer, selectedTag, sizeof(selectedTag));
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully equipped %s", selectedTag);
				}
			}
			else
			{
				PrintToChat(param1, "\x04[SNTTags]: \x01You are unable to equip this tag.")
			}
		}
		case MenuAction_Cancel:
		{
			mTagHomeMenu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
		}
	}
	return 0;
}

public int Tags_DonatorTagMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menuItemBuffer[255];
			char equippedTagBuffer[255];
			char equippedTagList[32];
			AdminId clientDonator = GetUserAdmin(param1) 
			GetClientCookie(param1, ckEquippedTag, equippedTagBuffer, 255);
			GetClientCookie(param1, ckEquippedTagList, equippedTagList, 32);
			menu.GetItem(param2, menuItemBuffer, 255);
			PrintToServer("[SNTTags] Menu Item Selected: %s, Current Tag Equipped: %s, Equipped Tag's List: %s", menuItemBuffer, equippedTagBuffer, equippedTagList);
			if (GetAdminFlag(clientDonator, Admin_Custom2))
			{
				if (strcmp(menuItemBuffer, equippedTagBuffer, false) == 0)
				{
					ToggleTag(param1, "DonatorTags", equippedTagBuffer, true);
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully unequipped your tag.")
				}
				else
				{
					if (equippedTagBuffer[0] != '\0' || (strcmp(equippedTagBuffer, "No Tag Equipped") != 0))
					{
						ToggleTag(param1, equippedTagList, equippedTagBuffer, true);
					}
					ToggleTag(param1, "DonatorTags", menuItemBuffer, false);
					char selectedTag[32];
					GetTagInfo("DonatorTags", menuItemBuffer, selectedTag, sizeof(selectedTag));
					PrintToChat(param1, "\x04[SNTTags]: \x01Sucessfully equipped %s", selectedTag);
				}
			}
			else
			{
				PrintToChat(param1, "\x04[SNTTags]: \x01You are unable to equip this tag.")
			}
		}
		case MenuAction_Cancel:
		{
			mTagHomeMenu.Display(param1, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
		}
	}
	return 0;
}

// Thanks to the SourceMod API forums for this code.
Menu BuildPlayerTagMenu()
{
	char TagListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TagListPath, sizeof(TagListPath), "configs/player_taglist.txt");
	File file = OpenFile(TagListPath, "rt");
	if (file == null)
	{
		PrintToServer("[SNTTags] Unable to load player_taglist.txt");
		return null;
	}
	else
	{
		PrintToServer("[SNTTags] Sucessfully loaded player_taglist.txt");
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Tags_PlayerTagMenu, MENU_ACTIONS_DEFAULT);
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
		GetTagInfo("PlayerTags", tagName, displayBuffer, 128);
		Format(menuItemBuffer, 256, "%s", displayBuffer);
		menu.AddItem(tagName, menuItemBuffer);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Surf 'n' Turf Tags");
	PrintToServer("[SNTTags] Successfully Built Player Tag Menu");
	return menu;
}

// Thanks to the SourceMod API forums for this code.
Menu BuildAwardTagMenu()
{
	char TagListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TagListPath, sizeof(TagListPath), "configs/event_taglist.txt");
	File file = OpenFile(TagListPath, "rt");
	if (file == null)
	{
		PrintToServer("[SNTTags] Unable to load event_taglist.txt");
		return null;
	}
	else
	{
		PrintToServer("[SNTTags] Sucessfully loaded event_taglist.txt");
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Tags_AwardTagMenu, MENU_ACTIONS_DEFAULT);
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
		GetTagInfo("AwardTags", tagName, displayBuffer, 128);
		Format(menuItemBuffer, 256, "%s", displayBuffer);
		menu.AddItem(tagName, menuItemBuffer);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Surf 'n' Turf Tags");
	PrintToServer("[SNTTags] Successfully built Event Tag menu.")
	return menu;
}

// Thanks to the SourceMod API forums for this code.
Menu BuildSupporterTagMenu()
{
	char TagListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TagListPath, sizeof(TagListPath), "configs/supporter_taglist.txt");
	File file = OpenFile(TagListPath, "rt");
	if (file == null)
	{
		PrintToServer("[SNTTags] Unable to load supporter_taglist.txt");
		return null;
	}
	else
	{
		PrintToServer("[SNTTags] Sucessfully loaded supporter_taglist.txt");
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Tags_SupporterTagMenu, MENU_ACTIONS_DEFAULT);
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
		GetTagInfo("SupporterTags", tagName, displayBuffer, 128);
		Format(menuItemBuffer, 256, "%s", displayBuffer);
		menu.AddItem(tagName, menuItemBuffer);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Surf 'n' Turf Tags");
	PrintToServer("[SNTTags] Successfully built Early Supporter tag menu.")
	return menu;
}

// Thanks to the SourceMod API forums for this code.
Menu BuildDonatorTagMenu()
{
	char TagListPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TagListPath, sizeof(TagListPath), "configs/donator_taglist.txt");
	File file = OpenFile(TagListPath, "rt");
	if (file == null)
	{
		PrintToServer("[SNTTags] Unable to load donator_taglist.txt");
		return null;
	}
	else
	{
		PrintToServer("[SNTTags] Sucessfully loaded donator_taglist.txt");
	}

	/* Create the menu Handle */
	Menu menu = new Menu(Tags_DonatorTagMenu, MENU_ACTIONS_DEFAULT);
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
		GetTagInfo("DonatorTags", tagName, displayBuffer, 128);
		Format(menuItemBuffer, 256, "%s", displayBuffer);
		menu.AddItem(tagName, menuItemBuffer);
	}

	/* Make sure we close the file! */
	file.Close();

	/* Finally, set the title */
	menu.SetTitle("Surf 'n' Turf Tags");
	PrintToServer("[SNTTags] Successfully built Donator tag menu.")
	return menu;
}

Menu BuildHomeMenu()
{
	Menu menu = new Menu(Tags_HomeMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Surf 'n' Turf Tags");
	menu.AddItem("playertags", "Player Tags");
	menu.AddItem("eventtags", "Event Tags");
	menu.AddItem("supportertags", "Supporter Tags");
	menu.AddItem("donatortags", "Donator Tags");
	return menu;
}

public void OnMapEnd()
{
	delete mTagHomeMenu;
	delete mTagPlayerMenu;
	delete mTagAwardMenu;
	delete mTagSupporterMenu;
	delete mTagDonatorMenu;
}

public int Tags_HomeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char MenuChoice[32];
			menu.GetItem(param2, MenuChoice, sizeof(MenuChoice));
			if (StrEqual(MenuChoice, "playertags"))
			{
				mTagPlayerMenu.Display(param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(MenuChoice, "eventtags"))
			{
				mTagAwardMenu.Display(param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(MenuChoice, "supportertags"))
			{
				mTagSupporterMenu.Display(param1, MENU_TIME_FOREVER);
			}
			else if (StrEqual(MenuChoice, "donatortags"))
			{
				mTagDonatorMenu.Display(param1, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
		}
	}
	return 0;
}

public Action:Action_OpenMenu(int client, int args)
{
	if (mTagHomeMenu == null){
		PrintToConsole(client, "[SNTTags] For some reason the home menu was not built.");
		return Plugin_Handled;
	}
	else if (mTagPlayerMenu == null)
	{
		PrintToConsole(client, "[SNTTags] configs/player_taglist.txt was not found.");
		return Plugin_Handled;
	}
	else if (mTagAwardMenu == null)
	{
		PrintToConsole(client, "[SNTTags] configs/event_taglist.txt was not found.");
		return Plugin_Handled;
	}
	else if (mTagSupporterMenu == null)
	{
		PrintToConsole(client, "[SNTTags] configs/supporter_taglist.txt was not found.");
		return Plugin_Handled;
	}
	else if (mTagDonatorMenu == null)
	{
		PrintToConsole(client, "[SNTTags] configs/donator_taglist.txt was not found.");
		return Plugin_Handled;
	}
	if (args > 0)
	{
		ReplyToCommand(client, "\x01\x04[SNTTags] Usage: \x01\x01/tag, /tags, or /tagmenu")
		return Plugin_Handled;
	}
	mTagHomeMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	bTagEquipped[client] = false;
}