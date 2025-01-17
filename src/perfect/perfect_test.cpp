#include <cstdio>
#include <iostream>
#include <windows.h>
#include "mill.h"
#include "miniMaxAI.h"
#include "randomAI.h"
#include "perfectAI.h"
#include "perfect.h"

#include "rule.h"
#include "config.h"

using namespace std;

extern Mill *mill;
extern PerfectAI *ai;

unsigned int startTestFromLayer = 0;

unsigned int endTestAtLayer = NUM_LAYERS - 1;

bool calculateDatabase = false;

#ifdef MADWEASEL_MUEHLE_PERFECT_AI_TEST
int main(void)
#else
int perfect_main(void)
#endif
{
    // locals
    bool playerOneHuman = false;
    bool playerTwoHuman = false;
    char ch[100];
    unsigned int from, to;
    mill = new Mill();
    ai = new PerfectAI(databaseDirectory);

    SetPriorityClass(GetCurrentProcess(), BELOW_NORMAL_PRIORITY_CLASS);
    srand(GetTickCount64());

    // intro
    cout << "*************************" << endl;
    cout << "* Muehle                *" << endl;
    cout << "*************************" << endl
        << endl;

    ai->setDatabasePath(databaseDirectory);

    // begin
#ifdef SELF_PLAY
    mill->beginNewGame(ai, ai, fieldStruct::playerOne);
#else
    mill->beginNewGame(ai, ai, (rand() % 2) ? fieldStruct::playerOne : fieldStruct::playerTwo);
#endif // SELF_PLAY

    if (calculateDatabase) {
        // calculate
        ai->calculateDatabase(MAX_DEPTH_OF_TREE, false);

        // test database
        cout << endl
            << "Begin test starting from layer: ";

        startTestFromLayer;

        cout << endl
            << "End test at layer: ";

        endTestAtLayer;

        ai->testLayers(startTestFromLayer, endTestAtLayer);

    } else {

#ifdef SELF_PLAY
        int moveCount = 0;
#else
        cout << "Is Player 1 human? (y/n):";

        cin >> ch;

        if (ch[0] == 'y')
            playerOneHuman = true;

        cout << "Is Player 2 human? (y/n):";

        cin >> ch;

        if (ch[0] == 'y')
            playerTwoHuman = true;
#endif // SELF_PLAY

        // play
        do {
            // print board
            cout << "\n\n\n";
            mill->getComputersChoice(&from, &to);
            cout << "\n\n";
            cout << "\nlast move was from " << (char)(mill->getLastMoveFrom() + 'a') << " to " << (char)(mill->getLastMoveTo() + 'a') << "\n\n";

#ifdef SELF_PLAY
            moveCount++;
            if (moveCount > rule.nMoveRule) {
                goto out;
            }
#endif // SELF_PLAY

            mill->printBoard();

            // Human
            if ((mill->getCurrentPlayer() == fieldStruct::playerOne && playerOneHuman) ||
                (mill->getCurrentPlayer() == fieldStruct::playerTwo && playerTwoHuman)) {

                do {
                    // Show text
                    if (mill->mustStoneBeRemoved())
                        cout << "\n   Which stone do you want to remove? [a-x]: \n\n\n";
                    else if (mill->inSettingPhase())
                        cout << "\n   Where are you going? [a-x]: \n\n\n";
                    else
                        cout << "\n   Your train? [a-x][a-x]: \n\n\n";

                    // get input
                    cin >> ch;
                    if ((ch[0] >= 'a') && (ch[0] <= 'x'))
                        from = ch[0] - 'a';
                    else
                        from = fieldStruct::size;

                    if (mill->inSettingPhase()) {
                        if ((ch[0] >= 'a') && (ch[0] <= 'x'))
                            to = ch[0] - 'a';
                        else
                            to = fieldStruct::size;
                    } else {
                        if ((ch[1] >= 'a') && (ch[1] <= 'x'))
                            to = ch[1] - 'a';
                        else
                            to = fieldStruct::size;
                    }

                    // undo
                    if (ch[0] == 'u' && ch[1] == 'n' && ch[2] == 'd' && ch[3] == 'o') {
                        // undo moves until a human player shall move
                        do {
                            mill->undoMove();
                        } while (!((mill->getCurrentPlayer() == fieldStruct::playerOne && playerOneHuman) ||
                                   (mill->getCurrentPlayer() == fieldStruct::playerTwo && playerTwoHuman)));

                        // reprint board
                        break;
                    }

                } while (mill->doMove(from, to) == false);

                // Computer
            } else {
                cout << "\n";
                mill->doMove(from, to);
            }

        } while (mill->getWinner() == 0);

        // end
        cout << "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n";

        mill->printBoard();

        if (mill->getWinner() == fieldStruct::playerOne)
            cout << "\n   Player 1 (o) won after " << mill->getMovesDone() << " move.\n\n";
        else if (mill->getWinner() == fieldStruct::playerTwo)
            cout << "\n   Player 2 (x) won after " << mill->getMovesDone() << " move.\n\n";
        else if (mill->getWinner() == fieldStruct::gameDrawn)
            cout << "\n   Draw!\n\n";
        else
            cout << "\n   A program error has occurred!\n\n";
    }

    char end;
    cin >> end;

    return 0;
}
