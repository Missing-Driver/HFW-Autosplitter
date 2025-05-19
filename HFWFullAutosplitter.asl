// Base address signatures:
    // GameModule: 48 8B 05 ?? ?? ?? ?? 0F B6 80 70 06 00 00
    // Player: 48 8B 05 ?? ?? ?? ?? 48 85 C0 74 06 89 98 68 38 00 00
    // HUD reference (add 0x08 to the found address): 4C 8D 35 ?? ?? ?? ?? 4C 8D 3D ?? ?? ?? ?? 66 66 66 0F 1F 84 00 00 00 00 00
state("HorizonForbiddenWest", "v1.5.80.0-Steam"){
    // GameModule: HorizonForbiddenWest.exe+8983150
        // Quick save flag:
        byte quickSaveOcilator: 0x08983150, 0x3F8; // Ocilates between 1 and 0 on quick saves
        // Loading screens flag:
        byte isLoading : 0x08983150, 0x4B4; // Bigger than 0 on loading screens

    // Player => HorizonForbiddenWest.exe+8982DA0
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
    // HUD reference => HorizonForbiddenWest.exe+8959F30
        // Focus scanner string (machine name):
        string32 scannedMachineName : 0x8959F30, 0x200, 0x1C0, 0x1B8, 0x8, 0xC0, 0x0;
}

