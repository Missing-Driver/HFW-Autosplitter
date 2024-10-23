state("HorizonForbiddenWest", "v1.5.80.0"){
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

    // TODO: Find a pointer that indicates a RF to fine tune checkpoint tracking.
}

// Script is executed
startup{
    vars.cutsceneTolerance = 2500; // in miliseconds
    vars.atCutscene = Convert.ToByte(1);
    vars.afterCutscene = Convert.ToByte(2);
    vars.sw = new Stopwatch();
    vars.delayedIsGod = Convert.ToByte(0);
    // Object containing useful functions:
    vars.Funcs = new ExpandoObject();

    // Determines if Aloy is over a given checkpoint zone:
    vars.Funcs.isSplit = (Func<double, double, double, double[], byte, byte, byte, bool>)((
            playerPosX, playerPosY, playerPosZ, checkpointCoordinates,
            oldGodState, currentGodState, cutsceneCondition
    ) => {
        switch(cutsceneCondition){
            // No cutscene should have been played immediatly before nor now:
            case 0:
                if(vars.sw.IsRunning){
                    return false;
                }
                break;
            // A cutscene should be playing now:
            case 1:
                if(currentGodState < 1){
                    return false;
                }
                break;
            // A cutscene should have been played immediatly before:
            case 2:
                if(!(vars.sw.IsRunning)){
                    return false;
                }
                // else{
                //     print("CUTSCENE CONDITION TRIGGERED.");
                // }
                break;
            default:
                break;
        }
        // Debugging
        // print((checkpointCoordinates[0] - checkpointCoordinates[3]).ToString() + " < " + playerPosX.ToString() + "?");
        // print((checkpointCoordinates[0] + checkpointCoordinates[3]).ToString() + " > " + playerPosX.ToString() + "?");
        // print((checkpointCoordinates[1] - checkpointCoordinates[3]).ToString() + " < " + playerPosY.ToString() + "?");
        // print((checkpointCoordinates[1] + checkpointCoordinates[3]).ToString() + " > " + playerPosY.ToString() + "?");
        // print((checkpointCoordinates[2] - checkpointCoordinates[3]).ToString() + " < " + playerPosZ.ToString() + "?");
        // print((checkpointCoordinates[2] + checkpointCoordinates[3]).ToString() + " > " + playerPosZ.ToString() + "?");

        return
        // Checks if Aloy is in checkpoint zone West-East:
        (checkpointCoordinates[0] - checkpointCoordinates[3]) < playerPosX &&
        (checkpointCoordinates[0] + checkpointCoordinates[3]) > playerPosX &&
        // Checks if Aloy is in checkpoint zone South-North:
        (checkpointCoordinates[1] - checkpointCoordinates[3]) < playerPosY &&
        (checkpointCoordinates[1] + checkpointCoordinates[3]) > playerPosY &&
        // Checks if Aloy is in checkpoint zone vertically:
        (checkpointCoordinates[2] - checkpointCoordinates[3]) < playerPosZ &&
        (checkpointCoordinates[2] + checkpointCoordinates[3]) > playerPosZ;
    });

    // 
    vars.Funcs.showToolsForm = (Action)(() => {
        int width = 240;
        int width2 = 225;

        var toolsForm = new Form() {
            Size = new System.Drawing.Size(450, 157),
            Text = "Metal Gear Solid Autosplitter Toolbox",
            FormBorderStyle = FormBorderStyle.FixedSingle,
            MaximizeBox = false
        };

        var btnSplitFiles = new Button() {
        Text = "Build Split Files for current settings",
            Dock = DockStyle.Fill
        };
        btnSplitFiles.Click += (EventHandler)((sender, e) => print("Files button clicked"));

        toolsForm.Controls.Add(btnSplitFiles);
        toolsForm.Show();
    });

    // Contains a list of checkpoint coordinates
    // and coorelates with the split list:
    // vars.checkpointCoordinates = new Dictionary<string, double[]>();
    vars.checkpoints =  new List<ExpandoObject>();
    // TODO: Turn this into a logic that could handle variable ending points.
    // Why? Example: Burning shores and Burning shores 100%.
    // One should stop at Seika cutscene, but the other one should continue boyond that;
    // so the code should be able to determine somehow which type of run is currently at play here:
    // NG+ starting point:
    vars.starting = new double[]{4049.48191132609, 947.758209985943, 624.717196655894, 0.5};

    // Contains de autosplitter settings and checkpoint coordinates:
    dynamic[,] _settings = {
        // ID - Ticked? - Label - Parent ID - Description, Coordinates-radius, cutsceneCheck
        // cutsceneCheck stablishes wether the checkpoint is activetaded immediately after or during a cutscene.
        // Autosplitter Options:
        {"options_header", true, "Options", null, "Autosplitter options and tools", null, null},
            {"splits_generator", false, "Split file generator", "options_header", "Split file generation tool", null, null},
        // Main game
        {"main_game", true, "Main game", null, "Main game splits", null, null},
        // Quests
            // TO THE BRINK
            {"to_the_brink", true, "To the brink", "main_game", null, null, null},
                {"cable_car", true, "Cable car", "to_the_brink", "End of the ride, after meeting Vuadis", new double[]{3870.30072180239, 848.134126001102, 520.639412373305, 3}, vars.afterCutscene},
                // TODO: double check the coordinates for this one:
                {"chainscrape_entrance", true, "Go to Chainscrape", "to_the_brink", "After talking to the guards", new double[]{3513.31486432803, 657.820138546522, 491.901066649007, 3}, vars.afterCutscene},
                {"scroungers", true, "Scroungers", "to_the_brink", "After killing the scroungers and talking to Thurlis", new double[]{3496.15236174044, 421.009232906598, 482.573202679697, 3}, vars.afterCutscene},
                {"find_erend", true, "Find Erend", "to_the_brink", "After the cutscene where Aloy finds Erend", new double[]{3449.88572539269, 148.835413748862, 496.067864863435, 3}, vars.afterCutscene},
                {"talk_to_erend", true, "Talk to Erend", "to_the_brink", "After killing the machines and talk to Erend", new double[]{3477.35439284111, 132.332308891053, 495.012863606143, 3}, vars.afterCutscene},
                {"clear_the_daunt", true, "Clear the Daunt", "to_the_brink", "After killing the Bristlebacks and talk with the Oseram worker", new double[]{3284.5078125, 358.046112060547, 479.179161621141, 3}, vars.afterCutscene},
                {"chainscrape_campfire", true, "Chainscrape campfire", "to_the_brink", "After fast traveling to the campfire", new double[]{3503.09481298536, 634.7410029230597, 496.63753112813, 0.5}, null},
                {"talk_to_ulvund", true, "Talk to Ulvund", "to_the_brink", "After Ulvund declares the work stoppage over", new double[]{3514.56575321363, 631.942178339057, 491.585375920346, 3}, vars.afterCutscene},
                // This one doesn't work:
                // {"bow_upgrade", true, "Bow upgrade", "to_the_brink", "After upgrading the bow at the workbench", new double[]{3503.0158447852, 667.755989785596, 495.516654022955}, Convert.ToByte(0)}
                {"to_the_brink_end", true, "To the brink completion", "to_the_brink", "After talking to Vuadis", new double[]{3478.15127197421, 693.580917980691, 502.252489202128, 3}, vars.afterCutscene},
            // THE EMBASSY
            {"the_embassy", true, "The Embassy", "main_game", null, null, null},
                {"ft_barren_light_campfire", true, "Go to Barren Light (campfire)", "the_embassy", "After fast traveling to Barren Light's campfire", new double[]{3040.32467007056, 17.4176695265878, 465.806756163831, 1}, null},
                {"ft_barren_light_entrance", true, "Go to Barren Light (setlement)", "the_embassy", "After fast traveling directly to Barren Light", new double[]{3067.86202363374, 29.2769007543735, 465.452685935666, 1}, null},
                {"barren_light_guards", true, "Talk to the Guards", "the_embassy", "After talking to Lawan", new double[]{3002.9937486091, -42.4641118231693, 460.273542940368, 3}, vars.afterCutscene},
                {"commander_ozar", true, "Talk to Commander Nozar", "the_embassy", "After talking to Commander Nozar", new double[]{2984.62499824589, -60.1051657119171, 457.769683837891, 3}, vars.afterCutscene},
                {"marshal_fashav", true, "Talk to the Tenakth Marshal", "the_embassy", "After talking to Marshal Fashav and the masacre", new double[]{2870.62179775211, -121.230065310201, 443.622149490734, 3}, null},
                // Not very consistent:
                // {"embassy_fight_s1", true, "Kill the Rebels 1", "the_embassy", "After phase 1 of embassy fight", new double[]{2870.62360055345, -120.76041278494, 443.616869219379}, null},
                {"embassy_fight_s2", true, "Kill the Rebels 2", "the_embassy", "After phase 2 of embassy fight", new double[]{2862.59138599705, -110.326070851414, 443.096934546515, 3}, vars.afterCutscene},
                {"the_embassy_end", true, "The embassy completion", "the_embassy", "After killing Grudda and talking to Lawan", new double[]{2856.34649391488, -111.947331052211, 442.736909297833, 3}, vars.afterCutscene},
            // DEATH'S DOOR
            {"deaths_door", true, "Death's Door", "main_game", null, null, null},
                {"latopolis_workshop_console", true, "Examine the Device", "deaths_door", "After interacting with the console at Silence's workshop", new double[]{1882.06305419515, -886.340802022707, 398.268561203955, 20}, vars.atCutscene},
                {"latopolis_entrance", true, "Enter the Facility", "deaths_door", "After entering Latopolis", new double[]{1396.21100749176, -1043.18508461455, 419.283511086773, 4}, null},
                {"latopolis_puzzle", true, "Latopolis puzzle", "deaths_door", "After pry open the first door", new double[]{1384.04396169236, -1018.86415177891, 419.11055211711, 4}, null},
                {"latopolis_hatch", true, "Find a Way to the Inner Gene-Locked Hatch", "deaths_door", "Before unlocking the Gene-Locked Hatch", new double[]{1317.94662456166, -957.727285226662, 427.153730726729, 7}, null},
                {"latopolis_fight_ending", true, "Erik fight", "deaths_door", "After interacting with the RECLUSE SPIDER and before Beta's cutscene", new double[]{1279.39724925022, -921.719401067575, 382.330274334309, 6}, null},
                {"latopolis_swim", true, "Search for a Way Out skip", "deaths_door", "After the skip", new double[]{1181.92985546908, -1008.48490176761, 382.335627528125, 9}, null},
                // TODO: check if final cutscene can be detected and use that to create a split here for the final cutscene.
                {"deaths_door_end", true, "Death's Door quest completion", "deaths_door", "After all the cutscenes", new double[]{2173.56175125315, -458.482903183264, 447.298365276365, 0.5}, null},
            // THE DYING LANDS
            {"dying_lands", true, "The Dying Lands", "main_game", null, null, null},
                {"varl_and_zo1", true, "Talk to Varl and Zo", "dying_lands", "After first talk with Varl and Zo", new double[]{1893.31466263015, 111.816843916912, 454.234876156028, 2.5}, null},
                {"varl_and_zo2", true, "Meet Varl and Zo outside the Chorus", "dying_lands", "After second talk with Varl and Zo", new double[]{1813.15244418883, 142.724109763483, 448.71504813782, 0.5}, null},
                {"ft_hg_plainsong", true, "Hunting grounds: Plainsong", "dying_lands", "After fast traveling to the hunting ground", new double[]{1607.28848872786, 405.726022671209, 477.930344282904, 0.5}, null},
                // Not very reliable:
                // {"sacred_cave", true, "Enter the Sacred Cave", "dying_lands", "After steping inside the sacred cave", new double[]{1258.05580584361, 14.1822783307252, 525.795176479354, 9}, Convert.ToByte(0)}
                {"discover_tau", true, "Repair-Bay TAU", "dying_lands", "A few metter before the cauldron door", new double[]{1310.32084919188, -37.4136490973169, 513.858193027531, 15}, null},
                {"tau_door", true, "Override the Door", "dying_lands", "After overriding the cauldron door", new double[]{1316.54221756116, -63.6139807290128, 506.395751721691, 0.5}, null},
                {"tau_node2", true, "Override the Network Uplink 2", "dying_lands", "After overriding the 2nd node", new double[]{1273.11842375116, -126.52472134368, 521.432223631847, 0.5}, null},
                {"tau_node3", true, "Override the Network Uplink 3", "dying_lands", "After overriding the 3nd node", new double[]{1243.80151488676, -70.0072635952895, 515.47515208731, 0.5}, null},
                {"tau_core", true, "Go to the Repair Bay Core", "dying_lands", "After overriding the core door and skiping the cutscene", new double[]{1204.44235299132, -147.802359328605, 511.744113913502, 2.5}, null},
                // This one is good, but it's too close to the next one (both in space and time), so it's not neccesary
                // {"tau_end_fight", true, "Kill the Grimhorn", "dying_lands", "After kill the Grimhorn and skiping the cutscene", new double[]{1203.72217560422, -176.297989567744, 498.881614953811, 1}, null},
                // Fix this one, user can miss it if they move fast enough:
                {"dying_lands_end", true, "The Dying Lands completion", "dying_lands", "After overriding the Repair Bay Core", new double[]{1204.80459153937, -181.34663738834, 499.016075359922, 0.5}, null},
            // THE EYE OF THE EARTH
            {"eye_of_the_earth", true, "The Eye of the Earth", "main_game", null, null, null},
                {"eye_of_the_earth_exterior", true, "Outside", "eye_of_the_earth", "After climbing the elevator shaft and getting outside", new double[]{1171.0786392495, -182.755379960889, 593.715639303984, 6}, null},
                // Not very reliable:
                // {"eye_of_the_earth_blocked", true, "Blocked vent (rock barrier)", "eye_of_the_earth", "After removing the rock barrier", new double[]{1151.71396453882, -147.507589064776, 627.015958776355, 6}, null},
                // This one has to be fixed, coordinates are wrong:
                {"eye_of_the_earth_end", true, "The Eye of the Earth completion", "eye_of_the_earth", "After leaving the base", new double[]{1065.27399802534, -133.990172280215, 595.289001756311, 0.5}, null},
            // THE SEA OF SANDS
            {"sea_of_sands", true, "The Sea of Sands", "main_game", null, null, null},
                // This one is ok but since Morlund is at the exact same position for 2 dialogs, 2 checkpoints interfiere with one each other:
                // {"talk_to_morlund", true, "Talk to Morlund", "sea_of_sands", "After talking to Morlund for the first time", new double[]{179.502815277958, -1752.24831899832, 379.806494659235, 0.5}, null},
                {"compressed_air_capsule", true, "Recover the Compressed Air Capsule", "sea_of_sands", "After recovering the compressed air capsule and resurface", new double[]{159.64849006303, -1755.42875464963, 379.329138009631, 12}, null},
                // This is the second dialog with Morlund, which interfieres with the first dialog checkpoint:
                // {"return_to_morlund", true, "Return to Morlund", "sea_of_sands", "After talking to Morlund and delivering the machine parts", new double[]{179.502815277958, -1752.24831899832, 379.806494659235, 0.5}, null},
                {"diving_mask", true, "Craft the Diving Mask", "sea_of_sands", "After crafting the diving mask and skipping the cutscene", new double[]{177.741601660649, -1751.70936257938, 379.81235963467, 0.5}, null},
                {"sos_tideripper_fight", true, "Tideripper fight start", "sea_of_sands", "After skipping the cutscene and when the fight starts", new double[]{292.6282361799, -1757.99238680789, 302.325390841927, 0.5}, null},
                {"recover_poseidon", true, "Recover Poseidon", "sea_of_sands", "After recovering Poseidon from the kernel console", new double[]{375.903582053325, -1608.43782359568, 290.981819448859, 0.5}, null},
                {"sos_shaft", true, "Return to the Elevator Shaft", "sea_of_sands", "While approaching the elevator shaft", new double[]{173.866923043304, -1759.11666480337, 337.479619031369, 7}, null},
                // This one is ok, but it interfieres with "compressed_air_capsule":
                // {"sos_shaft_climb", true, "Climb to the Surface", "sea_of_sands", "After climbing the shaft", new double[]{171.257314207326, -1759.84989518264, 379.349947902309, 0.5}, null},
                {"sos_exit", true, "Exit the Ruin", "sea_of_sands", "After skipping the final cutscene", new double[]{193.717782655841, -1753.93191945512, 379.301165994257, 0.5}, null},
                // There are several "Return to base" checkpoints and they interfiere with one another, so...
                // {"poseidon_base_east", true, "Return to the Base (East entrance)", "sea_of_sands", "After entering the base via the East entrance (the one with the campfire outside)", new double[]{1171.9476728197, -128.422619843684, 596.227658606234, 4}, null},
                // {"poseidon_base_west", true, "Return to the Base (West entrance)", "sea_of_sands", "After entering the base via the West entrance", new double[]{1080.05640796071, -128.785940423581, 596.217785478564, 4}, null},
                {"sea_of_sands_end", true, "The Sea of Sands completion", "sea_of_sands", "After delivering Poseidon to Gaia", new double[]{1126.68089650339, -173.705765425105, 604.692957182031, 0.5}, null},
            // THE BROKEN SKY
            {"broken_sky", true, "The Broken Sky", "main_game", null, null, null},
                {"talk_to_dekka1", true, "Enter the Tenakth Stronghold", "broken_sky", "When meeting Dekka for the first time", new double[]{-561.143929724229, -700.816345744507, 421.460233722531, 0.5}, null},
                {"talk_to_hekarro1", true, "Go to the Throne Room", "broken_sky", "After talking to Hekarro", new double[]{-651.100222225294, -725.423997357323, 424.442085891196, 0.5}, null},
                {"talk_to_dekka2", true, "Talk to Dekka", "broken_sky", "After talking to Dekka, before leaving the Memorial Grove", new double[]{-560.236789948414, -701.793430349189, 421.425153185022, 0.5}, null},
                {"talk_to_kotallo1", true, "Meet Kotallo at Stone Crest", "broken_sky", "After talking to Kotallo at Stone Crest", new double[]{-1319.93318078725, 552.224311608684, 504.850704846138, 0.5}, null},
                {"bulwark_arrival", true, "Bullwark", "broken_sky", "First time at the Bulwark", new double[]{-1722.13121999946, 391.309904382682, 404.7912937556, 0.5}, null},
                {"bulwark_guards", true, "Talk to the Guard", "broken_sky", "After meeting Tekotteh for the first time", new double[]{-1730.15005636434, 314.720215311573, 433.568395292096, 0.5}, null},
                {"talk_to_kotallo2", true, "Talk to Kotallo", "broken_sky", "After scanning the ancient debris", new double[]{-1733.26332649985, 469.88229567626, 370.670485070325, 0.5}, null},
                {"find_a_cannon", true, "Find a Cannon", "broken_sky", "When the fight against the rebels starts", new double[]{-1574.79929628765, 621.389553832259, 381.590784403321, 0.5}, null},
                {"loot_the_tremortusk", true, "Loot the Tremortusk", "broken_sky", "After looting the Tremortusk", new double[]{-1571.64630251081, 650.12790960532, 383.799969405757, 0.5}, null},
                {"broken_sky_end", true, "The Broken Sky completion", "broken_sky", "After skipping the wall cutscene", new double[]{-1723.03082693475, 479.147360910377, 372.401923291072, 0.5}, null},
            // SEEDS OF THE PAST
            {"seeds_of_the_past", true, "Seeds of the past", "main_game", null, null, null},
                {"green_house", true, "Go to DEMETER's Coordinates", "seeds_of_the_past", "After the first cutscene (the one of the Quen)", new double[]{-2298.23907620846, -318.615574466228, 263.998140257198, 0.5}, null},
                {"console1_room", true, "1st console room entrance", "seeds_of_the_past", "After entering the console room ", new double[]{-2435.0981399617, -174.997195373757, 274.856778440544, 4}, null},
                {"console1_active", true, "Examine the Console", "seeds_of_the_past", "After skiping the cutscene examinning the 1st console", new double[]{-2425.85302734263, -183.151794431744, 274.700555429794, 4}, null},
                {"console2_room", true, "Enter the Facility", "seeds_of_the_past", "After meeting Alva for the first time", new double[]{-2443.00975010494, -299.953638112824, 262.793997428293, 4}, null},
                // This one works, but Aloy is able to move a little bit earlier than the checkpoint activation, so it could be missed if the player moves fast enough:
                //{"console2_active", true, "Examine the Paired Console", "seeds_of_the_past", "After activating the 2nd console", new double[]{-2436.64217986681, -309.127913258448, 2262.734527587891, 4}, null},
                {"tunnel1_entrance", true, "Enter the Facility Tunnels", "seeds_of_the_past", "After touching ground at the 1st tunnel", new double[]{-2443.40121643837, -309.314601698732, 243.939336833515, 6}, null},
                {"tunnel1_exit", true, "Search the Tunnels for an Exit", "seeds_of_the_past", "After exiting the first tunnel and skipping the cutscene", new double[]{-2330.46044921875, -200.520797729492, 262.781005859375, 0.5}, null},
                {"station_elm_power", true, "Restore Power to the Control Room Door", "seeds_of_the_past", "After inserting the energy cell", new double[]{-2363.93797978578, -89.4260734850626, 262.823791553125, 0.5}, null},
                {"station_elm_alva", true, "Return to Alva", "seeds_of_the_past", "After entering the console room where Alva is waiting", new double[]{-2382.86432348684, -91.7786335675385, 268.333543254255, 4}, null},
                {"station_elm_console", true, "Examine the Paired Console", "seeds_of_the_past", "After activating the paired console and skipping the cutscenes", new double[]{-2388.5490316418, -74.8628508350812, 262.703375081376, 0.5}, null},
                {"tunnel2_entrance", true, "Enter the Tunnels", "seeds_of_the_past", "After touching ground at the 2nd tunnel", new double[]{-2387.6757885908, -71.3182560050464, 242.95631960088, 6}, null},
                {"tunnel2_exit", true, "Search the Tunnels for an Exit", "seeds_of_the_past", "After exitting the 2nd tunnel", new double[]{-2395.49493342838, -4.42559897501379, 265.73728479002, 12}, null},
                {"recover_demeter", true, "Recover DEMETER", "seeds_of_the_past", "After recovering Demeter from the kernel console", new double[]{-2416.27800689559, -167.78638302058, 266.72524659487, 0.5}, null},
                // There are several "Return to base" checkpoints and they interfiere with one another, so...
                // {"demeter_base_east", true, "Return to the Base (East entrance)", "seeds_of_the_past", "After entering the base via the East entrance (the one with the campfire outside)", new double[]{1171.9476728197, -128.422619843684, 596.227658606234, 4}, null},
                // {"demeter_base_west", true, "Return to the Base (West entrance)", "seeds_of_the_past", "After entering the base via the West entrance", new double[]{1080.05640796071, -128.785940423581, 596.217785478564, 4}, null},
                {"seeds_of_the_past_end", true, "Seeds of the past completion", "seeds_of_the_past", "When Gaia cutscene starts", new double[]{1126.66485822731, -172.822726250194, 604.694116791, 0.5}, null},
            // CRADLE OF ECHOES
            {"cradle_of_echoes", true, "Cradle of echoes", "main_game", null, null, null},
                {"cradle_of_echoes_start", true, "Quest begins", "cradle_of_echoes", "After skipping the first cutscene", new double[]{471.539801043492, 1001.57282180152, 611.669422346633, 0.5}, null},
                {"coe_erend", true, "Return to Erend", "cradle_of_echoes", "After talking to Erend", new double[]{470.409454582841, 1015.90345562832, 612.800859119769, 0.5}, null},
                {"coe_varl", true, "Talk to Varl", "cradle_of_echoes", "After talking to Varl", new double[]{519.371672352834, 1041.28389025133, 617.032501176756, 0.5}, null},
                {"coe_specter2", true, "Kill the Specter", "cradle_of_echoes", "After killing the second Specter", new double[]{473.852036567318, 998.084829098778, 611.678023448328, 0.5}, null},
                {"coe_backt_to_base", true, "Return to the Base", "cradle_of_echoes", "After skipping the cutscene and getting teleported back to the base", new double[]{1110.90792882489, -128.354186657351, 596.179073691019, 0.5}, null},
                {"cradle_of_echoes_end", true, "Cradle of echoes completion", "cradle_of_echoes", "Talking to Beta at the base", new double[]{1126.6162109375, -160.857620239258, 586.722442859669, 0.5}, null},
            // The Kulrut
            {"kulrut", true, "The Kulrut", "main_game", null, null, null},
                {"k_talk_to_hekarro", true, "Talk to Hekarro", "kulrut", "After talkint to Hekarro and Kotallo", new double[]{-710.314951462999, -667.036788503602, 421.747506281721, 0.5}, null},
                {"k_talk_to_dekka1", true, "Talk to Dekka 1", "kulrut", "After talkint to dekka and skipping the cutscene", new double[]{-703.347499714865, -503.289783425664, 435.613621093304, 0.5}, null},
                {"k_machines", true, "Kill the Machines", "kulrut", "After killing the machines and skipping the cutscene", new double[]{-702.827301064194, -627.365261405692, 402.449885715847, 0.5}, null},
                {"k_Slitherfang", true, "Kill the Slitherfang", "kulrut", "After killing the Slitherfang and skipping the cutscene", new double[]{-706.039611816406, -643.008728027344, 402.406090332079, 0.5}, null},
                {"k_hekarro_vs_regalla", true, "Find Hekarro", "kulrut", "After skipping Hekarro vs Regalla fight cutscene", new double[]{-658.39816076211, -729.239206238282, 425.459378641215, 0.5}, null},
                {"recover_aether", true, "Recover Aether", "kulrut", "After recovering Aether from the kernel console", new double[]{-645.114730751759, -723.951979701174, 410.155398411358, 0.5}, null},
                {"k_talk_to_dekka2", true, "Talk to Dekka 2", "kulrut", "After skipping the 'Visions' cutscene", new double[]{-623.938389487385, -718.1939104308, 420.71443575872, 0.5}, null},
                {"kulrut_end", true, "The Kulrut completion", "kulrut", "After deliver Aether to Gaia", new double[]{1126.69021617063, -173.088289075991, 604.70717884778, 0.5}, null},
            // FARO'S TOMB
            {"faros_tomb", true, "Faro's Tomb", "main_game", null, null, null},
                {"fst_shore", true, "At the shore", "faros_tomb", "After skipping storm cutscenes", new double[]{-4534.15870749811, -1481.90821055777, 256.349266290743, 0.5}, null},
                {"fst_ceo1", true, "Meeting the Quen", "faros_tomb", "After meeting the CEO for the 1st time", new double[]{-3899.12943281898, -902.091247103172, 261.23119216371, 0.5}, null},
                {"thebes", true, "Thebes", "faros_tomb", "After the unskippable and normal cutscenes", new double[]{-4183.57372897825, -753.115054217072, 215.436076155165, 0.5}, null},
                {"fst_main_door", true, "Open the Main Door", "faros_tomb", "After skipping the business pijamas cutscene", new double[]{-4196.3108154492, -752.314828835741, 215.619348997814, 0.5}, null},
                {"fst_ Corruptors", true, " Corruptors fight", "faros_tomb", "At the start of the corruptor fight", new double[]{-4282.04934113465, -735.67165659405, 195.512327701274, 0.5}, null},
                {"dentist_chair", true, "Dentist chair", "faros_tomb", "After skipping the dentist chair cutscene", new double[]{-4412.62988279942, -792.022888315817, 183.9418136565, 0.5}, null},
                {"omega_clearance", true, "Recover Ted Faro's Omega Clearance", "faros_tomb", "After interacting with the console and skipping the cutscene", new double[]{-4339.08831859753, -706.646734324226, 171.495901107954, 0.5}, null},
                {"faros_tomb_end", true, "Faro's Tomb completion", "faros_tomb", "After skipping the escape cutscene", new double[]{-4124.24500894019, -759.285889982147, 257.148196770059, 0.5}, null},
            // GEMINI
            {"gemini", true, "Gemini", "main_game", null, null, null},
                {"g_talk_to_varl", true, "Talk to Varl", "gemini", "After talking to Varl and Beta", new double[]{1126.45822424273, -161.686925474541, 586.722473144535, 0.5}, null},
                {"g_talk_to_gaia", true, "Talk to Gaia", "gemini", "After selecting Gemini dialog option", new double[]{1126.65167234839, -172.991956621409, 604.694030761719, 0.5}, null},
                // 2 checkpoints in exact same place:
                // {"g_override_network_uplink1", true, "Override the Network Uplink 1", "gemini", "After overriding node 1", new double[]{-347.897836289684, -131.387933812729, 327.14517165756, 2.5}, null},
                // 2 checkpoints in exact same place:
                // {"g_override_network_uplink2", true, "Override the Network Uplink 2", "gemini", "After overriding node 2", new double[]{-492.896564169676, -282.965080579165, 332.436717812881, 2.5}, null},
                {"gemini_end", true, "Gemini completion", "gemini", "Skipping the cutscene where Aloy wakes up at Tilda's", new double[]{-2659.00016519993, -2429.99335463173, 284.97422481142, 2.5}, null},
            // ALL THAT REMAINS
            {"all_that_remains", true, "All That Remains", "main_game", null, null, null},
                {"atr_meet_tilda", true, "Meet Tilda Upstairs", "all_that_remains", "After talking to Tilda", new double[]{-2567.43172459692, -2545.58495087604, 299.141551522392, 0.5}, null},
            // THE WINGS OF THE TEN
            {"wings_of_the_ten", true, "The wings of the ten", "main_game", null, null, null},
                {"wott_return_to_base", true, "Return to the Base", "wings_of_the_ten", "After skipping the cutscene at the base", new double[]{1126.77739727647, -113.387087343977, 595.457464879265, 0.5}, null},
                {"wott_talk_to_zo", true, "Talk to Zo", "wings_of_the_ten", "After talking to Zo", new double[]{1210.21069335938, -85.7714157104492, 599.363121582079, 0.5}, null},
                {"wott_memorial_grove", true, "Fly to the Memorial Grove", "wings_of_the_ten", "After arriving to Memorial Grove, when the fight vs regala starts", new double[]{-736.548583984375, -670.595947265625, 425.874931884813, 0.5}, null},
                {"regalla_fight1", true, "Fight agaist regala phase 1 completed", "wings_of_the_ten", "After beating fight agains Regall phase 1, and begining the phase 2", new double[]{-757.453307539219, -649.848390188923, 418.134736702906, 0.5}, null},
                {"regalla_fight2", true, "Fight agaist regala phase 2 completed", "wings_of_the_ten", "After beating fight agains Regall phase 2, and begining the phase 3", new double[]{-725.179532514988, -637.336851349486, 402.650763676429, 0.5}, null},
                {"wings_of_the_ten_end", true, "The wings of the ten completion", "wings_of_the_ten", "After skipping Silence cutscene", new double[]{-649.816195195953, -725.043352083936, 424.440494659386, 0.5}, null},
            // SINGULARITY
            {"singularity", true, "Singularity", "main_game", null, null, null},
                {"s_return_to_base", true, "Return to the Base", "singularity", "After skipping the first cutscene at the base", new double[]{1148.42504882813, -114.680801391602, 595.735626515009, 0.5}, null},
                {"s_companions", true, "Assemble your companions", "singularity", "After skipping the second cutscene at the base", new double[]{1126.52331542969, -172.044509887695, 604.699059082079, 0.5}, null},
                // Aloy's position gets messed up here, probably because of the Far Zenith skip:
                // {"s_companions2", true, "Call your companions at the campfire", "singularity", "After selecting the dialog option at the campfire", new double[]{-1153.43478651065, -2660.38023495023, 256.983926892281, 2.5}, null},
                {"s_tower_way", true, "Go to the launch tower", "singularity", "After skipping the cutscene from the launch tower (before Erik fight)", new double[]{-1593.68208047545, -3022.68463255181, 290.297510162035, 0.5}, null},
                {"s_elevator", true, "Elevator", "singularity", "After skipping the elevator cutscene and when the fight vs Erik starts", new double[]{-1739.01039530308, -2935.70935367304, 275.411357082563, 0.5}, null},
                {"s_kill_erik", true, "Kill Erik", "singularity", "After sending that mf directly to his private suite in hell", new double[]{-1750.06598672244, -2936.75970356017, 275.548077226695, 0.5}, null},
                {"s_tower_top", true, "Go to the Top of the Tower", "singularity", "After activating the console at the top of the tower and skipping the cutscene", new double[]{-1777.06428950257, -2917.20452540441, 381.164883909853, 0.5}, null},
                {"s_kill_tilda", true, "Defeat Tilda", "singularity", "After activating the console at the top of the tower and skipping the cutscene", new double[]{-1814.22644042969, -2890.05590820313, 379.655666866147, 0.5}, null},
                // This should be implemented using Iso's code logic to stop the timer (this is the last split, but it's not a checkpoint):
                //-1814.22644042969, -2890.05590820313, 379.655666866147, 0.5
    };

    // Initialize autosplit settings and checkpoint coordinates
    dynamic tmp = null;
    for (int i = 0; i < _settings.GetLength(0); i++){
        // Settings entry
        settings.Add(_settings[i, 0], _settings[i, 1], _settings[i, 2], _settings[i, 3]);
        // Tool tip message (if available)
        if(_settings[i, 4] != null){
            settings.SetToolTip(_settings[i, 0], _settings[i, 4]);
        }
        // Add checkpoint to the list (if available)
        if(_settings[i, 5] != null){
            // vars.checkpointCoordinates.Add(_settings[i, 0], _settings[i, 5]);
            tmp = new ExpandoObject();
            tmp.ID = _settings[i, 0];
            tmp.coordinates = _settings[i, 5];
            tmp.cutsceneCheck = _settings[i, 6] != null ? _settings[i, 6] : Convert.ToByte(0);
            // Has the checkpoint already been reached before?
            tmp.reachedBefore = false;
            vars.checkpoints.Add(tmp);
        }
    }
}

