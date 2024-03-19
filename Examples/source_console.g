//run console


// Loop test
int loopAantal = 3;
string tmp = "test";
for (int i = 1; i < loopAantal+1; i++) {
	println(i + " " + tmp);
}


// Optimize check
println(9*8*7*6*5*4*3*2*1 + " will be optimized to 362880.");


// Array test
int[] array = [ 1, 2, 4, 8, 16, 32 ];
println("Array[2] = 4 => " + array[2]);


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
    println("if statement gelukt");
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
//print "Integer (1-100): ";
//int aantal = input_int();


// String input from console
//print "String: ";
//string tmp = input_string();


class ConsoleClass {
    string a;
    string b;
    int f1;
}

ConsoleClass a;
a.a = "Hallo!";

println("ConsoleClass a.a = Hallo! => " + a.a);

string tmpFilename = "test.txt";
int tmpFile = fopen(tmpFilename, "wb");
fputs("Line1\r\n", tmpFile);
fputs("Line2\r\n", tmpFile);
fputs("Line3\r\n", tmpFile);
fclose(tmpFile);

println("\r\nReading generated file...");
string allText = GC_ReadAllText(tmpFilename);
print(allText);


println("\r\nReading generated file line by line...");
tmpFile = fopen(tmpFilename, "rb");
string textLine = "";
while (textLine != null) {
    textLine = fgets(tmpFile);
    if (textLine != null and textLine == "Line2\r\n") {
        println("Second line found...");
    } else {
        if (textLine != null) {
            print(textLine);
        }
    }
}
fclose(tmpFile);
