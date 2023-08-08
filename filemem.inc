#if defined _Filemem_included
  #endinput
#endif
#define _Filemem_included

#define FILEMEM_FORMAT_STRING_LENGTH 256
#define FILEMEM_FLUSH_BYTES 256
#define FILEMEM_INVALID_ADDRESS -1

native Handle Filemem_Create();
native bool Filemem_CreateValue(Handle filemem=INVALID_HANDLE, const char[] name, int& addr=FILEMEM_INVALID_ADDRESS, any ...);

native bool Filemem_SetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any value, 		bool IsChar, 						any ...);
native bool Filemem_GetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any& value, 		bool IsChar, 						any ...);
native bool Filemem_SetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, 	any[] value, 	bool IsString, 	any ...);
native bool Filemem_GetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, 	any[] value, 	bool IsString, 	any ...);

native int Filemem_FindAddr(Handle filemem=INVALID_HANDLE, const char[] name);

public SharedPlugin __pl_Filemem =
{
	name = "filemem",
	file = "filemem.smx",
	required = 0,	
};
