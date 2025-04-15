
function insertColors(ptr colorptr) {
	u32[256] colors = colorptr;
	// https://codebase64.org/doku.php?id=base:commodore_vic-ii_color_analysis
	colors[0] = 0xff000000;  // #000000  First 16 colors are C-64 colors.
	colors[1] = 0xfff1f1f1;  // #ffffff  white
	colors[2] = 0xffac4749;  // #993322  red
	colors[3] = 0xff78d5d0;  // #66ddee  cyan
	colors[4] = 0xffac49c1;  // #aa3399  purple
	colors[5] = 0xff5dc158;  // #55bb22  green
	colors[6] = 0xff4044cb;  // #1133aa  blue
	colors[7] = 0xffe1e063;  // #ffee55  yellow
	colors[8] = 0xffaf6821;  // #995511  brown
	colors[9] = 0xff7E5500;  // #663300  dark brown
	colors[10] = 0xffd67d7f; // #dd6655  pink
	colors[11] = 0xff686868; // #444444  dark grey
	colors[12] = 0xff8f8f8f; // #777777  grey
	colors[13] = 0xffa0eb9c; // #aaff77  light gren
	colors[14] = 0xff8898ff; // #5577ff  light blue
	colors[15] = 0xffb9b9b9; // #bbbbbb  light grey
	// https://lospec.com/palette-list/commander-x16-default
	colors[255] = 0xffffffff;
}
