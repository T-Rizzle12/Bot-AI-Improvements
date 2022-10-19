//------------------------------------------------------
//     Author : T-Rizzle
//------------------------------------------------------

printl("Including botaifix_events...\n");
printl("Bot AI Fix starting up!")

::BotAIFix.Events.OnGameEvent_player_hurt <- function (params)
{	
	BotAIFix.OnInfectedHurt(params);
}
::BotAIFix.Events.OnGameEvent_player_death <- function (params)
{
	BotAIFix.OnInfectedHurt(params);
}
::BotAIFix.Events.OnGameEvent_player_use <- function (params)
{
	BotAIFix.OnInfectedHurt(params);
}
::BotAIFix.Events.OnGameEvent_player_shoot <- function (params)
{
	BotAIFix.OnInfectedHurt(params);
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
