
#template console
#include msvcrt.g


// Loop test
int loopNr = 3;
string tmp = "test";
for (int i = 1; i < loopNr+1; i++) {
	println(i + " " + tmp);
}


// Nested functions test
int outsideInt = 100;
function nest() {
    function nest2() {
        function nest3() {
            outsideInt = outsideInt + 1;
        }
        nest3();
        outsideInt++;
    }
    nest2();
}
nest();
if (outsideInt != 102) {
    println("nesting has failed");
}


// Optimize check
println(9*8*7*6*5*4*3*2*1 + " will be optimized to 362880.");


// Array test
int[] array = [ 1, 2, 4, 8, 16, 32 ];
println("Array[2] = 4 => " + array[2]);


// string Array test
string[] strArray = [ "Hello", "World" ];
println("Array[1] = World => " + strArray[1]);


// Function test
string strOutside = "strOutside";
function functionTest() {
    string strInside = "strInside";
    println("functionTest: " + strInside + "   " + strOutside);
    strOutside = "strOutside is redefined and must remain the same.";
    println(strOutside);
}
functionTest();
println(strOutside);


// Array parameter test
function fArrayTest(int[] arrayPar) {
    int[] array2 = [ 5, 10 ];
    println("ArrayPar: 16 = " + arrayPar[4]);
    println("Array2 binnen fArrayTest: 10 = " + array2[1]);
}
fArrayTest(array);


// math rules check
i = 4 + 5 * 30 / 3;
println("54 = " + i);


// if statement
if (i == 54) {
    println("if statement succeeded.");
}


// assembly test
asm {
  mov   rax, [i@main]
  add   rax, rax
  mov   [i@main], rax
}
println("108 = " + i);


// assembly function
function asmFn(int j) asm {
  mov   rax, [j@asmFn]
  add   rax, rax     ; 80 + 80 = 160
  mov   [j@asmFn], rax  ; j = 160
  push  rbp
  mov   rbp, [rbp]
  mov   [i@main], rax  ; i = 160
  pop   rbp
}
asmFn(0x50);   // 0x50 = 80
println("160 = " + i);


// GC_CurrentExeDir check.
string fontFilename = GC_CurrentExeDir + "source_console.asm";
println(fontFilename);


// floats
float f1 = 1.1;
f1 = f1 + 10.2;
f1 = f1 / 3;
println("f1: 3.77 = " + f1);


// Integer input from console
//print("Integer (1-100): ");
//int aantal = gc.input_int();
//println("Value: " + aantal);


// String input from console
//print("String: ");
//tmp = gc.input_string();
//println("Value: " + tmp);


class ConsoleClass {
	float f1;
	int	i1;
	string str1;

	function testf() {
        println("ConsoleClass this.str1 = Hello! => " + this.str1);
	}
}

ConsoleClass a;
a.str1 = "Hello!";

println("ConsoleClass a.str1 = Hello! => " + a.str1);
a.testf();

ConsoleClass b;
b.str1 = "World!";
a = b;
println("World! => " + a.str1);

string tmpFilename = "test.txt";
int tmpFile = msvcrt.fopen(tmpFilename, "wb");
msvcrt.fputs("Line " + chr$(65) + "\r\n", tmpFile);
msvcrt.fputs("Line " + chr$(65+1) + "\r\n", tmpFile);
msvcrt.fputs("Line " + chr$(65+2) + "\r\n", tmpFile);
msvcrt.fclose(tmpFile);

println("\r\nReading generated file...");
string allText = gc.ReadAllText(tmpFilename);
print(allText);


println("\r\nReading generated file line by line...");
tmpFile = msvcrt.fopen(tmpFilename, "rb");
string textLine = "";
while (textLine != null) {
    textLine = msvcrt.fgets(tmpFile);
    if (textLine != null) {
        if (textLine == "Line A\r\n") {
            println("First line found...");
        } else if (textLine == "Line B\r\n") {
            println("Second line found...");
            break;
        } else {
            print(textLine);
        }
    }
}
msvcrt.fclose(tmpFile);


// array tests
int[4] testArray = [ 1, 2, 3, 4 ];
function fn(int i) {
	if (i > 3) { return true; }
	println(testArray[i]);
	return fn(i+1);
}
bool testArrayResult = fn(0);
println("testArrayResult (true) = " + testArrayResult);


// group tests
group testgroup {
    function gfun1() {
        println("gfun1");
    }
    function gfun2() {
        println("gfun2");
    }
}
testgroup.gfun2();


// msvcrt tests
tmpFilename = "write.bin";
tmpFile = msvcrt.fopen(tmpFilename, "wb");
int arraySize = 10*1024;
byte[] ptr = msvcrt.calloc(1,arraySize);
i64[] ptr2 = ptr;
ptr2[0] = 0xfffffe02;
println(ptr[1]);
msvcrt.fwrite(ptr, arraySize, 1, tmpFile);
msvcrt.fclose(tmpFile);
msvcrt.free(ptr);


println("End.");
