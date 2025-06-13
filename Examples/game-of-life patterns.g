

function PlaceX(int x, int y) {
	copyLine(&board[x,y++], "");
	copyLine(&board[x,y++], "");
	copyLine(&board[x,y++], "");
	copyLine(&board[x,y++], "");
}


function PlaceSuhajda104P177(int x, int y) {
	copyLine(&board[x,y++], "................O............O................");
	copyLine(&board[x,y++], ".........OO........................OO.........");
	copyLine(&board[x,y++], "........OOO...OO..............OO...OOO........");
	copyLine(&board[x,y++], "..............OO.OO........OO.OO..............");
	copyLine(&board[x,y++], "................O............O................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..O........................................O..");
	copyLine(&board[x,y++], ".OO........................................OO.");
	copyLine(&board[x,y++], ".OO........................................OO.");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..OO......................................OO..");
	copyLine(&board[x,y++], "..OO......................................OO..");
	copyLine(&board[x,y++], "O...O....................................O...O");
	copyLine(&board[x,y++], "...O......................................O...");
	copyLine(&board[x,y++], "...O......................................O...");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "...O......................................O...");
	copyLine(&board[x,y++], "...O......................................O...");
	copyLine(&board[x,y++], "O...O....................................O...O");
	copyLine(&board[x,y++], "..OO......................................OO..");
	copyLine(&board[x,y++], "..OO......................................OO..");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], ".OO........................................OO.");
	copyLine(&board[x,y++], ".OO........................................OO.");
	copyLine(&board[x,y++], "..O........................................O..");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "..............................................");
	copyLine(&board[x,y++], "................O............O................");
	copyLine(&board[x,y++], "..............OO.OO........OO.OO..............");
	copyLine(&board[x,y++], "........OOO...OO..............OO...OOO........");
	copyLine(&board[x,y++], ".........OO........................OO.........");
	copyLine(&board[x,y++], "................O............O................");
}


function PlaceSlider(int x, int y) {
	copyLine(&board[x,y++], ".*.");
	copyLine(&board[x,y++], "..*");
	copyLine(&board[x,y++], "***");
}


function PlacePentomino(int x, int y) {
	copyLine(&board[x,y++], ".**");
	copyLine(&board[x,y++], "**.");
	copyLine(&board[x,y++], ".*.");
}


function PlacePufferTrain(int x, int y) {
	copyLine(&board[x,y++], "...O.");
	copyLine(&board[x,y++], "....O");
	copyLine(&board[x,y++], "O...O");
	copyLine(&board[x,y++], ".OOOO");
	copyLine(&board[x,y++], ".....");
	copyLine(&board[x,y++], ".....");
	copyLine(&board[x,y++], ".....");
	copyLine(&board[x,y++], "O....");
	copyLine(&board[x,y++], ".OO..");
	copyLine(&board[x,y++], "..O..");
	copyLine(&board[x,y++], "..O..");
	copyLine(&board[x,y++], ".O...");
	copyLine(&board[x,y++], ".....");
	copyLine(&board[x,y++], ".....");
	copyLine(&board[x,y++], "...O.");
	copyLine(&board[x,y++], "....O");
	copyLine(&board[x,y++], "O...O");
	copyLine(&board[x,y++], ".OOOO");
}


function PlaceGliderEater(int x, int y) {
	copyLine(&board[x,y++], "**..");
	copyLine(&board[x,y++], "*.*.");
	copyLine(&board[x,y++], "..*.");
	copyLine(&board[x,y++], "..**");
}


function Place119P4H1V0(int x, int y) {
	copyLine(&board[x,y++], ".................................O.");
	copyLine(&board[x,y++], "................O...............O.O");
	copyLine(&board[x,y++], "......O.O......O.....OO........O...");
	copyLine(&board[x,y++], "......O....O....O.OOOOOO....OO.....");
	copyLine(&board[x,y++], "......O.OOOOOOOO..........O..O.OOO.");
	copyLine(&board[x,y++], ".........O.....O.......OOOO....OOO.");
	copyLine(&board[x,y++], "....OO.................OOO.O.......");
	copyLine(&board[x,y++], ".O..OO.......OO........OO..........");
	copyLine(&board[x,y++], ".O..O..............................");
	copyLine(&board[x,y++], "O..................................");
	copyLine(&board[x,y++], ".O..O..............................");
	copyLine(&board[x,y++], ".O..OO.......OO........OO..........");
	copyLine(&board[x,y++], "....OO.................OOO.O.......");
	copyLine(&board[x,y++], ".........O.....O.......OOOO....OOO.");
	copyLine(&board[x,y++], "......O.OOOOOOOO..........O..O.OOO.");
	copyLine(&board[x,y++], "......O....O....O.OOOOOO....OO.....");
	copyLine(&board[x,y++], "......O.O......O.....OO........O...");
	copyLine(&board[x,y++], "................O...............O.O");
	copyLine(&board[x,y++], ".................................O.");
}


