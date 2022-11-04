//------------------------------------------------------
//     Author : T-Rizzle
//------------------------------------------------------

if (!IncludeScript("botaifix_timers"))
	error("[BAIF][ERROR] Failed to include 'botaifix_timers'!\n");

const BUTTON_ATTACK = 1;
const BUTTON_DUCK = 4;
const BUTTON_USE = 32;
const BUTTON_SHOVE = 2048;
const BUTTON_RELOAD = 8192;
const BUTTON_ZOOM = 524288;

	::BotAIFix <-
	{
		Events = {}
		Survivors = {}
		Bots = {}
		Tanks = {}
		Special = {}
		ModeName = ""
		MapName = ""
		load_convars = 0
		allow_deadstopping = 1
		improved_revive_ai = 1
		tactical_crouching = 1
		t1_shove = 1
		common_revive_abandon_distance = 50
		melee_distance = 150
		melee_attack_distance = 45
		shove_distance = 45
		crouch_distance = 2000
		stand_distance = 400
		melee_abandon_distance = 200
		close_player_distance = 400
		special_shove_distance = 150
		spit_uncrouch_distance = 200
		tank_flee_distance = 400
		tank_revive_abandon_distance = 400
		incap_shoot_distance = 200
	}
	::BotAIFix.FileExists <- function (fileName)
	{
		//Check to see if the file exists
		local fileContents = FileToString(fileName);
		if (fileContents == null)
			return false;
		
		return true;
	}
	::BotAIFix.StringReplace <- function (str, orig, replace)
	{
		//Slimzo showed me how to create lists after reading files
		local expr = regexp(orig);
		local ret = "";
		local pos = 0;
		local captures = null;
		
		while (captures = expr.capture(str, pos))
		{
			foreach (i, c in captures)
			{
				ret += str.slice(pos, c.begin);
				ret += replace;
				pos = c.end;
			}
		}
		
		if (pos < str.len())
			ret += str.slice(pos);

		return ret;
	}
	::BotAIFix.CanTraceTo <- function (source, dest, mask = TRACE_MASK_SHOT, maxDist = 0)
	{
		/*
		// Note: Doing "end = dest.GetOrigin()" doesn't work when the object is lying on it's side with a certain angle because the trace ends right next to the object itself so i add a little offset towards the object's Up.
		//       Apparently the bot's internal AI is also affected by this bug, it often happens with medkits and pills the bot refuses to pick up.
		
		local traceTable = { start = source.EyePosition(), end = dest.GetOrigin() + (dest.GetAngles().Up() * 2), ignore = source, mask = mask };
		*/
		
		// 15 jun 2021 update added the GetCenter() function to CBaseEntity which should solve the issue described above
		
		local start = source.EyePosition();
		local end = dest.GetCenter();
		local traceTable = { start = start, end = end + (end - start), ignore = source, mask = mask }; // end = end + (end - start) <- If i stop to the item's center, depending on the item's model, it is possible that the trace doesn't reach it
		
		TraceLine(traceTable);
		
		if (!traceTable.hit || traceTable.enthit != dest)
			return false;
		
		if (maxDist && (traceTable.pos - start).Length() > maxDist)
			return false;
		
		return true;
	}
	::BotAIFix.VectorDotProduct <- function (a, b)
	{
		return (a.x * b.x) + (a.y * b.y) + (a.z * b.z);
	}
	::BotAIFix.CanSeeLocation <- function (player, dest, tolerance = 50)
	{
		if (!BotAIFix.IsValidSurvivor(player))
		{
			printl("VSLib Warning: Player " + player + " is invalid.");
			return;
		}
		
		local clientPos = player.EyePosition();
		local clientToTargetVec = dest - clientPos;
		local clientAimVector = player.EyeAngles().Forward();
		
		local angToFind = acos(BotAIFix.VectorDotProduct(clientAimVector, clientToTargetVec) / (clientAimVector.Length() * clientToTargetVec.Length())) * 360 / 2 / 3.14159265;
		
		if (angToFind < tolerance)
			return true;
		else
			return false;
	}
	::BotAIFix.CanSeeOtherEntity <- function (player, dest, tolerance = 50)
	{
		//This is will grab the distance for the selected entities
		if (!BotAIFix.IsValidSurvivor(player))
		{
			printl("VSLib Warning: Player " + player + " is invalid.");
			return;
		}
		if (!BotAIFix.CanSeeLocation(player, dest.GetCenter(), tolerance))
			return false;
		//Check to make sure it's not behind a wall or something
		local m_trace = { start = player.EyePosition(), end = dest.GetCenter(), ignore = player, mask = TRACE_MASK_SHOT };
		TraceLine(m_trace);
		
		if (!m_trace.hit || m_trace.enthit == null || m_trace.enthit == player)
			return false;
		
		if (m_trace.enthit.GetClassname() == "worldspawn" || !m_trace.enthit.IsValid())
			return false;
			
		if (m_trace.enthit == dest)
			return true;
		
		return false;
	}
	::BotAIFix.LoadSettingsFromFile <- function (settings, scope)
	{
		//loads this addon's cvars
		if(!settings)
		{
			return false;
		}
		foreach (setting in settings)
		{
			if (setting != "")
			{
				try
				{
					local compiledscript = compilestring(scope + setting);
					compiledscript();
				}
				catch(exception)
				{
					error("[BAIF][ERROR] Settings file is corrupted, recreating file with default setttings!\n");
					BotAIFix.CreateSettingsFile();
				}
			}
		}
		return true;
	}
	::BotAIFix.CreateSettingsFile <- function ()
	{
		local Cvars =
		[
			"load_convars = 0",
			"allow_deadstopping = 1",
			"improved_revive_ai = 1",
			"tactical_crouching = 1",
			"t1_shove = 1",
			"common_revive_abandon_distance = 50",
			"melee_distance = 150",
			"melee_attack_distance = 45",
			"shove_distance = 45",
			"crouch_distance = 2000",
			"stand_distance = 400",
			"melee_abandon_distance = 200",
			"close_player_distance = 400",
			"special_shove_distance = 150",
			"spit_uncrouch_distance = 200",
			"tank_flee_distance = 400",
			"tank_revive_abandon_distance = 400",
			"incap_shoot_distance = 200",
		]
		local fileContents2 = ""
		foreach(str in Cvars)
		{
			if (fileContents2 == "")
				fileContents2 = str;
			else
				fileContents2 += "\n" + str;
		}
		StringToFile("botaifix/cfg/settings.txt", fileContents2);
	}
	::BotAIFix.Initialize <- function (modename, mapname)
	{
		//This is the main startup process for this addon
		printl(modename);
		printl(mapname);
		BotAIFix.ModeName = modename;
		BotAIFix.MapName = mapname;
		if(!BotAIFix.FileExists("botaifix/cfg/settings.txt"))
		{
			BotAIFix.CreateSettingsFile();
		}
		local fileContents = FileToString("botaifix/cfg/settings.txt");
		fileContents = BotAIFix.StringReplace(fileContents, "\\r", "\n");
		fileContents = BotAIFix.StringReplace(fileContents, "\\n\\n", "\n");   // Basically: any CRLF combination ("\n", "\r", "\r\n") becomes "\n"
		fileContents = split(fileContents, "\n");
		BotAIFix.LoadSettingsFromFile(fileContents, "BotAIFix.");
		if(!BotAIFix.FileExists("botaifix/cfg/const.nut"))
		{
			local Think =
			[
				"const think_rate = 0.5",
			]
			local fileContents2 = ""
			foreach(str in Think)
			{
				if (fileContents2 == "")
					fileContents2 = str;
				else
					fileContents2 += "\n" + str;
			}
			StringToFile("botaifix/cfg/const.nut", fileContents2);
		}
		local textString = FileToString("botaifix/cfg/const.nut");
		local compiledscript = compilestring(textString);
		compiledscript();
		
		printl("think_rate = " + think_rate);
		printl("load_convars = " + BotAIFix.load_convars);
		printl("allow_deadstopping = " + BotAIFix.allow_deadstopping);
		printl("improved_revive_ai = " + BotAIFix.improved_revive_ai);
		printl("tactical_crouching = " + BotAIFix.tactical_crouching);
		printl("t1_shove = " + BotAIFix.t1_shove);
		printl("common_revive_abandon_distance = " + BotAIFix.common_revive_abandon_distance);
		printl("melee_distance = " + BotAIFix.melee_distance);
		printl("melee_attack_distance = " + BotAIFix.melee_attack_distance);
		printl("shove_distance = " + BotAIFix.shove_distance);
		printl("crouch_distance = " + BotAIFix.crouch_distance);
		printl("close_player_distance = " + BotAIFix.close_player_distance);
		printl("special_shove_distance = " + BotAIFix.special_shove_distance);
		printl("stand_distance = " + BotAIFix.stand_distance);
		printl("melee_abandon_distance = " + BotAIFix.melee_abandon_distance);
		printl("spit_uncrouch_distance = " + BotAIFix.spit_uncrouch_distance);
		printl("tank_flee_distance = " + BotAIFix.tank_flee_distance);
		printl("tank_revive_abandon_distance = " + BotAIFix.tank_revive_abandon_distance);
		printl("incap_shoot_distance = " + BotAIFix.incap_shoot_distance);
		
		load_convars = BotAIFix.load_convars;
		allow_deadstopping = BotAIFix.allow_deadstopping;
		improved_revive_ai = BotAIFix.improved_revive_ai;
		tactical_crouching = BotAIFix.tactical_crouching;
		t1_shove = BotAIFix.t1_shove;
		common_revive_abandon_distance = BotAIFix.common_revive_abandon_distance;
		melee_distance = BotAIFix.melee_distance;
		melee_attack_distance = BotAIFix.melee_attack_distance;
		shove_distance = BotAIFix.shove_distance;
		crouch_distance = BotAIFix.crouch_distance;
		stand_distance = BotAIFix.stand_distance;
		melee_abandon_distance = BotAIFix.melee_abandon_distance;
		close_player_distance = BotAIFix.close_player_distance;
		special_shove_distance = BotAIFix.special_shove_distance;
		spit_uncrouch_distance = BotAIFix.spit_uncrouch_distance;
		tank_flee_distance = BotAIFix.tank_flee_distance;
		tank_revive_abandon_distance = BotAIFix.tank_revive_abandon_distance;
		incap_shoot_distance = BotAIFix.incap_shoot_distance;
		
		local ThinkEnt = null;

		if (!ThinkEnt || !ThinkEnt.IsValid())
		{
			local ThinkEnt = SpawnEntityFromTable("info_target", { targetname = "botaifix" });
			if(ThinkEnt)
			{
				//This is where the think function is created
				ThinkEnt.ValidateScriptScope();
				local scope = ThinkEnt.GetScriptScope();
				scope["BotAIFixThinkFunc"] <- ::BotAIFix.Think;
				AddThinkToEnt(ThinkEnt, "BotAIFixThinkFunc");
				printl("BAI Entitiy created");
			}
		}
		if(load_convars != 0)
		{
			//These are the cvars for this addon
			Convars.SetValue("allow_all_bot_survivor_team", 1);
			Convars.SetValue("sb_all_bot_game", 1);
			Convars.SetValue("sb_allow_shoot_through_survivors", 0);
			Convars.SetValue("sb_battlestation_give_up_range_from_human", 300);
			Convars.SetValue("sb_battlestation_human_hold_time", 0.25);
			Convars.SetValue("sb_debug_apoproach_wait_time", 0);
			Convars.SetValue("sb_close_checkpoint_door_interval", 0.14);
			Convars.SetValue("sb_enforce_proximity_lookat_timeout", 0);
			Convars.SetValue("sb_combat_saccade_speed", 2250);
			Convars.SetValue("sb_enforce_proximity_range", 2000);
			Convars.SetValue("sb_far_hearing_range", 0xffffff);
			//Bots should still have a reaction time
			Convars.SetValue("sb_friend_immobilized_reaction_time_expert", 0.14);
			Convars.SetValue("sb_friend_immobilized_reaction_time_hard", 0.14);
			Convars.SetValue("sb_friend_immobilized_reaction_time_normal", 0.14);
			Convars.SetValue("sb_friend_immobilized_reaction_time_vs", 0.14);
			Convars.SetValue("sb_locomotion_wait_threshold", 0);
			Convars.SetValue("sb_max_battlestation_range_from_human", 300);
			Convars.SetValue("sb_max_scavenge_separation", 2000);
			Convars.SetValue("sb_near_hearing_range", 10000);
			Convars.SetValue("sb_neighbor_range", 100);
			Convars.SetValue("sb_normal_saccade_speed", 1500);
			Convars.SetValue("sb_path_lookahead_range", 1575);
			Convars.SetValue("sb_reachability_cache_lifetime", 0);
			Convars.SetValue("sb_rescue_vehicle_loading_range", 30);
			Convars.SetValue("sb_separation_danger_max_range", 300);
			Convars.SetValue("sb_separation_danger_min_range ", 200);
			Convars.SetValue("sb_separation_range", 300);
			Convars.SetValue("sb_sidestep_for_horde", 1);
			Convars.SetValue("sb_temp_health_consider_factor", 0.8);
			Convars.SetValue("sb_close_threat_range", 1);
			Convars.SetValue("sb_threat_close_range", 75);
			Convars.SetValue("sb_threat_exposure_stop", 0xffffff);
			Convars.SetValue("sb_threat_far_range", 10000);
			Convars.SetValue("sb_threat_medium_range", 6000);
			Convars.SetValue("sb_threat_very_close_range", 75);
			Convars.SetValue("sb_threat_very_far_range", 0xffffff);
			Convars.SetValue("sb_toughness_buffer", 20);
			Convars.SetValue("sb_vomit_blind_time", 0);
			//This helps with players not being able to join your server
			Convars.SetValue("sv_consistency", 0);
		}
	}
	::BotAIFix.OnPlayerSpawn <- function (player, params)
	{	
		if (BotAIFix.IsValidSurvivor(player))
		{
			if (NetProps.GetPropInt(player, "m_iTeamNum") != TEAM_SPECTATORS)
			{
				::BotAIFix.Survivors[player.GetPlayerUserId()] <- player;
				
				if (IsPlayerABot(player))
				{
					::BotAIFix.Bots[player.GetPlayerUserId()] <- player;
				}
			}
		}
		else if (("GetZombieType" in player) && player.GetZombieType() == 8)
		{
			::BotAIFix.Tanks[player.GetPlayerUserId()] <- player;
		}
		else if (("GetZombieType" in player) && player.GetZombieType() == 3)
		{
			::BotAIFix.Special[player.GetPlayerUserId()] <- player;
		}
		else if (("GetZombieType" in player) && player.GetZombieType() == 5)
		{
			::BotAIFix.Special[player.GetPlayerUserId()] <- player;
		}
	}
	::BotAIFix.OnPlayerDisconnected <- function (userid, player, params)
	{
		if (player && player.IsValid() && IsPlayerABot(player))
			return;

		if (userid in ::BotAIFix.Survivors)
			delete ::BotAIFix.Survivors[userid];
	}
	::BotAIFix.OnBotReplacedPlayer <- function (player, bot, params)
	{
		if (player.GetPlayerUserId() in ::BotAIFix.Survivors)
			delete ::BotAIFix.Survivors[player.GetPlayerUserId()];
		
		if (!BotAIFix.IsValidSurvivor(bot))
			return;
		
		::BotAIFix.Survivors[bot.GetPlayerUserId()] <- bot;
		::BotAIFix.Bots[bot.GetPlayerUserId()] <- bot;
		
	}
	::BotAIFix.OnPlayerReplacedBot <- function (player, bot, params)
	{	
		if (bot.GetPlayerUserId() in ::BotAIFix.Survivors)
			delete ::BotAIFix.Survivors[bot.GetPlayerUserId()];
		
		if (bot.GetPlayerUserId() in ::BotAIFix.Bots)
			delete ::BotAIFix.Bots[bot.GetPlayerUserId()];
		
		if (!BotAIFix.IsValidSurvivor(player))
			return;
		
		::BotAIFix.Survivors[player.GetPlayerUserId()] <- player;
	}
	::BotAIFix.IsValidSurvivor <- function (player)
	{
		local team = NetProps.GetPropInt(player, "m_iTeamNum");
		if (team == TEAM_SURVIVORS)
			return true;
			
		if (team != TEAM_L4D1_SURVIVORS)
			return false;
		
		//if (BotAIFix.ModeName != "coop" && BotAIFix.ModeName != "realism" && BotAIFix.ModeName != "versus" && BotAIFix.ModeName != "mutation12") // mutation12 = realism versus
		//	return true;
		
		if (BotAIFix.MapName != "c6m1_riverbank" && BotAIFix.MapName != "c6m3_port")
			return true;
		
		return false;
	}
	::BotAIFix.TankCheck <- function (player)
	{
		local ret = null;
		local close_tank = 10000;
		//Checks if their are any tanks on the map and grabs their distance from the player
		foreach (id, tank in ::BotAIFix.Tanks)
		{
			if (!tank.IsValid())
				continue;
			
			if (tank.GetPlayerUserId() == player.GetPlayerUserId())
				continue;
			
			local dist = (tank.GetOrigin() - player.GetOrigin()).Length();
			if(dist < close_tank && !tank.IsDead() && !tank.IsDying() && !tank.IsIncapacitated())
			{
				close_tank = dist;
				ret = tank;
			}
			
		}
		return ret;
	}
	::BotAIFix.PlayerDistance <- function (player)
	{
		local close_player = 10000;
		//Finds the closest human player to the bot that is alive
		foreach (id, surv in ::BotAIFix.Survivors)
		{
			if (!surv.IsValid())
				continue;
			
			if (surv.GetPlayerUserId() == player.GetPlayerUserId())
				continue;
				
			if(IsPlayerABot(surv))
				continue;
				
			local dist = (surv.GetOrigin() - player.GetOrigin()).Length();
			if(dist < close_player && !surv.IsDead() && !surv.IsDying())
			{
				close_player = dist;
			}
			
		}
		if(close_player == 10000)
		{
			//Bots can crouch whenever they want to
			close_player = 0;
		}
		return close_player;
	}
	::BotAIFix.SpecialCheck <- function (player)
	{
		local ret = null;
		local close_special = 10000;
		//Finds the closest special infected to the bot
		foreach (id, special in ::BotAIFix.Special)
		{
			if (!special.IsValid())
				continue;
			
			if (special.GetPlayerUserId() == player.GetPlayerUserId())
				continue;
			
			local dist = (special.GetOrigin() - player.GetOrigin()).Length();
			if(dist < close_special && !special.IsDead() && !special.IsDying())
			{
				close_special = dist;
				ret = special;
			}
			
		}
		return ret;
	}
	::BotAIFix.CommonCheck <- function (player)
	{
		local common_dist = 10000;
		local ent = null;
		local ret = null;
		//Checks for the closet common infected to the bot
		while(ent = Entities.FindByClassname(ent, "infected"))
		{
			if(ent.IsValid() && NetProps.GetPropInt(ent, "m_lifeState") == 0) // 0 = the infected is still alive
			{
				local dist = (ent.GetOrigin() - player.GetOrigin()).Length();
				if(dist < common_dist)
				{
					common_dist = dist;
					ret = ent;
				}
			}
		}
		return ret;
	}
	::BotAIFix.BotPressButton <- function (player, button, holdtime = 0)
	{
		//printl(button);
		NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | button);
		if(holdtime > 0)
		{
			BotAIFixTimers.AddTimer(null, holdtime, @(params) BotAIFix.BotStopPressingButton(params.player, params.button), { player = player, button = button });
		}
	}
	::BotAIFix.BotStopPressingButton <- function (player, button)
	{
		NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~button));
	}
	::BotAIFix.PlayerUnDisableButton <- function (player, button)
	{
		NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & (~button));
	}
	::BotAIFix.PlayerDisableButton <- function (player, button, holdtime = 0.1)
	{
		//printl(button);
		NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") | button);
		BotAIFixTimers.AddTimer(null, holdtime, @(params) BotAIFix.PlayerUnDisableButton(params.player, params.button), { player = player, button = button });
	}
	::BotAIFix.SurvivorsHeld <- function ()
	{
		foreach (surv in ::BotAIFix.Survivors)
		{
			if (surv.IsValid() && surv.IsDominatedBySpecialInfected())
				return true;
		}
	}
	::BotAIFix.CheckTeamMelee <- function ()
	{
		local team_melee = 0;
		//Checks if a bot and/or player has a chainsaw or melee weapon
		foreach (surv in ::BotAIFix.Survivors)
		{
			if(surv.IsValid())
			{
				local inv = {};
				GetInvTable(surv, inv);
				if("slot1" in inv)
				{
					local item = inv["slot1"];
					if(item.GetClassname() == "weapon_chainsaw" || !IsPlayerABot(surv) && item.GetClassname == "weapon_melee")
					{
						team_melee++;
					}
				}
			}
		}
		return team_melee;
	}
	::BotAIFix.SpitCheck <- function (player)
	{
		//This will find the nearest spit entity and grab its distance from the player
		local spit = null;
		local spit_dist = 10000;
		while(spit = Entities.FindByClassname(spit, "insect_swarm"))
		{
			local dist = (spit.GetOrigin() - player.GetOrigin()).Length();
			if(dist < spit_dist)
			{
				spit_dist = dist;
			}
		}
		return spit_dist;
	}
	::BotAIFix.NoCloseBots <- function (nav_area)
	{
		//This will will stop the fire entity from being blocked if a bot is too close to it
		foreach (bot in ::BotAIFix.Bots)
		{
			if(bot.IsValid() && bot.IsSurvivor() && !bot.IsDead() && !bot.IsDying() && !bot.IsIncapacitated() && !bot.IsHangingFromLedge())
			{
				//printl((nav_area.GetCenter() - bot.GetOrigin()).Length());
				if(200 > (nav_area.GetCenter() - bot.GetOrigin()).Length())
				{
					return false;
				}
			}
		}
		return true;
	}
	::BotAIFix.FireCheck <- function ()
	{
		//This will block areas where their is fire stopping the bots from repeatedly walking into them
		local fire = null;
		local nav_area = null;
		while(fire = Entities.FindByClassname(fire, "inferno"))
		{
			nav_area = NavMesh.GetNearestNavArea(fire.GetOrigin(), 2048, false, false);
			//printl(nav_area);
			if(nav_area != null && !nav_area.IsBlocked(2, false) && BotAIFix.NoCloseBots(nav_area))
			{
				//printl("Blocked " + nav_area);
				local kvs = { classname = "script_nav_blocker", origin = fire.GetOrigin(), extent = Vector(150, 150, 150), teamToBlock = "2", affectsFlow = "0" };
				local ent = g_ModeScript.CreateSingleSimpleEntityFromTable(kvs);
				ent.ValidateScriptScope();
				
				DoEntFire("!self", "SetParent", "!activator", 0, fire, ent); // I parent the nav blocker to the fire entity so it is automatically killed when the fire is gone
				DoEntFire("!self", "BlockNav", "", 0, null, ent);
			}
		}
	}
	::BotAIFix.OnSmokerTongueGrab <- function (player, smoker, params)
	{
		//This makes the bot that was grabbed by the smoker aim and "hopefully" shoot the smoker
		if(IsPlayerABot(player))
		{
			player.SetForwardVector(smoker.GetCenter() - player.GetCenter());
		}
	}
	::BotAIFix.OnReviveEnd <- function (player, params)
	{
		//This fixes bots being forced to shoot after being revived
		NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~1));
	}
	::BotAIFix.GetDistance <- function (player, ent, default_dist = 500)
	{
		//This is will grab the distance for the selected entities
		if(ent != null && player != null)
		{
			return (ent.GetOrigin() - player.GetOrigin()).Length();
		}
		return default_dist;
	}
	::BotAIFix.VectorAngles <- function (forwardVector)
	{
		//Got this code from left4lib
		local pitch = 0;
		local yaw = 0;
		
		if (forwardVector.y == 0 && forwardVector.x == 0)
		{
			if (forwardVector.z > 0)
				pitch = 270;
			else
				pitch = 90;
		}
		else
		{
			yaw = (atan2(forwardVector.y, forwardVector.x) * 180 / 3.14159265359);
			if (yaw < 0)
				yaw += 360;

			local tmp = sqrt((forwardVector.x * forwardVector.x) + (forwardVector.y * forwardVector.y));
			pitch = atan2(-forwardVector.z, tmp) * 180 / 3.14159265359;
			if (pitch < 0)
				pitch += 360;
		}
		
		return QAngle(pitch, yaw, 0);
	}
	::BotAIFix.BotLookAt <- function (bot, target = null, deltaPitch = 0, deltaYaw = 0)
	{
		//Got this code from left4lib
		local angles = bot.EyeAngles();
		local position = null;
		if (target != null && target.IsValid())
		{
			position = target.GetOrigin();
		}
		
		if (position != null)
		{
			local v = position - bot.EyePosition();
			v.Norm();
			angles = BotAIFix.VectorAngles(v);
		}
		
		if (deltaPitch != 0 || deltaYaw != 0)
			angles = RotateOrientation(angles, QAngle(deltaPitch, deltaYaw, 0));
		
		bot.SnapEyeAngles(angles);
	}
	::BotAIFix.Cleaner <- function (params)
	{
		// Survivors
		foreach (id, surv in ::BotAIFix.Survivors)
		{
			if (!surv || !surv.IsValid())
			{
				delete ::BotAIFix.Survivors[id];
			}
		}
		
		// Bots
		foreach (id, bot in ::BotAIFix.Bots)
		{
			if (!bot || !bot.IsValid())
			{
				delete ::BotAIFix.Bots[id];
			}
		}
		
		// Tanks
		foreach (id, tank in ::BotAIFix.Tanks)
		{
			if (!tank || !tank.IsValid())
			{
				delete ::BotAIFix.Tanks[id];
			}
		}
		
		// Specials
		foreach (id, special in ::BotAIFix.Special)
		{
			if (!special || !special.IsValid())
			{
				delete ::BotAIFix.Special[id];
			}
		}
	}
	::BotAIFix.OnRoundStart <- function (params)
	{
		BotAIFixTimers.AddTimer("Cleaner", 1, BotAIFix.Cleaner, {}, true);
	}
	::BotAIFix.Think <- function ()
	{
		//This is where the entire thinking process happens
		local params = null;
		BotAIFix.OnInfectedHurt(params);
		//printl("Think");
		return think_rate;
	}
	::BotAIFix.OnInfectedHurt <- function (params)
	{
		foreach (player in ::BotAIFix.Bots)
		{
			if(player && player.IsValid() && player.IsSurvivor() && !player.IsDead() && !player.IsDying())
			{
				local player_dist = BotAIFix.PlayerDistance(player);
				local tank = BotAIFix.TankCheck(player);
				local tank_dist = BotAIFix.GetDistance(player, tank, 10000);
				local special = BotAIFix.SpecialCheck(player);
				local special_dist = BotAIFix.GetDistance(player, special);
				local spit_dist = BotAIFix.SpitCheck(player);
				local common = BotAIFix.CommonCheck(player);
				local dist = BotAIFix.GetDistance(player, common);
				local inv = {};
				GetInvTable(player, inv);
				local item = null;
				if("slot1" in inv)
				{
					item = inv["slot1"];
				}
				//printl(player.GetPlayerName() + "'s Closest human player distance: " + player_dist)
				//printl(player.GetPlayerName() + "'s Closest common infected distance: " + dist)
				//printl(player.GetPlayerName() + "'s Closest special infected distance: " + special_dist)
				//printl(player.GetPlayerName() + "'s Closest tank distance: " + tank_dist)
				
				if(player.IsIncapacitated() && !player.IsHangingFromLedge() && !player.IsDominatedBySpecialInfected())
				{
					local maskButtons = player.GetButtonMask();
					//I have to make sure the game does not disable the attack button
					BotAIFix.PlayerUnDisableButton(player, BUTTON_ATTACK);
					BotAIFix.BotStopPressingButton(player, BUTTON_SHOVE);
					if((maskButtons & BUTTON_ATTACK))
					{
						//Since you have to spam click in order to fire a pistol I have to tell the bot to release the attack key before shooting again
						//printl("~attack");
						BotAIFix.BotStopPressingButton(player, BUTTON_ATTACK);
					}
					else if(incap_shoot_distance >= dist && !(maskButtons & BUTTON_ATTACK))
					{
						//This forces the bot to use their attack key
						//printl("attack");
						BotAIFix.BotPressButton(player, BUTTON_ATTACK);
						if(!BotAIFix.SurvivorsHeld())
						{
							BotAIFix.BotLookAt(player, common);
						}
					}
				}
				if(!player.IsIncapacitated() && !player.IsHangingFromLedge() && !player.IsDominatedBySpecialInfected())
				{
					local holdingItem = player.GetActiveWeapon();
					if(holdingItem == null)
					{
						//When a bot's chainsaw runs out of fuel sometimes the GetActiveWeapon fails, so I created this failsafe
						local chainsaw_fix = inv["slot1"];
						local holdingItem = chainsaw_fix.GetClassname();
						player.SwitchToItem(holdingItem);
						BotAIFix.PlayerUnDisableButton(player, BUTTON_ATTACK);
						BotAIFix.BotStopPressingButton(player, BUTTON_ATTACK);
						BotAIFix.BotStopPressingButton(player, BUTTON_SHOVE);
					}
					if(holdingItem.GetClassname() == "weapon_gascan" || holdingItem.GetClassname() == "weapon_cola_bottles" || holdingItem.GetClassname() == "weapon_pain_pills" || holdingItem.GetClassname() == "weapon_adrenaline" || holdingItem.GetClassname() == "weapon_pipe_bomb" || holdingItem.GetClassname() == "weapon_vomitjar" || holdingItem.GetClassname() == "weapon_molotov")
					{
						//Fixes a bug where bots can't use healing or throwables because they were forced to shove
						BotAIFix.BotStopPressingButton(player, BUTTON_SHOVE);
						BotAIFix.BotStopPressingButton(player, BUTTON_DUCK);
						BotAIFix.BotStopPressingButton(player, BUTTON_ZOOM);
					}
					if(holdingItem.GetClassname() != "weapon_gascan" && holdingItem.GetClassname() != "weapon_cola_bottles" && holdingItem.GetClassname() != "weapon_pipe_bomb" && holdingItem.GetClassname() != "weapon_vomitjar" && holdingItem.GetClassname() != "weapon_molotov" && holdingItem.GetClassname() != "weapon_pain_pills" && holdingItem.GetClassname() != "weapon_adrenaline" && holdingItem.GetClassname() != "weapon_first_aid_kit" && holdingItem.GetClassname() != "weapon_defibrillator")
					{
						if(tactical_crouching == 0 || stand_distance >= dist || crouch_distance <= dist || close_player_distance <= player_dist || tank_flee_distance >= tank_dist || !player.IsInCombat() || player.IsOnFire() || spit_uncrouch_distance >= spit_dist || !NetProps.GetPropInt(player, "m_hasVisibleThreats") && !player.IsInCombat())
						{
							//This makes bots not crouch when an enemy is too close or too far
							BotAIFix.BotStopPressingButton(player, BUTTON_DUCK);
							local maskButtons = player.GetButtonMask();
							if((maskButtons & BUTTON_ZOOM))
							{
								BotAIFix.BotStopPressingButton(player, BUTTON_ZOOM);
								DoEntFire("!self", "RunScriptCode", "BotAIFix.BotPressButton(self, BUTTON_ZOOM, 0.1)", 0.1, null, player);
							}
						}
						
						if(close_player_distance <= player_dist && !BotAIFix.SurvivorsHeld())
						{
							//This makes bots with melee weapons not stray too far from the group
							Convars.SetValue("sb_melee_approach_victim", 0);
						}
						if(close_player_distance > player_dist || BotAIFix.SurvivorsHeld())
						{
							//This makes bots with melee weapons attack nearby zombies more effectively
							Convars.SetValue("sb_melee_approach_victim", 1);
						}
						
						if(improved_revive_ai != 0)
						{
							//This will make bots stop reviving players who are incapacitated when a tank and/or common infected is near
							if(common_revive_abandon_distance >= dist && NetProps.GetPropInt(player, "m_reviveTarget") > 0)
							{
								local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
								NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
								NetProps.SetPropEntity(player, "m_reviveTarget", -1);
								NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
								player.SetForwardVector(common.GetCenter() - player.GetCenter());
								BotAIFix.BotLookAt(player, common);
								BotAIFix.BotPressButton(player, BUTTON_SHOVE, 0.1);
								BotAIFix.PlayerDisableButton(player, BUTTON_USE, 10.0);
								Convars.SetValue("sb_revive_friend_distance", 0);
								DoEntFire("!self", "RunScriptCode", "Convars.SetValue(\"sb_revive_friend_distance\", 125)", 5, null, player);
							}
							if(tank != null && Director.IsTankInPlay())
							{
								if(tank_flee_distance >= tank_dist)
								{
									CommandABot( { cmd = BOT_CMD_RETREAT, target = tank, bot = player } );
								}
								if(tank_revive_abandon_distance >= tank_dist && NetProps.GetPropInt(player, "m_reviveTarget") > 0)
								{
									local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
									NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
									NetProps.SetPropEntity(player, "m_reviveTarget", -1);
									NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
									BotAIFix.BotLookAt(player, tank);
									BotAIFix.PlayerDisableButton(player, BUTTON_USE, 2.0);
									Convars.SetValue("sb_revive_friend_distance", 0);
									DoEntFire("!self", "RunScriptCode", "Convars.SetValue(\"sb_revive_friend_distance\", 125)", 5, null, player);
									//NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | BUTTON_SHOVE);
								}
							}
						}
						
						if("slot0" in inv && (melee_abandon_distance < dist || tank_flee_distance > tank_dist))
						{
							//If the infected get too far bots should swap back to their primary weapon if they have one and it has ammo
							local primary_weapon = inv["slot0"];
							local main_weapon = primary_weapon.GetClassname();
							local PrimType = NetProps.GetPropInt(primary_weapon, "m_iPrimaryAmmoType");
							if(NetProps.GetPropIntArray(player, "m_iAmmo", PrimType) > 0 && ((main_weapon != "weapon_autoshotgun" && main_weapon != "weapon_pumpshotgun" && main_weapon != "weapon_shotgun_chrome" && main_weapon != "weapon_shotgun_spas") || (holdingItem.GetClassname() == "weapon_melee" || holdingItem.GetClassname() == "weapon_chainsaw")))
							{
								player.SwitchToItem(main_weapon);
							}
						}
						
						if(special != null && allow_deadstopping != 0)
						{
							//If a hunter or jockey gets too close try to dead stop them, "This will also help bots shove them off players as well."
							if(special_shove_distance >= special_dist && !special.IsStaggering() && !special.IsGhost())
							{
								BotAIFix.BotPressButton(player, BUTTON_SHOVE, 0.1);
							}
						}
						
						if(holdingItem.GetClassname() != "weapon_chainsaw" && shove_distance >= dist && !(NetProps.GetPropIntArray(common, "m_staggerTimer", 1) > -1.0))
						{
							//Have bots shove when an enemy gets too close
							//printl("Shove!!");
							BotAIFix.BotPressButton(player, BUTTON_SHOVE, 0.1);
							BotAIFix.BotLookAt(player, common);
							player.SetForwardVector(common.GetCenter() - player.GetCenter());
						}
						
						if(melee_attack_distance >= dist && BotAIFix.CanSeeOtherEntity(player, common) && (holdingItem.GetClassname() == "weapon_chainsaw" || holdingItem.GetClassname() == "weapon_melee"))
						{
							//Bots will hold down their attack button with chainsaws when the infected get too close
							//printl("Attack!!");
							BotAIFix.BotPressButton(player, BUTTON_ATTACK, 1);
							BotAIFix.BotLookAt(player, common);
							player.SetForwardVector(common.GetCenter() - player.GetCenter());
						}
						
						if(crouch_distance > dist && stand_distance < dist && close_player_distance > player_dist && tank_flee_distance < tank_dist && spit_uncrouch_distance < spit_dist && !player.IsOnFire() && tactical_crouching != 0)
						{
							if(NetProps.GetPropInt(player, "m_hasVisibleThreats") || player.IsInCombat())
							{
								//This makes bots crouch when an enemy is not too close or not too far
								BotAIFix.BotPressButton(player, BUTTON_DUCK);
								if(holdingItem.GetClassname() == "weapon_sniper_scout" || holdingItem.GetClassname() == "weapon_sniper_military" || holdingItem.GetClassname() == "weapon_sniper_awp" || holdingItem.GetClassname() == "weapon_hunting_rifle")
								{
									//If a bot has a sniperrifle they should scope in to improve their aim
									BotAIFix.BotPressButton(player, BUTTON_ZOOM);
								}
							}
						}
						
						if(melee_distance >= dist && item != null && tank_flee_distance < tank_dist && BotAIFix.CanTraceTo(player, common))
						{
							//If the infected get too close, bots should pull out their melee weapon if they have one
							if(item.GetClassname() == "weapon_melee" && holdingItem.GetClassname() != "weapon_melee")
							{
								player.SwitchToItem("weapon_melee");
								BotAIFix.BotPressButton(player, BUTTON_SHOVE, 0.1);
							}
							else if(item.GetClassname() == "weapon_chainsaw" && holdingItem.GetClassname() != "weapon_chainsaw")
							{
								player.SwitchToItem("weapon_chainsaw");
								BotAIFix.BotPressButton(player, BUTTON_SHOVE, 2.5); //This will help bots shove with the chainsaw upon pulling it out
							}
						}
					}
				}
			}
		}
	}

//last_set <- 0;
team_melee_weapons <- Convars.GetFloat("sb_max_team_melee_weapons");
function Update()
{
   //if(Time() >= last_set + 0.333)
   //{
       //Here is where you put all the things you do after the timer runs out
	   //local params = null;
       //BotAIFix.OnInfectedHurt(params);
       //last_set = Time(); //Keep this so the timer works properly
   //}
   
   //The Update Script runs every second, this allows the bots to "think"
	//This seems to not work when I put it into the think function
	local current_team_melee = BotAIFix.CheckTeamMelee();
	local max_survivors = 0;
	foreach (id, survivor in ::BotAIFix.Survivors)
	{
		if(survivor.IsValid())
		{
			max_survivors++;
		}
	}
	BotAIFix.FireCheck();
	if(team_melee_weapons == 0)
	{
		team_melee_weapons = 2;
	}
	if(team_melee_weapons + current_team_melee >= max_survivors)
	{
		Convars.SetValue("sb_max_team_melee_weapons", max_survivors);
	}
	else
	{
		Convars.SetValue("sb_max_team_melee_weapons", team_melee_weapons + current_team_melee);
	}
}

IncludeScript("botaifix_events");