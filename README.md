# Ground

This is the compiler for the programming language `Ground` for Windows, which is an effort to return to high
performance computing. It allows mixing high-level programming constructs with x86-64. The assembly can be added 
anywhere in the Ground code, so the programmer stays in control of the CPU.  
  
Ground has constructs like `class` and `function`, statements like `while`, `for` and `if`, datatypes 
like `string` and `float` and arrays. See file `unittests.g` for some syntax examples.  
  
Ground variables can be referenced in assembly by using the generated symbolic constants. The compiler itself is 
written in C# and generates x86-64 assembly which is assembled by [FASM](https://flatassembler.net/).  
The generated code is poured into an assembly template which can be freely chosen. This will result in small `.EXE` 
files when the template is chosen wisely. For instance, there is a `console` template which opens the console, but 
also a sdl3 template which doesn't have a console and is useful when starting `SDL3` applications. Ofcourse you 
can create your own template.  
  
The `hello-world.g` is 43 bytes, the generated `hello-world.exe` is 6k.  
Ground .EXE files will be small because most external code is loaded at load-time. The usage of the known system 
DLL's, like `ucrtbase` or `msvcrt`, is promoted. No Visual C++ redistributable installations are needed.  
Several game examples are included with Ground, like racer.g:
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Racer.jpg?raw=true" width="500" />
</p>

It's easy in Ground to replace a statement with x86-64. For example, we have the following code in mode7.g:
```
		for (x in 0..< SCREEN_WIDTH) {
			float fSampleWidth = x / SCREEN_WIDTH_F;
			float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
```

We can replace a statement with x86-64:
```
		for (x in 0..< SCREEN_WIDTH) {
			float fSampleWidth = x / SCREEN_WIDTH_F;
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
```

