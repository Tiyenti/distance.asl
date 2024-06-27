state("Distance") {}

startup
{
	vars.Log = (Action<object>)(output => print("[Distance] " + output));
	vars.TEXT1 = "Are you sure that you'd like to return to the main menu?";
	vars.TEXT2 = "Are you sure you want to go to the main menu?";

	dynamic[,] sett =
	{
		{ null, "Adventure", true },
			{ "Adventure", "Instantiation", false },
			{ "Adventure", "Cataclysm",     true },
			{ "Adventure", "Diversion",     true },
			{ "Adventure", "Euphoria",      true },
			{ "Adventure", "Entanglement",  true },
			{ "Adventure", "Automation",    true },
			{ "Adventure", "Abyss",         true },
			{ "Adventure", "Embers",        true },
			{ "Adventure", "Isolation",     true },
			{ "Adventure", "Repulsion",     true },
			{ "Adventure", "Compression",   true },
			{ "Adventure", "Research",      true },
			{ "Adventure", "Contagion",     true },
			{ "Adventure", "Overload",      true },
			{ "Adventure", "Ascension",     true },
			{ "Adventure", "Enemy",         true },
			{ "Adventure", "Credits",       true },
		{ null, "Lost to Echoes", true },
			{ "Lost to Echoes", "Long Ago",                      false },
			{ "Lost to Echoes", "Forgotten Utopia",              true },
			{ "Lost to Echoes", "A Deeper Void",                 true },
			{ "Lost to Echoes", "Eye of the Storm",              true },
			{ "Lost to Echoes", "The Sentinel Still Watches",    true },
			{ "Lost to Echoes", "Shadow of the Beast",           true },
			{ "Lost to Echoes", "Pulse of a Violent Heart",      true },
			{ "Lost to Echoes", "It Was Supposed To Be Perfect", true },
			{ "Lost to Echoes", "Echoes",                        true },
		{ null, "Nexus", true },
			{ "Nexus", "Mobilization", false },
			{ "Nexus", "Resonance",    true },
			{ "Nexus", "Deterrence",   true },
			{ "Nexus", "Terminus",     false },
			{ "Nexus", "Collapse",     true }
	};

	for (int i = 0; i < sett.GetLength(0); ++i)
	{
		var parent = sett[i, 0];
		var id = sett[i, 1];
		var state = sett[i, 2];

		settings.Add(id, state, parent == null ? id : "Split after finishing " + id, parent);
	}

	vars.Unity = Assembly.Load(File.ReadAllBytes(@"Components\UnityASL.bin")).CreateInstance("UnityASL.Unity");
}

onStart
{
	// RTA starts earlier than loadless time does, and the time where that starts
	// is in a state where the game isn't actually loading yet, so the timer counts up a bit
	// before the first loading screen.
	vars.LockGameTime = true;
}

