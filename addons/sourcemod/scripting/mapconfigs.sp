// enforce semicolons after each code statement
#pragma semicolon 1
// enforce new syntax
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.4"

#define CONFIG_DIR "sourcemod/map-cfg/"



/*****************************************************************


		P L U G I N   I N F O


*****************************************************************/

public Plugin myinfo = {
	name = "Map configs",
	author = "Berni,caxanga334",
	description = "Map specific configs execution with prefix support",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=607079"
}



/*****************************************************************


		G L O B A L   V A R S


*****************************************************************/

// ConVar Handles
ConVar mc_version = null;

// Misc



/*****************************************************************


		F O R W A R D   P U B L I C S


*****************************************************************/

public void OnPluginStart() {
	
	// ConVars
	mc_version = CreateConVar("mc_version", PLUGIN_VERSION, "Map Configs plugin version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	// Set it to the correct version, in case the plugin gets updated
	mc_version.SetString(PLUGIN_VERSION);
}

public void OnAutoConfigsBuffered() {
	ExecuteMapSpecificConfigs();
}



/*****************************************************************


		P L U G I N   F U N C T I O N S


*****************************************************************/

void ExecuteMapSpecificConfigs() {
	
	char currentMap[PLATFORM_MAX_PATH], buffer[PLATFORM_MAX_PATH];
	GetCurrentMap(buffer, sizeof(buffer));
	
	// Better support for workshop maps ( in TF2, IDK about other games )
	if(!GetMapDisplayName(buffer, currentMap, sizeof(currentMap))) {
		strcopy(currentMap, sizeof(currentMap), buffer); // Use results of GetCurrentMap if GetMapDisplayName fails.
	}

	int mapSepPos = FindCharInString(currentMap, '/', true);
	if (mapSepPos != -1) {
		strcopy(currentMap, sizeof(currentMap), currentMap[mapSepPos+1]);
	}

	LogMessage("Searching specific configs for %s", currentMap);

	Handle adt_configs = CreateArray(PLATFORM_MAX_PATH);

	char cfgdir[PLATFORM_MAX_PATH];
	
	Format(cfgdir, sizeof(cfgdir), "cfg/%s", CONFIG_DIR);
	
	Handle dir = OpenDirectory(cfgdir);
	
	if (dir == null) {
		
		LogMessage("Error iterating folder %s, folder doesn't exist !", cfgdir);
		return;
	}
	
	char configFile[PLATFORM_MAX_PATH];
	char explode[2][64];
	FileType fileType;
	
	while (ReadDirEntry(dir, configFile, sizeof(configFile), fileType)) {
		if (fileType == FileType_File) {
			
			ExplodeString(configFile, ".", explode, 2, sizeof(explode[]));
			
			if (StrEqual(explode[1], "cfg", false)) {
				
				if (strncmp(currentMap, explode[0], strlen(explode[0]), false) == 0) {
					PushArrayString(adt_configs, configFile);
				}
			}
		}
	}
	
	SortADTArray(adt_configs, Sort_Ascending, Sort_String);
	
	int size = GetArraySize(adt_configs);
	
	for (int i=0; i<size; ++i) {
		GetArrayString(adt_configs, i, configFile, sizeof(configFile));
		
		LogMessage("Executing map specific config: %s", configFile);
		
		ServerCommand("exec %s%s", CONFIG_DIR, configFile);
	}
	
	delete dir;
	delete adt_configs;
	
	return;
}