The `asm` block is literally copied to the assembler. If you want, you can inspect the generated .asm file to see 
every detail. Reading it will give you knowledge of the x86-64 WIN32 runtime environment, 
the [PE format](https://learn.microsoft.com/en-us/windows/win32/debug/pe-format) and 
the [x64 calling convention](https://learn.microsoft.com/en-us/cpp/build/x64-calling-convention).  

### How to run Ground
In your `Ground` root folder you have a file named `LoadResources.bat`. Run it.  
It will unzip `.\Resources\GroundResources.zip` and download the needed DLL's, like SDL3, from trusted repositories 
like MSYS2 or Github. The zipfile also contains extra files that could not be downloaded from the internet, like manual 
build DLL's, sounds and images. For all DLL's used, sourcecode is available. The included 
[GroundSideLibrary](https://github.com/ReneOlsthoorn/GroundSideLibrary) is available on github.  
After this is done, Run `Visual Studio 2026` and open `GroundCompiler.slnx`. Hit the Play button in Visual Studio and 
the game Bertus should compile and run.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Bertus.jpg?raw=true" width="491" /><br/>
</p>

### Running other examples
When the resources are downloaded, you can change line 24 in Program.cs `fileName = "bertus.g";` to 
`fileName = "mode7.g";` to run the Mode7 example. See the comment on line 24 for more filenames of examples. The mode7.g 
is the unoptimized version. The innerloop needs 5ms (on my machine with a Ryzen 7 5700g) to complete each frame. 
The mode7_optimized is the optimized version and has an innerloop of 1ms.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Mode7.png?raw=true" width="500" /><br/>
</p>

### About the C language
On Windows, many programmers use the 50-years old language C as their low-level programming language. Understandably so. 
The quality of the generated code by Visual Studio C is good and the sourcecode can be reused for other processors. 
However, there are major annoyances:
1. The Visual Studio C compiler forces "secure" code onto you. Microsoft has `/GS`, `SDL checks` and runtime checks.
1. A massive runtime library is included when you create a `HelloWorld.exe`. Before you know it, you need to 
ship `vc_redist.x64.exe` with your little 4k demo.
1. Strange workarounds are needed when your try to "ignore all default libraries", such as `#define _NO_CRT_STDIO_INLINE` 
and `_fltused`. The default stacksize is 4k on a system with more than 8 Gb memory!
1. Visual Studio does not allow the mixing of C and assembly in the same function. The reason seems clear: manual 
inserted assembly makes optimization too hard for the compiler.
1. Highlevel constructs like classes are not available and moving to C++ is a mistake. Good luck with C++'s 
`reinterpret_cast<Object>(-1)` or `std::shared_ptr<>`. Maybe you will also wonder, like me, why the copy-constructor is not 
called when the compiler is doing `Return value optimization`.
1. The Visual Studio C datatypes `int` and `float` are wrong for a 64 bit system. They are 4 bytes, but need to be 8.

Ground tries to leave all these Visual C/C++ problems behind and close the gap between compact highlevel 
constructs and assembly. Typical usage of x86-64 is in innerloops. See `.\Examples\mode7_optimized.g` for 
an example of innerloop optimization.

Ground has a reference count system, so there is no garbage collector. Reference counting makes string concatenation easier.
The generated code is reentrant, so multiple threads can run the same code if you use local variables. Recursion is also
possible as can be seen in the sudoku.g example. See the Chess example on how to use additional threads.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Chess.jpg?raw=true" width="500" /><br/>
</p>

### Choosing a template
With the special `#template` directive, the programmer can choose a generation template. The default is `console`. See the
directory Templates for the console.fasm template. Use the `sdl3` template for SDL3 applications without a console window.
A lot of functions are shared between the console.fasm and sdl3.fasm templates.

### include a library
With the `#library` directive, you can include a library. For instance `#library user32 user32.dll` does 3 things:
1. include user32.g into your sourcecode at that location.
2. insert the user32.dll into the loadtime DLL list of the template.
3. insert the user32_api.inc into the template.

### include a file
With the `#include` directive, you can insert a textfile into your sourcefile.

### Mixing of ground code and assembly
The danger of programming in higher level languages is that the control over the CPU is lost. Ground refuses that.
So, there are ways to mix the two. First of all, you can use the `asm { }` everywhere. The assembly code between the brackets 
will literally be used. Second, there is a special group, called g, which directly refers to an assembly variable. The advantage 
is that you stay in the ground language context.
So `g.SDL_WINDOWPOS_UNDEFINED` will resolve to the `SDL_WINDOWPOS_UNDEFINED` equate.
`g.[pixels_p]` will return the content of the `pixels_p` assembly variable.

A powerful mixing is this:
```
byte[61,36] screenArray = g.[screentext1_p];
```
The content of the screentext1_p variable will be used by the array screenArray. That is special because normally an array will refer to
memory that is managed by Ground. This case overrides that and it will use a freely defined pointer to be the base. The coder can make 
statements like:
```
screenArray[30,10] = 'A';
```

Another piece to investigate is:
```
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
if (*eventType == g.SDL_QUIT) { running = false; }
```
The first line allocated `SDL3_EVENT_SIZE`, that is 128, bytes. The second line creates a pointer of a u32 to an element. The third line
retrieves the value that variable eventType points to and compares it with `SDL_QUIT`.  
In `smoothscroller.g`, you see a lot of examples of mixing ground and assembly.

### Variables
When creating an array, the memory layout will be as expected. For instance when you have `byte[40] array = [];`, 
the address of the array (`&array`) will point to an array of 40 bytes. Defining a Class with variables will
align the variables at their natural alignment. So an 64-bit int defined after a byte will skip 7 bytes. This can be
prevented. Use `packed` after the Classes name for that.  

### Only 64-bit
The `AMD Opteron` in 2003 was the first x86 processor to get 64-bit extensions. Although `AMD` was much smaller than `Intel`,
they created the x86-64 standard. We are now 20+ years later and everybody has a 64 bit processor. Since `Windows 7`,
which was released in 2009, the 64-bit version is pushed as the default. Nowadays, `Windows 11` only ships as 64-bit 
version, so 64-bit is a safe bet. That's why Ground will only generate x86-64 code.

### Using ucrt or msvcrt
When you compile a C program with `Visual Studio 2026`, it links to `VCRUNTIME140.dll`, `VCRUNTIME140_1.dll` or whatever version
of the VC runtime is active that week. It's a mess. Those DLL's are not available by default on a Windows system. So the users need to 
install the VC Runtime Redistributable, which is a hassle. The way to avoid this mess is simple: don't use the new VC runtimes, 
use the OG `msvcrt.dll` or the new `ucrtbase.dll`.  
The MSVCRT is available on all Windows versions since Windows XP. It is also a KnownDLL. See the registry at:
`Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\KnownDLLs`. MSYS2 advices to use `ucrt`, so 
that will be the future.

### Some remarks
* You can only declare Classes at the root level. Inner classes are not supported.
* Don't do string concatenation in your main-loop because memory-cleanup runs when the scope is left. In your mainloop, you don't leave a scope, so it will result in a memory exhaustion.
* Unrelated methods and variables can be easily stored in a separate file that you include in the main sourcefile.
* The Chipmunk physics DLL had to be manually build, because it only works without symbols in the DLL. 
These steps where done: I checked out the sourcecode and created a directory called build. Into this directory I created the make files like this: 
`cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS_RELEASE="-s" -DBUILD_STATIC=ON`  
In the CMakeLists.txt, I included: `target_link_options(chipmunk PRIVATE -static)` as the last line, to prevent the libwinpthread loadtime 
dependency. After that build the library with `cmake --build .` and the `libchipmunk.dll` is created in build\src.

### Sourcecode visible while debugging in x64dbg:
If you want to debug with x64dbg, switch on the `generateDebugInfo` boolean in Program.cs and check if the used x64dbg 
folder is correct, because Ground will generate a x64dbg database file there. After compilation, you can load your 
.EXE in x64dbg and you will see the original generated assembly in the comment column of the debugger.

### Optimizer
Ground contains an optimizer (in `Optimizer.cs`), which will replace literals and removes unused variables. It will 
scan the assembly code for usage of variables to avoid removing used variables.
```
int a = (2*5)+5+3+(4/2);
int b = 4*10;
int c = b / a;
```
Will result in the following generated code:
```
mov   rax, 2
```
The optimizer will fold the numbers of variable a and b and substitute the values in the calculation of c, which 
also results in a literal. The optimizer can also result in better readable code. For instance, look at the 
following function:
```
function NrMoves() : int {
	return ((movesListNeedle - movesList) / BYTES_PER_MOVE);
}
```
The BYTES_PER_MOVE is defined as 8, so you are tempted to do a `>> 3` in stead of a divide by 8. A shift right 
is faster than a divide operand. However, this is not needed because the optimizer does it for you.

### GroundSideLibrary
There is a lot of C code in the world. C is practically the base of all major operating systems like Unix, Windows,
Linux, BSD and MacOS. A lot of C libraries do an excellent job. For instance the unpacking of a `.PNG` file can be
done with existing C libraries. The `GroundSideLibrary` is a .DLL which contains all that C code and creates an 
interface for it. It is compiled using MSYS2 MINGW64, which is great and uses MSVCRT or UCRT by default.

### State of Ground : Alpha
The Ground language is `Alpha`, so do not use the language if you look for a stable language.
Ground is created to facilitate high performance code. Ground will always be Alpha!

### Looking for a high performance programming language with inline assembly. 
Your Windows PC has a CPU which can execute code incredibly fast using a language called `x86-64` assembly.  
While learning the Amiga Protracker format, I found C# code that could read a mod file. It does the necessary BigEndian 
conversion like this:
```
var data = base.ReadBytes(4);
Array.Reverse(data);
return BitConverter.ToInt32(data, 0);
```
In x86-64, this functionality is done with one statement:
```
bswap eax
```
Surely, `C#` or `Java` will allow you to insert x86-64 assembly... NOT!!  
In defense of C# and Java, they are both positioned as productivity languages. Inserting assembly is a high performance
feature. So, let's look at high performance languages then. There are many to choose from these days.  
For instance the `V language`. It has no garbage collection and transpiles to C. Unfortunately there is no focus on 
assembly in V.  
Second language: `Beef`. No garbage collector. C# look-a-like approach. The backend is `LLVM`, so unfortunately 
no easy assembly.  
Third language: `Odin`. But same as Beef, it uses the LLVM backend. Odin positions itself as a general purpose language. 
Well, for general purpose software I would recommend C# or Kotlin because they are fast enough (for instance, C# can do 
parallel execution) and have the most libraries available for all kinds of tasks. Microsoft and Java are dominating. 
Also in the job market.  
`Python` is slower but that's no problem for a scripting language. It can connect to native compiled libraries with relative
ease. I used to do python in 2003-2004 with Python 2.2 and 2.3 and I loved it. It was very easy to make an application 
with wxWindows. But the GIL always felt problematic. No blame to Guido for that, because single threading natural in a 
scripting language.  
By the way: a very interesting general purpose programming language is `Pharo` Smalltalk. Everything is an object in 
Smalltalk and the code editor is available in the image. I used to be a `Smalltalk` programmer from 1997-2002 and I 
still love the language and environment.  
But, back to our search for a high performance language: 
`BlitzBasic` supports inline assembly. But wait... it is 32 bit. 
`BlitzMax` has an LLVM backend that does not support easy assembly language. 
`Wren` is a scriping language, 
`Nim` transpiles to C. 
`Dart` has a garbage collector and is busy with flutter and has no focus on high performance. 
`Go` also has a garbage collector, but a small one. A high performance garbage collector can be faster than reference counting. Unfortunately Go does not 
support inline assembly. `Go` is a systems programming language and those languages want to abstract the CPU away.  
`Rust` has a LLVM backend, so no easy assembly. The same for `Zig`. The same for `Crystal`. In Crystal, I coded a 
"Hello, World!". It was 660k and used VCRUNTIME140.dll, gc.dll and iconv-2.dll. So, apart from the VC-redistributable, 
you also must ship 2 extra DLL's to make your "Hello, World!" run on a modern PC. That's not convenient.  
So, now you understand why `Ground` is necessary :-)  There is only one CPU in your PC. Get a grip on it and let it dance!

## Write your own Programming Language!
The choices made in Ground might not be to your liking. Perhaps you want to use Go as the implementation language or 
don't want a reference count system but a garbage collector. Why not write your own language? Use the lexer from this 
compiler or borrow some code generation constructs. It might be less work than you think.  

### Technical details on the memory model in Ground.
The `stack` is 512k and is defined at the top of the generated assembly file.  
Ground has got it's own managed memory for reference types like arrays, classes and strings, because doing malloc and 
free on every object creation will not perform. When doing string concatenation, something must provide the needed
memory. So, you automatically will go to a managed memory situation. Now that the objects are allocated, you
want to be able to assign them to other variables in distant scopes, without copying the memory. So, that will naturally
lead to reference counting. Ground does that. Reference counts are added and subtracted, and when nothing references 
the object anymore, it is freed within it's own managed memory. There is no garbage collector. The fast processing 
is done at the end of a function.  

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
The reference counting system has an overhead during runtime. So, I agree with the creator of the `Beef` language that 
it's more ideal to have no Garbage Collection or Reference Counting, which Beef facilitates with the `Scope` keyword.

### Details about the compiler
There are several steps done before the generated .EXE file is executed:

1) The Lexer generates tokens from the sourcecode.  
2) The tokens are grouped in a Abstract Syntax Tree (AST) by the Parser.  
3) The Optimizer makes the AST more compact, for instance by combining integer or string literals.  
4) The Compiler converts the AST to x86-64 assembly. It uses FASM to generate the Portable Executable file.  

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
For instance in the method `CodeEmitterX64>>PopSub()` you see different code for different expression types. One for 
integer, one for float, one for strings. Why substract strings?  Well, that actually isn't the case. Normally the 
first part of a comparison is a substraction. When the result is zero, the values are equal. For comparing strings 
however, this substraction is skipped and a byte-for-byte string comparison is done.

