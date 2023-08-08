#if defined _Filemem_included
  #endinput
#endif
#define _Filemem_included

#define FILEMEM_FORMAT_STRING_LENGTH 256
#define FILEMEM_FLUSH_BYTES 256
#define FILEMEM_INVALID_ADDRESS -1

/*

----------- file memory structure -----------

char name[FILEMEM_FORMAT_STRING_LENGTH] 				offs: 0
int array_length  							offs: FILEMEM_FORMAT_STRING_LENGTH
int size 								offs: FILEMEM_FORMAT_STRING_LENGTH + 4
int value_address 							offs: FILEMEM_FORMAT_STRING_LENGTH + 8
int array_address							offs: FILEMEM_FORMAT_STRING_LENGTH + 12
int end_address 							offs: FILEMEM_FORMAT_STRING_LENGTH + 16
int arrays[array_length]						offs: FILEMEM_FORMAT_STRING_LENGTH + 20
char values[size]							offs: FILEMEM_FORMAT_STRING_LENGTH + 20 + (4 * array_length)


file memory structure size: FILEMEM_FORMAT_STRING_LENGTH + 20 + (4 * array_length) + size

*/


/*

creates filemem handle and 
register handle into filemem's stringmap

YOU MUST CALL IT ONCE EACH EVERY PLUGINS!

return value: filemem handle

*/
native Handle Filemem_Create();

/*

Handle filemem  		-> target memory to create value if INVALID_HANDLE, then calling plugin's filemem used.
const char[] name		-> name of file memory structure
int& addr			-> address of file memory structure header(offs: 0)
any ...				-> array or size

Filemem_CreateValue(filemem, "Var001", addr, 4); 	--> it creates file memory structure that named 'Var001' and size of intager(4 bytes)

							--> basically, it's same as int Var001


Filemem_CreateValue(filemem, "Var001", addr, 1); 		--> char Var001
Filemem_CreateValue(filemem, "Var001", addr, 4, 123); 		--> int Var001[123]
Filemem_CreateValue(filemem, "Var001", addr, 4, 3, 2, 1); 	--> int Var001[3][2][1]
Filemem_CreateValue(filemem, "Var001", addr, 1, 256); 		--> char Var001[256]


return value: if it successfully created value then true, otherwise false(filemem is invalid)
*/

native bool Filemem_CreateValue(Handle filemem=INVALID_HANDLE, const char[] name, int& addr=FILEMEM_INVALID_ADDRESS, any ...);

/*

int addr			-> if FILEMEM_INVALID_ADDRESS, then find file memory structure with `name`
const char[] name 	-> if NULL_STRING or invalid name, then it fails(return false)
any ...				-> array index

Filemem_SetValue(filemem, _, "Var001", 32, false, 0, 4);				--> Var001[4] = 32
Filemem_SetValue(filemem, _, "Var001", 'C', true, 1);					--> (char)Var001[1] = 'C'
Filemem_SetValue(filemem, _, "Var001", 3, false, 0, 5, 4, 3, 2, 1)  			--> Var001[5][4][3][2][1] = 3


return value: if address cannot found or filemem is invalid then false, otherwise true
*/
native bool Filemem_SetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any value, bool IsChar, any ...);

native bool Filemem_GetValue(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, any& value, bool IsChar, any ...);
native bool Filemem_SetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, any[] value, bool IsString, any ...);
native bool Filemem_GetArray(Handle filemem=INVALID_HANDLE, int addr=FILEMEM_INVALID_ADDRESS, const char[] name=NULL_STRING, int array_len, any[] value, bool IsString, any ...);

/*

find address by name

return value: file memory structure header(offs: 0)

*/
native int Filemem_FindAddr(Handle filemem=INVALID_HANDLE, const char[] name);

public SharedPlugin __pl_Filemem =
{
	name = "filemem",
	file = "filemem.smx",
	required = 0,
};
