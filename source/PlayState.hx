package;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;

class PlayState extends FlxState
{
    public static var curPiece(default, set): Piece;
    public static var borderWidth: Int = 18;

    var cleared(default, set): Int = 0;
    var clearedText: FlxText;
    var gameOver: Bool;
    var grid: GameGrid.Sprites;
    var heldPiece(default, set): Piece;
    var heldPieceDisplay: PieceDisplay;
    var nextPieceDisplay: PieceDisplay;

    override public function create()
    {
        super.create();

        PieceQueue.updatePiece();
        curPiece = PieceQueue.getAndUpdatePiece();

        var gridWidth = GameGrid.columns * GameGrid.Sprites.cellSize;
        var gridHeight = (GameGrid.rows - GameGrid.Sprites.hiddenRows) * GameGrid.Sprites.cellSize;

        grid = new GameGrid.Sprites((FlxG.width - gridWidth) / 2, (FlxG.height - gridHeight) / 2);
        add(grid);

        add(new FlxSprite(grid.x - borderWidth, grid.y).makeGraphic(borderWidth, gridHeight, 0xFF808080));
        add(new FlxSprite(grid.x + gridWidth, grid.y).makeGraphic(borderWidth, gridHeight, 0xFF808080));
        add(new FlxSprite(grid.x - borderWidth, grid.y - borderWidth).makeGraphic(gridWidth + borderWidth * 2, borderWidth, 0xFF808080));
        add(new FlxSprite(grid.x - borderWidth, grid.y + gridHeight).makeGraphic(gridWidth + borderWidth * 2, borderWidth, 0xFF808080));

        heldPieceDisplay = new PieceDisplay(95, 95);
        heldPieceDisplay.updateSprites();
        add(heldPieceDisplay);

        nextPieceDisplay = new PieceDisplay(951, 95);
        nextPieceDisplay.updateSprites(PieceQueue.next);
        add(nextPieceDisplay);

        clearedText = new FlxText(0, 600, 0, "Score: 0", 24);
        clearedText.x = (460 - clearedText.width) / 2;
        add(clearedText);
    }

    var frames: Int = 0;
    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        frames++;
        gameOver = !GameGrid.isRowEmpty(0) && !GameGrid.isRowEmpty(1);

        if (!gameOver) {
            if (FlxG.keys.justPressed.LEFT)
                movePieceLeft();
            if (FlxG.keys.justPressed.RIGHT)
                movePieceRight();
            if (FlxG.keys.justPressed.DOWN)
                movePieceDown();
            if (FlxG.keys.justPressed.UP)
                rotatePieceClockwise();
            if (FlxG.keys.justPressed.Z)
                rotatePieceCounterClockwise();
            if (FlxG.keys.justPressed.C)
                heldPiece = curPiece;
            if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE) {
                curPiece.move(getDropDistance(), 0);
                placePiece();
            }