### More details on code generation:
`RAX/XMM0` is used to exchange the value to store or to read. `RDX` helps in that process.  
Most functions start with `push rbp` followed by `mov rbp, rsp`. This makes the stack 16-byte aligned which is needed 
for the fastcall convention. This also means that the pointer for the parentframe is at `[rbp]`.

## Ground is an Ode to the x86-64 Windows PC
Ever since 1994, that is more than 30 years ago, I use the Microsoft DOS/Windows platform on x86 compatible machines.
I want to take a moment here to give credits to that platform.  
Recently, I took time to remember my old `Commodore 64` and `Amiga 500` days. Back then, I was heavily invested in the 
`Amiga 500`, because it seemed to be the successor of the `C-64`. However, the platform did not upgrade for a long time. 
The Amiga was released in 1985, but the next model for the masses was the `Amiga 1200` released at the end of 1992. 
That was more than 7 years later. I really felt let down by Commodore in 1990.  
  
Later it became clear that Commodore had no focus on the Amiga in the years 1988-1990. They were busy with the PC-line, 
like releasing the `PC-60-III`, the `CDTV` project and the `C-65` project. The C-65 had the new `CSG-4510` processor running 
at 3.5 Mhz, two `SID` chips, 128k of RAM, a `DMA` controller with `blitter` and new `VIC-III` chip displaying 320x200 pixels 
and 256 colors.  
Meanwhile, Commodore totally neglected the `Amiga Ranger` prototypes created by Jay Miner in 1988.  
  
