#pragma newdecls required

#include <sourcemod>
#include <filemem>

public Plugin myinfo =
{
	name = "filemem",
	author = "CoolGuy-0000",
	description = "",
	version = "1.0",
	url = "https://github.com/CoolGuy-0000"
};


StringMap g_strmap;

public void OnNotifyPluginUnloaded(Handle plugin){
	char szPluginIndex[25];
	File filemem;
	IntToString(view_as<int>(plugin), szPluginIndex, sizeof(szPluginIndex));
	
	if(g_strmap.GetValue(szPluginIndex, filemem)){
		CloseHandle(filemem);
		g_strmap.Remove(szPluginIndex);
	}
}

public void OnPluginStart(){
	g_strmap = CreateTrie();
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){

	CreateNative("Filemem_Create", Native_Filemem_Create);
	CreateNative("Filemem_CreateValue", Native_Filemem_CreateValue);
	CreateNative("Filemem_SetValue", Native_Filemem_SetValue);
	CreateNative("Filemem_GetValue", Native_Filemem_GetValue);
	CreateNative("Filemem_SetArray", Native_Filemem_SetArray);
	CreateNative("Filemem_GetArray", Native_Filemem_GetArray);
	CreateNative("Filemem_FindAddr", Native_Filemem_FindAddr);
	return APLRes_Success;
}

//Handle Filemem_Create();
public any Native_Filemem_Create(Handle plugin, int num_params){

	File filemem = GetPluginFilemem(plugin);
	
	if(filemem)return INVALID_HANDLE;
	
	char plugin_name[PLATFORM_MAX_PATH];
	
	GetPluginFilename(plugin, plugin_name, sizeof(plugin_name));
	Format(plugin_name, sizeof(plugin_name), "addons/sourcemod/data/%s.fms", plugin_name);
	
	filemem = OpenFile(plugin_name, "w+");
	if(!filemem){
		SetFailState("[Filemem]cannot open file -> %s", plugin_name);
		return INVALID_HANDLE;
	}
	
	char szPluginIndex[25];
	IntToString(view_as<int>(plugin), szPluginIndex, sizeof(szPluginIndex));
	
	g_strmap.SetValue(szPluginIndex, filemem, true);
	return filemem;
}

//bool Filemem_CreateValue(Handle filemem=INVALID_HANDLE, const char[] name, int& addr, any ...);
public any Native_Filemem_CreateValue(Handle plugin, int num_params){
	
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	filemem.Seek(0, SEEK_END);
	
	int addr;
	addr = filemem.Position;
	SetNativeCellRef(3, addr);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(2, name, sizeof(name));
	
	_Filemem_WriteString(filemem, name, sizeof(name));
	
	int array_len = num_params-3;
	
	filemem.WriteInt32(array_len); //array_length
	
	int later_init_pos;
	
	later_init_pos = filemem.Position;
	
	filemem.WriteInt32(0); //size
	filemem.WriteInt32(0); //value_address
	filemem.WriteInt32(0); //array_address
	filemem.WriteInt32(0); //end_address
	filemem.Flush();
	
	int array_address, value_address, end_address;
	
	array_address = filemem.Position;
	
	int size = 1;
	
	for(int param = 4; param <= num_params; param++){
		if((param % (FILEMEM_FLUSH_BYTES/4) ) == 0)filemem.Flush();
		
		int array_value = GetNativeCellRef(param);
		filemem.WriteInt32(array_value);
		size *= array_value;
	}
	filemem.Flush();
	
	value_address = filemem.Position;
	
	for(int i = 0; i < size; i++){
		if((i % FILEMEM_FLUSH_BYTES) == 0)filemem.Flush();
		filemem.WriteInt8(0);
	}
	
	filemem.Flush();
	
	end_address = filemem.Position;
	
	filemem.Seek(later_init_pos, SEEK_SET);
	
	filemem.WriteInt32(size); //size
	filemem.WriteInt32(value_address); //value_address
	filemem.WriteInt32(array_address); //array_address
	filemem.WriteInt32(end_address); //end_address
	
	filemem.Flush();
	
	return true;
}
//bool Filemem_SetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any value, bool IsChar, any ...);
public any Native_Filemem_SetValue(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	int addr;
	addr = GetNativeCell(2);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(3, name, sizeof(name));
		
	if(!_Filemem_SeekValueStartAddr(filemem, addr, name, 6, num_params))return false;

	any value;
	value = GetNativeCell(4);
	
	bool IsChar;
	IsChar = GetNativeCell(5);
	
	if(IsChar)filemem.WriteInt8(value);
	else filemem.WriteInt32(value);
	
	filemem.Flush();
	
	return true;
}
//bool Filemem_GetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any& value, bool IsChar, any ...);
public any Native_Filemem_GetValue(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	int addr;
	addr = GetNativeCell(2);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(3, name, sizeof(name));
	
	if(!_Filemem_SeekValueStartAddr(filemem, addr, name, 6, num_params))return false;
	
	bool IsChar;
	IsChar = GetNativeCell(5);
	
	any result;
	
	if(IsChar)filemem.ReadInt8(result);
	else filemem.ReadInt32(result);

	SetNativeCellRef(4, result);
	
	return true;
}
//bool Filemem_SetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, any[] value, bool IsString, any ...);
public any Native_Filemem_SetArray(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	int addr;
	addr = GetNativeCell(2);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(3, name, sizeof(name));
	
	if(!_Filemem_SeekValueStartAddr(filemem, addr, name, 7, num_params))return false;
	
	int array_len;
	array_len = GetNativeCell(4);
	
	bool IsString;
	IsString = GetNativeCell(6);
	
	if(IsString){
		char[] array = new char[array_len];
		GetNativeString(5, array, array_len);
		_Filemem_WriteString(filemem, array, array_len);
	}
	else{
		int[] array = new int[array_len];
		GetNativeArray(5, array, array_len);
		_Filemem_WriteArray(filemem, array, array_len);
	}

	return true;
}
//bool Filemem_GetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, any[] value, bool IsString, any ...);
public any Native_Filemem_GetArray(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	int addr;
	addr = GetNativeCell(2);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(3, name, sizeof(name));
	
	if(!_Filemem_SeekValueStartAddr(filemem, addr, name, 7, num_params))return false;
	
	int array_len;
	array_len = GetNativeCell(4);
	
	bool IsString;
	IsString = GetNativeCell(6);

	if(IsString){
		char[] array = new char[array_len];
		_Filemem_ReadString(filemem, array, array_len);
		SetNativeString(5, array, array_len);
	}
	else{
		int[] array = new int[array_len];
		filemem.Read(array, array_len, 4);
		SetNativeArray(5, array, array_len);
	}
	
	return true;
}
//int Filemem_FindAddr(Handle filemem=INVALID_HANDLE, const char[] name);
public any Native_Filemem_FindAddr(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	if(filemem == INVALID_HANDLE){
		filemem = GetPluginFilemem(plugin);
		if(!filemem)return false;
	}
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(2, name, sizeof(name));
	
	return _Filemem_FindValue(filemem, name);
}

