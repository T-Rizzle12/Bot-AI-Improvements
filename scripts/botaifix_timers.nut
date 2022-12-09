//------------------------------------------------------
//     Author : smilzo
//     https://steamcommunity.com/id/smilz0
//------------------------------------------------------

if (!("BotAIFixTimers" in getroottable()))
{
	::BotAIFixTimers <-
	{
		DummyEnt = null
		Timers = {}
		Thinkers = {}
	}

	::BotAIFixTimers.AddTimer <- function(name, delay, func, params = {}, repeat = false)
	{
		if (!name || name == "")
			name = UniqueString();
		else if (name in ::BotAIFixTimers.Timers)
		{
			error("[BotAIFixTimers][WARN] AddTimer - A timer with this name already exists: " + name + "\n");
			return false;
		}
		
		local si = getstackinfos(2);
		local f = "";
		local s = "";
		local l = "";
		if ("func" in si)
			f = si.func;
		if ("src" in si)
			s = si.src;
		if ("line" in si)
			l = si.line;
		local dbgInfo = "Func: " + f + " - Src: " + s + " - Line: " + l;
		
		local timer = { Delay = delay, Func = func, params = params, Repeat = repeat, LastTime = Time(), DbgInfo = dbgInfo };
		::BotAIFixTimers.Timers[name] <- timer;
		
		return true;
	}

	::BotAIFixTimers.RemoveTimer <- function(name)
	{
		if (!(name in ::BotAIFixTimers.Timers))
		{
			//error("[BotAIFixTimers][WARN] RemoveTimer - A timer with this name does not exist: " + name + "\n");
			return false;
		}
		
		delete ::BotAIFixTimers.Timers[name];
		
		return true;
	}

	::BotAIFixTimers.ThinkFunc <- function()
	{
		local curtime = Time();
		
		foreach (timerName, timer in ::BotAIFixTimers.Timers)
		{
			if ((curtime - timer.LastTime) >= timer.Delay)
			{
				if (timer.Repeat)
					timer.LastTime = curtime;
				else
					delete ::BotAIFixTimers.Timers[timerName];
				
				try
				{
					timer.Func(timer.params);
				}
				catch(exception)
				{
					error("[BotAIFixTimers][ERROR] Exception in timer '" + timerName + "': " + exception + " (" + timer.DbgInfo + ")\n");
				}
			}
		}
		
		return 0.01;
	}
	
	::BotAIFixTimers.AddThinker <- function(name, delay, func, params = {})
	{
		if (!name || name == "")
			name = UniqueString();
		else if (name in ::BotAIFixTimers.Thinkers)
		{
			error("[BotAIFixTimers][WARN] AddThinker - A thinker with this name already exists: " + name + "\n");
			return false;
		}
		
		local si = getstackinfos(2);
		local f = "";
		local s = "";
		local l = "";
		if ("func" in si)
			f = si.func;
		if ("src" in si)
			s = si.src;
		if ("line" in si)
			l = si.line;
		local dbgInfo = "Func: " + f + " - Src: " + s + " - Line: " + l;
		
		local thinkerEnt = SpawnEntityFromTable("info_target", { targetname = "botaifixtimers_" + name });
		if (!thinkerEnt || !thinkerEnt.IsValid())
		{
			error("[BotAIFixTimers][ERROR] Failed to spawn thinker entity for thinker '" + name + "'!\n");
			return false;
		}
		
		thinkerEnt.ValidateScriptScope();
		local scope = thinkerEnt.GetScriptScope();
		scope.ThinkerName <- name;
		scope.ThinkerDelay <- delay;
		scope.ThinkerFunc <- func;
		scope.ThinkerParams <- params;
		scope.ThinkerDbgInfo <- dbgInfo;
		scope["ThinkerThinkFunc"] <- ::BotAIFixTimers.ThinkerThinkFunc;
		AddThinkToEnt(thinkerEnt, "ThinkerThinkFunc");
			
		local thinker = { Delay = delay, Func = func, params = params, Ent = thinkerEnt, DbgInfo = dbgInfo };
		::BotAIFixTimers.Thinkers[name] <- thinker;
		
		return true;
	}
	
	::BotAIFixTimers.RemoveThinker <- function(name)
	{
		if (!(name in ::BotAIFixTimers.Thinkers))
		{
			//error("[BotAIFixTimers][WARN] RemoveThinker - A thinker with this name does not exist: " + name + "\n");
			return false;
		}
		
		local thinkerEnt = ::BotAIFixTimers.Thinkers[name].Ent;
		if (thinkerEnt && thinkerEnt.IsValid())
			thinkerEnt.Kill();
		else
			error("[BotAIFixTimers][WARN] RemoveThinker - Thinker '" + name + "' had no valid entity\n");
		
		delete ::BotAIFixTimers.Thinkers[name];
		
		return true;
	}
	
	::BotAIFixTimers.ThinkerThinkFunc <- function()
	{
		try
		{
			ThinkerFunc(ThinkerParams);
		}
		catch(exception)
		{
			error("[BotAIFixTimers][ERROR] Exception in thinker '" + ThinkerName + "': " + exception + " (" + ThinkerDbgInfo + ")\n");
		}
		
		return ThinkerDelay;
	}
}

if (!::BotAIFixTimers.DummyEnt || !::BotAIFixTimers.DummyEnt.IsValid())
{
	::BotAIFixTimers.DummyEnt = SpawnEntityFromTable("info_target", { targetname = "botaifixtimers" });
	if (::BotAIFixTimers.DummyEnt)
	{
		::BotAIFixTimers.DummyEnt.ValidateScriptScope();
		local scope = ::BotAIFixTimers.DummyEnt.GetScriptScope();
		scope["L4TThinkFunc"] <- ::BotAIFixTimers.ThinkFunc;
		AddThinkToEnt(::BotAIFixTimers.DummyEnt, "L4TThinkFunc");
			
		printl("[BotAIFixTimers][DEBUG] Spawned dummy entity");
	}
	else
		error("[BotAIFixTimers][ERROR] Failed to spawn dummy entity!\n");
}
else
	printl("[BotAIFixTimers][DEBUG] Dummy entity already spawned");
