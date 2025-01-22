
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

asm equates {
kernel32_THREAD_BASE_PRIORITY_LOWRT = 15
kernel32_THREAD_PRIORITY_TIME_CRITICAL = kernel32_THREAD_BASE_PRIORITY_LOWRT
}
