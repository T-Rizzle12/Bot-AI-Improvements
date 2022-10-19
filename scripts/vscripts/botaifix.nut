//------------------------------------------------------
//     Author : T-Rizzle
//------------------------------------------------------

	::BotAIFix <-
	{
		Events = {}
		last_set = 0
		load_convars = 0
		allow_deadstopping = 1
		improved_revive_ai = 1
		tactical_crouching = 1
		melee_distance = 100
		melee_attack_distance = 40
		melee_shove_distance = 30
		crouch_distance = 2000
		stand_distance = 400
		melee_abandon_distance = 200
		close_player_distance = 400
		special_shove_distance = 100
		spit_uncrouch_distance = 200
		tank_flee_distance = 800
		incap_shoot_distance = 200
	}
	::BotAIFix.FileExists <- function (fileName)
	{
		local fileContents = FileToString(fileName);
		if (fileContents == null)
			return false;
		
		return true;
	}
	::BotAIFix.StringReplace <- function (str, orig, replace)
	{
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
	::BotAIFix.LoadSettingsFromFile <- function (settings, scope)
	{
		if(!settings)
		{
			return false;
		}
		foreach (setting in settings)
		{
			if (setting != "")
			{
				local compiledscript = compilestring(scope + setting);
				compiledscript();
			}
		}
		return true;
	}
	::BotAIFix.Initialize <- function (modename, mapname)
	{
		printl(modename);
		printl(mapname);
		if(!BotAIFix.FileExists("botaifix/cfg/settings.txt"))
		{
			local Cvars =
			[
				"load_convars = 0",
				"allow_deadstopping = 1",
				"improved_revive_ai = 1",
				"tactical_crouching = 1",
				"melee_distance = 100",
				"melee_attack_distance = 40",
				"melee_shove_distance = 30",
				"crouch_distance = 2000",
				"stand_distance = 400",
				"melee_abandon_distance = 200",
				"close_player_distance = 400",
				"special_shove_distance = 100",
				"spit_uncrouch_distance = 200",
				"tank_flee_distance = 800",
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
		printl("melee_distance = " + BotAIFix.melee_distance);
		printl("melee_attack_distance = " + BotAIFix.melee_attack_distance);
		printl("melee_shove_distance = " + BotAIFix.melee_shove_distance);
		printl("crouch_distance = " + BotAIFix.crouch_distance);
		printl("close_player_distance = " + BotAIFix.close_player_distance);
		printl("special_shove_distance = " + BotAIFix.special_shove_distance);
		printl("stand_distance = " + BotAIFix.stand_distance);
		printl("melee_abandon_distance = " + BotAIFix.melee_abandon_distance);
		printl("spit_uncrouch_distance = " + BotAIFix.spit_uncrouch_distance);
		printl("tank_flee_distance = " + BotAIFix.tank_flee_distance);
		printl("incap_shoot_distance = " + BotAIFix.incap_shoot_distance);
		
		load_convars = BotAIFix.load_convars;
		allow_deadstopping = BotAIFix.allow_deadstopping;
		improved_revive_ai = BotAIFix.improved_revive_ai;
		tactical_crouching = BotAIFix.tactical_crouching;
		melee_distance = BotAIFix.melee_distance;
		melee_attack_distance = BotAIFix.melee_attack_distance;
		melee_shove_distance = BotAIFix.melee_shove_distance;
		crouch_distance = BotAIFix.crouch_distance;
		stand_distance = BotAIFix.stand_distance;
		melee_abandon_distance = BotAIFix.melee_abandon_distance;
		close_player_distance = BotAIFix.close_player_distance;
		special_shove_distance = BotAIFix.special_shove_distance;
		spit_uncrouch_distance = BotAIFix.spit_uncrouch_distance;
		tank_flee_distance = BotAIFix.tank_flee_distance;
		incap_shoot_distance = BotAIFix.incap_shoot_distance;
		
		local ThinkEnt = null

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
			Convars.SetValue("sb_threat_close_range", 100);
			Convars.SetValue("sb_threat_exposure_stop", 0xffffff);
			Convars.SetValue("sb_threat_far_range", 400000000);
			Convars.SetValue("sb_threat_medium_range", 6000);
			Convars.SetValue("sb_threat_very_close_range", 50);
			Convars.SetValue("sb_threat_very_far_range", 0xffffff);
			Convars.SetValue("sb_toughness_buffer", 20);
			Convars.SetValue("sb_vomit_blind_time", 0);
			Convars.SetValue("sv_consistency", 0);
		}
	}
	::BotAIFix.TankCheck <- function (player)
	{
		local player2 = null;
		local ret = null;
		local close_tank = 10000;
		//Checks if their are any tanks on the map and grabs their distance from the player
		while(player2 = Entities.FindByClassname(player2, "player"))
		{
			if(!player2.IsSurvivor() && !player2.IsDead() && !player2.IsDying())
			{
				if(player2.GetZombieType() == 8)
				{
					local dist = (player2.GetOrigin() - player.GetOrigin()).Length();
					if(dist < close_tank)
					{
						close_tank = dist;
						ret = player2;
					}
				}
			}
		}
		return ret;
	}
	::BotAIFix.SpecialCheck <- function (player)
	{
		local player2 = null;
		local ret = null;
		local close_special = 10000;
		//Checks if their are any hunters or jockeys
		while(player2 = Entities.FindByClassname(player2, "player"))
		{
			if(!player2.IsSurvivor() && !player2.IsDead() && !player2.IsDying())
			{
				if(player2.GetZombieType() == 3 || player2.GetZombieType() == 5)
				{
					local dist = (player2.GetOrigin() - player.GetOrigin()).Length();
					if(dist < close_special)
					{
						close_special = dist;
						ret = player2;
					}
				}
			}
		}
		return ret;
	}
	::BotAIFix.PlayerDistance <- function (player)
	{
		local player_dist = 0;
		local player2 = null;
		//Checks and makes sure that bots don't stray too far from real players
		while(player2 = Entities.FindByClassname(player2, "player"))
		{
			if(player2.IsSurvivor() && !player2.IsDead() && !player2.IsDying() && !IsPlayerABot(player2))
			{
				local dist = (player2.GetOrigin() - player.GetOrigin()).Length();
				if(player_dist == 0)
				{
					player_dist = 10000;
				}
				if(dist < player_dist)
				{
					player_dist = dist;
				}
			}
		}
		return player_dist;
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
	::BotAIFix.CheckTeamMelee <- function ()
	{
		local team_melee = 0;
		local player = null;
		//Checks if a bot and/or player has a chainsaw or melee weapon
		while(player = Entities.FindByClassname(player, "player"))
		{
			local inv = {};
			GetInvTable(player, inv);
			if("slot1" in inv)
			{
				local item = inv["slot1"];
				if(item.GetClassname() == "weapon_chainsaw" || !IsPlayerABot(player) && item.GetClassname == "weapon_melee")
				{
					team_melee++;
				}
			}
		}
		return team_melee;
	}
	::BotAIFix.MaxSurvivors <- function ()
	{
		local player = null;
		local max_survivors = 0;
		//Checks how many survivors are currently in the game
		while(player = Entities.FindByClassname(player, "player"))
		{
			if(player.IsSurvivor())
			{
				max_survivors++;
			}
		}
		return max_survivors;
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
		local player = null;
		while(player = Entities.FindByClassname(player, "player"))
		{
			if(player.IsSurvivor() && !player.IsDead() && !player.IsDying() && IsPlayerABot(player) && !player.IsIncapacitated() && !player.IsHangingFromLedge())
			{
				printl((nav_area.GetCenter() - player.GetOrigin()).Length());
				if(200 > (nav_area.GetCenter() - player.GetOrigin()).Length())
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
	::BotAIFix.VectorAngles <- function (forwardVector)
	{
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
		local angles = bot.EyeAngles();
		local position = null;
		if (target != null)
		{
			position = target
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
		local player = null;
		while(player = Entities.FindByClassname(player, "player"))
		{
			if(player.IsSurvivor() && !player.IsDead() && !player.IsDying() && IsPlayerABot(player))
			{
				local player_dist = BotAIFix.PlayerDistance(player);
				local tank = BotAIFix.TankCheck(player);
				local tank_dist = 10000;
				local special = BotAIFix.SpecialCheck(player);
				local special_dist = 500;
				local spit_dist = BotAIFix.SpitCheck(player);
				local common = BotAIFix.CommonCheck(player);
				local dist = 500;
				local inv = {};
				GetInvTable(player, inv);
				local item = null;
				if("slot1" in inv)
				{
					item = inv["slot1"];
				}
				//I need to create a function to reduce clutter and automate this process
				if(special != null)
				{
					special_dist = (special.GetOrigin() - player.GetOrigin()).Length();
				}
				if(tank != null)
				{
					tank_dist = (tank.GetOrigin() - player.GetOrigin()).Length();
				}
				if(common != null)
				{
					dist = (common.GetOrigin() - player.GetOrigin()).Length();
				}
				//printl(player.GetPlayerName() + "'s Closest human player distance: " + player_dist)
				//printl(player.GetPlayerName() + "'s Closest common infected distance: " + dist)
				//printl(player.GetPlayerName() + "'s Closest special infected distance: " + special_dist)
				//printl(player.GetPlayerName() + "'s Closest tank distance: " + tank_dist)
				
				if(player.IsIncapacitated() && !player.IsHangingFromLedge() && !player.IsDominatedBySpecialInfected())
				{
					local maskButtons = player.GetButtonMask();
					//I have to make sure the game does not disable the attack button
					NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & (~1));
					NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~2048));
					if((maskButtons & 1))
					{
						//Since you have to spam click in order to fire a pistol I have to tell the bot to release the attack key before shooting again
						printl("~attack");
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~1));
					}
					else if(incap_shoot_distance >= dist && !(maskButtons & 1))
					{
						//This forces the bot to use their attack key
						printl("attack");
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 1);
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
						NetProps.SetPropInt(player, "m_afButtonDisabled", NetProps.GetPropInt(player, "m_afButtonDisabled") & (~1));
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~1));
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~2048));
					}
					if(holdingItem.GetClassname() == "weapon_gascan" || holdingItem.GetClassname() == "weapon_cola_bottles" || holdingItem.GetClassname() == "weapon_pain_pills" || holdingItem.GetClassname() == "weapon_adrenaline" || holdingItem.GetClassname() == "weapon_pipe_bomb" || holdingItem.GetClassname() == "weapon_vomitjar" || holdingItem.GetClassname() == "weapon_molotov")
					{
						//Fixes a bug where bots can't use healing or throwables because they were forced to shove
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~2048));
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~4));
						NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~524288));
					}
					if(holdingItem.GetClassname() != "weapon_gascan" && holdingItem.GetClassname() != "weapon_cola_bottles" && holdingItem.GetClassname() != "weapon_pipe_bomb" && holdingItem.GetClassname() != "weapon_vomitjar" && holdingItem.GetClassname() != "weapon_molotov" && holdingItem.GetClassname() != "weapon_pain_pills" && holdingItem.GetClassname() != "weapon_adrenaline" && holdingItem.GetClassname() != "weapon_first_aid_kit" && holdingItem.GetClassname() != "weapon_defibrillator")
					{
						if(tactical_crouching == 0 || stand_distance >= dist || crouch_distance <= dist || close_player_distance <= player_dist || tank_flee_distance >= tank_dist || !player.IsInCombat() || player.IsOnFire() || spit_uncrouch_distance >= spit_dist || !NetProps.GetPropInt(player, "m_hasVisibleThreats") && !player.IsInCombat())
						{
							//This makes bots not crouch when an enemy is too close or too far
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~4));
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~524288));
						}
						
						if(close_player_distance <= player_dist)
						{
							//This makes bots with melee weapons not stray too far from the group
							Convars.SetValue("sb_melee_approach_victim", 0);
						}
						if(close_player_distance > player_dist)
						{
							//This makes bots with melee weapons attack nearby zombies more effectively
							Convars.SetValue("sb_melee_approach_victim", 1);
						}
						
						if(tank_flee_distance >= tank_dist || melee_distance >= dist && NetProps.GetPropInt(player, "m_reviveTarget") > 0)
						{
							if(improved_revive_ai != 0)
							{
								//This will make bots stop reviving players who are incapacitated when a tank and/or common infected is near
								if(melee_distance >= dist && NetProps.GetPropInt(player, "m_reviveTarget") > 0)
								{
									local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
									NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
									NetProps.SetPropEntity(player, "m_reviveTarget", -1);
									NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
									if(common != null)
									{
										BotAIFix.BotLookAt(player, common, -6);
									}
									NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 2048);
								}
								if(tank != null && Director.IsTankInPlay())
								{
									CommandABot( { cmd = BOT_CMD_RETREAT, target = tank, bot = player } );
									if(NetProps.GetPropInt(player, "m_reviveTarget") > 0)
									{
										local player2 = NetProps.GetPropEntity(player, "m_reviveTarget");
										NetProps.SetPropFloat(player2, "m_flProgressBarDuration", 0.0);
										NetProps.SetPropEntity(player, "m_reviveTarget", -1);
										NetProps.SetPropEntity(player2, "m_reviveOwner", -1);
										BotAIFix.BotLookAt(player, tank);
										//NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 2048);
									}
									
								}
							}
						}
						
						if(melee_distance < dist && special_shove_distance < special_dist || special != null && special.IsStaggering())
						{
							//If the infected get too far stop shoving
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~2048));
						}
						
						if(holdingItem.GetClassname() == "weapon_sniper_scout" || holdingItem.GetClassname() == "weapon_sniper_military" || holdingItem.GetClassname() == "weapon_sniper_awp" || holdingItem.GetClassname() == "weapon_hunting_rifle" || holdingItem.GetClassname() == "weapon_melee" || holdingItem.GetClassname() == "weapon_chainsaw" || tank_flee_distance > tank_dist)
						{
							//If the infected get to far bots should swap back to their primary weapon if they have one and it has ammo
							if("slot0" in inv && melee_abandon_distance < dist)
							{
								local primary_weapon = inv["slot0"];
								local main_weapon = primary_weapon.GetClassname();
								local PrimType = NetProps.GetPropInt(primary_weapon, "m_iPrimaryAmmoType");
								if(NetProps.GetPropIntArray(player, "m_iAmmo", PrimType) > 0)
								{
									player.SwitchToItem(main_weapon);
								}
							}
						}
						
						if(special != null && allow_deadstopping != 0)
						{
							//If a hunter or jockey gets too close try to dead stop them, "This will also help bots shove them off players as well."
							if(special_shove_distance >= special_dist && !special.IsStaggering() && !special.IsGhost())
							{
								NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 2048);
							}
						}
						
						if(Time() <= last_set + 1 && holdingItem.GetClassname() == "weapon_chainsaw" || holdingItem.GetClassname() == "weapon_melee" && melee_shove_distance >= dist)
						{
							//Have bots shove when an enemy gets to close or when they just pulled out their chainsaw
							//Msg("Shove!!")
							if(common != null)
							{
								player.SetForwardVector(common.GetCenter() - player.GetCenter());
							}
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 2048);
						}
						
						if(Time() >= last_set + 1 && holdingItem.GetClassname() == "weapon_chainsaw" || holdingItem.GetClassname() == "weapon_melee" && melee_shove_distance < dist)
						{
							//Bots should stop shoving when their chainsaw can be used
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~2048));
						}
						
						
						if(melee_attack_distance >= dist && holdingItem.GetClassname() == "weapon_chainsaw" && NetProps.GetPropInt(player, "m_hasVisibleThreats"))
						{
							//Bots will hold down their attack button with chainsaws when the infected get too close
							if(common != null)
							{
								BotAIFix.BotLookAt(player, common, -6);
							}
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 1);
						}
						
						if(melee_attack_distance < dist && holdingItem.GetClassname() == "weapon_chainsaw")
						{
							//Bots should not attack when infected get too far from them and they are currently holding a melee weapon
							NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") & (~1));
						}
						
						if(crouch_distance > dist && stand_distance < dist && close_player_distance > player_dist && tank_flee_distance < tank_dist && spit_uncrouch_distance < spit_dist && !player.IsOnFire() && tactical_crouching != 0)
						{
							if(NetProps.GetPropInt(player, "m_hasVisibleThreats") || player.IsInCombat())
							{
								//This makes bots crouch when an enemy is not too close or not too far
								NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 4);
								if(holdingItem.GetClassname() == "weapon_sniper_scout" || holdingItem.GetClassname() == "weapon_sniper_military" || holdingItem.GetClassname() == "weapon_sniper_awp" || holdingItem.GetClassname() == "weapon_hunting_rifle")
								{
									//If a bot has a sniperrifle they should scope in to improve their aim
									NetProps.SetPropInt(player, "m_afButtonForced", NetProps.GetPropInt(player, "m_afButtonForced") | 524288);
								}
							}
						}
						
						if(melee_distance >= dist && item != null && tank_flee_distance < tank_dist)
						{
							//If the infected get too close, bots should pull out their melee weapon if they have one
							if(item.GetClassname() == "weapon_melee" && holdingItem.GetClassname() != "weapon_melee")
							{
								player.SwitchToItem("weapon_melee");
							}
							else if(item.GetClassname() == "weapon_chainsaw" && holdingItem.GetClassname() != "weapon_chainsaw")
							{
								player.SwitchToItem("weapon_chainsaw");
								last_set = Time(); //This will help bots shove with the chainsaw upon pulling it out
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
	local current_team_melee = BotAIFix.CheckTeamMelee();
	local max_survivors = BotAIFix.MaxSurvivors();
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
