# Ground

Compiler for the programming language Ground. The compiler itself is created in C# and generates FASM x86-64 assembly.
Ground allows x86-64 assembly language to be added anywhere in the code. Mixing Ground- and assembly is 
possible due to generated symbolic constants for each local Ground variable.  
The primary usecase for Ground is creating highspeed programs.  
The code that Ground generates is poured in an assembly template which can be freely chosen. This will result in
small .EXE files when the template is chosen wisely. For instance, there is a "console" template, but also a "sdl3" 
template which loads the SDL3.dll and SDL3_image.dll. Ofcourse you can create your own template. A second reason why 
the .EXE will remain small is that all external code is loaded at load-time. The usage of the known system DLL's, 
like msvcrt, is promoted.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Smoothscroller.jpg?raw=true" width="500" />
</p>

The central concept of Ground is the ability to replace a statement with x86-64. So for example we have the following
code in mode7.g:
```
		for (int x = 0; x < g.GC_Screen_DimX; x++) {
			float fSampleWidth = x / float_ScreenDIMx;
			float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			...
```

We can replace a statement with x86-64:
```
		for (int x = 0; x < g.GC_Screen_DimX; x++) {
			float fSampleWidth = x / float_ScreenDIMx;

			//float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleX;
			asm {
				movq xmm2, [fStartX@main]
				movq xmm1, [fEndX@main]
				subsd xmm1, xmm2
				movq xmm0, [fSampleWidth@main]
				mulsd xmm0, xmm1
				addsd xmm0, xmm2
				movq [fSampleX@main], xmm0
			}
			...
```

Diving into this language will give you knowledge of the x86-64 WIN32 runtime environment, the Portable Executable 
format, the x64 calling convention and Compiler Design.

The C programming language is 50 years old at this moment. It is a well-known language to do low-level programming, but 
nowadays C compilers do not allow the mixing of C and assembly in the same function. The reason is obvious: manual 
inserted assembly makes optimization of the generated code hard.  
It used to be possible in Visual Studio to start an assembly block at a random place, but nowadays the entire function
must be assembly or C. This creates a distance. Ground tries to close this gap. It respects x86-64 assembly and allows 
it everywhere. The Ground code is more compact, so typical usage of x86-64 is in innerloops.  
See Examples\mode7_optimized.g for an example of innerloop optimization.

Ground has language constructs like class, group, function, while, if, string, float, etc...
See file Examples\console.g to see some usage.  
It has a reference count system, so garbage collection is automatic. This makes string concatenation easier.
The generated code is reentrant, so multiple threads can run the same code if you use local variables. Recursion is also
possible as can be seen in the sudoku.g example.

### Installing Fasm 1.73:
Ground uses FASM to assemble the generated code. Download Fasm at https://flatassembler.net/fasmw17332.zip.
Set the INCLUDE environment variable to ```<installation directory>\INCLUDE```.
Add the ```<installation directory>``` to the System variables Path variable.

### Sourcecode visible while debugging in x64dbg:
If you want to debug with x64dbg, assemble FASM's listing.asm into listing.exe and put it in the FASM installation 
directory. Switch on the generateDebugInfo boolean in Program.cs and check if the used x64dbg folder is correct, because 
Ground will generate a x64dbg database file there. After compilation, you can load your .EXE in x64dbg and you will see 
the original sourcecode in the comment column of the debugger.

### Running the mode7.g example
You will need 3 additional files to run the mode7.g sample. First, the font which is located in the Resources
folder and is called ```playfield1024.png```.  
Second, the GroundSideLibrary.dll which is on https://github.com/ReneOlsthoorn/GroundSideLibrary.  
Third, the SDL3.dll in https://github.com/libsdl-org/SDL/releases/download/release-3.2.8/SDL3-3.2.8-win32-x64.zip.
Put the 3 files in de same folder as the generated mode7.exe and it will run.  
You can also download all the necessary files and example executables at: https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/GroundExecutables.zip?raw=true
The mode7.g is the unoptimized version. The innerloop needs 5ms(on my machine with a Ryzen 7 5700g) to complete each frame.
The mode7_optimized is the optimized version and has an innerloop of 1ms.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Mode7.png?raw=true" width="500" />
</p>

