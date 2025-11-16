# Ground

This is the compiler for the programming language Ground for Windows. Ground allows mixing high-level programming 
constructs with x86-64 assembly. As a programmer you will stay in contact with your x86-64 CPU.  
In Ground, assembly can be added anywhere and has constructs like classes (supporting instance variables and methods), 
functions, groups of functions, compact for-loops, statements like ```while``` and ```if```, arrays and datatypes 
like ```string``` and ```float```, etc...  
See file ```.\Examples\unittests.g``` on how to use the language.  
  
Mixing Ground and assembly is possible by using the generated symbolic constants.  
The compiler itself is created in C# and generates x86-64 assembly which is assembled with the freely available
FASM for Windows.  
The generated code is poured into an assembly template which can be chosen. This will result in small .EXE 
files when the template is chosen wisely. For instance, there is a ```console``` template, but also a ```sdl3``` 
template which loads the ```SDL3.dll``` and ```SDL3_image.dll```. Ofcourse you can create your own template.  
  
The ```hello-world.g``` is 43 bytes, the generated ```hello-world.asm``` is 7k and the ```hello-world.exe``` is 6k.  
A second reason why the .EXE will remain small is that all external code is loaded at load-time. The usage of the 
known system DLL's, like ```MSVCRT.DLL```, is promoted. Several game examples are included with Ground:
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

The asm block is literally copied to the assembler. If you want, you can inspect the generated .asm file to see 
every detail. Reading it will give you knowledge of the x86-64 WIN32 runtime environment, the Portable Executable 
format and the x64 calling convention.  

On Windows, many programmers use the 50-years old language C as their low-level programming language. Understandably so. 
The quality of the generated code by Visual Studio C is good and the sourcecode can be reused for other processors. 
However, there are major annoyances:
1. The Visual Studio C compiler forces "secure" code onto you. Microsoft has ```/GS```, ```SDL checks``` and runtime checks.
1. A massive runtime library is included when you create a ```HelloWorld.exe```. Before you know it, you need to 
ship ```vc_redist.x64.exe``` with your little 4k demo.
1. Strange workarounds are needed when your try to "ignore all default libraries", such as ```#define _NO_CRT_STDIO_INLINE``` 
and ```_fltused```. The default stacksize is 4k on a system with more than 8 Gb memory!
1. Visual Studio does not allow the mixing of C and assembly in the same function. The reason seems clear: manual 
inserted assembly makes optimization too hard for the compiler.
1. Highlevel constructs like classes are not available and moving to C++ is a mistake. Good luck with C++'s 
```reinterpret_cast<Object>(-1)``` or ```std::shared_ptr<>```. Maybe you will also wonder why the copy-constructor is not 
called when the compiler is doing ```Return value optimization```.
1. The Visual Studio C datatypes ```int``` and ```float``` are wrong for a 64 bit system. They are 4 bytes, but need to be 8.

Ground tries to leave all the Visual Studio C/C++ problems behind and close the gap between compact highlevel 
constructs and assembly. Typical usage of x86-64 is in innerloops. See ```.\Examples\mode7_optimized.g``` for 
an example of innerloop optimization.

Ground has a reference count system, so garbage collection is automatic. This makes string concatenation easier.
The generated code is reentrant, so multiple threads can run the same code if you use local variables. Recursion is also
possible as can be seen in the sudoku.g example. See the Chess example on how to use additional threads.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Chess.jpg?raw=true" width="500" /><br/>
</p>

### Installing FASM 1.73:
Ground uses FASM to assemble the generated code. Download Fasm at https://flatassembler.net/fasmw17332.zip.
Set the INCLUDE environment variable to ```<installation directory>\INCLUDE```.
Add the ```<installation directory>``` to the System variables Path variable.

### Sourcecode visible while debugging in x64dbg:
If you want to debug with x64dbg, assemble FASM's listing.asm into listing.exe and put it in the FASM installation 
directory. Switch on the ```generateDebugInfo``` boolean in Program.cs and check if the used x64dbg folder is correct, because 
Ground will generate a x64dbg database file there. After compilation, you can load your .EXE in x64dbg and you will see 
the original sourcecode in the comment column of the debugger.

### Running the examples
The most easy way to run all the examples is using Visual Studio. Open and compile the Ground.sln solution and you 
will get a folder called ```<GroundProjectFolder>\bin\Debug\net9.0``` in your solution's location.  
In that folder, you must unzip the ```<GroundProjectFolder>\Resources\GroundResources.zip```
The zipfile contains additional DLL's, sounds and images. The sourcecode for the included GroundSideLibrary.dll is 
available on github at: https://github.com/ReneOlsthoorn/GroundSideLibrary.  
After unzipping, you must go to your ```<GroundProjectFolder>\bin\Debug\net9.0``` folder and run the batchfile called 
```Load.bat``` to download and automatically unzip ```SDL3```, ```SDL3_image```, ```LibCurl``` and ```StockFish```. 
After this, you can change line 20 in Program.cs `fileName = "sudoku.g"` to `fileName = "mode7.g"` to run the Mode7 
example. The mode7.g is the unoptimized version. The innerloop needs 5ms (on my machine with a Ryzen 7 5700g) to 
complete each frame. The mode7_optimized is the optimized version and has an innerloop of 1ms.
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Mode7.png?raw=true" width="500" />
</p>

