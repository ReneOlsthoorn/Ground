

f32[4] pieceSrcRect = [0,0,70,70];
f32[4] pieceDestRect = [0,0,70,70];


class Piece {
	int gridX;		// 0..7
	int gridY;		// 0..7
	int x;			// somewhere on the screen
	int y;
	int type;		// 0 = Pawn, 1 = King, 2 = Queen, 3 = Rook, 4 = Bishop, 5 = Knight
	ptr texture;
	bool isWhite;
	bool visible;

	function IsKing() : bool { return (this.type == 1); }
	function IsPawn() : bool { return (this.type == 0); }

	function FillXY() {
		if not (this.visible)
			return;
		this.x = this.gridX * BLOCK_DIM + OFFSET_PIXELS_GRID_LEFT;
		this.y = this.gridY * BLOCK_DIM;
	}

	function Render() {
		if not (this.visible)
			return;
		pieceDestRect[0] = this.x;
		pieceDestRect[1] = this.y;
		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		sdl3.SDL_RenderTextureRotated(renderer, this.texture, pieceSrcRect, pieceDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}

	function FillFrom(int px, int py) {
		this.visible = true;
		int startX = px - OFFSET_PIXELS_GRID_LEFT;
		if (startX < 0) {
			this.visible = false;
			return;
		}
		if (startX >= GRID_COLUMNS*BLOCK_DIM) {
			this.visible = false;
			return;
		}
		this.gridX = startX / BLOCK_DIM;
		this.gridY = py / BLOCK_DIM;
		this.FillXY();
	}

	function GetAlphaPosition(byte* p) {
		p[0] = this.gridX + 'a';
		p[1] = '1' + (7 - this.gridY);
		p[2] = 0;
	}

	function HasPosition(byte* p) {
		if not (this.visible)
			return false;
		int startGridX = p[0] - 'a';
		int startGridY = 7-(p[1] - '1');
		bool result = (this.gridX == startGridX and this.gridY == startGridY);
		return result;
	}

	function SetPosition(byte* p) {
		if not (this.visible)
			return;
		this.gridX = p[0] - 'a';
		this.gridY = 7-(p[1] - '1');
		this.FillXY();
	}
}
