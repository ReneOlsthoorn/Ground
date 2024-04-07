# Ground

"Ground" aims to be a programming language for Windows which promotes the use of x64 assembly code and keeping the 
generated .EXE files small. It is created to give me more knowledge about the x86-64 WIN32 runtime environment, not 
to be a serious programming language. So, if you are looking for a good programming language, I suggest you use a 
different language like "Beef language", C#, C or Javascript. Only programmers interested in compiler design should 
use this software.

The C programming language (not C++ with it's reinterpret_cast<> and return-value-optimization drama) is 50 years old 
at this moment. It is a nice language to do low-level programming, but nowadays C compilers do not allow the mixing 
of C and assembly. The reason is obvious: manual inserted assembly makes optimization of the generated code hard.

Ground respects x64 assembly and gives it the proper place : usage in optimized loops. For precalculation, the fastest 
performance is often not needed. In a Ground sourcefile, the x64 assembly can be inserted everywhere and it can use all 
the variables in the function. Ground has a reference count system, so garbage collection is automatic. This makes 
string concatenation easier.


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
The  RefCount list exists for values that are assigned to variables. Perhaps the lists can be merged, but then an extra 
property must be added which tells the code that the variable is temporary. My choice was to create separate lists.
The reference counting system has an overhead during runtime. So, I agree with the "Beef language" that it's more ideal
to have no Garbage Collection or Reference Counting.

Details about the compiler. There are several steps done before the generated .EXE file is executed:

1) The Lexer generates tokens from the sourcecode.
2) The tokens are grouped in a Abstract Syntax Tree (AST) by the Parser.
3) The Optimizer makes the AST more compact, for instance by combining integer or string literals.
4) The Compiler converts the AST to x86-64 assembly. It uses FASM 1.73 to generate the Portable Executable file.

### Installing Fasm 1.73:
Download Fasm https://flatassembler.net/fasmw17332.zip
Set the INCLUDE environment variable to <installation directory>\INCLUDE
Add the <installation directory> to the System variables Path variable.

### Debugging with x64dbg:
If you want to debug with x64dbg, also assemble FASM's listing.asm into listing.exe and put it in the FASM installation 
directory. Switch on the generateDebugInfo boolean in Program.cs and check if the used x64dbg folder is correct, because 
Ground will generate a x64dbg database file there. After compilation, you can load your .exe in x64dbg and you will see 
the original sourcecode in the comment column of the tool.

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
At the moment of Compilation, in the Compiler visitor loop, the Compiler will use this determined type to convert the
Left-side and Right-side using emitted code. In our example: the integer will get extra code which will convert the
integer to a string (see usage of EmitConversionCompatibleType in method VisitorBinaryExpr in sourcefile Compiler.cs).

### ParentScopeVariable
When the Parser is done, we have a tree of Statement or Expression subclassed objects. The symbols in the symboltable
usually have a reference to these objects. So, what kind of symbol is ParentScopeVariable? Well, it defines a usage 
of a variable from another scope. So, the ParentScopeVariable knows how many levels down the original variable is. In
the code generation process this is important.

### Emitting x86-64 code:
Emitting happens in the CodeEmitterX64 class. For different types, different codepaths are emitted. For instance in
the method CodeEmitterX64>>PopSub() you see different code for different expression types. One for integer, one for
float, one for strings. Why substract strings?  Well, that actually doesn't happen. Normally the first part of a 
comparison is a substraction. When the result is zero, the values are equal. For strings however, this substraction 
is skipped and a byte-for-byte string comparison is done.

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

### Code generation:
RAX/XMM0 is used to exchange the value the store or to read. RDX helps in that process.
Most functions start with "push rbp" followed by "mov rbp, rsp". This makes the stack 16-byte aligned which is needed 
for the fastcall convention. This also means that the pointer for the parentframe is at [rbp].

Ground has two modes for PE(portable executable) file generation: Executable(.EXE) or Dynamic Link Library(.DLL).
Ground has a console mode which generates an .EXE file, and an GUI mode which generates a .DLL file.
The .DLL can be used by the Ground execution environment which opens a Window with SDL2 and runs the code with access
to a character buffer, like the C64. This execution environment is not included, because it would really draw the 
focus away from the compiler.


## An Ode to the x86-64 Windows PC
Ever since 1994, that is 30 years ago, I use the Microsoft DOS/Windows platform on Intel x86 compatible machines.
I want to take a moment here to bring credits to that platform. Recently, I took time to remember my old Commodore 64 
and Amiga 500 days. I was heavily time-invested in the Amiga 500, because it seemed to be the successor of the C64. 
However, the platform did not update for a long time. The Commodore Amiga was released in 1985, but the next model for 
the masses was the Amiga 1200 released in 1992, that is 7 years later. I really felt let down by Commodore in 1990/1991.
As a programmer, you have intellectual- and time investments in a platform and when it becomes inactive you feel lost.
Fortunately, the good thing I did was to move to the Wintel platform and bought an ESCOM 486DX2 66 MHz PC in 1994. Now, 
30 years and numerous PC upgrades later, the platform is still a good choice. It has no vendor lock-in and you can pick 
and choose your moment to upgrade. We are truly blessed with this platform. This must be said!
