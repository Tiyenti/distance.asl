/* Distance Autosplitter script - Provides autostart/split/reset and load removal
Created by Brionac, Californ1a, Seekr, and TntMatthew

---
Thanks to ClownFiesta for the base script to read from an output log:
https://raw.githubusercontent.com/ClownFiesta/AutoSplitters/master/LiveSplit.SlayTheSpire.asl

Copyright (c) 2018 ClownFiesta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
---
*/

state("Distance")
{
    string255 richPresence : "discord-rpc.dll", 0xD51C;
    int gameState : "mono.dll", 0x001F62C8, 0x0, 0x50, 0x3E0, 0x0, 0x18, 0x44;
}

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
    //Get the path for the logs
    vars.stsLogPath =  System.IO.Directory.GetParent(modules.First().FileName).FullName + "\\speedrun_data.txt";
    //Open the logs and set the position to the end of the file
    vars.reader = new StreamReader(new FileStream(vars.stsLogPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
    vars.reader.BaseStream.Seek(0, SeekOrigin.End);
    vars.lastPointerPosition = vars.reader.BaseStream.Position;
    //Set the command to "UPDATE"
    vars.command = "UPDATE";

    vars.isLoading = false;
    vars.firstLoadEnd = false;
    vars.prevLoadWasMM = false;
}

update
{
    // this seemed to be causing issues so I commented it out, but i will keep it here for convenience in case I feel like trying to add it back
    /* if (vars.reader.BaseStream.Length == vars.lastPointerPosition){ //If the logs haven't changed, skip the rest of the code (update, reset, split, start, etc.). We place it first to lessen the load on the computer
        return false;
    } else*/ 

    if (vars.reader.BaseStream.Length < vars.lastPointerPosition){ //If the logs have been reset, then place the pointer at the end and update vars.lastPointerPosition and skip the rest of the code.
        vars.reader.BaseStream.Seek(0, SeekOrigin.End);
        vars.lastPointerPosition = vars.reader.BaseStream.Position;
        return false;
    }

    if (timer.CurrentPhase == TimerPhase.NotRunning)
    {
        vars.firstLoadEnd = false;
    }

    string line = "";
	//string prevLine = "";
    while((line = vars.reader.ReadLine()) != null){ //Read the log until its end
        //Updates vars.lastPointerPosition to its new position.
        vars.lastPointerPosition = vars.reader.BaseStream.Position;
        print(line);
        //Changes the value of vars.command depending on the content of line and returns true if a command needs to be issued.
        if (line.Contains("SpeedrunStart"))
        {
            vars.command = "START";
            return true;
        }
        // Cutscenes end on ModeFinished so handle those here
        else if (line.Contains("ModeFinished"))
        {
            if (line.Contains("Instantiation") && settings["combine_inst"] == false) 
            {
                vars.command = "SPLIT";
                return true;
            }
            if (line.Contains("Long Ago") && settings["combine_long"] == false)
            {
                vars.command = "SPLIT";
                return true;
            }
            if (line.Contains("Mobilization") && settings["combine_mob"] == false)
            {
                vars.command = "SPLIT";
                return true;
            }
        }
        else if (line.Contains("LevelEnd"))
        {
            if (!line.Contains("Echoes"))
            {
                if (line.Contains("Enemy") && settings["disable_enemy"] == true)
                {
                    return false;
                }
                else if (line.Contains("Terminus") && settings["combine_col"] == true)
                {
                    return false;
                }
                else
                {
                    vars.command = "SPLIT";
                    return true;
                }
            }
        }
        // We don't use the LoadStart/LoadEnd lines from the log to actually detect loads as the MainMenu doesn't have
        // a LoadEnd line printed for it - that'd break multiset categories. However, we use it to detect the first load
        // to prevent time from counting at the start.
        else if (line.Contains("LoadEnd"))
        {
            if (vars.firstLoadEnd == false)
            {
                vars.firstLoadEnd = true;
            }
            return true;
        }
        else if (line.Contains("SpeedrunEnd"))
        {
            if (line.Contains("(DNF)"))
            {
                vars.command = "RESET";
                return true;
            }
            else
            {
                if (current.richPresence.Contains("\"Echoes\"") || current.richPresence.Contains("Collapse"))
                {
                    vars.command = "SPLIT";
                    return true;
                }
            }
        }
		//prevLine = line;
    }

}

reset
{
    if (vars.command == "RESET")
    {
        vars.command = "UPDATE";
        return true;
    }
}

split
{
    if (vars.command == "SPLIT")
    {
        vars.command = "UPDATE";
        return true;
    }
}

start
{
    if (vars.command == "START")
    {
        vars.command = "UPDATE";
        return true;
    }
}

exit
{   
    // Resets the timer if the game closes (either from a bug or manually)
    new TimerModel() { CurrentState = timer }.Reset();
    vars.reader.Close();
    vars.lastPointerPosition = 0;
    vars.isLoading = false;
    vars.firstLoadEnd = false;
}

shutdown
{
    // Closing the reader (Only useful when you close LiveSplit before closing Distance)
    vars.reader.Close();
}

isLoading
{
    // This stops LiveSplit's timer from freaking out due to the first-load timestop hack
    if (vars.firstLoadEnd == false)
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

gameTime
{
    // Prevent time from counting before the first load screen
    if (vars.firstLoadEnd == false)
    {
        return new TimeSpan();
    }
}