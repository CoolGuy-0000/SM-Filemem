#pragma newdecls required

#include <sourcemod>
#include <filemem>

public Plugin myinfo =
{
	name = "filemem",
	author = "CoolGuy-0000",
	description = "",
	version = "1.2",
	url = "https://github.com/CoolGuy-0000"
};


File g_FMSListFile;

public void OnNotifyPluginUnloaded(Handle plugin){
	List_DetachFromPlugin(plugin);
}

public void OnPluginStart(){
	g_FMSListFile = OpenFile("addons/sourcemod/data/fms_list.list", "w+");
	if(!g_FMSListFile)SetFailState("[Filemem]critical error!, can not create list file!");
	List_WriteDefault();
}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max){

	CreateNative("Filemem.Filemem", Native_Filemem_Filemem);
	CreateNative("Filemem.CreateValue", Native_Filemem_CreateValue);
	CreateNative("Filemem.FindAddr", Native_Filemem_FindAddr);
	CreateNative("Filemem.Close", Native_Filemem_Close);
	
	CreateNative("FMS.FMS", Native_FMS_FMS);
	CreateNative("FMS.Set", Native_FMS_Set);
	CreateNative("FMS.Get", Native_FMS_Get);
	CreateNative("FMS.SetArray", Native_FMS_SetArray);
	CreateNative("FMS.GetArray", Native_FMS_GetArray);
	CreateNative("FMS.SetString", Native_FMS_SetString);
	CreateNative("FMS.GetString", Native_FMS_GetString);
	CreateNative("FMS.MemSet", Native_FMS_MemSet);
	CreateNative("FMS.GetName", Native_FMS_GetName);
	CreateNative("FMS.GetArrayLength", Native_FMS_GetArrayLength);
	CreateNative("FMS.GetSize", Native_FMS_GetSize);
	CreateNative("FMS.GetArrayInfo", Native_FMS_GetArrayInfo);
	
	CreateNative("FMSList.FMSList", Native_FMSList_FMSList);
	CreateNative("FMSList.GetInfo", Native_FMSList_GetInfo);
	CreateNative("FMSList.Attach", Native_FMSList_Attach);
	CreateNative("FMSList.Detach", Native_FMSList_Detach);
	CreateNative("FMSList.DetachAllFilemems", Native_FMSList_DetachAllFilemems);
	
	
	CreateNative("Filemem_GetList", Native_Filemem_GetList);
	
	return APLRes_Success;
	
}

public any Native_Filemem_Filemem(Handle plugin, int num_params){
	
	char name[PLATFORM_MAX_PATH];
	GetNativeString(1, name, sizeof(name));

	return _CreateFilemem(name);
}
public any Native_Filemem_CreateValue(Handle plugin, int num_params){
	
	File filemem = GetNativeCell(1);
	
	filemem.Seek(0, SEEK_END);
	
	int addr;
	FMS _fms;
	
	addr = filemem.Position;
	
	int info[FMSListInfo_LASTID];
	
	info[FMSListInfo_FILEMEM] = view_as<int>(filemem);
	info[FMSListInfo_PLUGIN] = view_as<int>(plugin);
	info[FMSListInfo_ADDR] = addr;
	
	_fms = view_as<FMS>(List_RegisterFMS(info));
	

	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(2, name, sizeof(name));
	
	_Filemem_WriteString(filemem, name, sizeof(name));
	
	int array_len = num_params-2;
	
	filemem.WriteInt32(array_len); //array_length
	
	int later_init_pos;
	
	later_init_pos = filemem.Position;
	
	filemem.WriteInt32(0); //size
	filemem.WriteInt32(0); //value_address
	filemem.WriteInt32(0); //array_address
	filemem.WriteInt32(0); //end_address
	filemem.WriteInt32(view_as<int>(_fms)); //list_address
	filemem.Flush();
	
	int array_address, value_address, end_address;
	
	array_address = filemem.Position;
	
	int size = 1;
	
	int[] array = new int[array_len];

	for(int param = 3; param <= num_params; param++){
		array[param-3] = GetNativeCellRef(param);
		size *= array[param-3];
	}
	
	ReverseArray(array, array_len);
	
	_Filemem_WriteArray(filemem, array, array_len);
	
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
	
	return _fms;
}
public any Native_Filemem_FindAddr(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	
	char name[FILEMEM_FORMAT_STRING_LENGTH];
	GetNativeString(2, name, sizeof(name));
	
	return _Filemem_FindValue(filemem, name);
}
public any Native_Filemem_Close(Handle plugin, int num_params){
	File filemem = GetNativeCell(1);
	List_DetachFromFilemem(filemem);
	CloseHandle(filemem);
	return 0;
}



