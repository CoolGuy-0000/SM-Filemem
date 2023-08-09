#include <sourcemod>
#include <filemem>

Filemem g_flm;

FMS g_Var[4];
FMS g_Pointer001;
FMS g_Array001;
FMS g_Array002;
FMS g_String001;
FMS g_String002;

void CreateVariables(){
	g_Var[0] = g_flm.CreateValue("Var001", 4);
	g_Var[1] = g_flm.CreateValue("Var002", 4);
	g_Var[2] = g_flm.CreateValue("Var003", 4);
	g_Var[3] = g_flm.CreateValue("Var004", 4);
	g_Pointer001 = g_flm.CreateValue("Pointer001", 4, 4);
	g_Array001 = g_flm.CreateValue("Array001", 5, 4);
	g_Array002 = g_flm.CreateValue("Array002", 5, 4);
	g_String001 = g_flm.CreateValue("String001", 128);
	g_String002 = g_flm.CreateValue("String002", 128);
	
	g_Var[0].Set(376);
	g_Var[1].Set(442);
	g_Var[2].Set(310);
	g_Var[3].Set(566);

}

void GetSet_Test(){
	g_Var[0].Set(123);
	
	int value;
	g_Var[0].Get(value);
	
	PrintToServer("[Filemem]Test #Normal - %d", value);
}
void Pointer_Test(){
	g_Pointer001.Set(g_Var[0], _, 0, 0);
	g_Pointer001.Set(g_Var[1], _, 1, 0);
	g_Pointer001.Set(g_Var[2], _, 2, 0);
	g_Pointer001.Set(g_Var[3], _, 3, 0);
	
	FMS random_var;
	g_Pointer001.Get(random_var, _, 0, GetRandomInt(0, 3));
	
	int value;
	random_var.Get(value);
	
	PrintToServer("[Filemem]Test #Pointer - %d", value);
}
void Array_Test(){

	g_Array001.SetArray({5, 6, 7, 8, 9}, 5);
	g_Array002.SetArray({10, 10, 10, 10, 10}, 5);
	
	int array1[5], array2[5];
	
	g_Array001.GetArray(array1, sizeof(array1));
	g_Array002.GetArray(array2, sizeof(array2));
	
	
	array1[0] += array2[0];
	array1[1] += array2[1];
	array1[2] += array2[2];
	array1[3] += array2[3];
	array1[4] += array2[4];
	
	PrintToServer("[Filemem]Test #Array - %d, %d, %d, %d, %d", array1[0], array1[1], array1[2], array1[3], array1[4]); 
	
}
void String_Test(){
	g_String001.SetString("hello world", strlen("hello_world")+1);
	g_String002.SetString(" Filemem Is Working!", strlen(" Filemem Is Working!")+1);
	
	char str1[128], str2[128];
	
	g_String001.GetString(str1, sizeof(str1));
	g_String002.GetString(str2, sizeof(str2));
	
	StrCat(str1, sizeof(str1), str2);
	
	PrintToServer("[Filemem]Test #String - %s", str1);
}
void MemSet_Test(){
	g_Array001.MemSet(0);
	
	int value;
	g_Array001.Get(value, _, 3, 0);
	
	PrintToServer("[Filemem]Test #MemSet - %d", value);
}

public void OnPluginStart(){
	g_flm = new Filemem();
	
	CreateVariables();
	
	GetSet_Test();
	Pointer_Test();
	Array_Test();
	String_Test();
	MemSet_Test();
	
	//CloseHandle(g_flm); DO NOT CLOSE HANDLE!!
}
