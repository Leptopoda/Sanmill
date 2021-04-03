/*
  This file is part of Sanmill.
  Copyright (C) 2019-2021 The Sanmill developers (see AUTHORS file)

  Sanmill is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Sanmill is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanmill/common/config.dart';
import 'package:sanmill/engine/engine.dart';
import 'package:sanmill/engine/native_engine.dart';
import 'package:sanmill/generated/l10n.dart';
import 'package:sanmill/main.dart';
import 'package:sanmill/mill/game.dart';
import 'package:sanmill/mill/mill.dart';
import 'package:sanmill/mill/types.dart';
import 'package:sanmill/services/audios.dart';
import 'package:sanmill/style/colors.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:sanmill/style/app_theme.dart';

import 'board.dart';

class GamePage extends StatefulWidget {
  static double boardMargin = AppTheme.boardMargin;
  static double screenPaddingH = AppTheme.boardScreenPaddingH;

  final EngineType engineType;
  final AiEngine engine;

  GamePage(this.engineType) : engine = NativeEngine();

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with RouteAware {
  // TODO: null-safety
  String? _status = '';
  //bool _searching = false;

  @override
  void initState() {
    print("Engine type: ${widget.engineType}");

    Game.instance.setWhoIsAi(widget.engineType);

    super.initState();
    Game.instance.init();
    widget.engine.startup();
  }

  changeStatus(String? status) {
    setState(() => _status = status);
  }

  void showTips() {
    if (!mounted) {
      return;
    }

    final winner = Game.instance.position.winner;

    Map<String, String> colorWinStrings = {
      PieceColor.black: S.of(context).blackWin,
      PieceColor.white: S.of(context).whiteWin,
      PieceColor.draw: S.of(context).draw
    };

    if (winner == PieceColor.nobody) {
      if (Game.instance.position.phase == Phase.placing) {
        changeStatus(S.of(context).tipPlace);
      } else if (Game.instance.position.phase == Phase.moving) {
        changeStatus(S.of(context).tipMove);
      }
    } else {
      changeStatus(colorWinStrings[winner]);
    }

    showGameResult(winner);
  }

  onBoardTap(BuildContext context, int index) {
    if (Game.instance.engineType == EngineType.testViaLAN) {
      return false;
    }

    final position = Game.instance.position;

    int? sq = indexToSquare[index];

    if (sq == null) {
      //print("putPiece skip index: $index");
      return;
    }

    // TODO
    // WAR: Fix first tap response slow when piece count changed
    if (position.phase == Phase.placing &&
        position.pieceOnBoardCount[PieceColor.black] == 0 &&
        position.pieceOnBoardCount[PieceColor.white] == 0) {
      Game.instance.newGame();

      if (Game.instance.isAiToMove()) {
        if (Game.instance.aiIsSearching()) {
          print("AI is thinking, skip tapping.");
          return false;
        } else {
          print("AI is not thinking. AI is to move.");
          engineToGo();
          return false;
        }
      }
    }

    if (Game.instance.isAiToMove() || Game.instance.aiIsSearching()) {
      print("AI's turn, skip tapping.");
      return false;
    }

    if (position.phase == Phase.ready) {
      Game.instance.start();
    }

    bool ret = false;
    Chain.capture(() {
      switch (position.action) {
        case Act.place:
          if (position.putPiece(sq)) {
            if (position.action == Act.remove) {
              //Audios.playTone('mill.mp3');
              changeStatus(S.of(context).tipRemove);
            } else {
              //Audios.playTone('place.mp3');
              changeStatus(S.of(context).tipPlaced);
            }
            ret = true;
            print("putPiece: [$sq]");
            break;
          } else {
            print("putPiece: skip [$sq]");
            changeStatus(S.of(context).tipBanPlace);
          }

          // If cannot move, retry select, do not break
          //[[fallthrough]];
          continue select;
        select:
        case Act.select:
          if (position.selectPiece(sq)) {
            Audios.playTone('select.mp3');
            Game.instance.select(index);
            ret = true;
            print("selectPiece: [$sq]");
            changeStatus(S.of(context).tipPlace);
          } else {
            Audios.playTone('illegal.mp3');
            print("selectPiece: skip [$sq]");
            changeStatus(S.of(context).tipSelectWrong);
          }
          break;

        case Act.remove:
          if (position.removePiece(sq)) {
            //Audios.playTone('remove.mp3');
            ret = true;
            print("removePiece: [$sq]");
            changeStatus(S.of(context).tipRemoved);
          } else {
            Audios.playTone('illegal.mp3');
            print("removePiece: skip [$sq]");
            changeStatus(S.of(context).tipBanRemove);
          }
          break;

        default:
          break;
      }

      if (ret) {
        Game.instance.sideToMove = position.sideToMove() ?? PieceColor.nobody;
        Game.instance.moveHistory.add(position.cmdline);

        // TODO: Need Others?
        // Increment ply counters. In particular,
        // rule50 will be reset to zero later on
        // in case of a capture.
        ++position.gamePly;
        ++position.rule50;
        ++position.pliesFromNull;

        //position.move = m;

        Move m = Move(position.cmdline);
        position.recorder.moveIn(m, position);

        setState(() {});

        if (position.winner == PieceColor.nobody) {
          engineToGo();
        } else {
          showTips();
        }
      }

      Game.instance.sideToMove = position.sideToMove() ?? PieceColor.nobody;

      setState(() {});
    });

    return ret;
  }

  engineToGo() async {
    // TODO
    print("Engine to go");

    while ((Config.isAutoRestart == true ||
            Game.instance.position.winner == PieceColor.nobody) &&
        Game.instance.isAiToMove() &&
        mounted) {
      if (widget.engineType == EngineType.aiVsAi) {
        String score =
            Game.instance.position.score[PieceColor.black].toString() +
                " : " +
                Game.instance.position.score[PieceColor.white].toString() +
                " : " +
                Game.instance.position.score[PieceColor.draw].toString();

        changeStatus(score);
      } else {
        changeStatus(S.of(context).thinking);
      }

      print("Waiting for engine's response...");
      final response = await widget.engine.search(Game.instance.position);
      print("Engine response type: ${response.type}");

      switch (response.type) {
        case 'move':
          Move mv = response.value;
          final Move move = new Move(mv.move);

          //Battle.instance.move = move;
          Game.instance.doMove(move.move);
          showTips();
          break;
        case 'timeout':
          changeStatus(S.of(context).timeout);
          assert(false);
          return;
        default:
          changeStatus('Error: ${response.type}');
          break;
      }

      if (Config.isAutoRestart == true &&
          Game.instance.position.winner != PieceColor.nobody) {
        Game.instance.newGame();
      }
    }
  }

  newGame() {
    confirm() {
      Navigator.of(context).pop();
      Game.instance.newGame();
      changeStatus(S.of(context).gameStarted);

      if (Game.instance.isAiToMove()) {
        print("New game, AI to move.");
        engineToGo();
      }
    }

    cancel() => Navigator.of(context).pop();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).newGame,
              style: TextStyle(color: UIColors.primaryColor)),
          content:
              SingleChildScrollView(child: Text(S.of(context).restartGame)),
          actions: <Widget>[
            TextButton(child: Text(S.of(context).restart), onPressed: confirm),
            TextButton(child: Text(S.of(context).cancel), onPressed: cancel),
          ],
        );
      },
    );
  }

  String getGameOverReasonString(GameOverReason? reason, String? winner) {
    String loseReasonStr;
    //String winnerStr =
    //    winner == Color.black ? S.of(context).black : S.of(context).white;
    String loserStr =
        winner == PieceColor.black ? S.of(context).white : S.of(context).black;

    switch (Game.instance.position.gameOverReason) {
      case GameOverReason.loseReasonlessThanThree:
        loseReasonStr = loserStr + S.of(context).loseReasonlessThanThree;
        break;
      case GameOverReason.loseReasonResign:
        loseReasonStr = loserStr + S.of(context).loseReasonResign;
        break;
      case GameOverReason.loseReasonNoWay:
        loseReasonStr = loserStr + S.of(context).loseReasonNoWay;
        break;
      case GameOverReason.loseReasonBoardIsFull:
        loseReasonStr = loserStr + S.of(context).loseReasonBoardIsFull;
        break;
      case GameOverReason.loseReasonTimeOver:
        loseReasonStr = loserStr + S.of(context).loseReasonTimeOver;
        break;
      case GameOverReason.drawReasonRule50:
        loseReasonStr = S.of(context).drawReasonRule50;
        break;
      case GameOverReason.drawReasonBoardIsFull:
        loseReasonStr = S.of(context).drawReasonBoardIsFull;
        break;
      case GameOverReason.drawReasonThreefoldRepetition:
        loseReasonStr = S.of(context).drawReasonThreefoldRepetition;
        break;
      default:
        loseReasonStr = S.of(context).gameOverUnknownReason;
        break;
    }

    return loseReasonStr;
  }

  GameResult getGameResult(var winner) {
    if (isAi[PieceColor.black]! && isAi[PieceColor.white]!) {
      return GameResult.none;
    }

    if (winner == PieceColor.black) {
      if (isAi[PieceColor.black]!) {
        return GameResult.lose;
      } else {
        return GameResult.win;
      }
    }

    if (winner == PieceColor.white) {
      if (isAi[PieceColor.white]!) {
        return GameResult.lose;
      } else {
        return GameResult.win;
      }
    }

    if (winner == PieceColor.draw) {
      return GameResult.draw;
    }

    return GameResult.none;
  }

  void showGameResult(var winner) {
    GameResult result = getGameResult(winner);
    Game.instance.position.result = result;

    switch (result) {
      case GameResult.win:
        //Audios.playTone('win.mp3');
        break;
      case GameResult.lose:
        //Audios.playTone('lose.mp3');
        break;
      case GameResult.draw:
        break;
      default:
        break;
    }

    Map<GameResult, String> retMap = {
      GameResult.win: S.of(context).youWin,
      GameResult.lose: S.of(context).gameOver,
      GameResult.draw: S.of(context).draw
    };

    var dialogTitle = retMap[result];

    if (dialogTitle == null) {
      return;
    }

    if (result == GameResult.win) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(dialogTitle,
                style: TextStyle(color: UIColors.primaryColor)),
            content: Text(getGameOverReasonString(
                    Game.instance.position.gameOverReason,
                    Game.instance.position.winner) +
                S.of(context).challengeHarderLevel),
            actions: <Widget>[
              TextButton(
                  child: Text(S.of(context).yes),
                  onPressed: () {
                    Config.skillLevel++;
                    Config.save();
                    Navigator.of(context).pop();
                  }),
              TextButton(
                  child: Text(S.of(context).no),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(dialogTitle,
                style: TextStyle(color: UIColors.primaryColor)),
            content: Text(getGameOverReasonString(
                Game.instance.position.gameOverReason,
                Game.instance.position.winner)),
            actions: <Widget>[
              TextButton(
                  child: Text(S.of(context).restart),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Game.instance.newGame();
                    changeStatus(S.of(context).gameStarted);

                    if (Game.instance.isAiToMove()) {
                      print("New game, AI to move.");
                      engineToGo();
                    }
                  }),
              TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop()),
            ],
          );
        },
      );
    }
  }

  void calcScreenPaddingH() {
    //
    // when screen's height/width rate is less than 16/9, limit witdh of board
    final windowSize = MediaQuery.of(context).size;
    double height = windowSize.height, width = windowSize.width;

    if (height / width < 16.0 / 9.0) {
      width = height * 9 / 16;
      GamePage.screenPaddingH =
          (windowSize.width - width) / 2 - AppTheme.boardMargin;
    }
  }

  Widget createPageHeader() {
    Map<EngineType, IconData> engineTypeToIconLeft = {
      EngineType.humanVsAi: Config.aiMovesFirst ? Icons.computer : Icons.person,
      EngineType.humanVsHuman: Icons.person,
      EngineType.aiVsAi: Icons.computer,
      EngineType.humanVsCloud: Icons.person,
      EngineType.humanVsLAN: Icons.person,
      EngineType.testViaLAN: Icons.cast,
    };

    Map<EngineType, IconData> engineTypeToIconRight = {
      EngineType.humanVsAi: Config.aiMovesFirst ? Icons.person : Icons.computer,
      EngineType.humanVsHuman: Icons.person,
      EngineType.aiVsAi: Icons.computer,
      EngineType.humanVsCloud: Icons.cloud,
      EngineType.humanVsLAN: Icons.cast,
      EngineType.testViaLAN: Icons.cast,
    };

    IconData iconArrow = getIconArrow();

    final subTitleStyle =
        TextStyle(fontSize: 16, color: UIColors.darkTextSecondaryColor);

    var iconColor = UIColors.darkTextPrimaryColor;

    var iconRow = Row(
      children: <Widget>[
        Expanded(child: SizedBox()),
        Icon(engineTypeToIconLeft[widget.engineType], color: iconColor),
        Icon(iconArrow, color: iconColor),
        Icon(engineTypeToIconRight[widget.engineType], color: iconColor),
        Expanded(child: SizedBox()),
      ],
    );

    return Container(
      margin: EdgeInsets.only(top: SanmillApp.StatusBarHeight),
      child: Column(
        children: <Widget>[
          iconRow,
          Container(
            height: 4,
            width: 180,
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Color(Config.boardBackgroundColor),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(_status!, maxLines: 1, style: subTitleStyle),
          ),
        ],
      ),
    );
  }

  IconData getIconArrow() {
    IconData iconArrow = Icons.code;

    if (Game.instance.position.phase == Phase.gameOver) {
      switch (Game.instance.position.winner) {
        case PieceColor.black:
          iconArrow = Icons.toggle_off_outlined;
          break;
        case PieceColor.white:
          iconArrow = Icons.toggle_on_outlined;
          break;
        default:
          iconArrow = Icons.thumbs_up_down_outlined;
          break;
      }
    } else {
      switch (Game.instance.sideToMove) {
        case PieceColor.black:
          iconArrow = Icons.keyboard_arrow_left;
          break;
        case PieceColor.white:
          iconArrow = Icons.keyboard_arrow_right;
          break;
        default:
          iconArrow = Icons.code;
          break;
      }
    }

    return iconArrow;
  }

  Widget createBoard() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: GamePage.screenPaddingH,
        vertical: GamePage.boardMargin,
      ),
      child: Board(
        width: MediaQuery.of(context).size.width - GamePage.screenPaddingH * 2,
        onBoardTap: onBoardTap,
      ),
    );
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget createToolbar() {
    final manualText = Game.instance.position.manualText;

    // TODO:
    final analyzeText = "Score: " +
        Game.instance.position.score[PieceColor.black].toString() +
        " : " +
        Game.instance.position.score[PieceColor.white].toString() +
        " : " +
        Game.instance.position.score[PieceColor.draw].toString() +
        "\n" +
        "Black has: " +
        Game.instance.position.pieceInHandCount[PieceColor.black].toString() +
        " pieces in hand\n" +
        "White has: " +
        Game.instance.position.pieceInHandCount[PieceColor.white].toString() +
        " pieces in hand\n" +
        "Black has: " +
        Game.instance.position.pieceOnBoardCount[PieceColor.black].toString() +
        " pieces on board\n" +
        "White has: " +
        Game.instance.position.pieceOnBoardCount[PieceColor.white].toString() +
        " pieces on board\n";

    final manualStyle =
        TextStyle(fontSize: 18, height: 1.5, color: Colors.yellow);

    var newGameButton = TextButton(
      child: Column(
        // Replace with a Row for horizontal icon + text
        children: <Widget>[
          Icon(
            Icons.motion_photos_on,
            color: UIColors.secondaryColor,
          ),
          Text(S.of(context).newGame,
              style: TextStyle(color: UIColors.secondaryColor)),
        ],
      ),
      onPressed: newGame,
    );

    var undoButton = TextButton(
      child: Column(
        // Replace with a Row for horizontal icon + text
        children: <Widget>[
          Icon(
            Icons.restore,
            color: UIColors.secondaryColor,
          ),
          Text(S.of(context).regret,
              style: TextStyle(color: UIColors.secondaryColor)),
        ],
      ),
      onPressed: () {
        Game.instance.regret(steps: 2);
        setState(() {});
      },
    );

    var moveHistoryButton = TextButton(
      child: Column(
        // Replace with a Row for horizontal icon + text
        children: <Widget>[
          Icon(
            Icons.list_alt,
            color: UIColors.secondaryColor,
          ),
          Text(S.of(context).gameRecord,
              style: TextStyle(color: UIColors.secondaryColor)),
        ],
      ),
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text(S.of(context).gameRecord,
                style: TextStyle(color: Colors.yellow)),
            content: SingleChildScrollView(
                child: Text(manualText, style: manualStyle)),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context).copy, style: manualStyle),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: manualText))
                        .then((_) {
                  showSnackBar(S.of(context).moveHistoryCopied);
                }),
              ),
              TextButton(
                child: Text(S.of(context).cancel, style: manualStyle),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );

    var hintButton = TextButton(
      child: Column(
        // Replace with a Row for horizontal icon + text
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline,
            color: UIColors.secondaryColor,
          ),
          Text(S.of(context).hint,
              style: TextStyle(color: UIColors.secondaryColor)),
        ],
      ),
      onPressed: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text(S.of(context).analyze,
                style: TextStyle(color: Colors.yellow)),
            content: SingleChildScrollView(
                child: Text(analyzeText, style: manualStyle)),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context).ok, style: manualStyle),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Color(Config.boardBackgroundColor),
      ),
      margin: EdgeInsets.symmetric(horizontal: GamePage.screenPaddingH),
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(children: <Widget>[
        Expanded(child: SizedBox()),
        newGameButton,
        Expanded(child: SizedBox()),
        undoButton,
        Expanded(child: SizedBox()),
        moveHistoryButton,
        Expanded(child: SizedBox()), //dashboard_outlined
        hintButton,
        Expanded(child: SizedBox()),
      ]),
    );
  }

  Widget buildMoveHistoryPanel(String text) {
    final manualStyle = TextStyle(
      fontSize: 18,
      color: UIColors.darkTextSecondaryColor,
      height: 1.5,
    );

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 16),
        child: SingleChildScrollView(child: Text(text, style: manualStyle)),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  Widget build(BuildContext context) {
    calcScreenPaddingH();

    final header = createPageHeader();
    final board = createBoard();
    final toolbar = createToolbar();

    return Scaffold(
      backgroundColor: Color(Config.darkBackgroundColor),
      body: Column(children: <Widget>[header, board, toolbar]),
    );
  }

  @override
  void dispose() {
    widget.engine.shutdown();
    super.dispose();
    routeObserver.unsubscribe(this);
  }

  @override
  void didPush() {
    final route = ModalRoute.of(context)!.settings.name;
    print('Game Page didPush route: $route');
    widget.engine.setOptions();
  }

  @override
  void didPopNext() {
    final route = ModalRoute.of(context)!.settings.name;
    print('Game Page didPopNext route: $route');
    widget.engine.setOptions();
  }

  @override
  void didPushNext() {
    final route = ModalRoute.of(context)!.settings.name;
    print('Game Page didPushNext route: $route');
    widget.engine.setOptions();
  }

  @override
  void didPop() {
    final route = ModalRoute.of(context)!.settings.name;
    print('Game Page didPop route: $route');
  }
}
