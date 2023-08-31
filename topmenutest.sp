#include <sourcemod>
#include <topmenus>

public Plugin:myinfo =
{
	name = "Surf'N'Turf Player Tag System",
	author = "Arcala the Gyiyg",
	description = "Plugin that lets users add tags before their name.",
	version = "1.0.0",
	url = "N/A"
} 

TopMenu mTagMenu;
TopMenuObject mobjPlayerTags;
TopMenuObject mobjAwardedTags;
TopMenuObject mobjEarlyTags;

public void OnPluginStart()
{
    RegConsoleCmd("sm_topmenu", Display_TopMenu, "Display Top Menu");
}

public void DefaultCategoryHandler(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		if (object_id == INVALID_TOPMENUOBJECT)
		{
			Format(buffer, maxlength, "Tag Menu:");
		}
		else if (object_id == mobjPlayerTags)
		{
			Format(buffer, maxlength, "Player Tags:");
		}
		else if (object_id == mobjAwardedTags)
		{
			Format(buffer, maxlength, "Event Tags:");
		}
		else if (object_id == mobjEarlyTags)
		{
			Format(buffer, maxlength, "Early Supporter Tags:");
		}
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == mobjPlayerTags)
		{
			Format(buffer, maxlength, "Player Tagss");
		}
		else if (object_id == mobjAwardedTags)
		{
			Format(buffer, maxlength, "Event Tags");
		}
		else if (object_id == mobjEarlyTags)
		{
			Format(buffer, maxlength, "Early Supporter Tags");
		}
	}
}

public void Category1(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    // add code here
}

public void Category2(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    // add code here
}

public void Category3(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
    // add code here
}

public void OnAllPluginsLoaded()
{
	mTagMenu = new TopMenu(DefaultCategoryHandler);
	mobjPlayerTags = mTagMenu.AddCategory("PlayerTags", Category1);
	mobjAwardedTags = mTagMenu.AddCategory("EventTags", Category2);
	mobjEarlyTags = mTagMenu.AddCategory("SupporterTags", Category3);
}

public Action Display_TopMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] Command is in-game only");
		return Plugin_Handled;
	}
	
	mTagMenu.Display(client, TopMenuPosition_Start);
	return Plugin_Handled;
}