            if (frames % 30 == 0) {
                frames = 0;
                movePieceDown();
            }
        } else {
            GameGrid.clear();
            FlxG.switchState(new PlayState());
        }
    }

    static function doesFit() {
        for (i in curPiece.getTilePoints()) {
            if (!GameGrid.isEmpty(i.row, i.column))
                return false;
        }

        return true;
    }

    public function rotatePieceClockwise() {
        curPiece.rotateClockwise();

        if (!doesFit())
            curPiece.rotateCounterClockwise();

        grid.updateSprites();
    }

    public function rotatePieceCounterClockwise() {
        curPiece.rotateCounterClockwise();

        if (!doesFit())
            curPiece.rotateClockwise();

        grid.updateSprites();
    }

    public function movePieceLeft() {
        curPiece.move(0, -1);

        if (!doesFit())
            curPiece.move(0, 1);

        grid.updateSprites();
    }

    public function movePieceRight() {
        curPiece.move(0, 1);

        if (!doesFit())
            curPiece.move(0, -1);

        grid.updateSprites();
    }

    public function movePieceDown() {
        curPiece.move(1, 0);

        if (!doesFit()) {
            curPiece.move(-1, 0);
            placePiece();
        }

        grid.updateSprites();
    }

    public function placePiece() {
        for (i in curPiece.getTilePoints())
            GameGrid.set(i.row, i.column, curPiece.id);

        cleared += GameGrid.clearRows();

        if (!gameOver) {
            curPiece = PieceQueue.getAndUpdatePiece();
            nextPieceDisplay.updateSprites(PieceQueue.next);
        }
    }

    public static function getDropDistance() {
        var drop = GameGrid.rows;

        for (i in curPiece.getTilePoints()) {
            var distance = 0;
            while (GameGrid.isEmpty(i.row + distance + 1, i.column))
                distance++;
            drop = Std.int(Math.min(drop, distance));
        }

        return drop;
    }

    public static function getGhostPiece() {
        return curPiece.getTilePoints().map(x -> new Point(x.row + getDropDistance(), x.column));
    }

    static function set_curPiece(value: Piece) {
        curPiece = value;
        curPiece.reset();

        curPiece.move(1, 0);

        if (!doesFit())
            curPiece.move(-1, 0);
        else {
            curPiece.move(1, 0);
    
            if (!doesFit())
                curPiece.move(-1, 0);
        }

        return value;
    }

    function set_heldPiece(value: Piece) {
        var previousHeldPiece = heldPiece;
        heldPiece = value;
        heldPiece.reset();

        curPiece = previousHeldPiece != null ? previousHeldPiece : PieceQueue.getAndUpdatePiece();
        heldPieceDisplay.updateSprites(heldPiece);
        return value;
    }

    function set_cleared(value: Int) {
        cleared = value;
        clearedText.text = "Score: " + value;
        return value;
    }
}

class PieceDisplay extends FlxSpriteGroup {
    public static var outlineWidth: Int = 18;
    public static var pieceBlockWidth: Int = 36;
    public static var pieceBlockOutlineWidth: Int = 2;
    public static var sprWidth: Int = 252;
    public static var pieces: Array<Array<Dynamic>> = [ // Block 1, Block 2, Block 3, Block 4, Width, Height
        [[0, 0], [0, 0], [0, 0], [0, 0], 0, 0],
        [[0, 0], [1, 0], [2, 0], [3, 0], 4, 1],
        [[0, 0], [0, 1], [1, 1], [2, 1], 3, 2],
        [[2, 0], [0, 1], [1, 1], [2, 1], 3, 2],
        [[0, 0], [1, 0], [0, 1], [1, 1], 2, 2],
        [[1, 0], [2, 0], [0, 1], [1, 1], 3, 2],
        [[0, 1], [1, 1], [2, 1], [1, 0], 3, 2],
        [[0, 0], [1, 0], [1, 1], [2, 1], 3, 2]
    ];

    public function updateSprites(?piece: Piece) {
        clear();

        add(new FlxSprite().makeGraphic(sprWidth, sprWidth, 0xFF808080));
        add(new FlxSprite(outlineWidth, outlineWidth).makeGraphic(sprWidth - outlineWidth * 2, sprWidth - outlineWidth * 2, 0xFF000000));

        if (piece != null) {
            var pieceData = pieces[piece.id];
            var sprite = new FlxSpriteGroup((sprWidth - pieceData[4] * pieceBlockWidth) / 2, (sprWidth - pieceData[5] * pieceBlockWidth) / 2);
            for (i in 0...4) {
                sprite.add(new FlxSprite(
                    pieceData[i][0] * pieceBlockWidth + pieceBlockOutlineWidth,
                    pieceData[i][1] * pieceBlockWidth + pieceBlockOutlineWidth
                ).makeGraphic(
                    pieceBlockWidth - pieceBlockOutlineWidth * 2,
                    pieceBlockWidth - pieceBlockOutlineWidth * 2,
                    GameGrid.Sprites.blockColors[piece.id]
                ));
            }
            add(sprite);
        }
    }
}