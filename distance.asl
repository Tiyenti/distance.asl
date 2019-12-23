// Distance Autosplitter script - Provides autostart/split/reset and load removal
// Created by Brionac, Californ1a, Seekr, and TntMatthew

state("distance")
{
    byte playerFinished : "mono.dll", 0x001F62C8, 0x0, 0x50, 0x3E0, 0x0, 0x18, 0x10, 0xC, 0x8, 0x10, 0x8, 0x6D;
    string255 richPresence : "discord-rpc.dll", 0xD51C;
    int gameState : "mono.dll", 0x001F62C8, 0x0, 0x50, 0x3E0, 0x0, 0x18, 0x44;
    string255 confirmDialog : "mono.dll", 0x001F62C8, 0x0, 0x50, 0x3E0, 0x0, 0x18, 0x20, 0x80, 0x28, 0x10, 0x11c, 0xC;
    int finishType : "mono.dll", 0x001F62C8, 0x0, 0x50, 0x3E0, 0x0, 0x18, 0x10, 0xC, 0x8, 0x10, 0x20;
}

// keeping this around for any patch, though we'll need a way to detect what version of the game is being run before
// this will be able to work
//state("distance")
//{
//    int finishGrid : "Distance.exe", 0x01022164, 0x14;
//    string255 richPresence : "discord-rpc.dll", 0xD51C;
//    int gameState : "mono.dll", 0x001F62CC, 0x50, 0x3E0, 0x0, 0x18, 0x40;
//    string255 confirmDialog : "mono.dll", 0x001F62CC, 0x50, 0x3E0, 0x0, 0x18, 0x20, 0x7c, 0x28, 0x10, 0x11c, 0xc;
//}

startup
{
    settings.Add("combine_cut", true, "Combine cutscenes and their adjacent levels into one split");

    settings.CurrentDefaultParent = "combine_cut";

    settings.Add("combine_inst", true, "Instantiation + Cataclysm");
    settings.Add("combine_long", true, "Long Ago + Forgotten Utopia");
    settings.Add("combine_mob", true, "Mobilization + Resonance");
    settings.Add("combine_col", true, "Terminus + Collapse");

    settings.CurrentDefaultParent = null;

    settings.Add("disable_enemy", false, "Disable Enemy split (if you prefer to manual split on hitting the visible grid)");

}

init
{
    // There's a small period of time at the start of a run where the game is in a not-loading state,
    // so in order to keep the start time at 0.00 we use this value. Once the first loading screen is detected,
    // we set this to 1 (todo: change this to a boolean, change variable name), which will allow time to be counted
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
        //print("Instantiation combined with Cataclysm, skipping");
        return false;
    }
    if (current.richPresence.Contains("Long Ago") && settings["combine_long"] == true)
    {
        //print("Long Ago combined with Utopia, skipping");
        return false;
    }
    if (current.richPresence.Contains("Mobilization") && settings["combine_mob"] == true)
    {
        //print("Mobilization combined with Resonance, skipping");
        return false;
    }
    if (current.richPresence.Contains("Enemy") && settings["disable_enemy"] == true)
    {
        //print("Enemy split disabled, skipping");
        return false;
    }

    if (current.richPresence.Contains("Terminus") && current.richPresence.Contains("Nexus | Solo") && settings["combine_col"] == true)
    {
        //print("Terminus combined with Collapse, skipping");
        return false;
    }

    if (current.richPresence.Contains("\"Echoes\"") || current.richPresence.Contains("Collapse"))
    {
        return current.gameState == 0 && old.gameState != 0;
    }
    else
    {
        if (current.finishType == 1 && old.finishType != 1)
        {
            return true;
        }

        /* if (current.playerFinished == 1 && old.playerFinished != 1)
        {
            print("finishType = " + current.finishType + " | is it <= 1?");
            //if (current.finishType == 1)
            //{
                //print("if true, will split!");
                //return true;
                //return current.finishType <= 1;
            //}
        }*/

        // Detect the first load, and then set the flag that will allow the timer to count
        if (vars.splitOnce == 0)
        {
            if (current.gameState < 7)
            {
                vars.splitOnce = 1;
            }
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
    if (current.confirmDialog != null)
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
