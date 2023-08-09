#if defined _Filemem_included
  #endinput
#endif
#define _Filemem_included

#include <sourcemod>

#define FILEMEM_FORMAT_STRING_LENGTH 256
#define FILEMEM_FLUSH_BYTES 256
#define FILEMEM_INVALID_ADDRESS -1

//still in development... :)

/*

----------- file memory structure -----------

char name[FILEMEM_FORMAT_STRING_LENGTH=256] 			offs: 0
int array_length  										offs: 256
int size 												offs: 260
int value_address 										offs: 264
int array_address										offs: 268
int end_address 										offs: 272
int arrays[array_length]								offs: 276
char values[size]										offs: 276 + (4 * array_length)


file memory structure size: FILEMEM_FORMAT_STRING_LENGTH + 20 + (4 * array_length) + size

*/

//file memory structure
methodmap FMS < Handle
{
	public native FMS(int addr);
	public native bool Set(any value, NumberType type=NumberType_Int32, any ...);
	public native bool Get(any& value, NumberType type=NumberType_Int32, any ...);
	public native bool SetArray(any[] value, int array_len, any ...);
	public native bool GetArray(any[] value, int array_len, any ...);
	public native bool SetString(char[] str, int str_len, any ...);
	public native bool GetString(char[] str, int str_len, any ...);
	public native bool MemSet(char value);
}

methodmap Filemem < Handle
{

	/*
		creates filemem handle and 
		register handle into filemem's stringmap

		YOU MUST CALL IT ONCE EACH EVERY PLUGINS!
		
		AND DO NOT CLOSE HANDLE!
		
		return value: filemem handle
	*/
	public native Filemem();
	
	/*
		const char[] name	-> name of file memory structure
		any ...				-> array or size
		
		Filemem.CreateValue("Var001", addr, 4); 						--> char Var001[4] 						--> int Var001
		Filemem.CreateValue("Var001", addr, 1); 						--> char Var001[1]
		Filemem.CreateValue("Var001", addr, 123, 4); 					--> char Var001[123][4] 				--> int Var001[123]
		Filemem.CreateValue("Var001", addr, 5, 4, 3, 2, 4); 			--> char Var001[5][4][3][2][4] 			--> int Var001[5][4][3][2]
		Filemem.CreateValue("Var001", addr, 256); 						--> char Var001[256]
	*/
	public native FMS CreateValue(const char[] name, any ...);
	
	public native FMS FindAddr(const char[] name);

}

native void OnFilememDestroyed();

public SharedPlugin __pl_Filemem =
{
	name = "filemem",
	file = "filemem.smx",
	required = 0,
};