// Game starts running (or it was already running)
init{
}

/****************************************************/
// start - Runs when timer is stopped & decides when to start
/****************************************************/
start{
    // Debugging:
    // print(current.WestEast.ToString());
    // print(current.SouthNorth.ToString());
    // print(current.DownUp.ToString());
    return
        // old.isGod > 0 && current.isGod == 0 &&
        vars.Funcs.isSplit(current.WestEast, current.SouthNorth, current.DownUp, vars.starting, old.isGod, current.isGod, vars.atCutscene);
}

isLoading
{
    return (current.isLoading > 0);
}

// Checks if it's time to split
split{
    // Meassures the time since the last cutscene.
    // The save state flag on memory changes a few miliseconds after the invulnerable flag,
    // so to detect whether we come from a cutscene or not, its imperative to store the invulnerable
    // value for a brief period of time:
    if(old.isGod > 0 && current.isGod == 0){ // isGod changed from 1 to 0 (from cutscene to free roam)
        vars.sw.Restart();
        print("GOD MOD OFF, TIMER STARTED");
    }
    else if(
        vars.sw.ElapsedMilliseconds >= vars.cutsceneTolerance &&
        vars.sw.IsRunning
    ){
        vars.sw.Stop();
        print("CUTSCENE TIME LIMIT REACHED, TIMER SOPED");
    }
    // Debugging:
    // print("Prev. god mode: " + old.isGod.ToString());
    // print("Is god mode: " + current.isGod.ToString());
    if(old.saveState != current.saveState && current.saveState > 0){
        // print(vars.sw.ElapsedMilliseconds.ToString());
        // var mesg = MessageBox.Show(
        //     "Save!",
        //     "LiveSplit | Sniper Elite"
        // );
        // print("********************************************************************************************");
        // print("Save state: " + current.saveState.ToString());
        foreach (var checkpoint in vars.checkpoints){
            if(!checkpoint.reachedBefore) {
                if(
                vars.Funcs.isSplit(
                    current.WestEast,
                    current.SouthNorth,
                    current.DownUp,
                    checkpoint.coordinates,
                    old.isGod,
                    current.isGod,
                    checkpoint.cutsceneCheck
                )
                ){
                    // Splits only if the user has enabled this split
                    // in the autosplitter settings:
                    if(settings[checkpoint.ID]){
                        // Safty messure: ensures only one split per checkpoint:
                        checkpoint.reachedBefore = true;
                        return true;
                    }
                    else{
                        print("SPLIT DESABLED IN SETTINGS.");
                    }
                }
                else{
                    print("OUT OF CHECKPOINT ZONE");
                }
            }
            else{
                print("ALRADY SPLITTED.");
            }
        }
        print("----------------------------------------------------------------------------------\n");
    }
}

onReset{		
	vars.prevSplit = "";
    // vars.Funcs.showToolsForm();
}