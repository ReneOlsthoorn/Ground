
dll kernel32 function Sleep(int milliseconds);
dll kernel32 function CreateThread(int threadAttributes, int stacksize, ptr startAddress, int parameter, int creationFlags, ptr threadId);
dll kernel32 function WaitForSingleObject(int handle, int milliseconds);
dll kernel32 function CloseHandle(int handle);
dll kernel32 function ExitThread(int exitCode);
dll kernel32 function GetCurrentThread() : ptr;
dll kernel32 function GetCurrentProcess() : ptr;
dll kernel32 function GetThreadPriority(ptr threadhandle) : int;
dll kernel32 function SetThreadPriority(ptr threadhandle, int priority);
dll kernel32 function GetPriorityClass(ptr processhandle) : int;
dll kernel32 function SetPriorityClass(ptr processhandle, int priorityClass);
dll kernel32 function CreatePipe(u64 hReadPipe, u64 hWritePipe, u64 lpPipeAttributes, u32 nSize) : bool;
dll kernel32 function SetHandleInformation(u64 hObject, u32 dwMask, u32 dwFlags) : bool;
dll kernel32 function CreateProcessA(string lpApplicationName, int lpCommandLine, int lpProcessAttributes, int lpThreadAttributes, bool bInheritHandles, u32 dwCreationFlags, ptr lpEnvironment, ptr lpCurrentDirectory, ptr lpStartupInfo, ptr lpProcessInformation) : bool;
dll kernel32 function ReadFile(int hFile, ptr lpBuffer, u32 nNumberOfBytesToRead, ptr lpNumberOfBytesRead, ptr lpOverlapped) : bool;
dll kernel32 function WriteFile(int hFile, ptr lpBuffer, u32 nNumberOfBytesToWrite, ptr lpNumberOfBytesWritten, ptr lpOverlapped) : bool;
dll kernel32 function TerminateProcess(ptr processhandle, int exitcode) : int;

asm equates {
kernel32_THREAD_BASE_PRIORITY_LOWRT = 15
kernel32_THREAD_PRIORITY_TIME_CRITICAL = kernel32_THREAD_BASE_PRIORITY_LOWRT
kernel32_HANDLE_FLAG_INHERIT = 0x00000001
kernel32_STARTF_USESTDHANDLES = 0x00000100
kernel32_CREATE_NO_WINDOWS = 0x08000000
kernel32_STARTF_USESHOWWINDOW = 0x00000001
kernel32_SW_HIDE = 0
kernel32_CREATE_NO_WINDOWS = 0x08000000
}