function PlaceGliderGun(int x, int y) {
	copyLine(&board[x,y++], "........................*...........");
	copyLine(&board[x,y++], "......................*.*...........");
	copyLine(&board[x,y++], "............**......**............**");
	copyLine(&board[x,y++], "...........*...*....**............**");
	copyLine(&board[x,y++], "**........*.....*...**..............");
	copyLine(&board[x,y++], "**........*...*.**....*.*...........");
	copyLine(&board[x,y++], "..........*.....*.......*...........");
	copyLine(&board[x,y++], "...........*...*....................");
	copyLine(&board[x,y++], "............**......................");
}


function PlaceAchimsp16(int x, int y) {
	copyLine(&board[x,y++], ".......**....");
	copyLine(&board[x,y++], ".......*.*...");
	copyLine(&board[x,y++], "..*....*.**..");
	copyLine(&board[x,y++], ".**.....*....");
	copyLine(&board[x,y++], "*..*.........");
	copyLine(&board[x,y++], "***..........");
	copyLine(&board[x,y++], ".............");
	copyLine(&board[x,y++], "..........***");
	copyLine(&board[x,y++], ".........*..*");
	copyLine(&board[x,y++], "....*.....**.");
	copyLine(&board[x,y++], "..**.*....*..");
	copyLine(&board[x,y++], "...*.*.......");
	copyLine(&board[x,y++], "....**.......");
}


function PlaceAchimsp144(int x, int y) {
	copyLine(&board[x,y++], "**........................**");
	copyLine(&board[x,y++], "**........................**");
	copyLine(&board[x,y++], "..................**........");
	copyLine(&board[x,y++], ".................*..*.......");
	copyLine(&board[x,y++], "..................**........");
	copyLine(&board[x,y++], "..............*.............");
	copyLine(&board[x,y++], ".............*.*............");
	copyLine(&board[x,y++], "............*...*...........");
	copyLine(&board[x,y++], "............*..*............");
	copyLine(&board[x,y++], "............................");
	copyLine(&board[x,y++], "............*..*............");
	copyLine(&board[x,y++], "...........*...*............");
	copyLine(&board[x,y++], "............*.*.............");
	copyLine(&board[x,y++], ".............*..............");
	copyLine(&board[x,y++], "........**..................");
	copyLine(&board[x,y++], ".......*..*.................");
	copyLine(&board[x,y++], "........**..................");
	copyLine(&board[x,y++], "**........................**");
	copyLine(&board[x,y++], "**........................**");
}


function PlaceBeluchenkosp37(int x, int y) {
	copyLine(&board[x,y++], "...........**...........**...........");
	copyLine(&board[x,y++], "...........**...........**...........");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], "......*.......................*......");
	copyLine(&board[x,y++], ".....*.*.....*.........*.....*.*.....");
	copyLine(&board[x,y++], "....*..*.....*.**...**.*.....*..*....");
	copyLine(&board[x,y++], ".....**..........*.*..........**.....");
	copyLine(&board[x,y++], "...............*.*.*.*...............");
	copyLine(&board[x,y++], "................*...*................");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], "**.................................**");
	copyLine(&board[x,y++], "**.................................**");
	copyLine(&board[x,y++], ".....**.......................**.....");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], "......*.*...................*.*......");
	copyLine(&board[x,y++], "......*..*.................*..*......");
	copyLine(&board[x,y++], ".......**...................**.......");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], ".......**...................**.......");
	copyLine(&board[x,y++], "......*..*.................*..*......");
	copyLine(&board[x,y++], "......*.*...................*.*......");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], ".....**.......................**.....");
	copyLine(&board[x,y++], "**.................................**");
	copyLine(&board[x,y++], "**.................................**");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], "................*...*................");
	copyLine(&board[x,y++], "...............*.*.*.*...............");
	copyLine(&board[x,y++], ".....**..........*.*..........**.....");
	copyLine(&board[x,y++], "....*..*.....*.**...**.*.....*..*....");
	copyLine(&board[x,y++], ".....*.*.....*.........*.....*.*.....");
	copyLine(&board[x,y++], "......*.......................*......");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], ".....................................");
	copyLine(&board[x,y++], "...........**...........**...........");
	copyLine(&board[x,y++], "...........**...........**...........");
}