As a programmer, you invest a lot of time and effort in a platform and when it becomes inactive you feel lost. 
Fortunately, a clear winner was arising: The `Microsoft DOS/Windows` platform. `Microsoft Office 4.2` containing `MS-Word 6.0`, 
`MS-Excel 5.0` and `MS-Powerpoint 4.0` on 25 `1.44"` disks was a tremendous hit. Everyone wanted it.  
At the same time `DOOM 2` released, a tremendous hit for gamers. Again, everyone wanted it.  
The PC platform had cheap hardware, so everybody joined. This resulted in total MARKET DOMINATION.  
In 1994, I bought an `ESCOM 486DX2 66 MHz` PC with 420MB harddisk and 4MB memory. It was great. Now, 30 years and numerous 
PC's later, the platform is still alive. It has no vendor lock-in and you can pick and choose your moment to upgrade. 
We were truly blessed with this plaform and it's domination for the last 30 years. This must be said!  
  
At this moment in 2026, several expert users are migrating to Linux because Windows 11 collects too much personal data and sends 
it to the cloud or uses it for AI. Microsoft wants to make Windows an agentic AI OS and forces users to give up privacy. 
I strongly disagree with this route, because it should be made optional.  
Use a third-party tool as such as [O&O ShutUp10++](https://www.oo-software.com/en/shutup10) to disable Copilot and Recall. However, 
with each new update, the settings can be turned on again. The whole situation is a shame, because Windows has such a great history. 
Like many users, I don't want to battle my OS. For the moment, I will not yet migrate to Linux because I owe so much to 
the Windows platform.  

### Smoothscroller
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Smoothscroller.jpg?raw=true" width="500" /><br/>
Scrolling is always good. Bouncing objects done with the Chipmunk Physics engine.</p>

### Jump
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Jump.jpg?raw=true" width="500" /><br/>
Jump on the platforms. 3D starfield background.</p>

### Game Of Life
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_GameOfLife.jpg?raw=true" width="500" /><br/>
Watch the Game Of Life patterns blow up! The current version has 20 different patterns.</p>

### The Fire example
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Fire.jpg?raw=true" width="500" /><br/>
The retro PC demo effect.</p>

### The Bertus game
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Bertus.jpg?raw=true" width="491" /><br/>
Try to beat the 4 levels!</p>

### Classic Snake game
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Snake.jpg?raw=true" width="498" /><br/>
Feed the snake 100 meals.</p>

### The Plasma example with no colorcycling
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_plasma_non_colorcycling.jpg?raw=true" width="500" /><br/>
Smoother than an Amiga 500 Copper plasma.</p>

### Tetrus
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Tetrus.jpg?raw=true" width="500" /><br/>
Solve 30 lines to complete.</p>

### Mode 7
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Mode7.png?raw=true" width="500" /><br/>
125 codelines that visually prove that depth is a division.
</p>

### Racer
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Racer.jpg?raw=true" width="500" /><br/>
Motor racing game. Avoid the other motor racers.</p>

### Bugs
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Bugs.jpg?raw=true" width="500" /><br/>
Let the bugs eat eachother and don't let any escape!</p>

### Join the Hype! Play Connect Four against your local LLM Ai
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Connect4.jpg?raw=true" width="500" /><br/>
Play Connect 4 (vier-op-een-rij) against Ollama Ai models!<br/>
Read the instructions in the connect4.g sourcecode.</p>

### Play Chess against StockFish
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Chess.jpg?raw=true" width="500" /><br/>
Play Chess locally against StockFish!<br/>
Set it to ELO 1 in the sourcecode or prepare to be beaten.</p>

### High Noon shootout
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_High_Noon.jpg?raw=true" width="500" /><br/>
A proper shootout at High Noon in Videopac G7000 retro style.</p>

### Memory
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Memory.jpg?raw=true" width="400" /><br/>
Can you beat 7 levels of classic memory?</p>

### Fireworks
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Fireworks.jpg?raw=true" width="500" /><br/>
How can a Firework show promote x86-64 assembly?</p>

### 3D
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_3D.jpg?raw=true" width="500" /><br/>
Rotating 3D object. Matrix calculations done with CGLM.</p>

### Electronic Life 2026
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Electronic_Life.jpg?raw=true" width="500" /><br/>
Electronic Life is back after 36 years!</p>

<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Amiga_Electronic_Life.jpg?raw=true" width="400" /><br/>
This was the original "Electronic Life" from 1990</p>


### Ground Release zipfile
The Ground Release zipfile on Github contains all the sourcecode and most of the examples as executable. 
The executables are in the `bin\Release` directory of the zipfile.

### Changelog
2025.01.29: Added kotlin for-loops.  
2025.03.27: SDL3 support and added win32-screengrab.g example.  
2025.04.15: Bertus game added.  
2025.06.06: Asm arrays added (see snake.g)  
2025.06.10: Game Of Life added.  
2025.06.20: Optimizer extended. It will replace literals now and remove unused variables.  
2025.07.14: Added Tetrus game.  
2025.08.23: Added Racer game.  
2025.09.04: Jump game added containing Sfxr sounds.  
2025.09.10: Bugs game added.  
2025.09.18: ConnectFour (Vier-op-een-rij) added.  
2025.09.29: Chess added using StockFish.  
2025.10.17: "Come Taste The Stars" (star_taste.g) experience added.  
2025.10.28: High Noon game added.  
2025.11.09: Memory game added.  
2025.11.29: GroundSideLibrary now build with MSYS2.  
2025.12.05: Fireworks demo added.  
2025.12.09: 3D demo added.  
2026.01.16: First version of Electronic Life 2026 added.  

### Open bugs
2025.12.13: A string as instance variable has bad reference counting.  
2025.12.13: Returning a string also has bad reference counting.  
2025.12.13: this.mod[10] doesn't work.
