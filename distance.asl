// Distance Autosplitter script - Provides autostart/split/reset and load removal
// Created by Brionac, Californ1a, Seekr, and TntMatthew

state("distance")
{
    int finishGrid : "Distance.exe", 0x01022164, 0x14;
    string255 richPresence : "discord-rpc.dll", 0xD51C;
    int gameState : "mono.dll", 0x001F62CC, 0x50, 0x3E0, 0x0, 0x18, 0x40;
    string255 confirmDialog : "mono.dll", 0x001F62CC, 0x50, 0x3E0, 0x0, 0x18, 0x20, 0x7c, 0x28, 0x10, 0x11c, 0xc;
}

startup
{
    settings.Add("combine_cut", true, "Combine cutscenes and their adjacent levels into one split");

    settings.CurrentDefaultParent = "combine_cut";

    settings.Add("combine_inst", true, "Instantiation");
    settings.Add("combine_long", true, "Long Ago");
    settings.Add("combine_mob", true, "Mobilization");
    settings.Add("combine_col", true, "Collapse");
}

init
{
    // This value here abuses the fact that leaving the main menu counts as splitting with
    // the finish pointer we use to prevent time from counting during run start and the first loading screen.
    // When leaving from the main menu, we eat that split - but we increment this value by 1.
    // If the value == 0, time is prevented from counting, but otherwise, it may count as normal.
    vars.splitOnce = 0;
}

update
{
    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.splitOnce = 0;
    }
}

split
{
    if (current.richPresence.Contains("Instantiation") && settings["combine_inst"] == true)
    {
        return false;
    }
    if (current.richPresence.Contains("Long Ago") && settings["combine_long"] == true)
    {
        return false;
    }
    if (current.richPresence.Contains("Mobilization") && settings["combine_mob"] == true)
    {
        return false;
    }

    if (current.richPresence.Contains("Terminus") && current.richPresence.Contains("Nexus | Solo") && settings["combine_col"] == true)
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

reset
{
    if (current.confirmDialog.StartsWith("Are you sure that you'd like to return to the main menu?")
        && !old.confirmDialog.StartsWith("Are you sure that you'd like to return to the main menu?"))
    {
        return true;
    }
    else if (current.confirmDialog.StartsWith("Are you sure you want to go to the main menu?")
        && !old.confirmDialog.StartsWith("Are you sure you want to go to the main menu?"))
    {
        return true;
    }
}

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