function PlaceMerzenich(int x, int y) {
	copyLine(&board[x,y++], "..**...........**..");
	copyLine(&board[x,y++], "..**...........**..");
	copyLine(&board[x,y++], ".*..*.........*..*.");
	copyLine(&board[x,y++], "..*.*.........*.*..");
	copyLine(&board[x,y++], "...................");
	copyLine(&board[x,y++], ".***...........***.");
	copyLine(&board[x,y++], ".*..*.........*..*.");
	copyLine(&board[x,y++], "*..*...........*..*");
	copyLine(&board[x,y++], ".**.............**.");
	copyLine(&board[x,y++], "...................");
	copyLine(&board[x,y++], ".**.............**.");
	copyLine(&board[x,y++], "*..*...........*..*");
	copyLine(&board[x,y++], ".*..*.........*..*.");
	copyLine(&board[x,y++], ".***...........***.");
	copyLine(&board[x,y++], "...................");
	copyLine(&board[x,y++], "..*.*.........*.*..");
	copyLine(&board[x,y++], ".*..*.........*..*.");
	copyLine(&board[x,y++], "..**...........**..");
	copyLine(&board[x,y++], "..**...........**..");
}


function Place106P135(int x, int y) {
	copyLine(&board[x,y++], "..........................OO..........................");
	copyLine(&board[x,y++], "..........................OO..........................");
	copyLine(&board[x,y++], "......O....O..............................O....O......");
	copyLine(&board[x,y++], "....OO.OOOO.OO..........................OO.OOOO.OO....");
	copyLine(&board[x,y++], "......O....O..............................O....O......");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], ".........................O..O.........................");
	copyLine(&board[x,y++], ".......................O.O..O.O.......................");
	copyLine(&board[x,y++], "........................OO..OO........................");
	copyLine(&board[x,y++], "..O..O....O..O..........................O..O....O..O..");
	copyLine(&board[x,y++], "OOO..OOOOOO..OOO......................OOO..OOOOOO..OOO");
	copyLine(&board[x,y++], "..O..O....O..O............OO............O..O....O..O..");
	copyLine(&board[x,y++], "..........................OO..........................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], "......................................................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], "....................O.O........O.O....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], "....................O.O........O.O....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
	copyLine(&board[x,y++], ".....................O..........O.....................");
}



function PlaceShip1(int x, int y) {
	copyLine(&board[x,y++], ".....O.O...");
	copyLine(&board[x,y++], "....O..O...");
	copyLine(&board[x,y++], "...OO......");
	copyLine(&board[x,y++], "..O........");
	copyLine(&board[x,y++], ".OOOO......");
	copyLine(&board[x,y++], "O....O.....");
	copyLine(&board[x,y++], "O..O.......");
	copyLine(&board[x,y++], "O..O.......");
	copyLine(&board[x,y++], ".O.........");
	copyLine(&board[x,y++], "..OOOO.....");
	copyLine(&board[x,y++], ".........O.");
	copyLine(&board[x,y++], "..O.O..OO.O");
	copyLine(&board[x,y++], ".OO....O...");
	copyLine(&board[x,y++], "..OO.......");
	copyLine(&board[x,y++], "...OOOOOOO.");
	copyLine(&board[x,y++], "....O.O....");
	copyLine(&board[x,y++], "......O..O.");
	copyLine(&board[x,y++], "....O.O....");
	copyLine(&board[x,y++], "...OOOOOOO.");
	copyLine(&board[x,y++], "..OO.......");
	copyLine(&board[x,y++], ".OO....O...");
	copyLine(&board[x,y++], "..O.O..OO.O");
	copyLine(&board[x,y++], ".........O.");
	copyLine(&board[x,y++], "..OOOO.....");
	copyLine(&board[x,y++], ".O.........");
	copyLine(&board[x,y++], "O..O.......");
	copyLine(&board[x,y++], "O..O.......");
	copyLine(&board[x,y++], "O....O.....");
	copyLine(&board[x,y++], ".OOOO......");
	copyLine(&board[x,y++], "..O........");
	copyLine(&board[x,y++], "...OO......");
	copyLine(&board[x,y++], "....O..O...");
	copyLine(&board[x,y++], ".....O.O...");
}


