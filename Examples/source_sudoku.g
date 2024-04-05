//run console
//Sudoku solver

int[9,9] puzzle = [
    0, 0, 0, 3, 6, 0, 5, 7, 2,
    6, 0, 0, 0, 0, 0, 0, 0, 4,
    0, 7, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 2, 6, 0, 3, 0, 0, 0,
    5, 0, 0, 0, 0, 0, 8, 2, 0,
    0, 0, 8, 0, 4, 0, 0, 3, 9,
    4, 3, 0, 8, 0, 1, 0, 0, 5,
    0, 0, 7, 2, 5, 9, 0, 0, 0,
    0, 5, 9, 0, 3, 0, 0, 0, 0 ];

// Result:
// 981  364  572
// 625  798  314
// 374  125  968
// 192  683  457
// 543  917  826
// 768  542  139
// 436  871  295
// 817  259  643
// 259  436  781

function draw() {
    for (int y = 0; y < 9; y++)
    {
        for (int x = 0; x < 9; x++)
        {
            print(puzzle[x,y]);
            if ((x + 1) % 3 == 0)
                print("  ");
        }
        print("\n");
        if ((y + 1) % 3 == 0)
            print("\n");
    }
}


function solve(int col, int row, int num) {
    for (int x = 0; x < 9; x++) {
        if (puzzle[x, row] == num) {
            return false;
        }
    }
    for (int y = 0; y < 9; y++) {
        if (puzzle[col, y] == num) {
            return false;
        }
    }

    int startRow = row - (row % 3);
    int startCol = col - (col % 3);

    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            if (puzzle[(j + startCol), (i + startRow)] == num) {
                return false;
            }
        }
    }
    return true;
}


function Sudoku(int col, int row) {
    if ((row == 8) and (col == 9)) {
        return true;
    }

    if (col == 9) {
        row = row + 1;
        col = 0;
    }

    if (puzzle[col, row] > 0) {
        return Sudoku(col+1, row);
    }

    for (int num = 1; num < 10; num++) {
        if (solve(col, row, num) == true) {
            puzzle[col, row] = num;
            if (Sudoku(col + 1, row) == true) {
                return true;
            }
        }
        puzzle[col, row] = 0;
    }
    return false;
}

println("Input Sudoku:\r\n");
draw();

bool result = Sudoku(0, 0);
if (result == true) {
    println("\r\nSolution:\r\n");
    draw();
} else {
    println("Solution does not exist.\r\n");
}