public int Native_FMS_FMS(Handle plugin, int num_params){
	return GetNativeCell(1);
}
public any Native_FMS_Set(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];


	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 4, num_params))return false;

	any value = GetNativeCell(2);
	
	NumberType type = GetNativeCell(3);
	
	switch(type){
		case NumberType_Int8:filemem.WriteInt8(value);
		case NumberType_Int16:filemem.WriteInt16(value);
		case NumberType_Int32:filemem.WriteInt32(value);
	}
	
	filemem.Flush();
	
	return true;
}
public any Native_FMS_Get(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];


	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 4, num_params))return false;
	
	NumberType type = GetNativeCell(3);
	
	any result;
	
	switch(type){
		case NumberType_Int8:filemem.ReadInt8(result);
		case NumberType_Int16:filemem.ReadInt16(result);
		case NumberType_Int32:filemem.ReadInt32(result);
	}

	SetNativeCellRef(2, result);
	
	return true;
}
public any Native_FMS_SetArray(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];
	

	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 4, num_params))return false;
	
	int array_len = GetNativeCell(3);
	
	any[] array = new any[array_len];
	GetNativeArray(2, array, array_len);

	_Filemem_WriteArray(filemem, array, array_len);
	
	return true;
}
public any Native_FMS_GetArray(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];
	

	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 4, num_params))return false;
	
	int array_len = GetNativeCell(3);
	
	any[] array = new any[array_len];
	filemem.Read(array, array_len, 4);
	
	SetNativeArray(2, array, array_len);
	
	return true;
}
public any Native_FMS_SetString(Handle plugin, int num_params){
	
	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];
	

	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 3, num_params))return false;
	
	int str_len;
	GetNativeStringLength(2, str_len);
	
	str_len++;
	
	char[] str = new char[str_len];
	GetNativeString(2, str, str_len);
	
	_Filemem_WriteString(filemem, str, str_len);
	
	return true;
}
public any Native_FMS_GetString(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];
	

	if(!_Filemem_SeekValueStartAddr(filemem, addr, NULL_STRING, 4, num_params))return false;
	
	int str_len = GetNativeCell(3);
	
	char[] str = new char[str_len];
	_Filemem_ReadString(filemem, str, str_len);
	
	SetNativeString(2, str, str_len);
	
	return true;
}
public any Native_FMS_MemSet(Handle plugin, int num_params){

	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];

	int value = GetNativeCell(2);
	
	
	int value_address;
	int end_address;
	
	filemem.Seek(addr+264, SEEK_SET);
	filemem.ReadInt32(value_address);
	filemem.Seek(addr+272, SEEK_SET);
	filemem.ReadInt32(end_address);
	
	filemem.Seek(value_address, SEEK_SET);
	
	for(int i = value_address; i < end_address; i++){
		if((i % FILEMEM_FLUSH_BYTES) == 0)filemem.Flush();
		filemem.WriteInt8(value);
	}
	
	filemem.Flush();
	return 0;
}
public any Native_FMS_GetName(Handle plugin, int num_params){
	
	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];

	int str_len = GetNativeCell(3);
	if(str_len > FILEMEM_FORMAT_STRING_LENGTH)str_len = FILEMEM_FORMAT_STRING_LENGTH;
	
	char[] str = new char[str_len];
	
	filemem.Seek(addr, SEEK_SET);
	filemem.ReadString(str, str_len, str_len);
	
	SetNativeString(2, str, str_len);
	return true;
}
public any Native_FMS_GetArrayLength(Handle plugin, int num_params){
	
	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];

	int array_length;
	
	filemem.Seek(addr+256, SEEK_SET);
	filemem.ReadInt32(array_length);
	
	SetNativeCellRef(2, array_length);
	return true;
}
public any Native_FMS_GetSize(Handle plugin, int num_params){
	
	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];

	int size;
	
	filemem.Seek(addr+260, SEEK_SET);
	filemem.ReadInt32(size);
	
	SetNativeCellRef(2, size);
	return true;
}
public any Native_FMS_GetArrayInfo(Handle plugin, int num_params){
	
	int list[FMSListInfo_LASTID];
	List_Get(list, GetNativeCell(1));
	
	File filemem = view_as<File>(list[FMSListInfo_FILEMEM]);
	int addr = list[FMSListInfo_ADDR];
	
	if(filemem == INVALID_HANDLE)SetFailState("[Filemem]memory is INVALID_HANDLE!");
	
	int array_len = GetNativeCell(3);
	int[] array = new int[array_len];
	
	int array_address;
	
	filemem.Seek(addr+268, SEEK_SET);
	filemem.ReadInt32(array_address);
	
	filemem.Seek(array_address, SEEK_SET);
	filemem.Read(array, array_len, 4);
	
	ReverseArray(array, array_len);
	
	SetNativeArray(2, array, array_len);
	
	return true;
}