### Variables
Apart from arrays and class structs, you should use 64-bit datatypes like ```int``` of ```float```. Only in context of arrays and classes are 
the datatypes respected.

### Choosing a template
With the special ```#template``` directive, the programmer can choose a generation template. The default is ```console```. See the
directory Templates for the console.fasm template. Use the ```sdl3``` template for SDL3 applications without console window.
A lot of functions are shared between the console.fasm and sdl3.fasm templates.

### include a library
With the ```#library``` directive, you can include a library. For instance ```#library user32 user32.dll``` does 3 things:
1. include user32.g into your sourcecode at that location.
2. insert the user32.dll into the loadtime DLL list of the template.
3. insert the user32_api.inc into the template.

### include a file
With the ```#include``` directive, you can insert a textfile into your sourcefile.

### Only 64-bit
The ```AMD Opteron``` in 2003 was the first x86 processor to get 64-bit extensions. Although ```AMD``` was much smaller than ```Intel```,
they created the x86-64 standard. We are now 20+ years later and everybody has a 64 bit processor. Since ```Windows 7```,
which was released in 2009, the 64-bit version is pushed as the default. Nowadays, ```Windows 11``` only ships as 64-bit 
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
First of all, you can use the ```asm { }``` everywhere. The assembly code between the brackets will literally be used.
Second, there is a special group, called g, which directly refers to an assembly variable. The advantage is that you 
stay in the ground language context.
So ```g.SDL_WINDOWPOS_UNDEFINED``` will resolve to the ```SDL_WINDOWPOS_UNDEFINED``` equate.
```g.[pixels_p]``` will resolve to the content of the ```pixels_p``` variable.

A powerful mixing is this:
```
byte[61,36] screenArray = g.[screentext1_p];
```
The content of the screentext1_p variable is put inside the screenArray and the coder can make statements like:
```
screenArray[30,10] = 'A';
```

An other piece to investigate is:
```
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
if (*eventType == g.SDL_QUIT) { running = false; }
```
The first line allocated ```SDL3_EVENT_SIZE```, that is 128, bytes. The second line creates a pointer of a u32 to the first element. The third line
retrieves the value pointed to by eventType and compares it with ```SDL_QUIT```.  
In ```smoothscroller.g```, you see a lot of examples of mixing ground and assembly.

### Some remarks
* You can only declare Classes at the root level. Inner classes are not supported.
* Don't do string concatenation in your main-loop because memory-cleanup runs when the scope is left. In your mainloop, you don't leave a scope, so it will result in a memory exhaustion.
* Unrelated methods and variables can be easily stored in a separate file that you include in the main sourcefile.

### Optimizer
Ground contains an optimizer (in ```Optimizer.cs```), which will replace literals and removes unused variables. It will 
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
The BYTES_PER_MOVE is defined as 8, so you are tempted to do a ```>> 3``` in stead of a divide by 8. A shift right 
is faster than a divide operand. However, this is not needed because the optimizer does it for you.

### GroundSideLibrary
There is a lot of C code in the world. C is practically the base of all major operating systems like Unix, Windows,
Linux, BSD and MacOS. A lot of C libraries do an excellent job. For instance the unpacking of a ```.PNG``` file can be
done with existing C libraries. The ```GroundSideLibrary``` is a .DLL which contains all that C code and creates an 
interface for it.

### State of Ground : Alpha
The Ground language is Alpha, so do not use the language if you look for a stable language.
Ground is created to facilitate the production of compact high performance code. Ground will always be Alpha!

### Write your own language!
The choices made in Ground might not be to your liking. Perhaps you want to use Go as the implementation language or 
don't want a reference count system. Why not write your own language? Use the lexer from this compiler or borrow some
code generation constructs. It might be less work than you think and you end up being an expert.

### Technical details on the memory model in Ground.
The ```stack``` is 512k and is defined at the top of the generated assembly file.

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
```RAX/XMM0``` is used to exchange the value to store or to read. ```RDX``` helps in that process.  
Most functions start with ```push rbp``` followed by ```mov rbp, rsp```. This makes the stack 16-byte aligned which is needed 
for the fastcall convention. This also means that the pointer for the parentframe is at ```[rbp]```.

## Ground is an Ode to the x86-64 Windows PC
Ever since 1994, that is more than 30 years ago, I use the Microsoft DOS/Windows platform on x86 compatible machines.
I want to take a moment here to give credits to that platform.  
Recently, I took time to remember my old ```Commodore 64``` and ```Amiga 500``` days. Back then, I was heavily invested in the 
```Amiga 500```, because it seemed to be the successor of the ```C-64```. However, the platform did not upgrade for a long time. 
The Amiga was released in 1985, but the next model for the masses was the ```Amiga 1200``` released at the end of 1992. 
That was more than 7 years later. I really felt let down by Commodore in 1990.  
  
