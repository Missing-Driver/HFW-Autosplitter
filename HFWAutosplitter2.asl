state("HorizonForbiddenWest", "v1.5.80.0-Steam"){
    // Quick/Auto save flag:
    byte saveState : 0x22D0DA0, 0x6938;
    // Loading screens flag:
    byte isLoading : 0x08983150, 0x4B4; 

    // player => HorizonForbiddenWest.exe+8982DA0
    // Humanoid entity:
    // 0x8982DA0, 0x1C10, 0x0, 0x10
        // Aloy's position:
        double WestEast : 0x8982DA0, 0x1C10, 0x0, 0x10, 0xD8; // X [West-East]
        double SouthNorth : 0x8982DA0, 0x1C10, 0x0, 0x10, 0xE0; // Y [South-North]
        double DownUp : 0x8982DA0, 0x1C10, 0x0, 0x10, 0xE8; // Z [Down-Up]
        // Destructibility:
        // 0x8982DA0, 0x1C10, 0x0, 0x10, 0xD0
            // Aloy's invulnerable flag:
            byte isGod :  0x8982DA0, 0x1C10, 0x0, 0x10, 0xD0, 0x70;
}

// Script is executed
startup{
    // Object containing useful functions:
    vars.Funcs = new ExpandoObject();
    // Contains a list of checkpoints and coorelates with the split list:
    vars.checkpoints =  new Dictionary<string, ExpandoObject>();
    // Checkpoints with known pointers:
    vars.memWatchers = new MemoryWatcherList();
    // Required to split outside the split action:
    vars.timerController = new TimerModel { CurrentState = timer };
    // Mirrors isLoading:
    vars.isLoading = 1;

    // Determines if Aloy is over a given checkpoint zone:
    vars.Funcs.isLegacySplit = (Func<double, double, double, double[], byte, byte, byte, bool>)((
            playerPosX, playerPosY, playerPosZ, checkpointCoordinates,
            oldGodState, currentGodState, cutsceneCondition
    ) => {
        return false;
    }); 
    // Determines if it's time to split or not:
    vars.Funcs.isSplit = (Func<MemoryWatcher, bool>)((watcher) => {
        return
            vars.isLoading < 1 &&
            vars.checkpoints.ContainsKey(watcher.Name) ? !vars.checkpoints[watcher.Name].reachedBefore : true &&
            watcher.Changed &&
            Convert.ToByte(watcher.Current) == 1;
    });
    // Splits:
    vars.Funcs.Split = (Action<MemoryWatcher>)((watcher) => {
        // Checks if timer is actually running:
        if (timer.CurrentAttemptDuration.TotalMilliseconds > 0){
            print("SPLIT: " + watcher.Name);
            if(vars.checkpoints.ContainsKey(watcher.Name)){
                vars.checkpoints[watcher.Name].reachedBefore = true;
            }
            vars.timerController.Split();
        }
    });

    // Handles the event risen by a checkpoint memory flag when it changes:
    MemoryWatcherList.MemoryWatcherDataChangedEventHandler isSplit = (MemoryWatcher watcher) => {
        if(vars.Funcs.isSplit(watcher)){
            vars.Funcs.Split(watcher);
        }
        // Debugging:
        // else{
        //     print(watcher.Name);
        //     print(vars.isLoading.ToString());
        //     print(vars.checkpoints[watcher.Name].reachedBefore.ToString());
        //     print(watcher.Current.ToString());
        // }
    };
    // Add it to the the event handlers of the memory wathcher list:
    vars.memWatchers.OnWatcherDataChanged += isSplit;

    dynamic[,] _settings = {
        // Main game
        // ID, Label, Tool tip, Parent ID, Default setting?, Flag pointer, Checkpoint zone
        {"main_game", "Main game", "Main game splits", null, true, null, null},
            // THE SEA OF SANDS
            {"sea_of_sands", "The Sea of Sands", null, "main_game", true, null, null},
                {"tsos_end", "The Sea of Sands completion", "After delivering Poseidon to Gaia", "sea_of_sands", true, new DeepPointer("HorizonForbiddenWest.exe", 0x08982DD0, 0xE0, 0x4F0, 0x1D0, 0x3F1), null},
            // SEEDS OF THE PAST
            {"seeds_of_the_past", "Seeds of the past", null, "main_game", true, null, null},
                {"sotp_end", "Seeds of the past completion", "After delivering Demeter to Gaia", "seeds_of_the_past", true, new DeepPointer("HorizonForbiddenWest.exe", 0x08982DD0,  0xE0, 0xF40, 0xB00, 0x411), null},
            // THE KULRUT
            {"kulrut", "The Kulrut", null, "main_game", true, null, null},
                {"kulrut_end", "The Kulrut completion", "After delivering Aether to Gaia", "kulrut", true, new DeepPointer("HorizonForbiddenWest.exe", 0x08982DD0, 0xE0, 0x10D0, 0x178, 0x651), null},
    };

    // Memory watcher for NG+ start:
    vars.memWatchers.Add(
        new MemoryWatcher<byte>(
            new DeepPointer("HorizonForbiddenWest.exe", 0x08982DD0, 0x180, 0x9C0, 0x400, 0x239)
        ){Name = "NGP_start"}
    );

    dynamic tmp = null;
    // Initialize autosplit settings and checkpoint coordinates
    for (int i = 0; i < _settings.GetLength(0); i++){
        // Autosplitter settings entry:
        // settings.Add(id, default_value = true, description = null, parent = null)
        settings.Add(_settings[i, 0], _settings[i, 4], _settings[i, 1], _settings[i, 3]);

        // Tool tip message (if available)
        if(_settings[i, 2] != null){
            settings.SetToolTip(_settings[i, 0], _settings[i, 2]);
        }

        // Add checkpoint to the list (if available)
        if(_settings[i, 5] != null || _settings[i, 6] != null){
            tmp = new ExpandoObject();
            // Memory flagged checkpoint:
            if (_settings[i, 5] != null){
                tmp.Type = "memory";
                // Add a memory wathcer to detect checkpoit activation:
                vars.memWatchers.Add(
                    new MemoryWatcher<byte>(_settings[i, 5]){Name = _settings[i, 0]}
                );
            }
            // Legacy checkpoint (position based):
            else if(_settings[i, 6] != null){
                tmp.Type = "position";
                tmp.geolocation = _settings[i, 6][0];
                tmp.cutsceneCheck = _settings[i, 6][1] != null ? _settings[i, 6][0] : Convert.ToByte(0);
            }
            // Has the checkpoint already been reached before?
            tmp.reachedBefore = false;
            vars.checkpoints.Add(_settings[i, 0], tmp);
        }
    }
}

update{
    vars.memWatchers.UpdateAll(game);
}

isLoading
{
    vars.isLoading = current.isLoading;
    return (current.isLoading > 0);
}

start{
   return vars.Funcs.isSplit(vars.memWatchers["NGP_start"]);
}

onReset{
    foreach (var checkpoint in vars.checkpoints){
        checkpoint.Value.reachedBefore = false;
    }
}