
#template console



int i = 3;
assert(i == 3);



float f = 3.14159265;
assert(f == 3.14159265);



// Testing the kotlin look-a-like for loops. Definition of loop iterator j is not necessary.
i = 0;
for (j in 1..20)
	i = i + j;
assert(i == 210);



// Use the ..< range operator to exclude the rightvalue, which is handy for zero-indexed arrays.
i = 0;
for (j in 0..< 20)
	i = i + j;
assert(i == 190);



// Normal C look-a-like loop.
int loopNr = 30;
i = 0;
for (int k = 1; k < loopNr; k++) { i = i + k; }
assert(i == 435);



// Modify an int value using an typepointer.
i = 0x1ffff;
u64* u64_ptr = &i;
*u64_ptr = 3;
assert(i == 3);



// Modify an int using a pointer, which always points to a 64-bit value.
pointer iPtr = &i;
ptr alternate_iptr = &i;  // ptr is an alias for pointer.
*iPtr = 5;
assert(i == 5);



// Remember: Intel x86 is little endian, which proved to be a better choice over time than the Motorola 68000 big endian, because value's can expand without a problem.
i = 0x1ffffffff;
u32* u32p = alternate_iptr;
*u32p = 1;      // Clear the lower 32 bits.
assert(i == 0x100000001);
j = 0;
*(u32p+j) = 2;  // One node of the binary expression is a u32* and combining it with an integer must result in a u32* expression type, else this will fail.
assert(i == 0x100000002);
u32p[j] = 3;
assert(i == 0x100000003);
*(u32p) = 4;
assert(i == 0x100000004);



// Array style can also be used, which does the offset calculation for you. Useful for pixel arrays. Array indexes start at zero.
i = 0x1ffff;
u32p[0] = 0xFEDC1234;
u32p[1] = 2;
assert(i == 0x2fedc1234);



// A 64 value can be seen as a 2x4 byte array. u8 is equal to byte.
u8[2,4] u8array = &i;
u8array[1,0] = 0;
u8array[0,2] = 3;
assert(i == 0x3FEDC0034);



// At this moment, there are only two options for arrays: initialize it with a pointer or initialize it with dynamic allocated memory.
// Assigning an empty array triggers the dynamic allocation of memory. Then, you get an memory-index as value, so do not expect a memory pointer.
// If you want to convert the memory-index to a memory-pointer, use a construction that takes the address of the first element like &array[0];
byte[64,64] u8d = [];
u8d[56,31] = 0x53;  // set the first byte of the last 64-bit value of the first half of the array.
byte* u8p = &u8d[0];
assert(u8d[56,31] == *(u8p+2048-8));
assert(*(u8p+2048-8) == 0x53);



// You can define an array without size specification, but then an initialize is necessary.
int[] array = [ 1, 2, 4, 8, 16, 0x10000ffff ];
assert(array[4] == 16);



// asm data will be inserted in the template near the end, at GC_INSERTIONPOINT_DATA
asm data {
unittest_extradata dq 0x2ffff
 dq 0x1fffe
 dd 1
 dd 2
 dq 3
}
ptr theExtraData = g.unittest_extradata;
u16 u16_ptr = *(theExtraData+8);
assert(u16_ptr == 65534);



u32 u32_var = *(theExtraData+20);
assert(u32_var == 2);



u64 u64_var = *(theExtraData+24);
assert(u64_var == 3);



assert(9*8*7*6*5*4*3*2*1 == 362880);



// Functions can be nested and they can use variables in previous scopes.
int outsideInt = 100;
function nest() {
    function nest2() {
        function nest3() {
            function nest4() {
                outsideInt = outsideInt + 1;
            }
            outsideInt = outsideInt + 1;
            nest4();
        }
        nest3();
        outsideInt = outsideInt + 1;
    }
    nest2();
    outsideInt = outsideInt + 1;
}
nest();
assert(outsideInt == 104);



// Classes can only be used at root level, or without a single function (not nested functions).
outsideInt = 100;
class TheClass {
	function methodNest() {
        outsideInt = outsideInt + 200;
	}
}
TheClass inst;
inst.methodNest();
assert(outsideInt == 300);



function classInsideFunction() {
	TheClass otherInst;
	otherInst.methodNest();
}
classInsideFunction();
assert(outsideInt == 500);



int outsideVariable = 400;
class ClassWithVars {
	int instVar;
	function method1(int i) {
		this.instVar = this.instVar + i;
		this.instVar = this.instVar + outsideVariable;
	}
	function method2() {
		this.instVar = 200;
		this.method1(100);
	}
}
int assertValue = 0;
function surrounded() {
    ClassWithVars k;
    k.method2();
    assertValue = k.instVar;
    assert(k.instVar == 700);
}
surrounded();
assert(assertValue == 700);



// Math priority rules check
i = 4 + 5 * 30 / 3;
assert(i == 54);



