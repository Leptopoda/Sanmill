import '../mill/recorder.dart';
import 'mill.dart';

class Position {
  //
  BattleResult result = BattleResult.pending;

  String _sideToMove;
  List<String> _board; // 8  *  3
  MillRecorder _recorder;

  Position.defaultPosition() {
    initDefaultPosition();
  }

  Map<int, int> sqToLoc = {
    8: 17,
    9: 18,
    10: 25,
    11: 32,
    12: 31,
    13: 30,
    14: 23,
    15: 16,
    16: 10,
    17: 12,
    18: 26,
    19: 40,
    20: 38,
    21: 36,
    22: 22,
    23: 8,
    24: 3,
    25: 6,
    26: 27,
    27: 48,
    28: 45,
    29: 42,
    30: 21,
    31: 0
  };

  Map<int, int> locToSq;

  void initDefaultPosition() {
    //
    locToSq = sqToLoc.map((k, v) => MapEntry(v, k));

    _sideToMove = Side.black;
    _board = List<String>(64); // 7 * 7
    for (var i = 0; i < 64; i++) {
      _board[i] ??= Piece.noPiece;
    }

    // Debugging
    _board[sqToLoc[8]] = Piece.whiteStone;
    //_board[7] = Piece.ban;
    //_board[8] = Piece.whiteStone;

    _recorder = MillRecorder(lastCapturedPosition: toFen());
  }

  Position.clone(Position other) {
    //
    _board = List<String>();

    other._board.forEach((piece) => _board.add(piece));

    _sideToMove = other._sideToMove;

    _recorder = other._recorder;
  }

  String move(int from, int to) {
    //
    if (!validateMove(from, to)) return null;

    final captured = _board[to];

    final move = Move(from, to, captured: captured);
    //StepName.translate(this, move);
    _recorder.stepIn(move, this);

    // 修改棋盘
    _board[to] = _board[from];
    _board[from] = Piece.noPiece;

    // 交换走棋方
    _sideToMove = Side.opponent(_sideToMove);

    return captured;
  }

  // 验证移动棋子的着法是否合法
  bool validateMove(int from, int to) {
    // 移动的棋子的选手，应该是当前方
    if (Side.of(_board[from]) != _sideToMove) return false;
    return true;
    //(StepValidate.validate(this, Move(from, to)));
  }

  // 在判断行棋合法性等环节，要在克隆的棋盘上进行行棋假设，然后检查效果
  // 这种情况下不验证、不记录、不翻译
  void moveTest(Move move, {turnSide = false}) {
    //
    // 修改棋盘
    _board[move.to] = _board[move.from];
    _board[move.from] = Piece.noPiece;

    // 交换走棋方
    if (turnSide) _sideToMove = Side.opponent(_sideToMove);
  }

  bool regret() {
    //
    final lastMove = _recorder.removeLast();
    if (lastMove == null) return false;

    _board[lastMove.from] = _board[lastMove.to];
    _board[lastMove.to] = lastMove.captured;

    _sideToMove = Side.opponent(_sideToMove);

    final counterMarks = MillRecorder.fromCounterMarks(lastMove.counterMarks);
    _recorder.halfMove = counterMarks.halfMove;
    _recorder.fullMove = counterMarks.fullMove;

    if (lastMove.captured != Piece.noPiece) {
      //
      // 查找上一个吃子局面（或开局），NativeEngine 需要
      final tempPosition = Position.clone(this);

      final moves = _recorder.reverseMovesToPrevCapture();
      moves.forEach((move) {
        //
        tempPosition._board[move.from] = tempPosition._board[move.to];
        tempPosition._board[move.to] = move.captured;

        tempPosition._sideToMove = Side.opponent(tempPosition._sideToMove);
      });

      _recorder.lastCapturedPosition = tempPosition.toFen();
    }

    result = BattleResult.pending;

    return true;
  }

  String toFen() {
    // TODO
    var fen = '';

    for (var file = 1; file <= 3; file++) {
      //
      var emptyCounter = 0;

      for (var rank = 1; rank <= 8; rank++) {
        //
        final piece = pieceAt((file - 1) * 8 + rank + 8);

        if (piece == Piece.noPiece) {
          //
          emptyCounter++;
          //
        } else {
          //
          if (emptyCounter > 0) {
            fen += emptyCounter.toString();
            emptyCounter = 0;
          }

          fen += piece;
        }
      }

      if (emptyCounter > 0) fen += emptyCounter.toString();

      if (file < 9) fen += '/';
    }

    fen += ' $side';

    // step counter
    fen += '${_recorder?.halfMove ?? 0} ${_recorder?.fullMove ?? 0}';

    return fen;
  }

  String movesSinceLastCaptured() {
    //
    var steps = '', posAfterLastCaptured = 0;

    for (var i = _recorder.stepsCount - 1; i >= 0; i--) {
      if (_recorder.stepAt(i).captured != Piece.noPiece) break;
      posAfterLastCaptured = i;
    }

    for (var i = posAfterLastCaptured; i < _recorder.stepsCount; i++) {
      steps += ' ${_recorder.stepAt(i).step}';
    }

    return steps.length > 0 ? steps.substring(1) : '';
  }

  get manualText => _recorder.buildManualText();

  get side => _sideToMove;

  changeSideToMove() => _sideToMove = Side.opponent(_sideToMove);

  String pieceAt(int index) => _board[index];

  get halfMove => _recorder.halfMove;

  get fullMove => _recorder.fullMove;

  get lastMove => _recorder.last;

  get lastCapturedPosition => _recorder.lastCapturedPosition;
}