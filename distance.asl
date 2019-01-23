// Distance Autosplitter script
// Created by Brionac, Californ1a, Seekr, and TntMatthew

state("distance")
{
    int finishGrid : "Distance.exe", 0x01022164, 0x14;
    string255 richPresence : "discord-rpc.dll", 0xD51C;
    int gameState : "mono.dll", 0x001F62CC, 0x50, 0x3E0, 0x0, 0x18, 0x40
}

startup
{
    settings.Add("split_cut", false, "Split after campaign intro cutscenes");

    settings.CurrentDefaultParent = "split_cut";

    settings.Add("split_inst", false, "Split after Instantiation");
    settings.Add("split_long", false, "Split after Long Ago");
    settings.Add("split_mob", false, "Split after Mobilization");
}

init
{
    // This value here abuses the fact that leaving the main menu counts as splitting with
    // the finish pointer we use to prevent time from counting during run start and the first loading screen.
    // When leaving from the main menu, we eat that split - but we increment this value by 1.
    // If the value == 0, time is prevented from counting, but otherwise, it may count as normal.
    vars.splitOnce = 0;

    // for ease of reading, we'll give the gameState values names here and use those instead
    vars.unloadScene = 0;
}

update
{
    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.splitOnce = 0;
    }

    print(current.gameState.ToString());
}

split
{
    if (current.richPresence.Contains("Instantiation") && settings["split_inst"] == false)
    {
        return false;
    }
    if (current.richPresence.Contains("Long Ago") && settings["split_long"] == false)
    {
        return false;
    }
    if (current.richPresence.Contains("Mobilization") && settings["split_mob"] == false)
    {
        return false;
    }

    if (old.gameState == 8)
    {
        return false;
    }

    if (current.finishGrid == 0 && old.finishGrid != 0)
    {
        if (!old.richPresence.Contains("In Main Menu"))
        {
            return current.finishGrid == 0 && old.finishGrid != 0;
        }
        else
        {
            // Increment splitOnce to show that time may now be counted
            vars.splitOnce++;
            return false;
        }
    }
}
 
start
{
    if (current.richPresence.Contains("In Main Menu"))
    {
        return current.gameState == 0 && old.gameState == 7;
    }
}

//reset
//{
//    if (current.richPresence.Contains("In Main Menu") &&
//        (old.richPresence.Contains("Credits") || old.richPresence.Contains("Echoes") || old.richPresence.Contains("Collapse")))
//    {
//        return false;
//    }
//
//    return current.richPresence.Contains("In Main Menu") & !old.richPresence.Contains("In Main Menu");
//}

gameTime
{
    // Prevent time from counting before the run begins
    if (vars.splitOnce == 0)
    {
        return new TimeSpan();
    }
}

isLoading
{
    // Prevents LiveSplit's timer from freaking out over game time constantly being set every tick
    if (vars.splitOnce == 0)
    {
        return true;
    }

    if (current.richPresence.Contains("In Main Menu"))
    {
        if (current.gameState < 7)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    else if (current.gameState < 8)
    {
        return true;
    }
    else
    {
        return false;
    }
}