public any Native_FMSList_FMSList(Handle plugin, int num_params){
	return g_FMSListFile;
}
public any Native_FMSList_GetInfo(Handle plugin, int num_params){
	int info[FMSListInfo_LASTID];
	List_Get(info, GetNativeCell(2));
	SetNativeArray(3, info, sizeof(info));
	return 0;
}
public any Native_FMSList_Attach(Handle plugin, int num_params){
	int info[FMSListInfo_LASTID];
	GetNativeArray(2, info, sizeof(info));
	List_RegisterFMS(info);
	return 0;
}
public any Native_FMSList_Detach(Handle plugin, int num_params){
	List_DetachFromFilemem(GetNativeCell(2));
	return 0;
}
public any Native_FMSList_DetachAllFilemems(Handle plugin, int num_params){
	Handle target = GetNativeCell(2);
	if(target == INVALID_HANDLE)target = plugin;
	
	List_DetachFromPlugin(target);
	return 0;
}

public any Native_Filemem_GetList(Handle plugin, int num_params){
	return g_FMSListFile;
}

File _CreateFilemem(const char[] name){
	char fms_name[PLATFORM_MAX_PATH];
	Format(fms_name, sizeof(fms_name), "addons/sourcemod/data/%s.fms", name);
		
	File filemem = OpenFile(fms_name, "w+");
	
	if(!filemem){
		SetFailState("[Filemem]cannot open file -> %s", fms_name);
		return view_as<File>(INVALID_HANDLE);
	}
	
	return filemem;
}

void List_WriteDefault(){
	int info[FMSListInfo_LASTID];
	
	info[FMSListInfo_FILEMEM] = 0;
	info[FMSListInfo_PLUGIN] = 0;
	info[FMSListInfo_ADDR] = FILEMEM_INVALID_ADDRESS;
	
	List_RegisterFMS(info);
}

int List_GetLastIdAddr(){
	g_FMSListFile.Seek(0, SEEK_SET);

	int info[FMSListInfo_LASTID];
	
	while(g_FMSListFile.Read(info, sizeof(info), 4))
		if(info[FMSListInfo_FILEMEM] == 0 || info[FMSListInfo_PLUGIN] == 0)return g_FMSListFile.Position-12;
	
	return g_FMSListFile.Position;
}
int List_RegisterFMS(int info[FMSListInfo_LASTID]){
	int last_addr = List_GetLastIdAddr();
	g_FMSListFile.Seek(last_addr, SEEK_SET);
	g_FMSListFile.Write(info, sizeof(info), 4);
	g_FMSListFile.Flush();
	return last_addr;
}
void List_DetachFromPlugin(Handle plugin){
	
	int info[FMSListInfo_LASTID];
	
	g_FMSListFile.Seek(0, SEEK_SET);
	
	while(g_FMSListFile.Read(info, sizeof(info), 4)){
		if(info[FMSListInfo_PLUGIN] == view_as<int>(plugin)){
			info[FMSListInfo_FILEMEM] = 0;
			info[FMSListInfo_PLUGIN] = 0;
			g_FMSListFile.Seek(g_FMSListFile.Position-12, SEEK_SET);
			g_FMSListFile.Write(info, sizeof(info), 4);
			g_FMSListFile.Flush();
		}
	}
	
}
void List_DetachFromFilemem(File filemem){
	int info[FMSListInfo_LASTID];
	
	g_FMSListFile.Seek(0, SEEK_SET);
	
	while(g_FMSListFile.Read(info, sizeof(info), 4)){
		if(info[FMSListInfo_FILEMEM] == view_as<int>(filemem)){
			info[FMSListInfo_FILEMEM] = 0;
			info[FMSListInfo_PLUGIN] = 0;
			g_FMSListFile.Seek(g_FMSListFile.Position-12, SEEK_SET);
			g_FMSListFile.Write(info, sizeof(info), 4);
			g_FMSListFile.Flush();
		}
	}
}
void List_Get(int info[FMSListInfo_LASTID], int addr){
	g_FMSListFile.Seek(addr, SEEK_SET);
	g_FMSListFile.Read(info, sizeof(info), 4);
}

int _Filemem_FindValue(File filemem, const char[] name){
	char target_name[FILEMEM_FORMAT_STRING_LENGTH];
	
	filemem.Seek(0, SEEK_SET);
	
	int pos;
	
	while(filemem.ReadString(target_name, sizeof(target_name), sizeof(target_name))){
		if(StrEqual(name, target_name)){
			filemem.Seek(20, SEEK_CUR);
			filemem.ReadInt32(pos);
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
		ReverseArray(array, array_count);
	}
	
	int offset;
	offset = _Filemem_ArrayIndexToOffset(filemem, header_pos, array, array_len);
	
	int value_address;
	
	filemem.Seek(header_pos+264, SEEK_SET);
	filemem.ReadInt32(value_address);
	
	filemem.Seek(value_address+offset, SEEK_SET);
	return true;
}

void ReverseArray(int[] array, int array_count){
	int[] _array = new int[array_count];
	int i2;
	for(int i = array_count-1; i >= 0; i--){
		_array[i2] = array[i];
		i2++;
	}
	for(int i = 0; i < array_count; i++)array[i] = _array[i];
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

