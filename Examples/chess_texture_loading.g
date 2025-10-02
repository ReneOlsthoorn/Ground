
ptr surface = sdl3_image.IMG_Load("image/chess/board.png");
if (surface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr convertedSurface = sdl3.SDL_ConvertSurface(surface, g.SDL_PIXELFORMAT_ARGB8888);
ptr texture = sdl3.SDL_CreateTextureFromSurface(renderer, convertedSurface);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
sdl3.SDL_DestroySurface(convertedSurface);

ptr[12] pieceTextures = [] asm;

function LoadPieceTexture(int pieceNr, string path) {
	surface = sdl3_image.IMG_Load(path);
	pieceTextures[pieceNr] = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
	sdl3.SDL_SetTextureScaleMode(pieceTextures[pieceNr], g.SDL_SCALEMODE_NEAREST);
	sdl3.SDL_DestroySurface(surface);
}
LoadPieceTexture(0, "image/chess/bp.png");
LoadPieceTexture(1, "image/chess/bk.png");
LoadPieceTexture(2, "image/chess/bq.png");
LoadPieceTexture(3, "image/chess/br.png");
LoadPieceTexture(4, "image/chess/bb.png");
LoadPieceTexture(5, "image/chess/bn.png");
LoadPieceTexture(6, "image/chess/wp.png");
LoadPieceTexture(7, "image/chess/wk.png");
LoadPieceTexture(8, "image/chess/wq.png");
LoadPieceTexture(9, "image/chess/wr.png");
LoadPieceTexture(10, "image/chess/wb.png");
LoadPieceTexture(11, "image/chess/wn.png");

function SetPiecesTextures() {
	for (i in 8..15) {
		pieces[i].texture = pieceTextures[0];
		pieces[i].type = 0;
	}
	pieces[4].texture = pieceTextures[1];
	pieces[4].type = 1;

	pieces[3].texture = pieceTextures[2];
	pieces[3].type = 2;

	pieces[0].texture = pieceTextures[3];
	pieces[0].type = 3;
	pieces[7].texture = pieceTextures[3];
	pieces[7].type = 3;

	pieces[2].texture = pieceTextures[4];
	pieces[2].type = 4;
	pieces[5].texture = pieceTextures[4];
	pieces[5].type = 4;

	pieces[1].texture = pieceTextures[5];
	pieces[1].type = 5;
	pieces[6].texture = pieceTextures[5];
	pieces[6].type = 5;

	for (i in 16..23) {
		pieces[i].texture = pieceTextures[6];
		pieces[i].type = 0;
	}
	pieces[28].texture = pieceTextures[7];
	pieces[28].type = 1;

	pieces[27].texture = pieceTextures[8];
	pieces[27].type = 2;

	pieces[24].texture = pieceTextures[9];
	pieces[24].type = 3;
	pieces[31].texture = pieceTextures[9];
	pieces[31].type = 3;

	pieces[26].texture = pieceTextures[10];
	pieces[26].type = 4;
	pieces[29].texture = pieceTextures[10];
	pieces[29].type = 4;

	pieces[25].texture = pieceTextures[11];
	pieces[25].type = 5;
	pieces[30].texture = pieceTextures[11];
	pieces[30].type = 5;
}
SetPiecesTextures();

ptr selectorTexture;
surface = sdl3_image.IMG_Load("image/chess/fieldselector.png");
selectorTexture = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
sdl3.SDL_SetTextureScaleMode(selectorTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
selector.texture = selectorTexture;
startSelection.texture = selectorTexture;

function FreePieceTextures() {
	for (i in 0..11)
		sdl3.SDL_DestroyTexture(pieceTextures[i]);

	sdl3.SDL_DestroyTexture(selectorTexture);
}

//
// +---+---+---+---+---+---+---+---+
// | r | n | b | q | k | b | n | r | 8
// +---+---+---+---+---+---+---+---+
// | p | p | p | p | p | p | p | p | 7
// +---+---+---+---+---+---+---+---+
// |   |   |   |   |   |   |   |   | 6
// +---+---+---+---+---+---+---+---+
// |   |   |   |   |   |   |   |   | 5
// +---+---+---+---+---+---+---+---+
// |   |   |   |   |   |   |   |   | 4
// +---+---+---+---+---+---+---+---+
// |   |   |   |   |   |   |   |   | 3
// +---+---+---+---+---+---+---+---+
// | P | P | P | P | P | P | P | P | 2
// +---+---+---+---+---+---+---+---+
// | R | N | B | Q | K | B | N | R | 1
// +---+---+---+---+---+---+---+---+
//   a   b   c   d   e   f   g   h
//