// Float calculations
float f1 = 1.1;
f1 = f1 + 11.2;
f1 = f1 / 3;
assert(f1 == 4.1);



// IF statement
i = 54;
if (i == 54) { i = 1; }
assert(i == 1);



// Using assembly
i = 54;
asm {
  mov   rax, [i@main]
  add   rax, rax
  mov   [i@main], rax
}
assert(i == 108);



string[] strArray = [ "Hello", "World" ];
assert(strArray[1] == "World");



// Array parameters
string assertStrResult = "";
function fArrayTest(string[] arrayPar) {
    assertStrResult = arrayPar[1];
}
fArrayTest(strArray);
assert(assertStrResult == strArray[1]);



string str1 = "Hello, ";
string str2 = "World";
string str3 = str1 + str2;
assert(str3 == "Hello, World");



str1 = "Character: " + chr$(65);
assert(str1 == "Character: A");



// full assembly function
function fullAsmFunction(int j) asm {
  mov   rax, [j@fullAsmFunction]
  add   rax, rax
  mov   [j@fullAsmFunction], rax
  push  rbp
  mov   rbp, [rbp]      ; select the parent stackframe.
  mov   [i@main], rax
  pop   rbp
}
fullAsmFunction(80);
assert(i == 160);



class VarClass {
	float f1;
	int	i1;
	string str1;

	function method() {
        this.i1 = this.i1 + 3;
	}
}
VarClass vcInst;
vcInst.str1 = "Hello!";
vcInst.i1 = 5;
vcInst.method();
assert(vcInst.i1 == 8);



// Grouping
group testgroup {
    function gfun1() {
        i = 0xfecc;
    }
    function gfun2() {
        gfun1();
    }
}
testgroup.gfun2();
assert(i == 0xfecc);



int outsideScopeVar = 34;
class Actor {
	int x;
	int y;
	int arrivedAtIndex;
	int movex;
	int movey;
	bool falling;
	function jump(newX, newY) {
		this.movex = newX;
		this.movey = newY;
		this.falling = false;
		outsideScopeVar = outsideScopeVar + this.movex + this.movey;
	}
	function isArrivedAtBlock() {
		return (this.falling == false and this.movex == 0 and this.movey == 0);
	}
	function reset() {
		this.movex = 0;
		this.movey = 0;
		this.falling = false;
		this.arrivedAtIndex = -1;
	}
}
Actor actor;
actor.reset();
actor.x = 10;
actor.y = 20;
assert(actor.arrivedAtIndex == -1);
Actor[3] balls = [ ];
function initBall(int idx) {
	balls[idx].reset();
	balls[idx].x = actor.x+16;
	balls[idx].y = 20;
	balls[idx].falling = true;
}
function startBall() {
	initBall(0);
	balls[0].jump(32,48);
	if (balls[0].x == (actor.x+16) && balls[0].y == actor.y) {
		balls[0].arrivedAtIndex = 99;
		balls[0].jump(32,48);
	}
}
startBall();
assert(balls[0].arrivedAtIndex == 99);
assert(outsideScopeVar == 80+80+34);


int[] shape1List = [3,9];
int shapeCount;
function GoLevel() {
	shapeCount = sizeof(shape1List) / 8;
}
GoLevel();
assert(shapeCount == 2);


class UnitTestClass {
	int instvar;
	function method1() {
		this.instvar = this.instvar + 1;
	}
}
UnitTestClass unitTestClass1;
unitTestClass1.instvar = 80;
unitTestClass1.method1();
assert(unitTestClass1.instvar == 81);



int xx = 10;
class TheClass2 {
	function method() {
		xx = xx + 20;
	}
}
function deep1() {
	TheClass2 cl2;
	function deep2() {
		TheClass2 cl1;
		cl1.method();
		cl2.method();
	}
	deep2();
}
deep1();
assert(xx == 50);


float starZ = 218.2914243448;
i = 100;
assert(!((i > 200) or (starZ < 0.0)));


byte[15,15] board = [ ] asm;

function copyLine(ptr dest, string src) {
	ptr src_p = &src;
asm {
  mov	rdx, [src_p@copyLine]
  mov	r8, [dest@copyLine]
.loop:
  mov	al, [rdx]
  test	al, al
  jz	.exitloop
  cmp	al, '.'
  jne	.notempty
  mov	al, 0
  jmp	.setfield
.notempty:
  mov	al, 1
.setfield:
  mov	byte [r8], al
  inc	r8
  inc	rdx
  jmp	.loop
.exitloop:
}
}

function PlaceAchimsp16(int x, int y) {
	copyLine(&board[x,y++], ".......**");
	copyLine(&board[x,y++], "..*.*..*.");
}

PlaceAchimsp16(1,2);
assert(board[5,3] == 1);


println("SUCCESS: unittests were completed with SUCCESS.");
