state("Distance") {}

startup
{
	vars.Log = (Action<object>)(output => print("[Distance] " + output));

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
			{ "Adventure", "Credits",       false },
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

	using (var prov = new Microsoft.CSharp.CSharpCodeProvider())
	{
		var param = new System.CodeDom.Compiler.CompilerParameters
		{
			GenerateInMemory = true,
			ReferencedAssemblies = { "LiveSplit.Core.dll", "System.dll", "System.Core.dll", "System.Xml.dll", "System.Xml.Linq.dll" }
		};

		string mono = File.ReadAllText(@"Components\mono.cs"), helpers = File.ReadAllText(@"Components\mono_helpers.cs");
		var asm = prov.CompileAssemblyFromSource(param, mono, helpers);
		vars.Unity = Activator.CreateInstance(asm.CompiledAssembly.GetType("Unity.Game"));
	}
}

onStart
{
	vars.WaitForStart = false;
}

init
{
	vars.Unity.TryOnLoad = (Func<dynamic, bool>)(helper =>
	{
		var str = helper.GetClass("mscorlib", "String"); // String

		var g = helper.GetClass("Assembly-CSharp", 0x200021C); // G

		var pm = helper.GetClass("Assembly-CSharp", 0x2000C2D); // PlayerManager
		var lp = helper.GetClass("Assembly-CSharp", 0x2000C2E); // LocalPlayer
		var pdb = helper.GetClass("Assembly-CSharp", 0x20006A1); // PlayerDataBase

		var gMan = helper.GetClass("Assembly-CSharp", 0x2000904); // GameManager
		var gm = helper.GetClass("Assembly-CSharp", 0x200091E); // GameMode
		var li = helper.GetClass("Assembly-CSharp", 0x2000B3F); // LevelInfo

		vars.Unity.Make<bool>(g.Static, g["instance"], g["playerManager_"], pm["current_"], lp["playerData_"], pdb["finished_"]).Name = "playerFinished";
		vars.Unity.Make<int>(g.Static, g["instance"], g["gameManager_"], gMan["state_"]).Name = "gameState";

		vars.Unity.MakeString(16, gMan.Static, gMan["sceneName_"], str["start_char"]).Name = "scene";
		vars.Unity.MakeString(64, g.Static, g["instance"], g["gameManager_"], gMan["mode_"], gm["levelInfo_"], li["levelName_"], str["start_char"]).Name = "level";

		return true;
	});

	vars.Unity.Load(game);
	vars.WaitForStart = false;
}

update
{
	if (!vars.Unity.Loaded) return false;

	vars.Unity.UpdateAll(game);

	current.SceneName = vars.Unity["scene"].Current;
	current.LevelName = vars.Unity["level"].Current;
	current.GameState = vars.Unity["gameState"].Current;
	current.PlayerFinished = vars.Unity["playerFinished"].Current;
}

start
{
	if (old.GameState == 7 && current.GameState == 0 && current.SceneName == "MainMenu")
		vars.WaitForStart = true;

	if (!vars.WaitForStart) return;

	return old.GameState < 8 && current.GameState >= 8 && current.SceneName == "GameMode";
}

split
{
	return !old.PlayerFinished && current.PlayerFinished && settings[current.LevelName];
}

reset
{
	return old.SceneName == "GameMode" && current.SceneName == "MainMenu";
}

isLoading
{
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
