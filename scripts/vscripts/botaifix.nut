//------------------------------------------------------
//     Author : T-Rizzle
//------------------------------------------------------

if (!IncludeScript("botaifix_timers"))
	error("[BAIF][ERROR] Failed to include 'botaifix_timers'!\n");

const IN_ATTACK = 1;
const IN_DUCK = 4;
const IN_FORWARD = 8;
const IN_BACK = 16;
const IN_USE = 32;
const IN_SHOVE = 2048;
const IN_RELOAD = 8192;
const IN_ZOOM = 524288; //Slimzo helped me find the bit number for this button

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
		improved_pistol_usage = 1
		common_revive_abandon_distance = 50
		melee_distance = 150
		melee_attack_distance = 50
		shove_distance = 50
		max_melee = 2
		crouch_distance = 2000
		stand_distance = 200
		melee_abandon_distance = 200
		close_player_distance = 400
		special_shove_distance = 150
		spit_uncrouch_distance = 200
		tank_flee_distance = 400
		tank_revive_abandon_distance = 400
		incap_shoot_distance = 200
		old_sb_max_team_melee_weapons = 0
	}
	::BotAIFix.FileExists <- function (fileName)
	{
		//Checks to see if the file exists
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
		//This checks to see if the location specified can be seen by the entity specified
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
		//This is will check to see if location specified can be seen by the entity, but this will onlt check the entitie's LOS, (Line of Sight)
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
		//Loads this addon's cvars/settings
		if(!settings)
		{
			error("[BAIF][ERROR] Settings file could not be found, recreating file with default setttings!\n");
			BotAIFix.CreateSettingsFile();
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
			"improved_pistol_usage = 1",
			"common_revive_abandon_distance = 50",
			"melee_distance = 150",
			"melee_attack_distance = 50",
			"shove_distance = 50",
			"max_melee = 2",
			"crouch_distance = 2000",
			"stand_distance = 200",
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
		if (!("think_rate" in getconsttable())) //This makes sure that thet Const.nut is not corrupted or invalid
		{
			error("[BAIF][ERROR] Const.nut file is corrupted, recreating file with default setttings!\n");
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
		printl("improved_pistol_usage = " + BotAIFix.improved_pistol_usage);
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
		
		//Is this even needed, I need to verify if it does
		load_convars = BotAIFix.load_convars;
		allow_deadstopping = BotAIFix.allow_deadstopping;
		improved_revive_ai = BotAIFix.improved_revive_ai;
		tactical_crouching = BotAIFix.tactical_crouching;
		t1_shove = BotAIFix.t1_shove;
		improved_pistol_usage = BotAIFix.improved_pistol_usage;
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
		
		//Its time to create the think function for the AI improvements, should I just use a timer instead like the other think functions?
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
			Convars.SetValue("sb_allow_shoot_through_survivors", 0); //This stops bots from shooting through teammates
			Convars.SetValue("sb_battlestation_give_up_range_from_human", 550);
			Convars.SetValue("sb_battlestation_human_hold_time", 0.01);
			Convars.SetValue("sb_debug_apoproach_wait_time", 0); //I just noticed that the l4d2 devs misspelled approach, it still works as intended though
			Convars.SetValue("sb_close_checkpoint_door_interval", 0.14); //Is this too high of a number?
			Convars.SetValue("sb_enforce_proximity_lookat_timeout", 0); //This might be too low
			Convars.SetValue("sb_combat_saccade_speed", 2250); //This is the bots "mouse sensitivity" when their is a horde or special infected
			Convars.SetValue("sb_enforce_proximity_range", 10000); //This stops bots from teleporting to the group if they get too far
			Convars.SetValue("sb_far_hearing_range", 3000); //This is how far bots can "hear"
			Convars.SetValue("sb_friend_immobilized_reaction_time_expert", 0.1); //Bots should still have a reaction time
			Convars.SetValue("sb_friend_immobilized_reaction_time_hard", 0.1); //Bots should still have a reaction time
			Convars.SetValue("sb_friend_immobilized_reaction_time_normal", 0.1); //Bots should still have a reaction time
			Convars.SetValue("sb_friend_immobilized_reaction_time_vs", 0.1); //Bots should still have a reaction time
			Convars.SetValue("sb_locomotion_wait_threshold", 0); //I think this is how long a bot must stand still before it can move again
			Convars.SetValue("sb_max_battlestation_range_from_human", 300);
			Convars.SetValue("sb_max_scavenge_separation", 2000); //This is how far away bots are allowed to scavenge for supplies
			Convars.SetValue("sb_near_hearing_range", 2500); //This is the range when a bot hears something that they should be worried about
			Convars.SetValue("sb_neighbor_range", 100); //This is how close a bot needs to be to another survivor in order for the bot to feel safe
			Convars.SetValue("sb_normal_saccade_speed", 1500); //This is the bots "mouse sensitivity" when they are not fighting a horde, attacking wandering common infected is a good example of when this is used
			Convars.SetValue("sb_path_lookahead_range", 0xffffff); //This is how far away a bot will look ahead of the group, until I find a good number I will leave it ridiculously high
			Convars.SetValue("sb_reachability_cache_lifetime", 0); //This is how long a bot will consider an area walkable, if said area becomes blocked or hazardous the bot will not mark it unsafe until this time has passed
			Convars.SetValue("sb_rescue_vehicle_loading_range", 30); //This is how close a bot will try to be to an escape vehicle
			Convars.SetValue("sb_separation_danger_max_range", 550); //If a player or bot gets this far from the group a bot will goto them to prevent them from being alone
			Convars.SetValue("sb_separation_danger_min_range ", 150); //If a bot gets this far from the group the bot will focus on getting back to the group
			Convars.SetValue("sb_separation_range", 550); //This is how far apart each player and bot should be from each other, doesn't work very often
			Convars.SetValue("sb_sidestep_for_horde", 1); //Bots will sidestep during hordes to acquire new infected targets
			Convars.SetValue("sb_temp_health_consider_factor", 0.8); //Temp health will be multipled by this when bots consider who needs healing
			Convars.SetValue("sb_close_threat_range", 50); //This causes bots to focus on the one zombie that enters this range until said zombie is either dead or has left said range
			Convars.SetValue("sb_threat_close_range", 50); //This causes bots to not waste time aiming at infected if they enter this range even if when the bot will miss said shot
			Convars.SetValue("sb_threat_exposure_stop", 300000); //Unknown what this does yet
			Convars.SetValue("sb_threat_exposure_walk", 150000); //Unknown what this does yet
			Convars.SetValue("sb_threat_far_range", 2500); //Bots will only attack zombies in this range if they are a part of a horde or are a special infected
			Convars.SetValue("sb_threat_medium_range", 2000); //Bots will attack zombies at this range even if they are not attacking the group, aka wanders will be considered threats
			Convars.SetValue("sb_threat_very_close_range", 50); //This causes bots to fire their weapons at infected if they enter this range even if the bot will miss said shot
			Convars.SetValue("sb_threat_very_far_range", 3000); //Any infected past this range are not considered as threats to the bots even if they are a boss infected
			Convars.SetValue("sb_toughness_buffer", 15); //When a bot considers who needs healing they add the specified HP to themselves when considering who needs healing
			Convars.SetValue("sb_vomit_blind_time", 2); //Bots should shove for a few seconds after being coverd in boomer bile
			Convars.SetValue("sv_consistency", 0); //This helps with players not being able to join your server
		}
	}
	::BotAIFix.OnPlayerSpawn <- function (player, params)
	{	
		if (BotAIFix.IsValidSurvivor(player))
		{
			if (NetProps.GetPropInt(player, "m_iTeamNum") != 0)
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
		else if (("GetZombieType" in player) && !player.IsSurvivor())
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
		if (team == 2)
			return true;
			
		if (team != 4)
			return false;
		
		//if (BotAIFix.ModeName != "coop" && BotAIFix.ModeName != "realism" && BotAIFix.ModeName != "versus" && BotAIFix.ModeName != "mutation12") // mutation12 = realism versus
		//	return true;
		
		if (BotAIFix.MapName != "c6m1_riverbank" && BotAIFix.MapName != "c6m3_port")
			return true;
		
		return false;
	}
	::BotAIFix.TankCheck <- function (player)
	{
		//Checks if their are any tanks on the map and grabs their distance from the bot
		local ret = null;
		local close_tank = 10000;
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
		//Finds the closest alive human player to the bot
		local close_player = 10000;
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
			//If their are no alive human players bots can crouch whenever they want to
			return 0;
		}
		return close_player;
	}
	::BotAIFix.SpecialCheck <- function (player)
	{
		//Finds the closest special infected to the bot
		local ret = null;
		local close_special = 10000;
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
		//Checks for the closet common infected to the bot
		local common_dist = 10000;
		local ent = null;
		local ret = null;
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
	::BotAIFix.WitchCheck <- function (player)
	{
		//This will find the nearest witch and grab its distance from the player
		local witch = null;
		local witch_dist = 10000;
		while(witch = Entities.FindByClassname(witch, "witch"))
		{
			local dist = (witch.GetOrigin() - player.GetOrigin()).Length();
			if(dist < witch_dist)
			{
				witch_dist = dist;
			}
		}
		return witch_dist;
	}
	::BotAIFix.UnfreezePlayer <- function (params)
	{
		local player = params["player"];
		
		if (player && player.IsValid())
			NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") & ~(1 << 5)); // unset FL_FROZEN
	}
	::BotAIFix.BotPressButton <- function (player, button, holdtime = 0, target = null, deltaPitch = 0, deltaYaw = 0, lockLook = false, unlockLookDelay = 0)
	{
		//printl(button);
		NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | button);
		if(lockLook)
		{
			NetProps.SetPropInt(player, "m_fFlags", NetProps.GetPropInt(player, "m_fFlags") | (1 << 5)); // set FL_FROZEN
			if(unlockLookDelay == 0)
			{
				unlockLookDelay = holdtime;
			}
		}
		if(target != null || deltaPitch != 0 || deltaYaw != 0)
		{
			BotAIFix.BotLookAt(player, target, deltaPitch, deltaYaw);
		}
		if(holdtime > 0)
		{
			BotAIFixTimers.AddTimer(null, holdtime, @(params) BotAIFix.BotStopPressingButton(params.player, params.button), { player = player, button = button });
			if(lockLook)
			{
				BotAIFixTimers.AddTimer(null, unlockLookDelay, BotAIFix.UnfreezePlayer, { player = player });
			}
		}
	}
	::BotAIFix.BotStopPressingButton <- function (player, button)
	{
		if(player && player.IsValid())
		{
			NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~button));
		}
	}
	::BotAIFix.PlayerUnDisableButton <- function (player, button)
	{
		if(player && player.IsValid())
		{
			NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & (~button));
		}
	}
	::BotAIFix.PlayerDisableButton <- function (player, button, holdtime = 0.1)
	{
		//printl(button);
		if(player && player.IsValid())
		{
			NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") | button);
			BotAIFixTimers.AddTimer(null, holdtime, @(params) BotAIFix.PlayerUnDisableButton(params.player, params.button), { player = player, button = button });
		}
	}
	::BotAIFix.SurvivorsHeld <- function (type = null)
	{
		foreach (id, surv in ::BotAIFix.Survivors)
		{
			if (surv.IsValid() && surv.IsDominatedBySpecialInfected())
			{
				local dominator = surv.GetSpecialInfectedDominatingMe();
				if(type == null || type = dominator.GetZombieType())
				{
					return true;
				}
			}
		}
	}
	::BotAIFix.CheckTeamMelee <- function ()
	{
		local team_melee = 0;
		//Checks if a bot and/or player has a chainsaw or melee weapon
		foreach (id, surv in ::BotAIFix.Survivors)
		{
			if(surv && surv.IsValid())
			{
				local inv = {};
				GetInvTable(surv, inv);
				if("slot1" in inv)
				{
					local item = inv["slot1"];
					if(item.GetClassname() == "weapon_chainsaw" || !IsPlayerABot(surv) && item.GetClassname() == "weapon_melee")
					{
						team_melee++;
					}
				}
			}
		}
		return team_melee;
	}
	::BotAIFix.NoCloseBots <- function (nav_area)
	{
		//This will will stop the fire entity from being blocked if a bot is too close to it
		foreach (id, bot in ::BotAIFix.Bots)
		{
			if(bot && bot.IsValid() && bot.IsSurvivor() && !bot.IsDead() && !bot.IsDying() && !bot.IsIncapacitated() && !bot.IsHangingFromLedge())
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
	::BotAIFix.FireCheck <- function (params)
	{
		//This will block areas where their is fire stopping the bots from repeatedly walking into them
		local fire = null;
		local nav_area = null;
		while(fire = Entities.FindByClassname(fire, "inferno"))
		{
			nav_area = NavMesh.GetNearestNavArea(fire.GetOrigin(), 2048, false, false);
			//printl(nav_area);
			if(nav_area != null && nav_area.IsValid() && !nav_area.HasAttributes(1 << 31) && BotAIFix.NoCloseBots(nav_area))
			{
				printl("Blocked " + nav_area);
				local kvs = { classname = "script_nav_blocker", origin = fire.GetOrigin(), extent = Vector(150, 50, 150), teamToBlock = "2", affectsFlow = "0" };
				local ent = g_ModeScript.CreateSingleSimpleEntityFromTable(kvs);
				ent.ValidateScriptScope();
				
				DoEntFire("!self", "SetParent", "!activator", 0, fire, ent); // I parent the nav blocker to the fire entity so it is automatically killed when the fire is gone
				DoEntFire("!self", "BlockNav", "", 0, null, ent);
				//DoEntFire("!self", "UnblockNav", "", Convars.GetFloat("inferno_flame_lifetime") - 0.1, null ent);
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
	::BotAIFix.ValidCheck <- function (params)
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
		BotAIFixTimers.AddTimer("ValidCheck", 1, BotAIFix.ValidCheck, {}, true);
		BotAIFixTimers.AddTimer("FireCheck", 0.85, BotAIFix.FireCheck, {}, true);
		BotAIFixTimers.AddTimer("MiscThink", 1, BotAIFix.MiscThink, {}, true);
		BotAIFix.old_sb_max_team_melee_weapons = Convars.GetFloat("sb_max_team_melee_weapons").tointeger();
	}
	::BotAIFix.AddonStop <- function ()
	{
		BotAIFixTimers.RemoveTimer("FireCheck");
		BotAIFixTimers.RemoveTimer("ValidCheck");
		BotAIFixTimers.RemoveTimer("MiscThink");
		
		BotAIFix.Survivors = {};
		BotAIFix.Bots = {};
		BotAIFix.Tanks = {};
		BotAIFix.Special = {};
		
	}
	::BotAIFix.OnRoundEnd <- function (params)
	{
		BotAIFix.AddonStop();
	}
	::BotAIFix.OnMapTransition <- function (params)
	{
		BotAIFix.AddonStop();
	}
	::BotAIFix.Think <- function ()
	{
		//This is where the entire thinking process happens
		local params = null;
		BotAIFix.OnInfectedHurt(params);
		//printl("Think");
		return think_rate;
	}
	::BotAIFix.MiscThink <- function (params)
	{
		//This seems to not work when I put it into the think function, the function above this one
		local current_team_melee = BotAIFix.CheckTeamMelee();
		local max_survivors = 0;
		foreach (id, survivor in ::BotAIFix.Survivors)
		{
			if(survivor && survivor.IsValid() && !survivor.IsDead() && !survivor.IsDying())
			{
				max_survivors++;
			}
		}
		if(current_team_melee + BotAIFix.max_melee + BotAIFix.old_sb_max_team_melee_weapons >= max_survivors)
		{
			//This makes sure that sb_max_team_melee_weapons is not greater than the maximum alive survivors
			Convars.SetValue("sb_max_team_melee_weapons", max_survivors);
		}
		else if(current_team_melee <= BotAIFix.max_melee + BotAIFix.old_sb_max_team_melee_weapons)
		{
			//This prevents sb_max_team_melee_weapons from increaing if a bot or player pickups a melee weapon unless it is less than max_melee
			Convars.SetValue("sb_max_team_melee_weapons", BotAIFix.max_melee + BotAIFix.old_sb_max_team_melee_weapons);
		}
		else
		{
			//This will increase sb_max_team_melee_weapons by the amount of players with melee weapons and bots with chainsaws
			Convars.SetValue("sb_max_team_melee_weapons", current_team_melee + BotAIFix.max_melee + BotAIFix.old_sb_max_team_melee_weapons);
		}
	}
	::BotAIFix.OnInfectedHurt <- function (params)
	{
		foreach (id, player in ::BotAIFix.Bots)
		{
			if(player && player.IsValid() && player.IsSurvivor() && !player.IsDead() && !player.IsDying())
			{
				local player_dist = BotAIFix.PlayerDistance(player);
				local tank = BotAIFix.TankCheck(player);
				local tank_dist = BotAIFix.GetDistance(player, tank, 10000);
				local special = BotAIFix.SpecialCheck(player);
				local special_dist = BotAIFix.GetDistance(player, special, 10000);
				local spit_dist = BotAIFix.SpitCheck(player);
				local witch_dist = BotAIFix.WitchCheck(player);
				local common = BotAIFix.CommonCheck(player);
				local dist = BotAIFix.GetDistance(player, common);
				local inv = {};
				GetInvTable(player, inv);
				local item = null;
				if("slot1" in inv)
				{
					item = inv["slot1"];
				}
				//printl(player.GetPlayerName() + "'s Closest human player distance: " + player_dist);
				//printl(player.GetPlayerName() + "'s Closest common infected distance: " + dist);
				//printl(player.GetPlayerName() + "'s Closest special infected distance: " + special_dist);
				//printl(player.GetPlayerName() + "'s Closest tank distance: " + tank_dist);
				//printl(player.GetPlayerName() + "'s common infected m_nSkin: " + common.GetSequenceName(common.GetSequence()));
				
				if(player.IsIncapacitated() && !player.IsHangingFromLedge() && !player.IsDominatedBySpecialInfected())
				{
					local maskButtons = player.GetButtonMask();
					//I have to make sure the game does not disable the attack button
					BotAIFix.PlayerUnDisableButton(player, IN_ATTACK);
					BotAIFix.BotStopPressingButton(player, IN_SHOVE);
					//With the new button method this is redundant, I will keep this here just in case
					/*
					if((maskButtons & IN_ATTACK))
					{
						//Since you have to spam click in order to fire a pistol I have to tell the bot to release the attack key before shooting again
						//printl("~attack");
						BotAIFix.BotStopPressingButton(player, IN_ATTACK);
					}
					else if(incap_shoot_distance >= dist && !(maskButtons & IN_ATTACK))
					{
						//This forces the bot to use their attack key
						//printl("attack");
						BotAIFix.BotPressButton(player, IN_ATTACK);
						if(!BotAIFix.SurvivorsHeld())
						{
						        BotAIFix.BotLookAt(player, common);
						}
					}
					*/
					if(!BotAIFix.SurvivorsHeld())
					{
						//This makes bots aim and attack nearby common infected
						BotAIFix.BotPressButton(player, IN_ATTACK, 0.1, common, -6, 0, true);
					}
					else
					{
						//If a player or bot is being held by a special infected the bots should just spam click instead
						BotAIFix.BotPressButton(player, IN_ATTACK, 0.1)
					}
				}
				if(!player.IsIncapacitated() && !player.IsHangingFromLedge() && !player.IsDominatedBySpecialInfected())
				{
					local holdingItem = player.GetActiveWeapon();
					if(holdingItem == null || !holdingItem.IsValid())
					{
						//When a bot's chainsaw runs out of fuel sometimes the GetActiveWeapon fails, so I created this failsafe
						local chainsaw_fix = inv["slot1"];
						local holdingItem = chainsaw_fix.GetClassname();
						player.SwitchToItem(holdingItem);
						BotAIFix.PlayerUnDisableButton(player, IN_ATTACK);
						BotAIFix.BotStopPressingButton(player, IN_ATTACK);
						BotAIFix.BotStopPressingButton(player, IN_SHOVE);
					}
					if(holdingItem.IsValid() && (holdingItem.GetClassname() == "weapon_gascan" || holdingItem.GetClassname() == "weapon_cola_bottles" || holdingItem.GetClassname() == "weapon_pain_pills" || holdingItem.GetClassname() == "weapon_adrenaline" || holdingItem.GetClassname() == "weapon_pipe_bomb" || holdingItem.GetClassname() == "weapon_vomitjar" || holdingItem.GetClassname() == "weapon_molotov"))
					{
						//Fixes a bug where bots can't use healing or throwables because they were forced to shove
						BotAIFix.BotStopPressingButton(player, IN_SHOVE);
						BotAIFix.BotStopPressingButton(player, IN_DUCK);
					}
					if(holdingItem.IsValid() && holdingItem.GetClassname() != "weapon_gascan" && holdingItem.GetClassname() != "weapon_cola_bottles" && holdingItem.GetClassname() != "weapon_pipe_bomb" && holdingItem.GetClassname() != "weapon_vomitjar" && holdingItem.GetClassname() != "weapon_molotov" && holdingItem.GetClassname() != "weapon_pain_pills" && holdingItem.GetClassname() != "weapon_adrenaline" && holdingItem.GetClassname() != "weapon_first_aid_kit" && holdingItem.GetClassname() != "weapon_defibrillator")
					{
						if(tactical_crouching == 0 || BotAIFix.SurvivorsHeld(1) || stand_distance >= dist || witch_dist < 500 || crouch_distance <= dist || close_player_distance <= player_dist || tank_flee_distance >= tank_dist || player.IsOnFire() || spit_uncrouch_distance >= spit_dist || !NetProps.GetPropInt(player, "m_hasVisibleThreats") && !player.IsInCombat())
						{
							//This makes bots not crouch when an enemy is too close or too far
							BotAIFix.BotStopPressingButton(player, IN_DUCK);
							local maskButtons = player.GetButtonMask();
							if((maskButtons & IN_ZOOM))
							{
								BotAIFix.BotStopPressingButton(player, IN_ZOOM);
								//DoEntFire("!self", "RunScriptCode", "BotAIFix.BotPressButton(self, BUTTON_ZOOM, 0.01)", 0.01, null, player);
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
								//This makes bots abandon revives when a common infected gets too close
								local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
								NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
								NetProps.SetPropEntity(player, "m_reviveTarget", -1);
								NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
								BotAIFix.BotPressButton(player, IN_SHOVE, 0.1, common, -6, 0, true); //I also make the bot shove the common that triggered this event
								BotAIFix.PlayerDisableButton(player, IN_USE, 10.0);
							}
							if(tank != null && Director.IsTankInPlay())
							{
								if(tank_flee_distance >= tank_dist)
								{
									//This tells bots to flee from the nearby tank
									CommandABot( { cmd = 2, target = tank, bot = player } );
									local velocity = player.GetVelocity();
									player.SetVelocity(Vector(-220, velocity.y, velocity.z)); //This is kind of a cheat because the bot will be able to move at the speed of a player with green health
									BotAIFix.BotPressButton(player, IN_BACK, 1);
									BotAIFix.PlayerDisableButton(player, IN_FORWARD, 1);
								}
								if(tank_revive_abandon_distance >= tank_dist && NetProps.GetPropInt(player, "m_reviveTarget") > 0)
								{
									//This makes bots abandon revives when a tank gets too close
									local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
									NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
									NetProps.SetPropEntity(player, "m_reviveTarget", -1);
									NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
									BotAIFix.BotLookAt(player, tank);
									BotAIFix.PlayerDisableButton(player, IN_USE, 2.0);
									CommandABot( { cmd = 2, target = tank, bot = player } );
									//NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | IN_SHOVE);
								}
							}
						}
						
						if("slot1" in inv && "slot0" in inv)
						{
							//This handles everything pistol related
							local secondary_weapon = inv["slot1"].GetClassname();
							local primary_weapon = inv["slot0"];
							local main_weapon = primary_weapon.GetClassname();
							local PrimType = NetProps.GetPropInt(primary_weapon, "m_iPrimaryAmmoType");
							if(improved_pistol_usage != 0 && 300 < dist && tank_flee_distance < tank_dist && 300 < special_dist && secondary_weapon != "weapon_melee" && secondary_weapon != "weapon_chainsaw")
							{
								if((player.IsInCombat() || NetProps.GetPropInt(player, "m_hasVisibleThreats")) && (main_weapon != "weapon_hunting_rifle" && main_weapon != "weapon_sniper_awp" && main_weapon != "weapon_sniper_military" && main_weapon != "weapon_sniper_scout"))
								{
									//If the infected get too far bots should swap to their pistols if they have one
									player.SwitchToItem(secondary_weapon);
								}
								else if(inv["slot1"].Clip1() != inv["slot1"].GetMaxClip1() && (!player.IsInCombat() && !NetProps.GetPropInt(player, "m_hasVisibleThreats")))
								{
									//Bots should reload their pistols if they are not in combat and they need to be reloaded
									//printl("Clip = " + inv["slot1"].Clip1());
									//printl("MaxClip = " + inv["slot1"].GetMaxClip1());
									player.SwitchToItem(secondary_weapon);
									BotAIFix.BotPressButton(player, IN_RELOAD, 0.1);
								}
								else if((melee_abandon_distance < dist || tank_flee_distance > tank_dist) && NetProps.GetPropIntArray(player, "m_iAmmo", PrimType) > 0 && (main_weapon == "weapon_sniper_scout" || main_weapon == "weapon_sniper_military" || main_weapon == "weapon_sniper_awp" || main_weapon == "weapon_hunting_rifle"))
							        {
									//Bots with sniper rifles should only use their pistols if infected get too close
									player.SwitchToItem(main_weapon);
							        }
							}
							else if((melee_abandon_distance < dist || tank_flee_distance > tank_dist) && NetProps.GetPropIntArray(player, "m_iAmmo", PrimType) > 0 && ((main_weapon != "weapon_autoshotgun" && main_weapon != "weapon_pumpshotgun" && main_weapon != "weapon_shotgun_chrome" && main_weapon != "weapon_shotgun_spas") || (holdingItem.GetClassname() == "weapon_melee" || holdingItem.GetClassname() == "weapon_chainsaw")))
							{
								//If the infected get too far and if the bot has a sniper rifle or melee weapon should swap back to their primary weapon if they have one and it has ammo
								player.SwitchToItem(main_weapon);
							}
						}
						
						if(special != null && allow_deadstopping != 0)
						{
							//If a hunter or jockey gets too close try to dead stop them, "This will also help bots shove them off players as well."
							if(special_shove_distance >= special_dist && !special.IsStaggering() && !special.IsGhost() && (special.GetZombieType() == 5 || special.GetZombieType() == 3))
							{
								BotAIFix.BotPressButton(player, IN_SHOVE, 0.1);
							}
						}
						
						if(melee_attack_distance >= dist && (BotAIFix.CanTraceTo(player, common) || 40 >= dist) && (holdingItem.GetClassname() == "weapon_chainsaw" || holdingItem.GetClassname() == "weapon_melee"))
						{
							//Bots will hold down their attack button with chainsaws when the infected get too close
							//printl("Attack!!");
							BotAIFix.BotPressButton(player, IN_ATTACK, 0.1, common, -6, 0, true);
						}
						if(holdingItem.GetClassname() != "weapon_chainsaw" && shove_distance >= dist && (BotAIFix.CanTraceTo(player, common) || 40 >= dist) && !common.GetSequenceName(common.GetSequence()).find("Shoved"))
						{
							//Have bots shove when an infected gets too close
							//printl("Shove!!");
							BotAIFix.BotPressButton(player, IN_SHOVE, 0.1, common, -6, 0, true);
						}
						
						if(!BotAIFix.SurvivorsHeld(1) && crouch_distance > dist && stand_distance < dist && witch_dist >= 500 && close_player_distance > player_dist && tank_flee_distance < tank_dist && spit_uncrouch_distance < spit_dist && !player.IsOnFire() && tactical_crouching != 0)
						{
							if(NetProps.GetPropInt(player, "m_hasVisibleThreats") || player.IsInCombat())
							{
								//This makes bots crouch when an enemy is not too close or not too far
								BotAIFix.BotPressButton(player, IN_DUCK);
								if(holdingItem.GetClassname() == "weapon_sniper_scout" || holdingItem.GetClassname() == "weapon_sniper_military" || holdingItem.GetClassname() == "weapon_sniper_awp" || holdingItem.GetClassname() == "weapon_hunting_rifle")
								{
									//If a bot has a sniperrifle they should scope in to improve their aim
									BotAIFix.BotPressButton(player, IN_ZOOM);
								}
							}
						}
						
						if(melee_distance >= dist && item != null && tank_flee_distance < tank_dist && BotAIFix.CanTraceTo(player, common))
						{
							//If the infected get too close, bots should pull out their melee weapon if they have one
							if(item.GetClassname() == "weapon_melee" && holdingItem.GetClassname() != "weapon_melee")
							{
								player.SwitchToItem("weapon_melee");
							}
							else if(item.GetClassname() == "weapon_chainsaw" && holdingItem.GetClassname() != "weapon_chainsaw")
							{
								player.SwitchToItem("weapon_chainsaw");
								BotAIFix.BotPressButton(player, IN_SHOVE, 2.7); //This will help bots shove with the chainsaw upon pulling it out
							}
						}
					}
				}
			}
		}
	}

IncludeScript("botaifix_events");
