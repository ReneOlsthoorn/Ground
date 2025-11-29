
dll ucrt function fopen(string filepath, string mode);
dll ucrt function fclose(int stream);
dll ucrt function fwrite(int buffer, int size, int count, int stream);
dll ucrt function fputs(string input, int stream);
dll ucrt function calloc(int number, int size) : ptr;
dll ucrt function free(ptr memory);
//dll ucrt function getch();
dll ucrt function sin(float angle) : float;
dll ucrt function cos(float angle) : float;
dll ucrt function fabs(float value) : float;
dll ucrt function atan2(float y, float x) : float;
dll ucrt function sqrt(float x) : float;
dll ucrt function fread(ptr buffer, int sizeElement, int elementCount, ptr stream) : int;  // result = nr elements loaded
//dll ucrt function printf(string format, int value);
//dll ucrt function fprintf(ptr stream, string format, int value);
dll ucrt function fflush(ptr stream);
dll ucrt function abs(int value) : int;
dll ucrt function rand() : int;
dll ucrt function srand(int seed);
//dll ucrt function time64(ptr time);
dll ucrt function pow(float x, float y) : float;
dll ucrt function strlen(ptr str) : int;
dll ucrt function strcpy(ptr dest, ptr src) : ptr;
dll ucrt function strstr(ptr haystack, ptr needle) : ptr;
dll ucrt function fseek64(int handle, int offset, int origin);
dll ucrt function ftell(int handle) : int;

asm equates {
ucrt_SEEK_SET = 0
ucrt_SEEK_CUR = 1
ucrt_SEEK_END = 2
}
