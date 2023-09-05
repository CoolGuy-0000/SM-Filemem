#if defined _Filemem_included
  #endinput
#endif
#define _Filemem_included

#include <sourcemod>

#define FILEMEM_MANAGER_BLOCK_SIZE 256
#define FILEMEM_FORMAT_STRING_LENGTH 256
#define FILEMEM_FLUSH_BYTES 256
#define FILEMEM_INVALID_ADDRESS -1

/*

----------- file memory structure -----------

char name[FILEMEM_FORMAT_STRING_LENGTH=256] 							offs: 0
int array_length  										offs: 256
int size 											offs: 260
int value_address 										offs: 264
int array_address										offs: 268
int end_address 										offs: 272
int list_address										offs: 276
int arrays[array_length]									offs: 280
char values[size]										offs: 280 + (4 * array_length)


*/




//file memory structure
methodmap FMS
{
	public native FMS(int addr);
	public native bool Set(any value, NumberType type=NumberType_Int32, any ...);
	public native bool Get(any& value, NumberType type=NumberType_Int32, any ...);
	public native bool SetArray(any[] value, int array_len, any ...);
	public native bool GetArray(any[] value, int array_len, any ...);
	public native bool SetString(char[] str, int str_len, any ...);
	public native bool GetString(char[] str, int str_len, any ...);
	public native bool MemSet(char value);
	
	public native bool GetName(char[] str, int str_len);
	public native bool GetArrayLength(int& len);
	public native bool GetSize(int& size);
	public native bool GetArrayInfo(int[] array, int array_len);
}


methodmap Filemem < Handle
{

	/*
		return value: filemem handle
	*/
	public native Filemem(const char[] name);

	/*
		const char[] name	-> name of file memory structure
		any ...				-> array or size
		
		Filemem.CreateValue("Var001", 4); 						--> char Var001[4] 				--> int Var001
		Filemem.CreateValue("Var001", 1); 						--> char Var001[1]
		Filemem.CreateValue("Var001", 123, 4); 						--> char Var001[123][4] 			--> int Var001[123]
		Filemem.CreateValue("Var001", 5, 4, 3, 2, 4); 					--> char Var001[5][4][3][2][4] 			--> int Var001[5][4][3][2]
		Filemem.CreateValue("Var001", 256); 						--> char Var001[256]
	*/
	public native FMS CreateValue(const char[] name, any ...);
	
	public native FMS FindAddr(const char[] name);
	
	public native void Close();
	
}

native File Filemem_GetList();


public SharedPlugin __pl_Filemem =
{
	name = "filemem",
	file = "filemem.smx",
	required = 0,
};