### Variables
Outside arrays or class structs, you should use 64-bit datatypes like int of float. Only in context of arrays and classes are the datatypes respected.

### Details on the memory model in Ground.
The stack is 512k and is defined at the top of the generated assembly file.

There are three memory spaces:
1. Variable space. (4mb by default)
This contains the actual data. It is just a continuous block of memory. The default allocation is 4mb at this moment.

2. Index space. (1000 elements by default)
We divide the variable space up in blocks. Each block is referenced by a row in the index space. Each row contains 
a pointer, the size of the block and the number of references to this block. At this moment, the rowsize is 32 bytes. 
When Ground generates code, a value-type variable will just contain the value in either RAX of XMM0. For reference-type
variables however, the value will be the index. This index will be used to lookup the pointer to the used memory block.

3. Reference space. (2000 elements by default)
In a reference counting system, each owner must manage their referenced objects. Functions are owners. The references 
in this case are indexes in the index space. When a function exits, the referenced objects must be looped and the 
reference count for each referenced object must be decremented. The reference space contains all lists of references 
for all functions. Such a list cannot be kept on the stack, because there can be nesting of functions and when a 
variable is assigned to a variable in a different scope/function it would mess up the stack.  
The reference space is used by two linked lists in a function: the RefCount list and the TmpRefCount list. Why 2 lists?
The function must keep track of the temporary memory that is allocated in the expressions, so it can be freed with ease.
The RefCount list exists for values that are assigned to variables. Perhaps the lists can be merged, but then an extra 
property must be added which tells the code that the variable is temporary. My choice was to create separate lists.
The reference counting system has an overhead during runtime. So, I agree with the creator of the "Beef language" that 
it's more ideal to have no Garbage Collection or Reference Counting.

### Details about the compiler
There are several steps done before the generated .EXE file is executed:

1) The Lexer generates tokens from the sourcecode.  
2) The tokens are grouped in a Abstract Syntax Tree (AST) by the Parser.  
3) The Optimizer makes the AST more compact, for instance by combining integer or string literals.  
4) The Compiler converts the AST to x86-64 assembly. It uses FASM 1.73 to generate the Portable Executable file.  

### Tokenize details:
Each token can have multiple types. For instance, the "True" token has 3 types: Literal, Boolean and True. The tokens 
are delivered by the TokenDispenser object.

### Parsing and initialization of the tree:
Using the ParseStatement and ParseExpression methods will result in a AST the contains statements and expressions.
The parsing is done in two steps: first, the plain parsing is done. This is done in the Parser class. Second, the tree 
is Initialized, which puts variables, string and functions in the symboltable and also determines the correct expression
type of BinaryExpressions.  
For instance when the user adds a string and an integer, in the tree there be a BinaryExpression which holds the string 
as a Left-side expression and the integer as a Right-side expression. In the Initialize phase, the correct expression 
type will be determined, which is string in this case. This will not convert the Left-side and Right-side, but will only
determine the correct type in the parent node.  
At the moment of Compilation, in the Compiler.cs visitor loop, the Compiler will use this determined type to convert
the Left-side and Right-side using emitted code. In our example: the integer will get extra code which will convert the
integer to a string (see usage of EmitConversionCompatibleType in method VisitorBinaryExpr in sourcefile Compiler.cs).

### ParentScopeVariable
When the Parser is done, we have a tree of Statement or Expression subclassed objects. The symbols in the symboltable
usually have a reference to these objects. So, what kind of symbol is ParentScopeVariable? Well, it defines a usage 
of a variable from another scope. So, the ParentScopeVariable knows how many levels down the original variable is. In
the code generation process this is important.

### Stack- and Heap allocation:
Normal variables and function parameters are allocated on the stack. This is also necessary because in multicore 
programming each process gets its own stack.  
Reference types like Arrays are allocated on the heap. A string is an array. Strings are fixed and allocated in the 
root Scope, so all functions can reuse them. Dynamic string cannot be reused and are allocated with Grounds own 
memorymanager.

