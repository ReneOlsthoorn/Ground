
#define CURL_GLOBAL_ALL 3
#define CURLVERSION_NOW 11
#define CURLOPT_URL 10002
#define CURLOPT_WRITEDATA 10001
#define CURLOPT_WRITEFUNCTION 20011

dll libcurl function curl_global_init(int flags) : int;
dll libcurl function curl_global_cleanup();
dll libcurl function curl_easy_init() : ptr;
dll libcurl function curl_easy_cleanup(ptr handle);
dll libcurl function curl_easy_setopt(ptr handle, int option, ptr p1);
dll libcurl function curl_easy_perform(ptr handle) : int;
dll libcurl function curl_version_info(int version) : ptr;