startup{
    // Object containing useful functions:
    vars.Funcs = new ExpandoObject();
    // Contains the list of splits and starting points:
    vars.splitLists =  new ExpandoObject();

    // Calculates the hash of a given module.
    // Taken from ISO2768mK's Horizon Forbidden West load remover:
    vars.Funcs.hashModule = (Func<ProcessModuleWow64Safe, string>)((module) => {
        byte[]  hashBytes = new byte[0];
        using (var sha256Object = System.Security.Cryptography.SHA256.Create())
        {
            using (var binary = File.Open(module.FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
            {
                hashBytes = sha256Object.ComputeHash(binary);
            }
        }
        var hexHashString = hashBytes.Select(x => x.ToString("X2")).Aggregate((a, b) => a + b);
        return hexHashString;
    });

    // Determines if Aloy is over a given checkpoint zone:
    vars.Funcs.isOnCheckpoint = (Func<Dictionary<string, ExpandoObject>, double, double, double, dynamic>)((
            splitList, playerPosX, playerPosY, playerPosZ
    ) => {
        dynamic result = new ExpandoObject();
        result.isOnCheckpoint = false;
        result.splitName = null;
        result.splitType = null;
        result.reachedBefore = null;
        foreach(var split in splitList){
            dynamic tmp = split.Value;
            // Checks if the current comparison checkpoint is triggered by zone bounds:
            if(!tmp.reachedBefore && tmp.geolocation != null){
                if(
                    // Checks if Aloy is in checkpoint zone West-East:
                    (tmp.geolocation[0] - tmp.geolocation[3]) < playerPosX &&
                    (tmp.geolocation[0] + tmp.geolocation[3]) > playerPosX &&
                    // Checks if Aloy is in checkpoint zone South-North:
                    (tmp.geolocation[1] - tmp.geolocation[3]) < playerPosY &&
                    (tmp.geolocation[1] + tmp.geolocation[3]) > playerPosY &&
                    // Checks if Aloy is in checkpoint zone vertically:
                    (tmp.geolocation[2] - tmp.geolocation[3]) < playerPosZ &&
                    (tmp.geolocation[2] + tmp.geolocation[3]) > playerPosZ
                ){
                    result.isOnCheckpoint = true;
                    result.splitName = split.Key;
                    result.splitType = tmp.Type;
                    result.reachedBefore = tmp.reachedBefore;
                    break;
                }
            }
        }
        return result;
    });

    // Contains the autosplitter settings:
    dynamic[,] _settings = {
        // Main game
        // ID, Label, Tool tip, Parent ID, Default setting?
        {"main_game", "Main game", "Main game splits", null, false},
            // STARTING POINTS
            {"mg_starting_points", "Starting points", "Select when livesplit will start the timer", "main_game", true},
                // NEW GAME+
                {"NGP_start", "NG+", "When the last cutscene before the cable car ride into the Daunt is skipped", "mg_starting_points", true},
            // MAIN QUESTS:
            {"mg_quests", "Quests", null, "main_game", true},
                // TO THE BRINK
                {"to_the_brink", "To the brink", null, "mg_quests", true},
                    {"chainscrape_entrance", "Go to Chainscrape", "After talking to the guards", "to_the_brink", true},
                    {"scroungers", "Scroungers", "After killing the scroungers and talking to Thurlis", "to_the_brink", true},
                    {"find_erend", "Find Erend", "When the cutscene where Aloy finds Erend ends", "to_the_brink", true},
                    {"ttb_talk_to_erend", "Talk to Erend", "After killing the machines and talk to Erend", "to_the_brink", true},
                    {"clear_the_daunt", "Clear the Daunt", "After killing the Bristlebacks and talk with the Oseram worker", "to_the_brink", true},
                    {"chainscrape_campfire", "Chainscrape campfire", "When fast traveling to the campfire", "to_the_brink", true},
                    {"talk_to_ulvund", "Talk to Ulvund", "After Ulvund declares the work stoppage over", "to_the_brink", true},
                    {"upgrade_bow", "Upgrade Your Bow", "After upgrading the bow at the workbench", "to_the_brink", true},
                    {"to_the_brink_end", "To the brink completion", "After talking to Vuadis", "to_the_brink", true},
                // THE EMBASSY
                {"the_embassy", "The Embassy", null, "mg_quests", true},
                    {"ft_barren_light_campfire", "Go to Barren Light (campfire)", "After fast traveling to Barren Light's campfire", "the_embassy", true},
                    {"ft_barren_light_entrance", "Go to Barren Light (setlement)", "After fast traveling directly to Barren Light", "the_embassy", true},
                    {"barren_light_guards", "Talk to the Guards", "When talking to Lawan", "the_embassy", true},
                    {"commander_ozar", "Talk to Commander Nozar", "After talking to Commander Nozar", "the_embassy", true},
                    {"the_embassy_end", "The embassy completion", "After finishing talkig to Lawan", "the_embassy", true},
                // DEATH'S DOOR
                {"deaths_door", "Death's Door", null, "mg_quests", true},
                    {"ft_tallkneck_cinnabar_sands", "Tallneck: Cinnabar Sands", "When fast travelling to the tallneck", "deaths_door", true},
                    {"workshop_console", "Examine the Device", "After interacting with the console at Silence's workshop", "deaths_door", true},
                    {"latopolis_orb", "Follow the Orb's Trail", "After interacting with the orb", "deaths_door", true},
                    {"latopolis_craft", "Craft the igniter", "After crafting the igniter at the workbench", "deaths_door", true},
                    {"latopolis_firegleam1", "Ignite the Firegleam 1", "After interacting with the firegleam", "deaths_door", true},
                    {"latopolis_hatch", "Gene-Locked Hatch", "After interacting with the Gene-Locked Hatch", "deaths_door", true},
                    {"latopolis_fight_ending", "Erik fight finishes", "After Erik fight", "deaths_door", true},
                    {"latopolis_firegleam2", "Ignite the Firegleam 2", "After interacting with the exit firegleam", "deaths_door", true},
                    {"deaths_door_end", "Death's Door quest completion", "After all the cutscenes", "deaths_door", true},
                // THE DYING LANDS
                {"dying_lands", "The Dying Lands", null, "mg_quests", true},
                    {"ft_campfire_cinnabar_sands", "Cinnabar Sands campfire Fast travel", "After fast traveling to the campfire", "dying_lands", true},
                    {"tdl_varl_and_zo1", "Talk to Varl and Zo", "After 1st talk with Varl and Zo", "dying_lands", true},
                    {"tdl_varl_and_zo2", "Meet Varl and Zo outside the Chorus", "After second talk with Varl and Zo", "dying_lands", true},
                    {"tau_door", "Override Tau Door", "After overriding the cauldron door and skiping the cutscene", "dying_lands", true},
                    {"tau_control_node1", "Override the 1st network uplink", "After overriding the 1st control node", "dying_lands", true},
                    {"tau_control_node2", "Override the 2nd network uplink", "After overriding the 2nd control node", "dying_lands", true},
                    {"tau_control_node3", "Override the 3rd network uplink", "After overriding the 3rd control node", "dying_lands", true},
                    {"tau_core_bay", "Go to the Repair Bay Core", "After overriding the core door", "dying_lands", true},
                    {"tau_core", "Override the Repair Bay Core", "When overriding the Repair Bay Core", "dying_lands", true},
                    // { "tdl_end", "The Dying Lands completion", "After the scripted animation of the new machine overrides", "dying_lands", true},
                // THE EYE OF THE EARTH
                {"eye_of_the_earth", "The Eye of the Earth", null, "mg_quests", true},
                    {"eote_minerva_console", "Examine the Console", "When playing the cutscene", "eye_of_the_earth", true},
                    {"eote__end", "The Eye of the Earth completion", "After leaving the base and skiping the cutscene", "eye_of_the_earth", true},
                // THE SEA OF SANDS
                {"sea_of_sands", "The Sea of Sands", null, "mg_quests", true},
                    {"compressed_air_capsule", "Recover the Compressed Air Capsule", "When recovering the compressed air capsule", "sea_of_sands", true},
                    {"diving_mask", "Craft the Diving Mask", "After crafting the diving mask", "sea_of_sands", true},
                    {"main_pump", "Drain the City", "After interacting with the console at the main station", "sea_of_sands", true},
                    {"recover_poseidon", "Recover Poseidon", "After recovering Poseidon from the kernel console", "sea_of_sands", true},
                    {"las_vegas_exit", "Exit the Ruin", "After skiping the last cutscene", "sea_of_sands", true},
                    {"tsos_end", "The Sea of Sands completion", "After delivering Poseidon to Gaia and skipping the cutscene", "sea_of_sands", true},
                // THE BROKEN SKY
                {"broken_sky", "The Broken Sky", null, "mg_quests", true},
                    {"tbs_entrance", "Enter the Tenakth Stronghold", "After talking to Dekka for the first time", "broken_sky", true},
                    {"throne_room", "Go to the Throne Room", "After talking to Hekarro at the Throne Room", "broken_sky", true},
                    {"tbs_talk_to_kotallo1", "Meet Kotallo at Stone Crest", "After talking to Kotallo at Stone Crest", "broken_sky", true},
                    {"tbs_kotallo_skip", "After Kotallo skip", "After skipping the cutscene", "broken_sky", true},
                    {"bulwark_guards", "Talk to the Guard", "After meeting Tekotteh for the first time and skiping the cutscene", "broken_sky", true},
                    {"tbs_talk_to_kotallo2", "Talk to Kotallo", "After talking to Kotallo, after scanning the ancient debris", "broken_sky", true},
                    {"loot_the_tremortusk", "Loot the Tremortusk", "After looting the Tremortusk and skipping the cutscene", "broken_sky", true},
                    {"broken_sky_end", "The Broken Sky completion", "After skipping the wall cutscene", "broken_sky", true},
                // SEEDS OF THE PAST
                {"seeds_of_the_past", "Seeds of the past", null, "mg_quests", true},
                    {"green_house", "Go to DEMETER's Coordinates", "After skipping the first cutscene (the one of the Quen)", "seeds_of_the_past", true},
                    {"console1_active", "Examine the Console", "After interacting with the 1st console and skipping the cutscene", "seeds_of_the_past", true},
                    {"console2_room", "Enter the Facility", "After meeting Alva for the first time", "seeds_of_the_past", true},
                    {"console2_active", "Examine the Paired Console", "After interacting with the paired console", "seeds_of_the_past", true},
                    {"tunnel1_exit", "Search the Tunnels for an Exit", "After exiting the first tunnel", "seeds_of_the_past", true},
                    {"station_elm_console", "Examine the Paired Console", "After activating the paired console and skipping the cutscenes", "seeds_of_the_past", true},
                    {"test_station_ivy", "Test Station Ivy", "When entering Test Station Ivy", "seeds_of_the_past", true},
                    {"recover_demeter", "Recover DEMETER", "When recovering Demeter from the kernel console", "seeds_of_the_past", true},
                    {"sotp_end", "Seeds of the past completion", "After delivering Demeter to Gaia", "seeds_of_the_past", true},
                // CRADLE OF ECHOES
                {"cradle_of_echoes", "Cradle of echoes", null, "mg_quests", true},
                    {"coe_console2", "Examine the main Console", "After entering the ectogenic chambers code", "cradle_of_echoes", true},
                    {"coe_specter2", "Kill the Specter 2", "After killing the second Specter", "cradle_of_echoes", true},
                    {"coe_end", "Cradle of echoes completion", "After talking to crazy Beta", "cradle_of_echoes", true},
                // THE KULRUT
                {"kulrut", "The Kulrut", null, "mg_quests", true},
                    {"ft_memorial_grove", "Go the the Memorial Grove", "After fast traveling to The Memorial Grove", "kulrut", true},
                    {"k_talk_to_hekarro", "Talk to Hekarro", "After talkint to Hekarro and Kotallo", "kulrut", true},
                    {"k_machines", "Kill the Machines", "After killing the machines and skipping the cutscene", "kulrut", true},
                    {"k_Slitherfang", "Kill the Slitherfang", "After killing the Slitherfang and skipping the cutscene", "kulrut", true},
                    {"recover_aether", "Recover Aether", "After recovering Aether from the kernel console", "kulrut", true},
                    {"kulrut_end", "The Kulrut completion", "After delivering Aether to Gaia", "kulrut", true},
                // FARO'S TOMB
                {"faros_tomb", "Faro's Tomb", null, "mg_quests", true},
                    {"fst_boat", "Boat", "When interacting with the boat", "faros_tomb", true},
                    {"fst_legacys_landfall", "Legacy's Landfall", "After arriving to Legacy's Landfall and talking to the clowns", "faros_tomb", true},
                    {"fst_talk_to_alva", "Talk to Alva", "When talking to Alva at Thebes", "faros_tomb", true},
                    {"fst_bunker_entrance", "Bunker entrance", "After skipping the cutscenes", "faros_tomb", true},
                    {"fst_entrance_skip", "Thebes entrance skip", "After the first skip, when clipping throug the floor", "faros_tomb", true},
                    {"fst_Corruptors", "Corruptors hall exit", "When openning the exit door from the Corruptors hall", "faros_tomb", true},
                    {"fst_omega_clearance", "Recover Ted Faro's Omega Clearance", "After intrecting with the console", "faros_tomb", true},
                    {"faros_tomb_end", "Faro's Tomb completion", "After skipping the escape cutscene", "faros_tomb", true},
                // GEMINI
                {"gemini", "Gemini", null, "mg_quests", true},
                    {"g_gemini", "Go to Gemini", "After talking to Gaia", "gemini", true},
                    {"g_node1", "Network Uplink 1", "After reaching the 1st chamber control node", "gemini", true},
                    {"g_node2", "Network Uplink 2", "After fully overriding the 2nd chamber control node", "gemini", true},
                    {"g_node3", "Network Uplink 3", "After fully overriding the Slaughterspine node", "gemini", true},
                    {"g_talk_to_beta", "Return to Beta and Varl", "Before the tragedy at Gemini", "gemini", true},
                    {"gemini_end", "Gemini completion", "After Aloy wakes up at Tilda's", "gemini", true},
                // THE WINGS OF THE TEN
                {"wings_of_the_ten", "The wings of the ten", null, "mg_quests", true},
                    {"wott_zo", "Talk to Zo", "After talking to Zo :'( T_T </3", "wings_of_the_ten", true},
                    {"wott_sunwing_override", "Mount a Sunwing", "When the cutscene starts playing", "wings_of_the_ten", true},
                    {"wott_memorial_grove", "Fly to the Memorial Grove", "When the battle cutscene starts playing", "wings_of_the_ten", true},
                    // {"wott_regalla1", "Regalla fight phase 1 passed", "After the 1st phase of Regalla fight", "wings_of_the_ten", true},
                    // {"wott_regalla2", "Regalla fight phase 2 passed", "After the 2nd phase of Regalla fight", "wings_of_the_ten", true},
                    // {"wott_regalla3", "Regalla fight phase 3 passed", "After the 3d phase of Regalla fight", "wings_of_the_ten", true},
                    {"wings_of_the_ten_end", "The wings of the ten completion", "After skipping Silence cutscene", "wings_of_the_ten", true},
                // SINGULARITY
                {"singularity", "Singularity", null, "mg_quests", true},
                    {"s_shield_skip", "Shield skip", "Meassures the infamous Far Zenith base skip", "singularity", true},
                    {"kill_erik", "Kill Erik", "After sending that mf directly to his private suite in hell", "singularity", true},
                    {"s_tower_top", "Go to the Top of the Tower", "After activating the console and skiping the cutscene at the top of the tower", "singularity", true},
                    {"s_defeat_tilda", "Defeat Tilda", "After you kill the witch", "singularity", true},
                    {"singularity_end", "Singularity completion", "When the final cutscene starts playing", "singularity", true},
        // BURNING SHORES DLC
        // ID, Label, Tool tip, Parent ID, Default setting?
        {"burning_shores", "Burning shores", "DLC splits", null, true},
            // STARTING POINTS
            {"bs_starting_points", "Starting points", "Select when livesplit will start the timer", "burning_shores", true},
                // Any% / 100%
                {"bs_start", "Any% / 100%", "After skiping the Sunwing cutscene.", "bs_starting_points", true},
            // MAIN QUESTS:
            {"bs_quests", "Quests", null, "burning_shores", true},
                // TO THE BURNING SHORES
                {"to_the_burning_shores", "To the Burning Shores", null, "bs_quests", true},
                    {"1st_encounter", "Kill the machines", "After killing the first machines at the start of Seika's cutscene", "to_the_burning_shores", true},
                    {"1st_skiff_ride", "1st skiff ride", "After interacting with the skiff for the first ride", "to_the_burning_shores", true},
                    {"seyka_tower_top", "Seyka tower cutscene", "When the cutscene at the end of the quest starts", "to_the_burning_shores", true},
                // HEAVEN AND EARTH
                {"heaven_and_earth", "Heaven and earth", null, "bs_quests", true},
                    {"hae_entrance", "Enter the facility", "After steping on the entrance area, after the OOB", "heaven_and_earth", true},
                    {"hae_skip", "Observatory skip", "After permorfing the OOB skip", "heaven_and_earth", true},
                    {"hae_caves", "Climb up the chasm", "After openning and crossing through the door at the very top of the caves", "heaven_and_earth", true},
                    {"hae_exit", "Observatory exit", "After interacting with the exit door", "heaven_and_earth", true},
                    {"hae_birds", "Examine the Base of the Statue", "After interacting with the transmitter", "heaven_and_earth", true},
                // THE STARS IN THEIR EYES
                {"tsite", "The stars in their eyes", null, "bs_quests", true},
                    {"tsite_device", "Scan the Device", "After scanning the shield node and skipping the cutscene", "tsite", true},
                    {"tsite_node1", "Northern control node", "After Seyka destroys the 1st control node", "tsite", true},
                    {"tsite_node2", "Southern control node", "After Seyka destroys the 2nd control node", "tsite", true},
                    {"tsite_guards", "Talk to the quen guards", "After talking to the guards at the gate", "tsite", true},
                    {"tsite_brenik", "Return to Brenik", "After telling Brenik the secrete code", "tsite", true},
                    {"tsite_seyka", "Talk to Seyka", "After talking to Seyka at the Ascension Hall", "tsite", true},
                    {"tsite_lockdown", "Disable the Lockdown", "After overriding the last control node at the Ascension Hall", "tsite", true},
                    {"tsite_zeth", "Defeat Zeth", "After killing that annoying moron", "tsite", true},
                    {"tsite_end", "The stars in their eyes completion", "After exiting Heaven's rest (cave exit)", "tsite", true},
                // FOR HIS AMUSEMENT
                {"fha", "For his amusement", null, "bs_quests", true},
                    {"fha_beach", "Meet Seyka at the beach", "After talking to the crying little baby", "fha", true},
                    {"fha_craft", "Craft the Waterwing override", "After crafting the override on the workbench at the shelter", "fha", true},
                    {"fha_pangea_park", "Fly and dive to Londra's park", "After arriving at Pangea Park island", "fha", true},
                    {"fha_armory_key", "The Armory key", "After recovering the key an interacting with Raptor Raid exit door", "fha", true},
                    {"fha_armory", "The Armory puzzle", "After talking to Nova and 'helping' her...", "fha", true},
                    {"fha_end", "For his amusement completion", "After killing the Slaughterspine and skipping the cutscene", "fha", true},
                // HIS FINAL ACT
                {"hfa", "His final act", null, "bs_quests", true},
                    {"hfa_pump", "Find a way to sabotage the pump", "After destroying the pump heat sinks and skipping the cutscene", "hfa", true},
                    {"hfa_heatsink1", "Destroy the abdominal heat sink", "After restarting from save", "hfa", true},
                    {"hfa_heatsink2", "Destroy the side heat sink", "After restarting from save", "hfa", true},
                    {"hfa_horus_end", "Destroy the primary heat sink in the front", "After the final phase of the Horus fight, after skipping the cutscene", "hfa", true},
                    {"hfa_londra", "Defeat Walter Londra", "After skipping the cutscene, after defeating Alondra (yes, ALONDRA)", "hfa", true},
                    {"hfa_fleets_end", "Meet seyka at fleet's end", "After talking to Seyka and Admiral Gerrit", "hfa", true},
                    {"hfa_end", "His final act completion", "After sendig Seyka directly to the friend zone with a one way ticket", "hfa", true},
                // EPILOGUE
                {"bs_epilogue", "Epilogue", null, "bs_quests", true},
                    {"bs_epilogue_sylens", "Meet Sylens in your room at the base", "After interacting with Aloy's room door", "bs_epilogue", true},

            // SIDE QUESTS:
            {"bs_sidequests", "Side quests", null, "burning_shores", true},
                // CAULDRON THETA
                {"bs_theta", "Cauldron THETA", null, "bs_sidequests", true},
                    {"theta_skip", "Cauldron THETA skip", "After overriding the shield control node", "bs_theta", true},
                    {"theta_end", "Cauldron THETA completion", "Once Aloy spawns outside the cauldron", "bs_theta", true},
                // A FRIEND IN THE DARK
                {"afitd", "A friend in the dark", null, "bs_sidequests", true},
                    {"afitd_Gildun1", "Free Gildun", "After meeting Gildun for the first time (in this game)", "afitd", true},
                    {"afitd_door2", "Unlock the door", "After unlocking the second door, after the fight", "afitd", true},
                    {"afitd_end", "A friend in the dark completion", "After giving Gildun his looking glass back", "afitd", true},
                // THE SPLINTER WITHIN
                {"tsw", "The splinter within", null, "bs_sidequests", true},
                    {"tsw_campfire", "Wait for the quen marine at the campfire", "After skipping the cutscene", "tsw", true},
                    {"tsw_rokomo", "Talk to the Quen Soldier", "After talking to Rokomo for the first time", "tsw", true},
                    {"tsw_end", "The splinter within completion", "After returning to Theoa and skipping the cutscene", "tsw", true},
                // IN HIS WAKE
                {"ihw", "In his wake", null, "bs_sidequests", true},
                    {"ihw_fight1", "First encounter", "After skipping the cutscene", "ihw", true},
                    {"ihw_fight2", "Second encounter", "After using the key at the console", "ihw", true},
                    {"ihw_weapon", "Loot Pirik's weapon", "After taking the weapon", "ihw", true},
                    {"ihw_prisoners", "Free the prisoners", "After releasing the prisoners", "ihw", true},
                    {"ihw_end", "In his wake completion", "After talking to Otosu and skipping the cutscene", "ihw", true},
                // ARENA
                {"arena", "The arena", null, "bs_sidequests", true},
                    {"ar_arena_ft", "The arena", "After fast traveling to the arena entrance", "arena", true},
                    {"ar_waterwings", "Apex Waterwings", "After successfuly completed this arena challenge", "arena", true},
                    {"ar_scrap_beasts", "Scrap Beasts", "After successfuly completed this arena challenge", "arena", true},
                    {"ar_wildfire", "Wildfire", "After successfuly completed this arena challenge", "arena", true},
                    {"ar_plasma", "Plasma and fire", "After successfuly completed this arena challenge", "arena", true},
            // 100%:
            {"bs_100", "100% additional splits", null, "burning_shores", true},
                // Scanned machines
                {"bs_scanned_machines", "Scanned machines [BETA]", "This splits are still in testing phase", "bs_100", true},
                    {"bs_scanned_bilegut", "Bilegut", "Once scanning a Bilegut for the first time", "bs_scanned_machines", true},
                    {"bs_scanned_stingspawn", "Stingspawn", "Once scanning a Stingspawn for the first time", "bs_scanned_machines", true},
                    {"bs_scanned_abilegut", "Apex Bilegut", "Once scanning an apex Bilegut for the first time", "bs_scanned_machines", true},
                    {"bs_scanned_waterwing", "Waterwing", "Once scanning a Waterwing for the first time", "bs_scanned_machines", true},
                    {"bs_scanned_awaterwing", "Apex Waterwing", "Once scanning an Apex Waterwing for the first time", "bs_scanned_machines", true},
                // Pangea figurines:
                {"bs_pangea_figurines", "Pangea figurines", null, "bs_100", true},
                    {"bs_pf_red_raptor", "Red raptor", "Once the figurine has been picked up", "bs_pangea_figurines", true},
                    {"bs_pf_dimorphodon", "Dimorphodon", "Once the figurine has been picked up", "bs_pangea_figurines", true},
                    {"bs_pf_green_raptor", "Green raptor", "Once the figurine has been picked up", "bs_pangea_figurines", true},
                    {"bs_pf_reggie", "Reggie the pterodactyl", "Once the figurine has been picked up", "bs_pangea_figurines", true},
                    {"bs_pf_queen_rex", "Queen Rex", "Once the figurine has been picked up", "bs_pangea_figurines", true},
                // Delver trinkets:
                {"bs_delver_trinkets", "Delver trinkets", null, "bs_100", true},
                    {"bs_dt_old_pot", "Old pot", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_music_box", "Music box", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_flask", "Cherished flask", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_cap", "Delver's cap", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_porker", "Lucky porker", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_pint", "Mighty pint", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                    {"bs_dt_hammer", "Hef the hammer", "Once the trinket has been picked up", "bs_delver_trinkets", true},
                // Aerial captures:
                {"bs_aerial_captures", "Aerial captures", null, "bs_100", true},
                    {"bs_ac_northeast", "Northeast", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                    {"bs_ac_north", "North", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                    {"bs_ac_northwest", "Northwest", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                    {"bs_ac_east", "East (Pangea park)", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                    {"bs_ac_west", "West", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                    {"bs_ac_south", "South", "After watching the holo at the end of the flying path", "bs_aerial_captures", true},
                // RELIC RUINS:
                {"bs_rr_murmuring_hollow", "Gather the Ornament", "After gathering the ornament hidden within Murmuring hollow", "bs_100", true},
    };

    // Contains de autosplitter checkpoints:
    vars.fullCheckpointList = new dynamic[,]{
        // Checkpoint ID, Checkpoint coordinates and radious, Checkpoint special type.
        // Main game
            // NEW GAME+ starting point
                {"NGP_start", new double[]{4098.76209477161, 976.628295635935, 657.717379307258, 0.5}, "start"},
            // TO THE BRINK
                {"chainscrape_entrance", new double[]{3513.28954696842, 657.851358029991, 491.901823297027, 0.5}, null},
                {"scroungers", new double[]{3496.16625976563, 420.995300292969, 482.579193115234, 0.5}, null},
                {"find_erend", new double[]{3449.64404296875, 149.040008544922, 496.120354248094, 0.5}, null},
                {"ttb_talk_to_erend", new double[]{3477.35424867844, 132.332365936884, 495.012577524216, 0.5}, null},
                {"clear_the_daunt", new double[]{3284.5078125, 358.046112060547, 479.179161621141, 0.5}, null},
                {"chainscrape_campfire", new double[]{3502.98200997908, 634.796115544159, 496.680757461465, 0.5}, null},
                {"talk_to_ulvund", new double[]{3514.56452074761, 631.926749546081, 491.560966397286, 0.5}, null},
                {"upgrade_bow", new double[]{3503.16166363766, 667.600455855819, 495.515878828901, 0.5}, null},
                {"to_the_brink_end", new double[]{3478.15000870147, 693.580931247833, 502.24428283851, 0.5}, null},
            // THE EMBASSY
                {"ft_barren_light_campfire", new double[]{3040.32470120382, 17.4174524381669, 465.80515145458, 0.5}, null},
                {"ft_barren_light_entrance", new double[]{3067.86206054688, 29.2767944335938, 465.452690673876, 0.5}, null},
                {"barren_light_guards", new double[]{3002.99369811482, -42.4643995791448, 460.26267730187, 0.5}, null},
                {"commander_ozar", new double[]{2984.62499824589, -60.1051657119171, 457.769683837891, 0.5}, null},
                {"the_embassy_end", new double[]{2856.36005324954, -111.985747328763, 442.737713530965, 0.5}, null},
            // DEATH'S DOOR
                {"ft_tallkneck_cinnabar_sands", new double[]{2104.01435593376, -263.975080138072, 450.963438504259, 0.5}, null},
                {"workshop_console", new double[]{1882.06305419515, -886.340802022707, 398.268561203955, 20}, "godMode"},
                {"latopolis_orb", new double[]{1419.53016905987, -1067.06460825383, 419.140068532041, 1}, "godMode"},
                {"latopolis_craft", new double[]{1466.99811286182, -1095.51017706008, 419.198201842229, 0.5}, null},
                {"latopolis_firegleam1", new double[]{1406.912723632, -1054.57499866326, 419.185678272215, 1}, "godMode"},
                {"latopolis_hatch", new double[]{1317.90443750157, -957.90438052909, 427.137498855591, 1}, "godMode"},
                {"latopolis_fight_ending", new double[]{1281.2002448612, -919.971436163863, 382.210234342071, 0.5}, null},
                {"latopolis_firegleam2", new double[]{1167.81559193197, -1016.70593891713, 382.643293593338, 3}, "godMode"},
                {"deaths_door_end", new double[]{2173.5621984611, -458.482665946886, 447.28075486375, 0.5}, null},
            // THE DYING LANDS
                {"ft_campfire_cinnabar_sands", new double[]{2087.25390625, -253.908569335938, 450.65200097661, 0.5}, null},
                {"tdl_varl_and_zo1", new double[]{1893.31334635097, 111.816643774753, 452.650905307732, 0.5}, null},
                {"tdl_varl_and_zo2", new double[]{1813.16283419915, 142.723773687015, 448.694478522055, 0.5}, null},
                {"tau_door", new double[]{1316.54252888908, -63.6133349345182, 506.381098885089, 0.5}, null},
                {"tau_control_node1", new double[]{1308.86660642313, -175.157675420581, 519.469597289899, 0.5}, null},
                {"tau_control_node2", new double[]{1273.11759062173, -126.524140426553, 521.432255727676, 0.5}, null},
                {"tau_control_node3", new double[]{1243.77344860644, -69.8571600970373, 515.476030366911, 0.5}, null},
                {"tau_core_bay", new double[]{1205.15536451275, -136.676953236032, 511.844694149086, 0.5}, null},
                {"tau_core", new double[]{1204.66921516848, -182.61169032363, 499.119144171476, 3}, "godMode"},
                // {"tdl_end", new DeepPointer("HorizonForbiddenWest.exe", SceneManagerGame, 0x180, 0x738, 0x688, 0x239), "completionFlag"},
            // THE EYE OF THE EARTH
                {"eote_minerva_console", new double[]{1126.6706505469, -173.15144282474, 604.670280642424, 0.02}, null},
                {"eote__end", new double[]{1065.82545839564, -133.980092158337, 595.294166270061, 0.5}, null},
            // THE SEA OF SANDS
                {"compressed_air_capsule", new double[]{168.197416841984, -1755.24666068276, 361.263234436512, 3}, "godMode"},
                {"diving_mask", new double[]{177.741179211531, -1751.70560600422, 379.812501915963, 0.5}, null},
                {"main_pump", new double[]{330.190289165106, -1928.76561676531, 321.221838337156, 5}, null},
                {"recover_poseidon", new double[]{375.903584454997, -1608.43782587602, 290.981902707293, 0.5}, null},
                {"las_vegas_exit", new double[]{193.733220936731, -1753.90793967061, 379.311517711234, 0.5}, null},
                {"tsos_end", new double[]{1127.60217285161, -173.180038452172, 604.699304510141, 0.02}, null},
            // THE BROKEN SKY
                {"tbs_entrance", new double[]{-561.124464789475, -700.814437511595, 421.434938894527, 0.5}, null},
                {"throne_room", new double[]{-651.099792480469, -725.424011230469, 424.443077636766, 0.5}, null},
                {"tbs_talk_to_kotallo1", new double[]{-1319.87776288786, 552.314045631327, 504.645307998755, 0.5}, null},
                {"tbs_kotallo_skip", new double[]{-1722.13056967033, 391.298481090563, 404.769377176902, 0.5}, null},
                {"bulwark_guards", new double[]{-1730.15002441406, 314.720001220703, 433.559997558594, 0.5}, null},
                {"tbs_talk_to_kotallo2", new double[]{-1733.27136230469, 469.887329101563, 370.655700683594, 0.5}, null},
                {"loot_the_tremortusk", new double[]{-1571.64681974216, 650.127638270998, 383.798339753437, 0.5}, null},
                {"broken_sky_end", new double[]{-1723.03051757813, 479.147155761719, 372.401939941454, 0.5}, null},
            // SEEDS OF THE PAST
                {"green_house", new double[]{-2298.2421875, -318.616302490234, 263.99916894536, 0.5}, null},
                {"console1_active", new double[]{-2425.85302734375, -183.151794433594, 274.627502441406, 0.5}, null},
                {"console2_room", new double[]{-2443.0078125, -299.952911376953, 262.790191650391, 0.5}, null},
                {"console2_active", new double[]{-2436.56268157932, -309.137984056258, 262.734527587883, 2.5}, "godMode"},
                {"tunnel1_exit", new double[]{-2330.46044921875, -200.520797729492, 262.781005859375, 5}, null},
                {"station_elm_console", new double[]{-2388.48193359375, -74.9281311035156, 262.702995849657, 0.5}, null},
                {"test_station_ivy", new double[]{-2448.1122551441, -101.469541747108, 259.844213518525, 2.5}, "godMode"},
                {"recover_demeter", new double[]{-2434.22285265303, -152.158308535442, 267.041717529297, 2.5}, "godMode"},
                // POSSIBLY A DEEP POINTER:
                {"sotp_end", new double[]{1126.69021617006, -173.088289075665, 604.702806330365, 0.02}, null},
            // CRADLE OF ECHOES
                {"coe_console2", new double[]{542.969725738266, 1292.93497227375, 587.041880984376, 0.5}, null},
                {"coe_specter2", new double[]{473.852036567318, 998.084829098778, 611.678522200313, 0.5}, null},
                {"coe_end", new double[]{1126.6162109375, -160.857620239258, 586.722794427189, 0.02}, null},
            // THE KULRUT
                {"ft_memorial_grove", new double[]{-536.684483707875, -689.538682652027, 417.409321179039, 0.5}, null},
                {"k_talk_to_hekarro", new double[]{-710.315347211363, -667.037382386658, 421.744580941959, 0.5}, null},
                {"k_machines", new double[]{-702.826599121094, -627.364440917969, 402.427398681641, 0.5}, null},
                {"k_Slitherfang", new double[]{-706.019287109375, -643.021606445313, 402.406517578172, 0.5}, null},
                {"recover_aether", new double[]{-645.115000369346, -723.952018067286, 410.15683428632, 0.5}, null},
                // POSSIBLY A DEEP POINTER:
                {"kulrut_end", new double[]{1126.69021616999, -173.088289075621, 604.702300013311, 0.02}, null},
            // FARO'S TOMB
                {"fst_boat", new double[]{-2990.19642267926, -1674.86461139416, 256.3049160796, 5}, null},
                {"fst_legacys_landfall", new double[]{-3899.26684570313, -902.060180664063, 261.231926513719, 0.5}, null},
                {"fst_talk_to_alva", new double[]{-4124.05110842, -756.899763504, 257.224526367, 3}, "godMode"},
                {"fst_bunker_entrance", new double[]{-4183.57373046859, -753.115051269541, 215.384563834406, 0.5}, null},
                {"fst_entrance_skip", new double[]{-4269.66085504454, -824.327741556586, 210.300998633437, 10}, null},
                {"fst_Corruptors", new double[]{-4320.63626606234, -752.726599781282, 195.796744658954, 3}, "godMode"},
                {"fst_omega_clearance", new double[]{-4339.00099401032, -706.6531888503, 171.640022814272, 0.5}, null},
                {"faros_tomb_end", new double[]{-4124.36059834746, -759.248954544443, 257.153193115285, 0.5}, null},
            // GEMINI
                {"g_gemini", new double[]{1126.75428020254, -174.590218730877, 604.691980619531, 0.02}, null},
                {"g_node1", new double[]{-348.888713246067, -131.514513890492, 327.097884915065, 0.5}, null},
                {"g_node2", new double[]{-492.760871467967, -282.555290755527, 332.496362258103, 0.5}, null},
                {"g_node3", new double[]{-339.144730091516, -278.248551935055, 322.857272032441, 0.5}, null},
                {"g_talk_to_beta", new double[]{-374.452293072273, -417.939213925904, 327.954232309294, 3}, "godMode"},
                {"gemini_end", new double[]{-2659.00016500233, -2429.99335417978, 285.01404581964, 0.5}, null},
            // THE WINGS OF THE TEN
                {"wott_zo", new double[]{1210.21069335938, -85.7714157104492, 599.363121582079, 0.5}, null},
                {"wott_sunwing_override", new double[]{1094.35817246086, -198.300083576356, 633.342505225047, 3}, "godMode"},
                {"wott_memorial_grove", new double[]{-413.221152900352, -640.554171294174, 449.722990602703, 0.5}, null},
                // {"wott_regalla1", new double[]{-736.548712368211, -670.596146410928, 425.873968463915, 9}, null},
                // {"wott_regalla2", new double[]{-725.179565429688, -637.336670875549, 402.649183273315, 9}, null},
                // {"wott_regalla3", new double[]{-723.864579582131, -641.325354661716, 402.624517784826, 0.5}, null},
                {"wings_of_the_ten_end", new double[]{-649.816218998241, -725.043389481538, 424.414696145977, 0.5}, null},
            // SINGULARITY
                {"s_shield_skip", new double[]{-1219.54711834311, -3090.94922358293, 296.551149547788, 0.5}, null},
                {"kill_erik", new double[]{-1750.06797966148, -2936.75771746821, 275.551751479856, 0.5}, null},
                {"s_tower_top", new double[]{-1777.06982410862, -2917.20605411477, 381.175567629306, 0.5}, null},
                {"s_defeat_tilda", new double[]{-1814.20812530164, -2890.07875239383, 379.655702061347, 0.5}, null},
                {"singularity_end", new double[]{-1771.61556974602, -2921.03838795219, 380.99396117125, 5}, "godMode"},
        // Burning Shores DLC
            // Any% / 100% starting point
            {"bs_start", new double[]{579.402985244988, -4744.63099183851, 272.138363853097, 0.5}, "start"},
            // MAIN QUEST:
            // TO THE BURNING SHORES
                {"1st_encounter", new double[]{579.509216308594, -4796.37451171875, 265.700012207031, 0.5}, null},
                {"1st_skiff_ride", new double[]{550.193397137225, -4888.73983266671, 256.706123883157, 3}, "godMode"},
                {"seyka_tower_top", new double[]{1314.83996582031, -5086.5498046875, 376.359985351563, 0.5}, null},
            // HEAVEN AND EARTH
                {"hae_entrance", new double[]{1681.50139808163, -4466.84910793488, 311.059579353667, 3}, null},
                {"hae_skip", new double[]{1610.56908489361, -4401.34228839236, 269.293970190135, 3}, null},
                {"hae_caves", new double[]{1665.53040831404, -4397.85957174656, 322.536962695967, 1.5}, null},
                {"hae_exit", new double[]{1688.56088969287, -4431.83438528854, 342.008026123047, 1}, "godMode"},
                {"hae_birds", new double[]{1700.8929417523, -4333.12964154039, 336.693485048051, 1}, null},
            // THE STARS IN THEIR EYES
                {"tsite_device", new double[]{671.1767578125, -4247.580078125, 364.371346056461, 0.5}, null},
                {"tsite_node1", new double[]{850.937923358551, -4247.55967300763, 334.179903984678, 0.5}, null},
                {"tsite_node2", new double[]{791.940568551686, -4334.13132739814, 336.345088257104, 0.5}, null},
                {"tsite_guards", new double[]{610.616577148438, -4180.3896484375, 355.393333984422, 0.5}, null},
                {"tsite_brenik", new double[]{585.672058105469, -4058.81665039063, 340.84414333466, 0.5}, null},
                {"tsite_seyka", new double[]{376.290186522529, -4033.02584477751, 347.723596373573, 0.5}, null},
                {"tsite_lockdown", new double[]{414.855391997958, -4078.59525948019, 347.103055190066, 1}, null},
                {"tsite_zeth", new double[]{490.881101608277, -4035.18501091004, 357.326517850161, 20}, "godMode"},
                {"tsite_end", new double[]{685.626228546476, -4232.82003793507, 366.291754902649, 5}, null},
            // FOR HIS AMUSEMENT
                {"fha_beach", new double[]{1679.49732642921, -5514.76367515274, 256.706150956685, 0.5}, null},
                {"fha_craft", new double[]{811.126218530529, -5728.98033493608, 271.906216653434, 1.5}, null},
                {"fha_pangea_park", new double[]{2054.69995325601, -5749.59179408595, 259.078674316406, 0.5}, null},
                {"fha_armory_key", new double[]{2157.78774281952, -5542.88095221416, 276.558212129631, 3}, "godMode"},
                {"fha_armory", new double[]{2414.26806624715, -5629.74023418672, 271.107658935447, 0.02}, null},
                {"fha_end", new double[]{2450.13549804688, -5519.61083984375, 276.371574951219, 0.5}, null},
            // HIS FINAL ACT
                {"hfa_pump", new double[]{-140.288650101829, -4405.51708924252, 291.169586181641, 0.5}, null},
                {"hfa_heatsink1", new double[]{-226.371047973633, -4541.36962890625, 255.631737304735, 2}, "load"},
                {"hfa_heatsink2", new double[]{-284.420972274733, -4744.3291719585, 256.311150313423, 2}, "load"},
                {"hfa_horus_end", new double[]{-395.409640753419, -5051.16508475822, 206.505044773057, 0.5}, null},
                {"hfa_londra", new double[]{525.822966525189, -5085.21922236716, 256.040630163653, 0.5}, null},
                {"hfa_fleets_end", new double[]{875.308607323886, -5281.71144685842, 286.902709960938, 0.5}, null},
                {"hfa_end", new double[]{557.655254785343, -4760.38492493345, 269.150512695315, 0.5}, null},
            // EPILOGUE
                {"bs_epilogue_sylens", new double[]{1143.77429199219, -114.443550467491, 595.744262695313, 1}, "godMode"},

            // SIDE QUESTS:
            // CAULDRON THETA
                {"theta_skip", new double[]{2582.82884434904, -4720.77054351766, 200.8623404934, 0.5}, null},
                {"theta_end", new double[]{2460.57511951495, -4921.2138186642, 384.286938799132, 0.5}, null},
            // A FRIEND IN THE DARK
            {"afitd_Gildun1", new double[]{1447.81317611019, -5524.29945726843, 328.782663334074, 0.5}, null},
            {"afitd_door2", new double[]{1345.18962729591, -5565.16709185834, 305.828236678266, 0.5}, null},
            {"afitd_end", new double[]{1339.74108886719, -5565.6025390625, 306.002899169922, 0.5}, null},
            // THE SPLINTER WITHIN
            {"tsw_campfire", new double[]{871.802062171314, -5170.43603166063, 275.356592662831, 0.5}, null},
            {"tsw_rokomo", new double[]{482.695770263672, -6017.8046875, 274.578239990282, 0.5}, null},
            {"tsw_end", new double[]{834.971971545528, -5260.93159566244, 260.218816052657, 1.5}, null},
            // IN HIS WAKE
            {"ihw_fight1", new double[]{357.012078330323, -5426.45056336841, 278.894016037032, 0.5}, null},
            {"ihw_fight2", new double[]{459.743231256395, -5428.56031121526, 285.602742426754, 1.5}, null},
            {"ihw_weapon", new double[]{554.146387487998, -5383.27608731334, 308.760219163817, 2}, null},
            {"ihw_prisoners", new double[]{570.81585802498, -5375.42744666556, 304.463432112337, 0.5}, null},
            {"ihw_end", new double[]{926.600524902344, -5207.0146484375, 275.809166503954, 0.5}, null},
            // ARENA
            {"ar_arena_ft", new double[]{-642.074339529311, -639.909989235961, 419.72826131323, 0.5}, null},
            {"ar_waterwings", new double[]{-699.745868893457, -636.915620098822, 402.383818079415, 0.75}, null},
            {"ar_scrap_beasts", new double[]{-697.177576538915, -634.871243540217, 402.365271740564, 0.75}, null},
            {"ar_wildfire", new double[]{-707.716203366027, -608.012112416244, 403.110432061751, 0.5}, null},
            {"ar_plasma", new double[]{-708.43611125974, -615.524131035898, 403.000484646731, 0.5}, null},

            // 100%:
                // Scanned machines:
                {"bs_scanned_bilegut", null, "scannedMachine"},
                {"bs_scanned_stingspawn", null, "scannedMachine"},
                {"bs_scanned_abilegut", null, "scannedMachine"},
                {"bs_scanned_waterwing", null, "scannedMachine"},
                {"bs_scanned_awaterwing", null, "scannedMachine"},
                // Pangea figurines:
                {"bs_pf_red_raptor", new double[]{2254.0838048678, -4670.81237375041, 347.046790327346, 3}, null},
                {"bs_pf_dimorphodon", new double[]{678.46577334631, -4685.19441996841, 276.498204511328, 3}, null},
                {"bs_pf_green_raptor", new double[]{1559.87037318258, -5261.95929130255, 271.947655036545, 3}, null},
                {"bs_pf_reggie", new double[]{2151.56265869878, -5636.9335026007, 280.147091183235, 3}, null},
                {"bs_pf_queen_rex", new double[]{261.787253751869, -5296.40371576509, 256.17314034581, 3}, null},
                // Delver trinkets:
                {"bs_dt_old_pot", new double[]{1920.97794938042, -4050.78969841137, 276.598048531097, 3}, null},
                {"bs_dt_music_box", new double[]{1253.15607322908, -4306.68023516095, 271.079866395179, 3}, null},
                {"bs_dt_flask", new double[]{1768.33649058513, -5220.7752206891, 262.433924331552, 3}, null},
                {"bs_dt_cap", new double[]{1301.96869671269, -5596.07021191483, 334.261349461326, 3}, null},
                {"bs_dt_porker", new double[]{1000.02972932324, -5805.72713712817, 261.445518778364, 3}, null},
                {"bs_dt_pint", new double[]{-103.364652171475, -5188.31427351914, 268.258170318277, 3}, null},
                {"bs_dt_hammer", new double[]{399.484585278808, -5701.37846541955, 282.310765716093, 3}, null},
                // Aerial captures:
                {"bs_ac_northeast", new double[]{1809.20196042182, -4416.28693400525, 339.85112327651, 5}, null},
                {"bs_ac_north", new double[]{1148.26926575496, -4628.73697115181, 296.270622050838, 5}, null},
                {"bs_ac_northwest", new double[]{680.992633763686, -4316.95435390056, 358.830697417472, 5}, null},
                {"bs_ac_east", new double[]{2014.30221502356, -5661.24461942541, 344.567425572295, 5}, null},
                {"bs_ac_west", new double[]{77.0932166504892, -5335.73164785332, 288.586175591653, 5}, null},
                {"bs_ac_south", new double[]{1042.37868057114, -4880.87407626747, 399.326339729538, 5}, null},
                // RELIC RUINS:
                {"bs_rr_murmuring_hollow", new double[]{1435.69123526547, -5500.88517475496, 328.469428990792, 3}, null},
    };

    // Correlation between machine in game name strings and autosplitter keys,
    // we use these for the scanning machine splits.
    // TODO: add machine names for other languages.
    vars.machines = new Dictionary<string, string>() {
        // {<IN_GAME_SCANNER_STRING>, <AUTOSPLITTER_KEY>}:
        { " BILEGUT",  "bs_scanned_bilegut"},
        { " STINGSPAWN",  "bs_scanned_stingspawn"},
        { " APEX BILEGUT",  "bs_scanned_abilegut"},
        { " WATERWING",  "bs_scanned_waterwing"},
        { " APEX WATERWING",  "bs_scanned_awaterwing"},
    };

    // Initialize autosplitter settings
    for (int i = 0; i < _settings.GetLength(0); i++){
        // Autosplitter settings entry:
        // settings.Add(id, default_value = true, description = null, parent = null)
        settings.Add(_settings[i, 0], _settings[i, 4], _settings[i, 1], _settings[i, 3]);

        // Tool tip message (if available)
        if(_settings[i, 2] != null){
            settings.SetToolTip(_settings[i, 0], _settings[i, 2]);
        }
    }
}

init{
    // Identifying game version:
    var module = modules.First(); // HorizonForbiddenWest.exe
    var hash = vars.Funcs.hashModule(module);

    // Default version: Patch 1.5.80.0 Steam | 9CEC6626AB60059D186EDBACCA4CE667573E8B28C916FCA1E07072002055429E
    version = "v1.5.80.0-Steam";
     // Patch 1.5.80.0 Epic games:
    if(hash == "8274587FA89612ADF904BDB2554DEA84D718B84CF691CCA9D2FB7D8D5D5D659B"){
        version = "v1.5.80.0-EpicGames";
    }else if(hash == "9CEC6626AB60059D186EDBACCA4CE667573E8B28C916FCA1E07072002055429E"){
        // Don't do anything, the default variables are the Steam ones...
    // TODO: add GOG version
    }else if(hash == "<GOG_HASH_STRING>"){
        // Update the variables...
    }
    else{
        // If no version was identified, show a warning message:
        MessageBox.Show(
            "The Autosplitter could not identify the game version, the default version was set to " + version + ".\nIf this is not the version of your game, the Autosplitter might not work properly.",
            "HFW Autosplitter",
            MessageBoxButtons.OK,
            MessageBoxIcon.Warning
        );
    }

    // Generates a split list, based on the splits selected by the user in the autosplitter settings.
    // The split list contains the split ID, type, status (reached or not) and the checkpoint coordinates
    // that trigger the split (if any). This ensures that the comparisons are performed only against this
    // smaller filtered list and not against the entire available checkpoint list:
    vars.Funcs.initSplitList = (Func<dynamic, dynamic>)((fullCheckpointList) => {
        dynamic splitLists = new ExpandoObject();
        splitLists.startingPoints = new Dictionary<string, ExpandoObject>();
        splitLists.splits = new Dictionary<string, ExpandoObject>();
        dynamic tmp = null;

        // Initialize checkpoint coordinates and pointers
        for (int i = 0; i < fullCheckpointList.GetLength(0); i++){
            //Add only user defined splits:
            if(settings[fullCheckpointList[i, 0]]){
                tmp = new ExpandoObject();
                tmp.Name = fullCheckpointList[i, 0];
                tmp.Type = fullCheckpointList[i, 2] != null ? fullCheckpointList[i, 2] : "quickSave";
                // Has the checkpoint already been reached before?
                tmp.reachedBefore = false;
                tmp.geolocation = null;

                // Position based checkpoints (most of them):
                if(fullCheckpointList[i, 1] != null){
                    tmp.geolocation = fullCheckpointList[i, 1];
                }

                // Starting points:
                if(tmp.Type == "start"){
                    splitLists.startingPoints.Add(tmp.Name, tmp);
                }
                // Splits:
                else{
                    splitLists.splits.Add(tmp.Name, tmp);
                }
            }
        }
        return splitLists;
    });

    print("Updating checkpoint list...");
    vars.splitLists = vars.Funcs.initSplitList(vars.fullCheckpointList);
}

update{
    // Debugging:
    if(current.quickSaveOcilator != old.quickSaveOcilator){
        print("\n" + current.WestEast.ToString() + ", " + current.SouthNorth.ToString() + ", " + current.DownUp.ToString() + "\n");
    }
}

isLoading{
    return (current.isLoading > 0);
}

start{
    // Starting points triggered by a quick save event:
    if(current.quickSaveOcilator != old.quickSaveOcilator){
        var checkpointQuery = vars.Funcs.isOnCheckpoint(vars.splitLists.startingPoints, current.WestEast, current.SouthNorth, current.DownUp);
        return checkpointQuery.isOnCheckpoint;
    }
}

onStart{
    // This will be executed only once per run, when the timer starts.
    // It will generate a list of checkpoints to compare based on the splits
    // selected by the user in the autosplitter settings; this way, the checkpoint
    // zone comparisons will be performed only against the few splits selected by
    // the user, and not the entiiiiiiire list of available checkpoints.
    // This is more cost efficient, because the heavy comparison (the comparison
    // against the entire checkpoint list) occurs only once (at the start of the run),
    // and not every time a split trigger is detected during the run.
    // It has to be updated every run, cause there's no direct way of catching an
    // update of the autosplitter settings, so in order to always use the most up to
    // date splits, we have to update it once per run to be sure. init{} is executed
    // only when the game is loaded, startup{} is executed only when the autosplitter
    // is loaded, none of those actions would be able to update the split list in real
    // time. update{} and split{} are executed 60 times per second by default, so those
    // are a big NO-NO:
    print("Updating checkpoint list...");
    vars.splitLists = vars.Funcs.initSplitList(vars.fullCheckpointList);
    print("Loaded splits: " + vars.splitLists.splits.Count.ToString());
}

split{
    string splitType = null;

    // Splits triggered by scanning a machine:
    if(current.scannedMachineName != null && current.scannedMachineName != old.scannedMachineName){
        if(vars.machines.ContainsKey(current.scannedMachineName)){
            print(vars.machines[current.scannedMachineName]);
            // Splits only if this segment hasn't been splited before:
            if (!vars.splitLists.splits[vars.machines[current.scannedMachineName]].reachedBefore){
                vars.splitLists.splits[vars.machines[current.scannedMachineName]].reachedBefore = true;
                print("SPLIT: " + vars.machines[current.scannedMachineName]);
                return true;
            }
        }
    }
    // Splits triggered by god mode (ex. cutscenes)
    else if(current.isGod != old.isGod && current.isGod > 0){
        splitType = "godMode";
    }
    // Splits triggered by a quick save event:
    else if(current.quickSaveOcilator != old.quickSaveOcilator){
        splitType = "quickSave";
    }
    // Splits triggered by a loading screen:
    else if(current.isLoading != old.isLoading && current.isLoading == 0){
        splitType = "load";
    }

    if(splitType != null){
        var checkpointQuery = vars.Funcs.isOnCheckpoint(vars.splitLists.splits, current.WestEast, current.SouthNorth, current.DownUp);
        if(checkpointQuery.splitName != null){
            if(
                // Checks if Aloy is over a checkpoint zone:
                checkpointQuery.isOnCheckpoint &&
                // Checks if the split type corresponds, otherwise ignores it:
                checkpointQuery.splitType == splitType
            ){
                print("SPLIT: " + checkpointQuery.splitName);
                // Updates the current segment split status, so that a segment won't be split twice:
                vars.splitLists.splits[checkpointQuery.splitName].reachedBefore = true;
                return true;
            }
        }
    }
}

onReset{
    // We don't need to reset the checkpoints status now, cause we
    // update them every start of a run.
}

exit{

}