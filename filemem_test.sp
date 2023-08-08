#include <sourcemod>
#include <filemem>

Handle g_myfile;


public void OnPluginStart(){

	g_myfile = Filemem_Create();
	
	int VarAddrs[3];
	
	Filemem_CreateValue(g_myfile, "Var001", VarAddrs[0], 4); //int Var001
	Filemem_CreateValue(g_myfile, "Var002", VarAddrs[1], 4); //int Var002
	Filemem_CreateValue(g_myfile, "Var003", VarAddrs[2], 4); //int Var003
	
	Filemem_CreateValue(g_myfile, "VarList", _, 4, 3); //int VarList[3]
	
	Filemem_SetValue(g_myfile, _, "Var001", 1234, false); //Var001 = 1234
	Filemem_SetValue(g_myfile, _, "Var002", 5401, false); //Var002 = 5401
	Filemem_SetValue(g_myfile, _, "Var003", 4889, false); //Var003 = 4889
	
	Filemem_SetValue(g_myfile, _, "VarList", VarAddrs[0], false, 0, 0); //VarList[0] = &Var001
	Filemem_SetValue(g_myfile, _, "VarList", VarAddrs[1], false, 0, 1); //VarList[1] = &Var002
	Filemem_SetValue(g_myfile, _, "VarList", VarAddrs[2], false, 0, 2); //VarList[2] = &Var003
	
	int VarPointers[3];
	int VarValues[3];
	
	Filemem_GetArray(g_myfile, _, "VarList", sizeof(VarPointers), VarPointers, false, 0, 0);

	Filemem_GetValue(g_myfile, VarPointers[0], _, VarValues[0], false); //VarValues[0] = *VarList[0]  
	Filemem_GetValue(g_myfile, VarPointers[1], _, VarValues[1], false); //VarValues[1] = *VarList[1]  
	Filemem_GetValue(g_myfile, VarPointers[2], _, VarValues[2], false); //VarValues[2] = *VarList[2]  
	
	PrintToServer("Var2Values: %d, %d, %d", VarValues[0], VarValues[1], VarValues[2]);
	
}