### More Indexspace details:
Indexspace row format has 32 bytes and only 20 bytes are used:
```
  memoryPtr(8) -> pointer to the allocated piece
  sizePtr(8)   -> size of the allocated space
  nrRefs(4)    -> how many variables point to this block
```
The elements of the Indexspace table are not moved.  
When a memoryblock is freed, the memoryPtr stays but the nrRefs goes to 0.  
When freeing the element, the previous element is inspected and if that one is also free the sizes are combined. The
absorbed index will become 0 completely.
When the memory_ptr is filled, but the size = 0, then it's a reference to a static string.<br/>
<br/>
Samples:
```
0x3100530331005303, 200,  0  -> free memory block of 200 bytes at location 0x3100530331005303
0x3100530331005303, 200,  1  -> allocated block of 200 bytes at location 0x3100530331005303
0x3100530331005303,   0,  1  -> pointer to a fixed zero-terminated string defined in the .data section
0,0,0                        -> free index row
0x3100530331005303, 300,  2  -> occupied memoryblock of 300 bytes with 2 references
```

### Emitting x86-64 code:
Code generation/emitting happens in the CodeEmitterX64 class. For different types, different codepaths are emitted. 
For instance in the method ```CodeEmitterX64>>PopSub()``` you see different code for different expression types. One for 
integer, one for float, one for strings. Why substract strings?  Well, that actually isn't the case. Normally the 
first part of a comparison is a substraction. When the result is zero, the values are equal. For comparing strings 
however, this substraction is skipped and a byte-for-byte string comparison is done.

### More details on code generation:
RAX/XMM0 is used to exchange the value the store or to read. RDX helps in that process.  
Most functions start with ```push rbp``` followed by ```mov rbp, rsp```. This makes the stack 16-byte aligned which is needed 
for the fastcall convention. This also means that the pointer for the parentframe is at ```[rbp]```.

### Choosing a template
With the special #template directive, the programmer can choose a generation template. The default is console. See the
directory Templates for the console.fasm template. Use the sdl3 template for SDL3 applications without console window.
A lot of functions are shared between the console.fasm and sdl3.fasm templates.

### include a file
With the #include directive, you can include DLL definitions or other code into your sourcefile.

### Only 64-bit
The AMD Opteron in 2003 was the first x86 processor to get 64-bit extensions. Although AMD was much smaller than Intel,
they created the x86-64 standard. We are now 20+ years later and everybody has a 64 bit processor. Since Windows 7,
which was released in 2009, the 64-bit version is pushed as the default. Nowadays, Windows 11 only ships as 64-bit 
version, so 64-bit is a safe bet. That's why Ground will only generate x86-64 code.

### Using MSVCRT
When you compile a C program with Visual Studio, it links ```VCRUNTIME140.dll```. That DLL is not by default available on
Windows. It also is a hassle for the users to manually install the VCRuntime. The way to avoid this is simple: don't 
use the default C runtime, use ```MSVCRT.DLL```!  
MSVCRT is available on all Windows version since Windows XP. It is also a KnownDLL. See the registry at:
```Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs```

### Mixing of ground code and assembly
The danger of programming in higher level languages is that the connection with assembly is lost. Ground refuses that.
So, there are a lot of ways to mix the two.
First of all, you can use the asm { } everywhere. The assembly code between the brackets will literally be used.
Second, there is a special group, called g, which directly refers to an assembly variable. The advantage is that you 
stay in the ground language context.
So ```g.SDL_WINDOWPOS_UNDEFINED``` will resolve to the SDL_WINDOWPOS_UNDEFINED equate.
```g.[pixels_p]``` will resolve to the content of the pixels_p variable.

A powerful mixing is this:
```
byte[61,36] screenArray = g.[screentext1_p];
```
The content of the screentext1_p variable is put inside the screenArray and the coder can make statements like:
```
screenArray[30,10] = "A";
```

An other piece to investigate is:
```
byte[128] event = [];
u32* eventType = &event[0];
if (*eventType == g.SDL_QUIT) { running = false; }
```
The first line allocated 128 bytes. The second line creates a pointer of a u32 to the first element. The third line
retrieves the value pointed to by eventType and compares it with SDL_QUIT.  
In smoothscroller.g, you see a lot of examples of mixing ground and assembly.

