
function insertColors(ptr colorptr) {
	u32[256] colors = colorptr;
	// https://codebase64.org/doku.php?id=base:commodore_vic-ii_color_analysis
	colors[0] = 0xff000000;  // First 16 colors are C-64 colors.
	colors[1] = 0xfff1f1f1;  // white
	colors[2] = 0xffac4749;  // red
	colors[3] = 0xff78d5d0;  // cyan
	colors[4] = 0xffac49c1;  // purple
	colors[5] = 0xff5dc158;  // green
	colors[6] = 0xff4044cb;  // blue
	colors[7] = 0xffe1e063;  // yellow
	colors[8] = 0xffaf6821;  // brown
	colors[9] = 0xff7E5500;  // dark brown
	colors[10] = 0xffd67d7f; // pink
	colors[11] = 0xff686868; // dark grey
	colors[12] = 0xff8f8f8f; // grey
	colors[13] = 0xffa0eb9c; // light gren
	colors[14] = 0xff8898ff; // light blue
	colors[15] = 0xffb9b9b9; // light grey
	colors[255] = 0xffffffff;
}