File GetPluginFilemem(Handle plugin){
	char szPluginIndex[25];
	IntToString(view_as<int>(plugin), szPluginIndex, sizeof(szPluginIndex));

	File filemem;
	g_strmap.GetValue(szPluginIndex, filemem);
	return filemem;
}

int _Filemem_FindValue(File filemem, const char[] name){
	char target_name[FILEMEM_FORMAT_STRING_LENGTH];
	
	filemem.Seek(0, SEEK_SET);
	
	int pos;
	
	while(filemem.ReadString(target_name, sizeof(target_name), sizeof(target_name))){
		if(StrEqual(name, target_name)){
			filemem.Seek(pos, SEEK_SET);
			return pos;
		}
		
		filemem.Seek(16, SEEK_CUR);
		filemem.ReadInt32(pos);
		filemem.Seek(pos, SEEK_SET);
	}
	
	return FILEMEM_INVALID_ADDRESS;
}

int _Filemem_ArrayIndexToOffset(File filemem, int header_pos, int[] array, int array_length){
	filemem.Seek(header_pos+256, SEEK_SET);
	
	int array2_len;
	filemem.ReadInt32(array2_len);
	
	filemem.Seek(header_pos+268, SEEK_SET);
	
	int array2_address;
	filemem.ReadInt32(array2_address);
	
	filemem.Seek(array2_address, SEEK_SET);
	
	
	int array2_value;
	int total_size = 1;
	int offset;
	
	for(int i = 0; i < array2_len; i++){
		if(i == array_length)break;
		filemem.ReadInt32(array2_value);
		offset += total_size*array[i];
		total_size *= array2_value;
	}

	return offset;
}

bool _Filemem_SeekValueStartAddr(File filemem, int addr, const char[] name, int array_arg_start, int num_params){
	int header_pos = addr;
	
	if(header_pos == FILEMEM_INVALID_ADDRESS){
		header_pos = _Filemem_FindValue(filemem, name);
		if(header_pos == FILEMEM_INVALID_ADDRESS)return false;
	}

	int array_len = num_params-(array_arg_start-1);
	int[] array = new int[array_len+1];
	int array_count;

	if(array_len == 0){
		array_len = 1;
		array[0] = 0;
	}
	else{
		for(int param = array_arg_start; param <= num_params; param++){
			array[array_count] = GetNativeCellRef(param);
			array_count++;
		}
	}
	
	int offset;
	offset = _Filemem_ArrayIndexToOffset(filemem, header_pos, array, array_len);
	
	int value_address;
	
	filemem.Seek(header_pos+264, SEEK_SET);
	filemem.ReadInt32(value_address);
	
	filemem.Seek(value_address+offset, SEEK_SET);
	return true;
}


void _Filemem_WriteString(File filemem, const char[] str, int count){
	for(int i = 0; i < count; i++){
		if((i % FILEMEM_FLUSH_BYTES) == 0)filemem.Flush();
		filemem.WriteInt8(str[i]);
	}
	filemem.Flush();
}
void _Filemem_WriteArray(File filemem, any[] array, int count){
	for(int i = 0; i < count; i++){
		if((i % (FILEMEM_FLUSH_BYTES/4)) == 0)filemem.Flush();
		filemem.WriteInt32(array[i]);
	}
	filemem.Flush();
}

void _Filemem_ReadString(File filemem, char[] str, int str_len){
	int val;
	
	for(int i = 0; i < str_len; i++){
		filemem.ReadInt8(val);
		str[i] = val;
	}
}

