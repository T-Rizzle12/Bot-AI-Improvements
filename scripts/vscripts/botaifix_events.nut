//------------------------------------------------------
//     Author : T-Rizzle
//------------------------------------------------------

printl("Including botaifix_events...\n");
printl("Bot AI Fix starting up!")

::BotAIFix.Events.OnGameEvent_weapon_reload <- function (params)
{	
	if("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
		local holdingItem = player.GetActiveWeapon();
		if(IsPlayerABot(player) && (holdingItem.GetClassname() == "weapon_autoshotgun" || holdingItem.GetClassname() == "weapon_pumpshotgun" || holdingItem.GetClassname() == "weapon_shotgun_chrome" || holdingItem.GetClassname() == "weapon_shotgun_spas") && 0 >= holdingItem.Clip1())
		{
			BotAIFix.PlayerDisableButton(player, BUTTON_ATTACK, 2.0);
		}
	}
}
::BotAIFix.Events.OnGameEvent_round_start <- function (params)
{
	BotAIFix.OnRoundStart(params);
}
::BotAIFix.Events.OnGameEvent_weapon_fire <- function (params)
{	
	if("userid" in params && "weapon" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
		local weapon = params["weapon"];
		local shove_chance = RandomInt(0,3);
		if(IsPlayerABot(player) && BotAIFix.t1_shove != 0 && shove_chance == 0 && (weapon == "pumpshotgun" || weapon == "sniper_scout" || weapon == "sniper_awp" || weapon == "shotgun_chrome"))
		{
			BotAIFix.BotPressButton(player, BUTTON_SHOVE, 0.1);
		}
	}
}
::BotAIFix.Events.OnGameEvent_player_disconnect <- function (params)
{
	if ("userid" in params)
	{
		local userid = params["userid"].tointeger();
		local player = g_MapScript.GetPlayerFromUserID(userid);
	
		BotAIFix.OnPlayerDisconnected(userid, player, params);
	}
}
::BotAIFix.Events.OnGameEvent_player_spawn <- function (params)
{
	if ("userid" in params)
	{
		local player = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
		BotAIFix.OnPlayerSpawn(player, params);
	}
}
::BotAIFix.Events.OnGameEvent_player_bot_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	BotAIFix.OnBotReplacedPlayer(player, bot, params);
}

::BotAIFix.Events.OnGameEvent_bot_player_replace <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["player"]);
	local bot = g_MapScript.GetPlayerFromUserID(params["bot"]);
	
	BotAIFix.OnPlayerReplacedBot(player, bot, params);
}
::BotAIFix.Events.OnGameEvent_tongue_grab <- function (params)
{
	local player = g_MapScript.GetPlayerFromUserID(params["victim"]);
	local smoker = g_MapScript.GetPlayerFromUserID(params["userid"]);
	
	BotAIFix.OnSmokerTongueGrab(player, smoker, params);
}
::BotAIFix.Events.OnGameEvent_revive_success <- function (params)
{	
	local player = g_MapScript.GetPlayerFromUserID(params["subject"]);
	BotAIFix.OnReviveEnd(player, params);
}

__CollectEventCallbacks(::BotAIFix.Events, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener);
