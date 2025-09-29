
dll msvcrt function fopen(string filepath, string mode);
dll msvcrt function fclose(int stream);
dll msvcrt function fwrite(int buffer, int size, int count, int stream);
dll msvcrt function fputs(string input, int stream);
dll msvcrt function calloc(int number, int size) : ptr;
dll msvcrt function free(ptr memory);
dll msvcrt function getch();
dll msvcrt function sin(float angle) : float;
dll msvcrt function cos(float angle) : float;
dll msvcrt function fabs(float value) : float;
dll msvcrt function atan2(float y, float x) : float;
dll msvcrt function sqrt(float x) : float;
dll msvcrt function fread(ptr buffer, int sizeElement, int elementCount, ptr stream) : int;  // result = nr elements loaded
dll msvcrt function printf(string format, int value);
dll msvcrt function fprintf(ptr stream, string format, int value);
dll msvcrt function fflush(ptr stream);
dll msvcrt function abs(int value) : int;
dll msvcrt function rand() : int;
dll msvcrt function srand(int seed);
dll msvcrt function time64(ptr time);
dll msvcrt function pow(float x, float y) : float;
dll msvcrt function strlen(ptr str) : int;
dll msvcrt function strcpy(ptr dest, ptr src) : ptr;
dll msvcrt function strstr(ptr haystack, ptr needle) : ptr;