function PlaceShip2(int x, int y) {
	copyLineR(&board[x,y++], "...O..........");
	copyLineR(&board[x,y++], "..O.O.........");
	copyLineR(&board[x,y++], ".OO...........");
	copyLineR(&board[x,y++], "..O...........");
	copyLineR(&board[x,y++], ".O.O..........");
	copyLineR(&board[x,y++], ".O............");
	copyLineR(&board[x,y++], "O.............");
	copyLineR(&board[x,y++], "O.O..OO.......");
	copyLineR(&board[x,y++], "O...O.......OO");
	copyLineR(&board[x,y++], ".OOO....OO..O.");
	copyLineR(&board[x,y++], "...OO.O.O.O..O");
	copyLineR(&board[x,y++], "....OO...OOOO.");
	copyLineR(&board[x,y++], "..............");
	copyLineR(&board[x,y++], "....OO...OOOO.");
	copyLineR(&board[x,y++], "...OO.O.O.O..O");
	copyLineR(&board[x,y++], ".OOO....OO..O.");
	copyLineR(&board[x,y++], "O...O.......OO");
	copyLineR(&board[x,y++], "O.O..OO.......");
	copyLineR(&board[x,y++], "O.............");
	copyLineR(&board[x,y++], ".O............");
	copyLineR(&board[x,y++], ".O.O..........");
	copyLineR(&board[x,y++], "..O...........");
	copyLineR(&board[x,y++], ".OO...........");
	copyLineR(&board[x,y++], "..O.O.........");
	copyLineR(&board[x,y++], "...O..........");
}


function PlaceShip3(int x, int y) {
	copyLine(&board[x,y++], ".....O.....");
	copyLine(&board[x,y++], "..OO.OO....");
	copyLine(&board[x,y++], ".O.O.O.....");
	copyLine(&board[x,y++], "OO...O.....");
	copyLine(&board[x,y++], ".O.O..O....");
	copyLine(&board[x,y++], "..OO.O.....");
	copyLine(&board[x,y++], "...........");
	copyLine(&board[x,y++], "......OO...");
	copyLine(&board[x,y++], ".....O.OOO.");
	copyLine(&board[x,y++], "....O...OOO");
	copyLine(&board[x,y++], ".....O.O...");
	copyLine(&board[x,y++], "......O....");
}


function PlaceShip4(int x, int y) {
	copyLine(&board[x,y++], "..O........");
	copyLine(&board[x,y++], "OO.OO......");
	copyLine(&board[x,y++], "..O..O.O...");
	copyLine(&board[x,y++], ".......O...");
	copyLine(&board[x,y++], ".......O.O.");
	copyLine(&board[x,y++], ".......O..O");
	copyLine(&board[x,y++], ".....OO...O");
	copyLine(&board[x,y++], ".....OO....");
	copyLine(&board[x,y++], ".....OO....");
	copyLine(&board[x,y++], ".....OO...O");
	copyLine(&board[x,y++], ".......O..O");
	copyLine(&board[x,y++], ".......O.O.");
	copyLine(&board[x,y++], ".......O...");
	copyLine(&board[x,y++], "..O..O.O...");
	copyLine(&board[x,y++], "OO.OO......");
	copyLine(&board[x,y++], "..O........");
}


function PlaceShip5(int x, int y) {
	copyLineR(&board[x,y++], "............O........");
	copyLineR(&board[x,y++], ".........OO.O........");
	copyLineR(&board[x,y++], ".......O.O...........");
	copyLineR(&board[x,y++], ".....O............OO.");
	copyLineR(&board[x,y++], ".OO..O.OOO......O...O");
	copyLineR(&board[x,y++], "OO.OO.O...O.OO..OOOO.");
	copyLineR(&board[x,y++], ".O.....OOOO...O..O...");
	copyLineR(&board[x,y++], "OO............O......");
	copyLineR(&board[x,y++], ".O.....OOOO...O...OOO");
	copyLineR(&board[x,y++], "OO.OO.O...O.OO...O...");
	copyLineR(&board[x,y++], ".OO..O.OOO......O...O");
	copyLineR(&board[x,y++], ".....O...........O.O.");
	copyLineR(&board[x,y++], ".......O.O...........");
	copyLineR(&board[x,y++], ".........OO.O........");
	copyLineR(&board[x,y++], "............O........");
}


