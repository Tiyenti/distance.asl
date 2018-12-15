state("distance")
{
    int ourLoadValue : "mono.dll", 0x001F40AC, 0x72C, 0x10, 0x20, 0x4C, 0x17C;
    int finishGrid : "Distance.exe", 0x01022164, 0x14;
    string255 richPresence : "discord-rpc.dll", 0xD51C;
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
    // This value is how for how long the player has been in Cataclysm;
    // this is used to prevent the restart cutscene skip from splitting 
    vars.ticksInLevel = 0;

    // This value is basically just here because leaving the main menu was splitting,
    // and I couldn't figure out a reasonable method to make it not do that, so I just
    // use this variable to eat that split and fix it that way.
    vars.splitOnce = 0;
}

update
{
    if (current.richPresence.Contains("Cataclysm"))
    {
        vars.ticksInLevel++;
    }

    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.splitOnce = 0;
    }
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

    if (current.richPresence.Contains("Cataclysm") & (vars.ticksInLevel < 1000))
    {
        return false;
    }

    if (current.finishGrid == 0 && old.finishGrid != 0)
    {
        vars.ticksInLevel = 0;
        
        if (vars.splitOnce > 0)
        {
            return current.finishGrid == 0 && old.finishGrid != 0;
        }
        else
        {
            vars.splitOnce++;
            return false;
        }
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

isLoading
{
    return current.ourLoadValue < 1065353216;
}