Later it became clear that Commodore had no focus on the Amiga in the years 1988-1990. They were busy with the PC-line, 
like releasing the ```PC-60-III```, the ```CDTV``` project and the ```C-65``` project. The C-65 had the new ```CSG-4510``` processor running 
at 3.5 Mhz, two ```SID``` chips, 128k of RAM, a ```DMA``` controller with ```blitter``` and new ```VIC-III``` chip displaying 320x200 pixels 
and 256 colors.  
Meanwhile, Commodore totally neglected the ```Amiga Ranger``` prototypes created by Jay Miner in 1988.  
  
As a programmer, you invest a lot of time and effort in a platform and when it becomes inactive you feel lost. 
Fortunately, a clear winner was arising: The ```Microsoft DOS/Windows``` platform. ```Microsoft Office 4.2``` containing ```MS-Word 6.0```, 
```MS-Excel 5.0``` and ```MS-Powerpoint 4.0``` on 25 ```1.44"``` disks was a tremendous hit. Everyone wanted it.  
At the same time ```DOOM 2``` released, a tremendous hit for gamers. Again, everyone wanted it.  
The PC platform had cheap hardware, so everybody joined. This resulted in total MARKET DOMINATION.  
In 1994, I bought an ```ESCOM 486DX2 66 MHz``` PC with 420MB harddisk and 4MB memory. It was great. Now, 30 years and numerous 
PC's later, the platform is still alive. It has no vendor lock-in and you can pick and choose your moment to upgrade. 
We were truly blessed with this plaform and it's domination for the last 30 years. This must be said!  
  
At this moment in 2025, several expert users are migrating to Linux because Windows 11 collects too much personal data and sends 
it to the cloud or uses it for AI. Microsoft wants to make Windows a sensory device for an AI companion and forces users to give 
up privacy. I strongly disagree with this route, because it should be made optional.  
Use a third-party tool as such as "O&O ShutUp10++" to disable Copilot and Recall. However, with each new update, the settings 
can be turned on again. The whole situation is a shame, because Windows has such a great history. Like many users, I don't want
to battle my OS. For the moment, I will not migrate yet to Linux because I owe so much to the Windows platform.  

### Smoothscroller
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Smoothscroller.jpg?raw=true" width="500" /><br/>
Scrolling is always good.</p>

### Jump
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Jump.jpg?raw=true" width="500" /><br/>
Jump on the platforms. 3D starfield background.</p>

### The Chipmunk Tennis example
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Chipmunk_tennis.jpg?raw=true" width="500" /><br/>
Example which uses the Chipmunk Physics engine.</p>

### The Plasma example with no colorcycling
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_plasma_non_colorcycling.jpg?raw=true" width="500" /><br/>
Smoother than an Amiga 500 plasma.</p>

### The Fire example
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Fire.jpg?raw=true" width="500" /><br/>
Early PC effect.</p>

### The Bertus game
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Bertus.jpg?raw=true" width="491" /><br/>
Try to beat the 4 levels!</p>

### Classic Snake game
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Snake.jpg?raw=true" width="498" /><br/>
Feed the snake 100 meals.</p>

### Game Of Life
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_GameOfLife.jpg?raw=true" width="500" /><br/>
Watch the Game Of Life patterns blow up! The current version has 20 different patterns.</p>

### Tetrus
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Tetrus.jpg?raw=true" width="500" /><br/>
Solve 30 lines to complete.</p>

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
Default set to ELO 1, so you must be able to win...</p>

### High Noon shootout
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_High_Noon.jpg?raw=true" width="500" /><br/>
A proper shootout at High Noon in Videopac G7000 retro style.</p>

### Memory
<p align="center">
<img src="https://github.com/ReneOlsthoorn/Ground/blob/master/Resources/Ground_Memory.jpg?raw=true" width="400" /><br/>
Can you beat 7 levels of the classic memory game?</p>


### Changelog
2025.01.29: Added kotlin for-loops.  
2025.03.27: SDL3 support and added win32-screengrab.g example.  
2025.04.15: Bertus game added.  
2025.06.06: Asm arrays added (see snake.g)  
2025.06.10: Game Of Life added.  
2025.06.20: Optimizer extended. It will replace literals now, and remove unused variables.  
2025.07.14: Added Tetrus game.  
2025.08.23: Added Racer game.  
2025.09.04: Jump game added containing Sfxr sounds.  
2025.09.10: Bugs game added.  
2025.09.18: ConnectFour (Vier-op-een-rij) added.  
2025.09.29: Chess added.  
2025.10.17: "Come Taste The Stars" (star_taste.g) experience added.  
2025.10.28: High Noon game added.  
2025.11.09: Memory game added.