### Some remarks
At this moment, you can only declare a Class instance at the root level.

### GroundSideLibrary
There is a lot of C code in the world. C is practically the base of all major operating systems like Unix, Windows,
Linux, BSD and macOS. A lot of C libraries do an excellent job. For instance the unpacking of a .PNG file can be
done with existing C libraries. The GroundSideLibrary is a .DLL which contains all that C code and creates an 
interface for it.

## Ground is an Ode to the x86-64 Windows PC
Ever since 1994, that is 30 years ago, I use the Microsoft DOS/Windows platform on Intel x86 compatible machines.
I want to take a moment here to give credits to that platform.  
Recently, I took time to remember my old Commodore 64 and Amiga 500 days. Back then, I was heavily invested in the 
Amiga 500, because it seemed to be the successor of the C64. However, the platform did not upgrade for a long time. 
The Commodore Amiga was released in 1985, but the next model for the masses was the Amiga 1200 released in 1992. 
That was more than 7 years later. I really felt let down by Commodore in 1990/1991.  
Later it became clear that Commodore had no focus on the Amiga in 1988,1989 and 1990. They were busy with the PC-line, 
like releasing the PC-60-III, the CDTV project and the C-65 project. The C-65 had the new CSG-4510 processor running 
at 3.5 Mhz, two SID chips, 128k of RAM, a DMA controller with blitter and new VIC-III chip displaying 320x200 pixels and 
256 colors.  
Not only was there no focus on the Amiga, but Commodore also neglected the Amiga Ranger prototypes created by Jay Miner 
in 1988.  
As a programmer, you have intellectual- and time investments in a platform and when it becomes inactive you feel lost.
Fortunately, the good thing was that I moved to the Wintel platform and bought an ESCOM 486DX2 66 MHz PC in 1994. Now,
30 years and numerous PC upgrades later, the platform is still a good choice. It has no vendor lock-in and you can pick 
and choose your moment to upgrade. We were truly blessed with this platform for 30 years. This must be said!  
At this moment in 2024, several expert users are migrating to Linux because Windows collects data about the usage of 
your computer. I agree with those users that data collecting is not nice. However, it can be disabled. Search for 
"How to disable Microsoft Compatibility Telemetry".

### State of Ground : Alpha
The Ground language is Alpha, so bugs and changes are plenty. Do not use the language if you look for a stable language.
Ground is created to facilitate the production of compact high performance code. Ground will always be Alpha!

### Running the smoothscroller.g example
You will need 3 additional files to run the smoothscroller.g sample. First, the font which is located in the Resources
folder and is called ```charset16x16.png```.  
Second, the GroundSideLibrary.dll which is on https://github.com/ReneOlsthoorn/GroundSideLibrary.  
Third, the SDL3.dll in https://github.com/libsdl-org/SDL/releases/download/release-3.2.8/SDL3-3.2.8-win32-x64.zip.  
Put the 3 files in de same folder as the generated smoothscroller.exe and it will run.  
You can also download all the necessary files at: https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/GroundExecutables.zip?raw=true

### The chipmunk_tennis.g example
There is also an example which interfaces with the Chipmunk Physics engine. Check it out, it's fun.  
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Chipmunk_tennis.jpg?raw=true" width="500" />
</p>

### The 3D Travelling Through Stars example
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Stars.png?raw=true" width="500" />
</p>

### The Plasma example with no colorcycling
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_plasma_non_colorcycling.jpg?raw=true" width="500" />
</p>

### The Fire example
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Fire.jpg?raw=true" width="500" />
</p>

### The Bertus game
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Bertus.jpg?raw=true" width="491" />
</p>

### Changelog
2025.01.29: Added kotlin for-loops:
```
for (i in 1..10)  { println(i); }  // from 1..10
for (i in 0..<10) { println(i); }  // from 0..9
```
2025.03.27: SDL3 support and added win32-screengrab.g example.
2025.04.15: Bertus game added.