init
{
	vars.LockGameTime = true;

	vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
	{
		var str = helper.GetClass("mscorlib", "String"); // String
		var dict = helper.GetClass("mscorlib", "Dictionary`2"); // Dictionary<TKey, TValue>

		var g = helper.GetClass("Assembly-CSharp", 0x020001E4); // G
		var pm = helper.GetClass("Assembly-CSharp", 0x02000BF5); // PlayerManager
		var lp = helper.GetClass("Assembly-CSharp", 0x02000BF6); // LocalPlayer
		var pdb = helper.GetClass("Assembly-CSharp", 0x02000669); // PlayerDataBase

		var gMan = helper.GetClass("Assembly-CSharp", 0x020008CC); // GameManager
		var gm = helper.GetClass("Assembly-CSharp", 0x020008E6); // GameMode
		var am = helper.GetClass("Assembly-CSharp", 0x020006E8); // AdventureMode
		var li = helper.GetClass("Assembly-CSharp", 0x02000B07); // LevelInfo

		var gdm = helper.GetClass("Assembly-CSharp", 0x020008BC); // GameDataManager
		var gd = helper.GetClass("Assembly-CSharp", 0x020008BA); // GameData

		var mpm = helper.GetClass("Assembly-CSharp", 0x02000B18); // MenuPanelManager
		var mpl = helper.GetClass("Assembly-CSharp", 0x020005C8); // MessagePanelLogic
		var ul = helper.GetClass("Assembly-CSharp", 0x02000110); // UILabel

		vars.Unity.Make<bool>(g.Static, g["instance"], g["playerManager_"], pm["current_"], lp["playerData_"], pdb["finished_"]).Name = "playerFinished";
		vars.Unity.Make<int>(g.Static, g["instance"], g["playerManager_"], pm["current_"], lp["playerData_"], pdb["finishType_"]).Name = "finishType";
		vars.Unity.Make<int>(g.Static, g["instance"], g["gameManager_"], gMan["state_"]).Name = "gameState";
		vars.Unity.MakeString(256, g.Static, g["instance"], g["menuPanelManager_"], mpm["messagePanel_"], mpl["messageLabel_"], ul["mText"], str["start_char"]).Name = "messagePanelLabel";

		vars.Unity.MakeString(16, gMan.Static, gMan["sceneName_"], str["start_char"]).Name = "scene";
		vars.Unity.MakeString(64, g.Static, g["instance"], g["gameManager_"], gMan["mode_"], gm["levelInfo_"], li["levelName_"], str["start_char"]).Name = "level";

		vars.GetValue = (Func<string, string>)(key =>
		{
			IntPtr dictPtr = IntPtr.Zero;
			new DeepPointer(g.Static + g["instance"], g["gameData_"], gdm["gameData_"], gd["stringDictionary_"], 0x0).DerefOffsets(game, out dictPtr);

			var count = game.ReadValue<int>(dictPtr + (int)(dict["count"]));
			IntPtr keys = game.ReadPointer(dictPtr + (int)(dict["keySlots"])), values = game.ReadPointer(dictPtr + (int)(dict["valueSlots"]));

			for (int i = 0; i < count; ++i)
			{
				var item = game.ReadString(game.ReadPointer(keys + 0x10 + 0x4 * i) + (int)(str["start_char"]), 64);
				if (item == key)
					return game.ReadString(game.ReadPointer(values + 0x10 + 0x4 * i) + (int)(str["start_char"]), 64);
			}

			return null;
		});

		return true;
	});

	vars.Unity.Load(game);
}

update
{
	if (!vars.Unity.Loaded) return false;

	vars.Unity.UpdateAll(game);

	current.SceneName = vars.Unity["scene"].Current ?? "";
	current.LevelName = vars.Unity["level"].Current ?? "";
	current.GameState = vars.Unity["gameState"].Current;
	current.PlayerFinished = vars.Unity["playerFinished"].Current;
	current.FinishType = vars.Unity["finishType"].Current;
	current.MessagePanelLabel = vars.Unity["messagePanelLabel"].Current;
	current.GameMode = vars.GetValue("Game Mode") ?? "";

	// vars.Log(current.PlayerFinished);
	// vars.Log(current.GameMode);
	// vars.Log(current.LevelName);
	// vars.Log(current.MessagePanelLabel);
}

start
{
	if (current.SceneName == "MainMenu")
		return current.GameState == 0 && old.GameState == 7;
}

split
{
	// Unlock game time once the loading screen shows up.
	if (vars.LockGameTime && current.GameState < 7)
		vars.LockGameTime = false;

	var finished = (!old.PlayerFinished && current.PlayerFinished) && current.FinishType == 1;
	var setting = settings.ContainsKey(current.LevelName) ? settings[current.LevelName] : true;
	var startedLoading = old.GameState != 0 && current.GameState == 0;

	switch ((string)(current.GameMode))
	{
		case "Adventure":
			return finished && setting;
		case "Lost to Echoes":
			return (current.LevelName == "Echoes" ? startedLoading : finished) && setting;
		case "Nexus":
			return (current.LevelName == "Collapse" ? startedLoading : finished) && setting;
		default:
			return finished;
	}
}

reset
{
	if (old.MessagePanelLabel == current.MessagePanelLabel)
		return;

	return current.MessagePanelLabel == vars.TEXT1 || current.MessagePanelLabel == vars.TEXT2;
}

gameTime
{
	// Before the first load, the timer needs to stay at 0.
	if (vars.LockGameTime)
		return TimeSpan.Zero;
}

isLoading
{
	if (vars.LockGameTime)
		return true;

	switch ((string)(current.SceneName))
	{
		case "MainMenu": return current.GameState < 7;
		case "GameMode": return current.GameState < 8;
	}
}

exit
{
	vars.Unity.Reset();
}

shutdown
{
	vars.Unity.Reset();
}
