
class OPENFILENAMEA {  //sizeof: 152 bytes
	u32	lStructSize;
	u64 hwndOwner;
	u64	hInstance;
	u64	lpstrFilter;
	u64	lpstrCustomFilter;
	u32	nMaxCustFilter;
	u32	nFilterIndex;
	u64	lpstrFile;
	u32	nMaxFile;
	u64	lpstrFileTitle;
	u32	nMaxFileTitle;
	u64	lpstrInitialDir;
	u64	lpstrTitle;
	u32	Flags;
	u16	nFileOffset;
	u16	nFileExtension;
	u64	lpstrDefExt;
	u64 lCustData;
	u64	lpfnHook;
	u64	lpTemplateName;
	u64 pvReserved;
	u32	dwReserved;
	u32	FlagsEx;
}

dll comdlg32 function GetOpenFileNameA(ptr structobj) : bool;
dll comdlg32 function GetSaveFileNameA(ptr structobj);