function PlaceShip6(int x, int y) {
	copyLine(&board[x,y++], ".OOOOO.....");
	copyLine(&board[x,y++], ".O....O....");
	copyLine(&board[x,y++], ".O.........");
	copyLine(&board[x,y++], "..O....O...");
	copyLine(&board[x,y++], "....O......");
	copyLine(&board[x,y++], ".....OO..O.");
	copyLine(&board[x,y++], "...O..O...O");
	copyLine(&board[x,y++], ".O.......O.");
	copyLine(&board[x,y++], "O.....O..O.");
	copyLine(&board[x,y++], "O...OO.....");
	copyLine(&board[x,y++], "OOOO..OO...");
}


function PlaceShip8(int x, int y) {
	copyLine(&board[x,y++], "..O........................");
	copyLine(&board[x,y++], "..OO.......................");
	copyLine(&board[x,y++], "...........................");
	copyLine(&board[x,y++], "...OOO.....................");
	copyLine(&board[x,y++], "...OOO.....................");
	copyLine(&board[x,y++], "....................O......");
	copyLine(&board[x,y++], "...................O.......");
	copyLine(&board[x,y++], "....OOO..............O.....");
	copyLine(&board[x,y++], ".....OO........OOO...O.....");
	copyLine(&board[x,y++], "O.OOO..O.....O......O......");
	copyLine(&board[x,y++], "O...O.OO.........OO........");
	copyLine(&board[x,y++], "OO.OO.OO.......O...........");
	copyLine(&board[x,y++], ".....OOO.....O...O.........");
	copyLine(&board[x,y++], "......OO......O..O.........");
	copyLine(&board[x,y++], ".......O......OOO..........");
	copyLine(&board[x,y++], "......OO...................");
	copyLine(&board[x,y++], "....O.O....................");
	copyLine(&board[x,y++], "..O........................");
	copyLine(&board[x,y++], ".O..O......................");
	copyLine(&board[x,y++], "O..O.......................");
	copyLine(&board[x,y++], "...O.......OOOOOOO.........");
	copyLine(&board[x,y++], "O.........OO.OOOO.OO.......");
	copyLine(&board[x,y++], "OOO...........O...OO..OO...");
	copyLine(&board[x,y++], "........O.O....OOO.O..OO...");
	copyLine(&board[x,y++], "......OO.......O.O....OO.O.");
	copyLine(&board[x,y++], "....O....O.......O.......OO");
	copyLine(&board[x,y++], "....O...O......O...........");
	copyLine(&board[x,y++], "....OO.O.......OOO.........");
}



function PlaceShip9(int x, int y) {
	copyLineR(&board[x,y++], "...............O.....O....");
	copyLineR(&board[x,y++], "..............O.....OO....");
	copyLineR(&board[x,y++], "..............O...O.......");
	copyLineR(&board[x,y++], "...............O....O.....");
	copyLineR(&board[x,y++], "...............O........OO");
	copyLineR(&board[x,y++], "...........OO...O.....O.O.");
	copyLineR(&board[x,y++], "..........O..O....OO......");
	copyLineR(&board[x,y++], ".........O.....O...O...O..");
	copyLineR(&board[x,y++], "..OO....O.O....OO.........");
	copyLineR(&board[x,y++], "..OO......O......O..O.....");
	copyLineR(&board[x,y++], "......O...O......OO..OO..O");
	copyLineR(&board[x,y++], "O....O..OO.............OO.");
	copyLineR(&board[x,y++], "O.O.OO.............O......");
	copyLineR(&board[x,y++], "OO..O.O.............O.....");
	copyLineR(&board[x,y++], "....................O.....");
	copyLineR(&board[x,y++], "...............OOO.O......");
	copyLineR(&board[x,y++], "..............O...O.......");
	copyLineR(&board[x,y++], "..............O..O........");
	copyLineR(&board[x,y++], "..........................");
	copyLineR(&board[x,y++], "............O..O..........");
	copyLineR(&board[x,y++], ".............OO...........");
	copyLineR(&board[x,y++], "............OO............");
	copyLineR(&board[x,y++], "................OO........");
	copyLineR(&board[x,y++], ".............O..OO........");
	copyLineR(&board[x,y++], "............O.............");
	copyLineR(&board[x,y++], "............OOO...........");
}



